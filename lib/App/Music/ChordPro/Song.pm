#!/usr/bin/perl

package main;

our $options;
our $config;

package App::Music::ChordPro::Song;

use strict;
use warnings;

use App::Music::ChordPro;
use App::Music::ChordPro::Chords;
use App::Music::ChordPro::Chords::Parser;
use App::Music::ChordPro::Output::Common;
use App::Music::ChordPro::Utils;

use Carp;
use List::Util qw(any);
use File::LoadLines;
use Storable qw(dclone);
use feature 'state';

# Parser context.
my $def_context = "";
my $in_context = $def_context;
my $skip_context = 0;
my $grid_arg;
my $grid_cells;

# Local transposition.
my $xpose = 0;
my $xpose_dir;
my $capo;

# Used chords, in order of appearance.
my @used_chords;

# Chorus lines, if any.
my @chorus;
my $chorus_xpose = 0;
my $chorus_xpose_dir = 0;

# Memorized chords.
my %memchords;			# all sections
my $memchords;			# current section
my $memcrdinx;			# chords tally
my $memorizing;			# if memorizing (a.o.t. recalling)

# Keep track of unknown chords, to avoid dup warnings.
my %warned_chords;

my $re_chords;			# for chords
my $intervals;			# number of note intervals
my @labels;			# labels used

# Normally, transposition and subtitutions are handled by the parser.
my $decapo;
my $no_transpose;		# NYI
my $no_substitute;

my $diag;			# for diagnostics
my $lineinfo;			# keep lineinfo

# Constructor.

sub new {
    my ( $pkg, $filesource ) = @_;

    $xpose = 0;
    $grid_arg = [ 4, 4, 1, 1 ];	# 1+4x4+1
    $in_context = $def_context;
    @used_chords = ();
    %warned_chords = ();
    %memchords = ();
    App::Music::ChordPro::Chords::reset_song_chords();
    @labels = ();
    @chorus = ();
    $capo = undef;
    upd_config();

    $diag->{format} = $config->{diagnostics}->{format};
    $diag->{file}   = $filesource;
    $diag->{line}   = 0;
    $diag->{orig}   = "(at start of song)";

    bless { chordsinfo => {},
	    meta       => {},
	    structure  => "linear",
	  } => $pkg;
}

sub upd_config {
    $decapo    = $config->{settings}->{decapo};
    $lineinfo  = $config->{settings}->{lineinfo};
    $intervals = @{ $config->{notes}->{sharp} };
}

sub ::break() {}

sub parse_song {
    my ( $self, $lines, $linecnt, $meta ) = @_;
    die("OOPS! Wrong meta") unless ref($meta) eq 'HASH';
    local $config = dclone($config);

    warn("Processing song ", $diag->{file}, "...\n") if $options->{verbose};
    ::break();
    # Load song-specific config, if any.
    if ( !$options->{nosongconfig} && $diag->{file} ) {
	if ( $options->{verbose} ) {
	    my $this = App::Music::ChordPro::Chords::get_parser();
	    $this = defined($this) ? $this->{system} : "";
	    print STDERR ("Parsers at start of ", $diag->{file}, ":");
	    print STDERR ( $this eq $_ ? " *" : " ", "$_")
	      for keys %{ App::Music::ChordPro::Chords::Parser->parsers };
	    print STDERR ("\n");
	}
	my $t = join("|",@{$config->{tuning}});
	my @configs;
	if ( $meta && $meta->{__config} ) {
	    my $cf = delete($meta->{__config})->[0];
	    die("Missing config: $cf\n") unless -s $cf;
	    warn("Config[song]: $cf\n") if $options->{verbose};
	    my $have = App::Music::ChordPro::Config::get_config($cf);
	    @configs = App::Music::ChordPro::Config::prep_configs( $have, $cf);
	}
	else {
	    for ( "prp", "json" ) {
		( my $cf = $diag->{file} ) =~ s/\.\w+$/.$_/;
		$cf .= ".$_" if $cf eq $diag->{file};
		next unless -s $cf;
		warn("Config[song]: $cf\n") if $options->{verbose};
		my $have = App::Music::ChordPro::Config::get_config($cf);
		@configs = App::Music::ChordPro::Config::prep_configs( $have, $cf);
		last;
	    }
	}
	foreach my $have ( @configs ) {
	    warn("Config[song*]: ", $have->{_src}, "\n") if $options->{verbose};
	    my $chords = $have->{chords};
	    $config->augment($have);
	    if ( $t ne join("|",@{$config->{tuning}}) ) {
		my $res =
		  App::Music::ChordPro::Chords::set_tuning($config);
		warn( "Invalid tuning in config: ", $res, "\n" ) if $res;
	    }
	    App::Music::ChordPro::Chords::reset_parser();
	    App::Music::ChordPro::Chords::Parser->reset_parsers;
	    if ( $chords ) {
		my $c = $chords;
		if ( @$c && $c->[0] eq "append" ) {
		    shift(@$c);
		}
		foreach ( @$c ) {
		    my $res =
		      App::Music::ChordPro::Chords::add_config_chord($_);
		    warn( "Invalid chord in config: ",
			  $_->{name}, ": ", $res, "\n" ) if $res;
		}
	    }
	    if ( $options->{verbose} > 1 ) {
		warn( "Processed ", scalar(@$chords), " chord entries\n")
		  if $chords;
		warn( "Totals: ",
		      App::Music::ChordPro::Chords::chord_stats(), "\n" );
	    }
	    if ( 0 && $options->{verbose} ) {
		my $this = App::Music::ChordPro::Chords::get_parser()->{system};
		print STDERR ("Parsers after local config:");
		print STDERR ( $this eq $_ ? " *" : " ", "$_")
		  for keys %{ App::Music::ChordPro::Chords::Parser->parsers };
		print STDERR ("\n");
	    }
	}
    }

    $config->unlock;
    for ( qw( transpose transcode decapo lyrics-only ) ) {
	next unless defined $options->{$_};
	$config->{settings}->{$_} = $options->{$_};
    }
    # Catch common error.
    unless ( UNIVERSAL::isa( $config->{instrument}, 'HASH' ) ) {
	$config->{instrument} //= "guitar";
	$config->{instrument} =
	  { type => $config->{instrument},
	    description => ucfirst $config->{instrument} };
	do_warn( "Missing or invalid instrument - set to ",
		 $config->{instrument}->{type}, "\n" );
    }
    $config->lock;
    for ( keys %{ $config->{meta} } ) {
	$meta->{$_} //= [];
	if ( UNIVERSAL::isa($config->{meta}->{$_}, 'ARRAY') ) {
	    push( @{ $meta->{$_} }, @{ $config->{meta}->{$_} } );
	}
	else {
	    push( @{ $meta->{$_} }, $config->{meta}->{$_} );
	}
    }

    $no_transpose = $options->{'no-transpose'};
    $no_substitute = $options->{'no-substitute'};
    my $fragment = $options->{fragment};
    my $target = $config->{settings}->{transcode};
    if ( $target ) {
	unless ( App::Music::ChordPro::Chords::Parser->have_parser($target) ) {
	    if ( my $file = ::rsc_or_file("config/notes/$target.json") ) {
		for ( App::Music::ChordPro::Config::get_config($file) ) {
		    my $new = $config->hmerge($_);
		    local $config = $new;
		    App::Music::ChordPro::Chords::Parser->new($new);
		}
	    }
	}
	unless ( App::Music::ChordPro::Chords::Parser->have_parser($target) ) {
	    die("No transcoder for ", $target, "\n");
	}
	warn("Got transcoder for $target\n") if $::options->{verbose};
	App::Music::ChordPro::Chords::set_parser($target);
	if ( $target ne App::Music::ChordPro::Chords::get_parser->{system} ) {
	    ::dump(App::Music::ChordPro::Chords::Parser->parsers);
	    warn("OOPS parser mixup, $target <> ",
		App::Music::ChordPro::Chords::get_parser->{system})
	}
	App::Music::ChordPro::Chords::set_parser($self->{system});
    }
    else {
	$target = $self->{system};
    }

    upd_config();
    $self->{source}     = { file => $diag->{file}, line => 1 + $$linecnt };
    $self->{system}     = $config->{notes}->{system};
    $self->{config}     = $config;
    $self->{meta}       = $meta if $meta;
    $self->{chordsinfo} = {};

    # Preprocessor.
    my $prep = make_preprocessor( $config->{parser}->{preprocess} );

    # Pre-fill meta data, if any. TODO? ALREADY DONE?
    if ( $options->{meta} ) {
	while ( my ($k, $v ) = each( %{ $options->{meta} } ) ) {
	    $self->{meta}->{$k} = [ $v ];
	}
    }

    # Build regexp to split out chords.
    if ( $config->{settings}->{memorize} ) {
	$re_chords = qr/(\[.*?\]|\^)/;
    }
    else {
	$re_chords = qr/(\[.*?\])/;
    }

    my $skipcnt = 0;
    while ( @$lines ) {
	if ( $skipcnt ) {
	    $skipcnt--;
	}
	else {
	    $diag->{line} = ++$$linecnt;
	}
	$diag->{orig} = $_ = shift(@$lines);

	if ( $prep->{all} ) {
	    # warn("PRE:  ", $_, "\n");
	    $prep->{all}->($_);
	    # warn("POST: ", $_, "\n");
	    if ( /\n/ ) {
		my @a = split( /\n/, $_ );
		$_ = shift(@a);
		unshift( @$lines, @a );
		$skipcnt += @a;
	    }
	}

	if ( $skip_context ) {
	    if ( /^\s*\{(\w+)\}\s*$/ ) {
		my $dir = $self->parse_directive($1);
		if ( $dir->{name} eq "end_of_$in_context" ) {
		    $in_context = $def_context;
		    $skip_context = 0;
		}
	    }
	    next;
	}

	if ( /^\s*\{(new_song|ns)\}\s*$/ ) {
	    last if $self->{body};
	    next;
	}

	if ( /^#/ ) {

	    # Handle assets.
	    my $kw = "";
	    my $kv = {};
	    if ( /^##(image|asset):\s+(.*)/i ) {
		$kw = lc($1);
		$kv = parse_kv($2);
	    }

	    if ( $kw eq "image" ) {
		my $id = $kv->{id};
		unless ( $id ) {
		    do_warn("Missing id for image asset\n");
		    next;
		}

		# In-line image asset.
		require MIME::Base64;
		require Image::Info;

		# Read the image.
		my $data = '';
		while ( @$lines && $lines->[0] =~ /^# (.+)/ ) {
		    $data .= MIME::Base64::decode($1);
		    shift(@$lines);
		}

		# Get info.
		my $info = Image::Info::image_info(\$data);
		if ( $info->{error} ) {
		    do_warn($info->{error});
		    next;
		}

		# Store in assets.
		$self->{assets} //= {};
		$self->{assets}->{$id} =
		  { data => $data, type => $info->{file_ext},
		    width => $info->{width}, height => $info->{height},
		  };

		if ( $config->{debug}->{images} ) {
		    warn("asset[$id] ", length($data), " bytes, ",
			 "width=$info->{width}, height=$info->{height}",
			 "\n");
		}
		next;
	    }

	    if ( $kw eq "asset" ) {
		my $id = $kv->{id};
		my $type = $kv->{type};
		unless ( $id ) {
		    do_warn("Missing id for asset\n");
		    next;
		}
		unless ( $type ) {
		    do_warn("Missing type for asset\n");
		    next;
		}

		# Read the data.
		my @data;
		while ( @$lines && $lines->[0] =~ /^# (.+)/ ) {
		    push( @data, $1 );
		    shift(@$lines);
		}

		# Store in assets.
		$self->{assets} //= {};
		$self->{assets}->{$id} =
		  { data => \@data, type => $type,
		    subtype => $config->{delegates}->{$type}->{type},
		    handler => $config->{delegates}->{$type}->{handler},
		  };
		if ( $config->{debug}->{images} ) {
		    warn("asset[$id] ", ::dump($self->{assets}->{$id}));
		}
		next;
	    }

	    # Collect pre-title stuff separately.
	    if ( exists $self->{title} || $fragment ) {
		$self->add( type => "ignore", text => $_ );
	    }
	    else {
		push( @{ $self->{preamble} }, $_ );
	    }
	    next;
	}

	if ( $in_context eq "tab" ) {
	    unless ( /^\s*\{(?:end_of_tab|eot)\}\s*$/ ) {
		$self->add( type => "tabline", text => $_ );
		next;
	    }
	}

	if ( exists $config->{delegates}->{$in_context} ) {

	    # 'open' indicates open.
	    if ( /^\s*\{(?:end_of_\Q$in_context\E)\}\s*$/ ) {
		delete $self->{body}->[-1]->{open};
		# A subsequent {start_of_XXX} will reopen a new item
	    }
	    else {
		# Add to an open item.
		if ( $self->{body} && @{ $self->{body} }
		     && $self->{body}->[-1]->{context} eq $in_context
		     && $self->{body}->[-1]->{open} ) {
		    push( @{$self->{body}->[-1]->{data}}, $_ );
		}

		# Else start new item.
		else {
		    my %opts;
		    ####TODO
		    if ( $xpose || $config->{settings}->{transpose} ) {
			$opts{transpose} =
			  $xpose + ($config->{settings}->{transpose}//0 );
		    }
		    my $d = $config->{delegates}->{$in_context};
		    $self->add( type => "delegate",
				delegate => $d->{module},
				subtype => $d->{type},
				handler => $d->{handler},
				data => [ $_ ],
				opts => \%opts,
				open => 1 );
		}
		next;
	    }
	}

	# For practical reasons: a prime should always be an apostroph.
	s/'/\x{2019}/g;

	# For now, directives should go on their own lines.
	if ( /^\s*\{(.*)\}\s*$/ ) {
	    if ( $prep->{directive} ) {
		# warn("PRE:  ", $_, "\n");
		$prep->{directive}->($_);
		# warn("POST: ", $_, "\n");
	    }
	    $self->add( type => "ignore",
			text => $_ )
	      unless $self->directive($1);
	    next;
	}

	if ( /\S/ && !$fragment && !exists $self->{title} ) {
	    do_warn("Missing {title} -- prepare for surprising results");
	    unshift( @$lines, "{title:$_}");
	    $skipcnt++;
	    next;
	}

	if ( $in_context eq "tab" ) {
	    $self->add( type => "tabline", text => $_ );
	    warn("OOPS");
	    next;
	}

	if ( $in_context eq "grid" ) {
	    $self->add( type => "gridline", $self->decompose_grid($_) );
	    next;
	}

	if ( /\S/ ) {
	    if ( $prep->{songline} ) {
		# warn("PRE:  ", $_, "\n");
		$prep->{songline}->($_);
		# warn("POST: ", $_, "\n");
	    }
	    $self->add( type => "songline", $self->decompose($_) );
	}
	elsif ( exists $self->{title} || $fragment ) {
	    $self->add( type => "empty" );
	}
	else {
	    # Collect pre-title stuff separately.
	    push( @{ $self->{preamble} }, $_ );
	}
    }
    do_warn("Unterminated context in song: $in_context")
      if $in_context;

    # These don't make sense after processing. Or do they?
    # delete $self->{meta}->{$_} for qw( key_actual key_from );

    warn("Processed song...\n") if $options->{verbose};
    $diag->{format} = "\"%f\": %m";

    $self->dump(0) if $config->{debug}->{song} > 1;

    if ( @labels ) {
	$self->{labels} = [ @labels ];
    }

    my $diagrams;
    if ( exists($self->{settings}->{diagrams} ) ) {
	$diagrams = $self->{settings}->{diagrams};
	$diagrams &&= $config->{diagrams}->{show} || "all";
    }
    else {
	$diagrams = $config->{diagrams}->{show};
    }

    if ( $diagrams =~ /^(user|all)$/
	 && !App::Music::ChordPro::Chords::Parser->get_parser($target,1)->has_diagrams ) {
	do_warn( "Chord diagrams suppressed for " .
		 ucfirst($target) . " chords" ) unless $options->{silent};
	$diagrams = "none";
    }

    if ( $diagrams =~ /^(user|all)$/ ) {
	my %h;
	@used_chords = map { $h{$_}++ ? () : $_ } @used_chords;

	if ( $diagrams eq "user" && $self->{define} && @{$self->{define}} ) {
	    @used_chords =
	    map { $_->{name} } @{$self->{define}};
	}

	if ( $config->{diagrams}->{sorted} ) {
	    @used_chords =
	      sort App::Music::ChordPro::Chords::chordcompare @used_chords;
	}
	$self->{chords} =
	  { type   => "diagrams",
	    origin => "song",
	    show   => $diagrams,
	    chords => [ @used_chords ],
	  };

	if ( %warned_chords ) {
	    my @a = sort App::Music::ChordPro::Chords::chordcompare keys(%warned_chords);
	    my $l;
	    if ( @a > 1 ) {
		my $a = pop(@a);
		$l = '"' . join('", "', @a) . '" and "' . $a . '"';
	    }
	    else {
		$l = '"' . $a[0] . '"';
	    }
	    do_warn( "No chord diagram defined for $l (skipped)\n" );
	}
    }

    $self->dump(0) if $config->{debug}->{song};
    $self->dump(1) if $config->{debug}->{songfull};

    return $self;
}

sub add {
    my $self = shift;
    return if $skip_context;
    push( @{$self->{body}},
	  { context => $in_context,
	    $lineinfo ? ( line => $diag->{line} ) : (),
	    @_ } );
    if ( $in_context eq "chorus" ) {
	push( @chorus, { context => $in_context, @_ } );
	$chorus_xpose = $xpose;
	$chorus_xpose_dir = $xpose_dir;
    }
}

sub chord {
    my ( $self, $c ) = @_;
    return $c unless length($c);

    if ( $c =~ /^\*(.+)/ ) {
	$self->add_chord
	  ( App::Music::ChordPro::Chord::Annotation->new
	    ( { name => $c, text => $1 } ) );
	return $c;
    }

    my ( $name, $info ) = $self->parse_chord($c);
    unless ( defined $name ) {
	# Warning was given.
	# Make annotation.
	$self->add_chord
	  ( App::Music::ChordPro::Chord::Annotation->new
	    ( { name => $c, text => $c } ) );
	return $c;
    }
    ( my $n = $name ) =~ s/\((.+)\)$/$1/;

    if ( ! $info->{origin} && $config->{diagrams}->{auto} ) {
	$info = App::Music::ChordPro::Chords::add_unknown_chord($name);
	$self->add_chord($info);
    }

    unless ( $info->is_note ) {
	if ( $info->{origin} ) {
	    push( @used_chords, $n ) if $info->{frets};
	}
	elsif ( $::running_under_test ) {
	    # Tests run without config and chords, so pretend.
	    push( @used_chords, $n );
	}
	else {
	    do_warn("Unknown chord: $n") if $config->{debug}->{chords};
	    $warned_chords{$n}++;
	}
    }
    return $name;
}

sub decompose {
    my ($self, $orig) = @_;
    my $line = fmt_subst( $self, $orig );
    undef $orig if $orig eq $line;
    $line =~ s/\s+$//;
    my @a = split( $re_chords, $line, -1);

    if ( @a <= 1 ) {
	return ( phrases => [ $line ],
		 $orig ? ( orig => $orig ) : (),
	       );
    }

    my $dummy;
    shift(@a) if $a[0] eq "";
    unshift(@a, '[]'), $dummy++ if $a[0] !~ $re_chords;

    my @phrases;
    my @chords;
    while ( @a ) {
	my $chord = shift(@a);
	push(@phrases, shift(@a));

	# Normal chords.
	if ( $chord =~ s/^\[(.*)\]$/$1/ && $chord ne "^" ) {
	    push(@chords, $self->chord($chord));
	    if ( $memchords && !$dummy ) {
		if ( $memcrdinx == 0 ) {
		    $memorizing++;
		}
		if ( $memorizing ) {
		    push( @$memchords, $chords[-1] );
		}
		$memcrdinx++;
	    }
	}

	# Recall memorized chords.
	elsif ( $memchords ) {
	    if ( $memcrdinx == 0 && @$memchords == 0 ) {
		do_warn("No chords memorized for $in_context");
		push( @chords, $chord );
		undef $memchords;
	    }
	    elsif ( $memcrdinx >= @$memchords ) {
		do_warn("Not enough chords memorized for $in_context");
		push( @chords, $chord );
	    }
	    else {
		push( @chords, $memchords->[$memcrdinx]);
	    }
	    $memcrdinx++;
	}

	# Not memorizing.
	else {
	    #do_warn("No chords memorized for $in_context");
	    push( @chords, $chord );
	}
	$dummy = 0;
    }

    return ( phrases => \@phrases,
	     chords  => \@chords,
	     $orig ? ( orig => $orig ) : (),
	   );
}

sub cdecompose {
    my ( $self, $line ) = @_;
    $line = fmt_subst( $self, $line ) unless $no_substitute;
    my %res = $self->decompose($line);
    return ( text => $line ) unless $res{chords};
    return %res;
}

sub decompose_grid {
    my ($self, $line) = @_;
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;
    return ( tokens => [] ) if $line eq "";

    my $orig;
    my %res;
    if ( $line !~ /\|/ ) {
	$res{margin} = { $self->cdecompose($line), orig => $line };
	$line = "";
    }
    else {
	if ( $line =~ /(.*\|\S*)\s([^\|]*)$/ ) {
	    $line = $1;
	    $res{comment} = { $self->cdecompose($2), orig => $2 };
	    do_warn( "No margin cell for trailing comment" )
	      unless $grid_cells->[2];
	}
	if ( $line =~ /^([^|]+?)\s*(\|.*)/ ) {
	    $line = $2;
	    $res{margin} = { $self->cdecompose($1), orig => $1 };
	    do_warn( "No cell for margin text" )
	      unless $grid_cells->[1];
	}
    }

    my @tokens = split( ' ', $line );
    my $nbt = 0;		# non-bar tokens
    foreach ( @tokens ) {
	if ( $_ eq "|:" || $_ eq "{" ) {
	    $_ = { symbol => $_, class => "bar" };
	}
	elsif ( $_ eq ":|" || $_ eq "}" ) {
	    $_ = { symbol => $_, class => "bar" };
	}
	elsif ( $_ eq ":|:" || $_ eq "}{" ) {
	    $_ = { symbol => $_, class => "bar" };
	}
	elsif ( $_ eq "|" ) {
	    $_ = { symbol => $_, class => "bar" };
	}
	elsif ( $_ eq "||" ) {
	    $_ = { symbol => $_, class => "bar" };
	}
	elsif ( $_ eq "|." ) {
	    $_ = { symbol => $_, class => "bar" };
	}
	elsif ( $_ eq "%" ) {
	    $_ = { symbol => $_, class => "repeat1" };
	}
	elsif ( $_ eq '%%' ) {
	    $_ = { symbol => $_, class => "repeat2" };
	}
	elsif ( $_ eq "/" ) {
	    $_ = { symbol => $_, class => "slash" };
	}
	elsif ( $_ eq "." ) {
	    $_ = { symbol => $_, class => "space" };
	    $nbt++;
	}
	else {
	    $_ = { chord => $self->chord($_), class => "chord" };
	    $nbt++;
	}
    }
    if ( $nbt > $grid_cells->[0] ) {
	do_warn( "Too few cells for grid content" );
    }
    return ( tokens => \@tokens, %res );
}

################ Parsing directives ################

my %abbrevs = (
   c	      => "comment",
   cb	      => "comment_box",
   cf	      => "chordfont",
   ci	      => "comment_italic",
   colb	      => "column_break",
   cs	      => "chordsize",
   eob	      => "end_of_bridge",
   eoc	      => "end_of_chorus",
   eot	      => "end_of_tab",
   eov	      => "end_of_verse",
   g	      => "grid",
   highlight  => "comment",
   ng	      => "no_grid",
   np	      => "new_page",
   npp	      => "new_physical_page",
   ns	      => "new_song",
   sob	      => "start_of_bridge",
   soc	      => "start_of_chorus",
   sot	      => "start_of_tab",
   sov	      => "start_of_verse",
   st	      => "subtitle",
   t	      => "title",
   tf         => "textfont",
   ts         => "textsize",
	      );


sub parse_directive {
    my ( $self, $d ) = @_;

    # $d is the complete directive line, without leading/trailing { }.
    $d =~ s/^[: ]+//;
    $d =~ s/\s+$//;
    my $dir = lc($d);
    my $arg = "";
    if ( $d =~ /^(.*?)[: ]\s*(.*)/ ) {
	( $dir, $arg ) = ( lc($1), $2 );
    }
    $dir =~ s/[: ]+$//;
    # $dir is the lowcase directive name.
    # $arg is the rest, if any.

    # Check for xxx-yyy selectors.
    if ( $dir =~ /^(.*)-(.+)$/ ) {
	$dir = $abbrevs{$1} // $1;
	my $sel = $2;
	my $negate = $sel =~ s/\!$//;
	$sel = ( $sel eq lc($config->{instrument}->{type}) )
	       ||
	       ( $sel eq lc($config->{user}->{name}) );
	$sel = !$sel if $negate;
	unless ( $sel ) {
	    if ( $dir =~ /^start_of_/ ) {
		return { name => $dir, arg => $arg, omit => 2 };
	    }
	    else {
		return { name => $dir, arg => $arg, omit => 1 };
	    }
	}
    }
    else {
	$dir = $abbrevs{$dir} // $dir;
    }

    return { name => $dir, arg => $arg, omit => 0 }
}

my %propstack;

sub directive {
    my ( $self, $d ) = @_;

    my $dd = $self->parse_directive($d);
    return 1 if $dd->{omit} == 1;

    my $arg = $dd->{arg};
    if ( $arg ne "" ) {
	$arg = fmt_subst( $self, $arg );
	return 1 if $arg !~ /\S/;
    }
    my $dir = $dd->{name};

    # Context flags.

    if ( $dir =~ /^start_of_(\w+)$/ ) {
	do_warn("Already in " . ucfirst($in_context) . " context\n")
	  if $in_context;
	$in_context = $1;
	if ( $dd->{omit} ) {
	    $skip_context = 1;
	    # warn("Skipping context: $in_context\n");
	    return 1;
	}
	@chorus = (), $chorus_xpose = $chorus_xpose_dir = 0
	  if $in_context eq "chorus";
	if ( $in_context eq "grid" ) {
	    if ( $arg eq "" ) {
		$self->add( type => "set",
			    name => "gridparams",
			    value => $grid_arg );
	    }
	    elsif ( $arg =~ m/^
			      (?: (\d+) \+)?
			      (\d+) (?: x (\d+) )?
			      (?:\+ (\d+) )?
			      (?:[:\s+] (.*)? )? $/x ) {
		do_warn("Invalid grid params: $arg (must be non-zero)"), return
		  unless $2;
		$grid_arg = [ $2, $3//1, $1//0, $4//0 ];
		$self->add( type => "set",
			    name => "gridparams",
			    value =>  [ @$grid_arg, $5||"" ] );
		push( @labels, $5 ) if length($5||"");
	    }
	    elsif ( $arg ne "" ) {
		$self->add( type => "set",
			    name => "gridparams",
			    value =>  [ @$grid_arg, $arg ] );
		push( @labels, $arg );
	    }
	    $grid_cells = [ $grid_arg->[0] * $grid_arg->[1],
			    $grid_arg->[2],  $grid_arg->[3] ];
	}
	elsif ( $arg && $arg ne "" ) {
	    $self->add( type  => "set",
			name  => "label",
			value => $arg );
	    push( @labels, $arg )
	      unless $in_context eq "chorus" && !$config->{settings}->{choruslabels};
	}
	else {
	    do_warn("Garbage in start_of_$1: $arg (ignored)\n")
	      if $arg;
	}

	# Enabling this always would allow [^] to recall anyway.
	# Feature?
	if ( $config->{settings}->{memorize} ) {
	    $memchords = $memchords{$in_context} //= [];
	    $memcrdinx = 0;
	    $memorizing = 0;
	}
	return 1;
    }
    if ( $dir =~ /^end_of_(\w+)$/ ) {
	do_warn("Not in " . ucfirst($1) . " context\n")
	  unless $in_context eq $1;
	$self->add( type => "set",
		    name => "context",
		    value => $def_context );
	$in_context = $def_context;
	undef $memchords;
	return 1;
    }
    if ( $dir =~ /^chorus$/i ) {
	if ( $in_context ) {
	    do_warn("{chorus} encountered while in $in_context context -- ignored\n");
	    return 1;
	}

	# Clone the chorus so we can modify the label, if required.
	my $chorus = @chorus ? dclone(\@chorus) : [];

	if ( @$chorus && $arg && $arg ne "" ) {
	    if ( $chorus->[0]->{type} eq "set" && $chorus->[0]->{name} eq "label" ) {
		$chorus->[0]->{value} = $arg;
	    }
	    else {
		unshift( @$chorus,
			 { type => "set",
			   name => "label",
			   value => $arg,
			   context => "chorus",
			 } );
	    }
	    push( @labels, $arg )
	      if $config->{settings}->{choruslabels};
	}

	if ( $chorus_xpose != ( my $xp = $xpose ) ) {
	    $xp -= $chorus_xpose;
	    for ( @$chorus ) {
		if ( $_->{type} eq "songline" ) {
		    for ( @{ $_->{chords} } ) {
			next if $_ eq '';
			my $info = $self->{chordsinfo}->{$_};
			next if $info->is_annotation;
			$info = $info->transpose($xp, $xpose <=> 0) if $xp;
			$info = $info->new($info);
			$_ = $self->add_chord($info);
		    }
		}
	    }
	}

	$self->add( type => "rechorus",
		    @$chorus
		    ? ( "chorus" => $chorus )
		    : (),
		  );
	return 1;
    }

    # Song settings.

    # Breaks.

    if ( $dir eq "column_break" ) {
	$self->add( type => "colb" );
	return 1;
    }

    if ( $dir eq "new_page" || $dir eq "new_physical_page" ) {
	$self->add( type => "newpage" );
	return 1;
    }

    if ( $dir eq "new_song" ) {
	die("FATAL - cannot start a new song now\n");
    }

    # Comments. Strictly speaking they do not belong here.

    if ( $dir =~ /^comment(_italic|_box)?$/ ) {
	my %res = $self->cdecompose($arg);
	$res{orig} = $dd->{arg};
	$self->add( type => $dir, %res )
	  unless exists($res{text}) && $res{text} =~ /^[ \t]*$/;
	return 1;
    }

    # Images.
    if ( $dir eq "image" ) {
	my $res = parse_kv($arg);
	my $uri;
	my $id;
	my %opts;
	while ( my($k,$v) = each(%$res) ) {
	    if ( $k =~ /^(title)$/i ) {
		$opts{lc($k)} = $v;
	    }
	    elsif ( $k =~ /^(width|height|border|center)$/i && $v =~ /^(\d+)$/ ) {
		$opts{lc($k)} = $v;
	    }
	    elsif ( $k =~ /^(scale)$/ && $v =~ /^(\d(?:\.\d+)?)$/ ) {
		$opts{lc($k)} = $v;
	    }
	    elsif ( $k =~ /^(center|border)$/i ) {
		$opts{lc($k)} = $v;
	    }
	    elsif ( $k =~ /^(src|uri)$/i ) {
		$uri = $v;
	    }
	    elsif ( $k =~ /^(id)$/i ) {
		$id = $v;
	    }
	    elsif ( $uri ) {
		do_warn( "Unknown image attribute: $1\n" );
		next;
	    }
	    # Assume just an image file uri.
	    else {
		$uri = $k;
	    }
	}
	$uri = "id=$id" if $id;
	unless ( $uri ) {
	    do_warn( "Missing image source\n" );
	    return;
	}
	$self->add( type => "image",
		    uri  => $uri,
		    opts => \%opts );
	return 1;
    }

    if ( $dir eq "title" ) {
	$self->{title} = $arg;
	push( @{ $self->{meta}->{title} }, $arg );
	return 1;
    }

    if ( $dir eq "subtitle" ) {
	push( @{ $self->{subtitle} }, $arg );
	push( @{ $self->{meta}->{subtitle} }, $arg );
	return 1;
    }

    # Metadata extensions (legacy). Should use meta instead.
    # Only accept the list from config.
    if ( any { $_ eq $dir } @{ $config->{metadata}->{keys} } ) {
	$arg = "$dir $arg";
	$dir = "meta";
    }

    # Metadata.
    if ( $dir eq "meta" ) {
	if ( $arg =~ /([^ :]+)[ :]+(.*)/ ) {
	    my $key = lc $1;
	    my @vals = ( $2 );
	    if ( $config->{metadata}->{autosplit} ) {
		@vals = map { s/s\+$//; $_ }
		  split( quotemeta($config->{metadata}->{separator}), $vals[0] );
	    }
	    my $m = $self->{meta};

	    # User and instrument cannot be set here.
	    if ( $key eq "user" || $key eq "instrument" ) {
		do_warn("\"$key\" can be set from config only.\n");
		return 1;
	    }

	    for my $val ( @vals ) {

		if ( $key eq "key" ) {
		    $val =~ s/[\[\]]//g;
		    my ( $name, $info ) = $self->parse_chord($val);
		    my $act = $name;

		    if ( $capo ) {
			$act = $self->add_chord( $info->transpose($capo) );
			$name = $act if $decapo;
		    }

		    push( @{ $m->{key} }, $name );
		    $m->{key_actual} = [ $act ];
#		    warn("XX key=$name act=$act capo=",
#			 $capo//"<undef>"," decapo=$decapo\n");
		    return 1;
		}


		if ( $key eq "capo" ) {
		    do_warn("Multiple capo settings may yield surprising results.")
		      if exists $m->{capo};

		    $capo = $val || undef;
		    if ( $capo && $m->{key} ) {
			if ( $decapo ) {
			    my $key = $self->store_chord
			      ($self->{chordsinfo}->{$m->{key}->[-1]}
			       ->transpose($val));
			    $m->{key}->[-1] = $key;
			    $key = $self->store_chord
			      ($self->{chordsinfo}->{$m->{key}->[-1]}
			       ->transpose($xpose));
			    $m->{key_actual} = [ $key ];
			}
			else {
			    my $act = $m->{key_actual}->[-1];
			    $m->{key_from} = [ $act ];
			    my $key = $self->store_chord
			      ($self->{chordsinfo}->{$act}->transpose($val));
			    $m->{key_actual} = [ $key ];
			}
		    }
		}

		elsif ( $key eq "duration" && $val ) {
		    $val = duration($val);
		}

		if ( $config->{metadata}->{strict}
		     && ! any { $_ eq $key } @{ $config->{metadata}->{keys} } ) {
		    # Unknown, and strict.
		    do_warn("Unknown metadata item: $key")
		      if $config->{settings}->{strict};
		    return;
		}

		push( @{ $self->{meta}->{$key} }, $val ) if defined $val;
	    }
	}
	else {
	    do_warn("Incomplete meta directive: $d\n")
	      if $config->{settings}->{strict};
	    return;
	}
	return 1;
    }

    # Song / Global settings.

    if ( $dir eq "titles"
	 && $arg =~ /^(left|right|center|centre)$/i ) {
	$self->{settings}->{titles} =
	  lc($1) eq "centre" ? "center" : lc($1);
	return 1;
    }

    if ( $dir eq "columns"
	 && $arg =~ /^(\d+)$/ ) {
	$self->{settings}->{columns} = $arg;
	return 1;
    }

    if ( $dir eq "pagetype" || $dir eq "pagesize" ) {
	$self->{settings}->{papersize} = $arg;
	return 1;
    }

    if ( $dir eq "grid" ) {
	$self->{settings}->{diagrams} = 1;
	return 1;
    }
    if ( $dir eq "no_grid" ) {
	$self->{settings}->{diagrams} = 0;
	return 1;
    }

    if ( $dir eq "transpose" ) {
	$propstack{transpose} //= [];

	if ( $arg =~ /^([-+]?\d+)\s*$/ ) {
	    my $new = $1;
	    push( @{ $propstack{transpose} }, [ $xpose, $xpose_dir ] );
	    my %a = ( type => "control",
		      name => "transpose",
		      previous => [ $xpose, $xpose_dir ]
		    );
	    $xpose += $new;
	    $xpose_dir = $new <=> 0;
	    my $m = $self->{meta};
	    if ( $m->{key} ) {
		my $key = $m->{key}->[-1];
		my $xp = $xpose;
		$xp += $capo if $capo;
		my $xpk = $self->{chordsinfo}->{$key}->transpose($xp);
		$self->{chordsinfo}->{$xpk->name} = $xpk;
		$m->{key_from} = [ $m->{key_actual}->[0] ];
		$m->{key_actual} = [ $xpk->name ];
	    }
	    $self->add( %a, value => $xpose, dir => $xpose_dir )
	      if $no_transpose;
	}
	else {
	    my %a = ( type => "control",
		      name => "transpose",
		      previous => [ $xpose, $xpose_dir ]
		    );
	    my $m = $self->{meta};
	    my ( $new, $dir );
	    if ( @{ $propstack{transpose} } ) {
		( $new, $dir ) = @{ pop( @{ $propstack{transpose} } ) };
	    }
	    else {
		$new = 0;
		$dir = $config->{settings}->{transpose} <=> 0;
	    }
	    $xpose = $new;
	    $xpose_dir = $dir;
	    if ( $m->{key} ) {
		$m->{key_from} = [ $m->{key_actual}->[0] ];
		my $xp = $xpose;
		$xp += $capo if $capo && $decapo;
		$m->{key_actual} =
		  [ $self->{chordsinfo}->{$m->{key}->[-1]}->transpose($xp)->name ];
	    }
	    if ( !@{ $propstack{transpose} } ) {
		delete $m->{$_} for qw( key_from );
	    }
	    $self->add( %a, value => $xpose, dir => $dir )
	      if $no_transpose;
	}
	return 1;
    }

    # More private hacks.
    if ( !$options->{reference} && $d =~ /^([-+])([-\w.]+)$/i ) {
	if ( $2 eq "dumpmeta" ) {
	    warn(::dump($self->{meta}));
	}
	$self->add( type => "set",
		    name => $2,
		    value => $1 eq "+" ? 1 : 0,
		  );
	return 1;
    }

    if ( !$options->{reference} && $dir =~ /^\+([-\w.]+(?:\.[<>])?)$/ ) {
	$self->add( type => "set",
		    name => $1,
		    value => $arg,
		  );

	# THIS IS BASICALLY A COPY OF THE CODE IN Config.pm.
	# TODO: GENERALIZE.
	my $ccfg = {};
	my @k = split( /[:.]/, $1 );
	my $c = \$ccfg;		# new
	my $o = $config;	# current
	my $lk = pop(@k);	# last key

	# Step through the keys.
	foreach ( @k ) {
	    $c = \($$c->{$_});
	    $o = $o->{$_};
	}

	# Final key. Merge array if so.
	if ( ( $lk =~ /^\d+$/ || $lk eq '>' || $lk eq '<' )
	       && ref($o) eq 'ARRAY' ) {
	    unless ( ref($$c) eq 'ARRAY' ) {
		# Only copy orig values the first time.
		$$c->[$_] = $o->[$_] for 0..scalar(@{$o})-1;
	    }
	    if ( $lk eq '>' ) {
		push( @{$$c}, $arg );
	    }
	    elsif ( $lk eq '<' ) {
		unshift( @{$$c}, $arg );
	    }
	    else {
		$$c->[$lk] = $arg;
	    }
	}
	else {
	    $$c->{$lk} = $arg;
	}
	$config->augment($ccfg);
	upd_config();

	return 1;
    }

    # Formatting.
    if ( $dir =~ /^(text|chord|tab|grid|diagrams|title|footer|toc)(font|size|colou?r)$/ ) {
	my $item = $1;
	my $prop = $2;
	my $value = $arg;

	$prop = "color" if $prop eq "colour";
	my $name = "$item-$prop";
	$propstack{$name} //= [];

	if ( $value eq "" ) {
	    # Pop current value from stack.
	    if ( @{ $propstack{$name} } ) {
		pop( @{ $propstack{$name} } );
	    }
	    # Use new current value, if any.
	    if ( @{ $propstack{$name} } ) {
		$value = $propstack{$name}->[-1]
	    }
	    else {
		# do_warn("No saved value for property $item$prop\n" );
		$value = undef;
	    }
	    $self->add( type  => "control",
			name  => $name,
			value => $value );
	    return 1;
	}

	if ( $prop eq "size" ) {
	    unless ( $value =~ /^\d+(?:\.\d+)?\%?$/ ) {
		do_warn("Illegal value \"$value\" for $item$prop\n");
		return 1;
	    }
	}
	if ( $prop =~ /^colou?r$/  ) {
	    my $v;
	    unless ( $v = get_color($value) ) {
		do_warn("Illegal value \"$value\" for $item$prop\n");
		return 1;
	    }
	    $value = $v;
	}
	$value = $prop eq 'font' ? $value : lc($value);
	$self->add( type  => "control",
		    name  => $name,
		    value => $value );
	push( @{ $propstack{$name} }, $value );
	return 1;
    }

    # define A: base-fret N frets N N N N N N fingers N N N N N N
    # define: A base-fret N frets N N N N N N fingers N N N N N N
    # optional: base-fret N (defaults to 1)
    # optional: N N N N N N (for unknown chords)
    # optional: fingers N N N N N N

    if ( $dir eq "define" or my $show = $dir eq "chord" ) {

	# Split the arguments and keep a copy for error messages.
	my @a = split( /[: ]+/, $arg );
	my @orig = @a;
	my $fail = 0;
	my $name = $a[0];
	my $strings = $config->diagram_strings;

	# Result structure.
	my $res = { name => $name };

	# Defaults.
	my $info;
	if ( $show ) {
	    ( my $n, $info ) = $self->parse_chord( $name, "allow" );
	    $name = $n if $info;
	}

	shift(@a);

	while ( @a ) {
	    my $a = shift(@a);

	    # Copy existing definition.
	    if ( $a eq "copy" ) {
		if ( my $i = App::Music::ChordPro::Chords::_known_chord($a[0]) ) {
		    $info = $i;
		    shift(@a);
		    $res->{$_} = $info->{$_}
		      for qw( base frets fingers keys );
		}
		else {
		    do_warn("Unknown chord to copy: $a[0]\n");
		    $fail++;
		    last;
		}
	    }

	    # base-fret N
	    elsif ( $a eq "base-fret" ) {
		if ( $a[0] =~ /^\d+$/ ) {
		    $res->{base} = shift(@a);
		}
		else {
		    do_warn("Invalid base-fret value: $a[0]\n");
		    $fail++;
		    last;
		}
	    }

	    # frets N N ... N
	    elsif ( $a eq "frets" ) {
		my @f;
		while ( @a && $a[0] =~ /^(?:[0-9]+|[-xXN])$/ ) {
		    push( @f, shift(@a) );
		}
		if ( @f == $strings ) {
		    $res->{frets} = [ map { $_ =~ /^\d+/ ? $_ : -1 } @f ];
		}
		else {
		    do_warn("Incorrect number of fret positions (" .
			    scalar(@f) . ", should be $strings)\n");
		    $fail++;
		    last;
		}
	    }

	    # fingers N N ... N
	    elsif ( $a eq "fingers" ) {
		my @f;
		# It is tempting to limit the fingers to 1..5 ...
		while ( @a ) {
		    $_ = shift(@a);
		    if ( /^[0-9]+$/ ) {
			push( @f, 0 + $_ );
		    }
		    elsif ( /^[A-MO-WYZ]$/ ) {
			push( @f, $_ );
		    }
		    elsif ( /^[-xNX]$/ ) {
			push( @f, -1 );
		    }
		    else {
			last;
		    }
		}
		if ( @f == $strings ) {
		    $res->{fingers} = \@f;
		}
		else {
		    do_warn("Incorrect number of finger settings (" .
			    scalar(@f) . ", should be $strings)\n");
		    $fail++;
		    last;
		}
	    }

	    # keys N N ... N
	    elsif ( $a eq "keys" ) {
		my @f;
		while ( @a && $a[0] =~ /^[0-9]+$/ ) {
		    push( @f, shift(@a) );
		}
		if ( @f ) {
		    $res->{keys} = \@f;
		}
		else {
		    do_warn("Invalid or missing keys\n");
		    $fail++;
		    last;
		}
	    }

	    # Wrong...
	    else {
		# Insert a marker to show how far we got.
		splice( @orig, @orig-@a, 0, "<<<" );
		splice( @orig, @orig-@a-2, 0, ">>>" );
		do_warn("Invalid chord definition: @orig\n");
		$fail++;
		last;
	    }
	}

	return 1 if $fail;

	if ( $show) {
	    my $ci;
	    if ( $res->{frets} || $res->{base} || $res->{fingers} ) {
		$ci = App::Music::ChordPro::Chord::Common->new
		  ( { name   => $res->{name},
		      origin => "inline",
		      base   => $res->{base} ? $res->{base} : 1,
		      frets  => $res->{frets},
		      $res->{fingers} ? ( fingers => $res->{fingers} ) : (),
		    } );
	    }
	    else {
		# Info is already in $info.
		$ci = $info->clone;
	    }

	    state $chidx = "ch000";
	    $chidx++;
	    # Combine consecutive entries.
	    if ( defined($self->{body})
		 && $self->{body}->[-1]->{type} eq "diagrams" ) {
		push( @{ $self->{body}->[-1]->{chords} },
		      " $chidx" );
	    }
	    else {
		$self->add( type => "diagrams",
			    show => "user",
			    origin => "chord",
			    chords => [ " $chidx" ] );
	    }
	    $self->{chordsinfo}->{" $chidx"} = $ci;
	    return 1;
	}
	elsif ( ! ( $res->{copy} ||$res->{frets} || $res->{keys} ) ) {
	    do_warn("Incomplete chord definition: $res->{name}\n");
	    return 1;
	}


	if ( $res->{frets} || $res->{fingers} || $res->{keys} ) {
	    $res->{base} ||= 1 unless $res->{copy};
	    push( @{$self->{define}}, $res );
	    my $ret =
	      App::Music::ChordPro::Chords::add_song_chord($res);
	    if ( $ret ) {
		do_warn("Invalid chord: ", $res->{name}, ": ", $ret, "\n");
		return 1;
	    }
	    $info = App::Music::ChordPro::Chords::_known_chord($res->{name});
	    croak("We just entered it?? ", $res->{name}) unless $info;
	}
	else {
	    App::Music::ChordPro::Chords::add_unknown_chord( $res->{name} );
	}

	# $used_chords{$res->{name}} = $info if $info;

	return 1;
    }

    # Warn about unknowns, unless they are x_... form.
    do_warn("Unknown directive: $d\n")
      if $config->{settings}->{strict} && $d !~ /^x_/;
    return;
}

sub add_chord {
    my ( $self, $info, $new_id ) = @_;

    if ( $new_id ) {
	state $id = "ch0000";
	$new_id = " $id";
	$id++;
    }
    else {
	$new_id = $info->name;
    }
    $self->{chordsinfo}->{$new_id} = $info->new($info);

    return $new_id;
}

sub duration {
    my ( $dur ) = @_;

    if ( $dur =~ /(?:(?:(\d+):)?(\d+):)?(\d+)/ ) {
	$dur = $3 + ( $2 ? 60 * $2 :0 ) + ( $1 ? 3600 * $1 : 0 );
    }
    my $res = sprintf( "%d:%02d:%02d",
		       int( $dur / 3600 ),
		       int( ( $dur % 3600 ) / 60 ),
		       $dur % 60 );
    $res =~ s/^[0:]+//;
    return $res;
}

sub get_color {
    $_[0];
}

sub msg {
    my $m = join("", @_);
    $m =~ s/\n+$//;
    my $t = $diag->{format};
    $t =~ s/\\n/\n/g;
    $t =~ s/\\t/\t/g;
    $t =~ s/\%f/$diag->{file}/g;
    $t =~ s/\%n/$diag->{line}/g;
    $t =~ s/\%l/$diag->{orig}/g;
    $t =~ s/\%m/$m/g;
    $t;
}

sub do_warn {
    warn(msg(@_)."\n");
}

sub parse_chord {
    my ( $self, $chord, $allow ) = @_;

    my $debug = $config->{debug}->{chords};

    warn("Parsing chord: \"$chord\"\n") if $debug;
    my $parens = $chord =~ s/^\((.+)\)$/$1/;
    my $info;
    my $xp = $xpose + $config->{settings}->{transpose};
    $xp += $capo if $capo && $decapo;
    my $xc = $config->{settings}->{transcode};
    my $global_dir = $config->{settings}->{transpose} <=> 0;
    my $unk;

    $info = App::Music::ChordPro::Chords::_known_chord($chord);
    if ( $info ) {
	warn( "Parsing chord: \"$chord\" found \"",
	      $chord, "\" in song/config chords\n" ) if $debug > 1;
    }
    else {
	$info = App::Music::ChordPro::Chords::parse_chord($chord);
	warn( "Parsing chord: \"$chord\" parsed ok\n" ) if $info && $debug > 1;
    }
#    if ( $info && ( my $i = App::Music::ChordPro::Chords::_known_chord($info->name) || App::Music::ChordPro::Chords::_known_chord($chord) ) ) {
#	require DDumper; DDumper::DDumper($i) if $chord =~ /N/;
#	warn("AAA", join(",",@{$i->{frets}}), " ", join(",",(-1)x($config->diagram_strings)) );
#	if ( $i->{frets} && join(",",@{$i->{frets}}) eq join(",",(-1)x($config->diagram_strings)) ) {
#	    warn("BBB");
#	    $xp = 0; $xc = '';
#	}
#    }
    $unk = !defined $info;
    unless ( $info || ( $allow && !( $xc || $xp ) ) ) {
	do_warn( "Cannot parse",
		 $xp ? "/transpose" : "",
		 $xc ? "/transcode" : "",
		 " chord \"$chord\"\n" )
	  if $xp || $xc || $config->{debug}->{chords};
    }

    if ( $xp && $info ) {
	# For transpose/transcode, chord must be wellformed.
	$info = $info->transpose( $xp,
				  $xpose_dir // $global_dir);
	warn( "Parsing chord: \"$chord\" transposed ",
	      $xp > 0 ? "+$xp" : "$xp", " to \"",
	      $info->name, "\"\n" ) if $debug > 1;
    }
    # else: warning has been given.

    if ( $info ) {
	# Look it up now, the name may change by transcode.
	if ( my $i = App::Music::ChordPro::Chords::_known_chord($info->name) ) {
	    warn( "Parsing chord: \"$chord\" found ",
		  $i->name, " for ", $info->name, " in song/config chords\n" ) if $debug > 1;
	    $info = $i->new({ %$i, name => $info->name }) ;
	    $unk = 0;
	}
	else {
	    warn( "Parsing chord: \"$chord\" \"", $info->name,
		  "\" not found in song/config chords\n" ) if $debug;
	    $unk = 1;
	}
    }

    if ( $xc && $info ) {
	$info = $info->transcode($xc);
	warn( "Parsing chord: \"$chord\" transcoded to ",
	      $info->name,
	      " (", $info->{system}, ")",
	      "\n" ) if $debug > 1;
	if ( my $i = App::Music::ChordPro::Chords::_known_chord($info->name) ) {
	    warn( "Parsing chord: \"$chord\" found \"",
		  $info->name, "\" in song/config chords\n" ) if $debug > 1;
	    $unk = 0;
	}
    }
    # else: warning has been given.

    if ( ! $info ) {
	if ( my $i = App::Music::ChordPro::Chords::_known_chord($chord) ) {
	    $info = $i;
	    warn( "Parsing chord: \"$chord\" found \"",
		  $chord, "\" in song/config chords\n" ) if $debug > 1;
	    $unk = 0;
	}
	elsif ( $config->{diagrams}->{auto} ) {
	    my $i = App::Music::ChordPro::Chords::add_unknown_chord($chord);
	    $info = bless { %$i, %$info } => ref($info);
	}
    }

    unless ( $info || $allow ) {
	if ( $config->{debug}->{chords} || ! $warned_chords{$chord}++ ) {
	    warn("Parsing chord: \"$chord\" unknown\n") if $debug;
	    do_warn( "Unknown chord: \"$chord\"\n" )
	      unless $chord =~ /^n\.?c\.?$/i;
	}
	if ( $config->{diagrams}->{auto} ) {
	    $info = App::Music::ChordPro::Chords::add_unknown_chord($chord);
	    warn( "Parsing chord: \"$chord\" added ",
		  $info->name, " to song chords\n" ) if $debug > 1;
	}
    }

    if ( $info ) {
	warn( "Parsing chord: \"$chord\" okay: \"",
	      $info->name, "\" \"",
	      $info->chord_display, "\"",
	      $unk ? " but unknown" : "",
	      "\n" ) if $debug > 1;
	$info->{parens} = $parens if $parens;
	$chord = $self->store_chord($info);
	return wantarray ? ( $chord, $info ) : $chord;
    }

    warn( "Parsing chord: \"$chord\" not found\n" ) if $debug;
    return;
}

sub store_chord {
    my ( $self, $info ) = @_;
    $self->{chordsinfo}->{$info->name} = $info;
    $info->name;
}

sub structurize {
    my ( $self ) = @_;

    return if $self->{structure} eq "structured";

    my @body;
    my $context = $def_context;

    foreach my $item ( @{ $self->{body} } ) {
	if ( $item->{type} eq "empty" && $item->{context} eq $def_context ) {
	    $context = $def_context;
	    next;
	}
	if ( $context ne $item->{context} ) {
	    push( @body, { type => $context = $item->{context}, body => [] } );
	}
	if ( $context ) {
	    push( @{ $body[-1]->{body} }, $item );
	}
	else {
	    push( @body, $item );
	}
    }
    $self->{body} = [ @body ];
    $self->{structure} = "structured";
}

sub dump {
    my ( $self, $full ) = @_;
    my $a = dclone($self);
    $a->{config} = ref(delete($a->{config}));
    unless ( $full ) {
	for my $ci ( keys %{$a->{chordsinfo}} ) {
	    for ( qw( frets fingers keys ) ) {
		next unless exists $a->{chordsinfo}{$ci}{$_};
		next unless @{$a->{chordsinfo}{$ci}{$_}};
		$a->{chordsinfo}{$ci}{$_} =
		  "[ " . join(" ", @{$a->{chordsinfo}{$ci}{$_}}) . " ]";
	    }
	    next unless $a->{chordsinfo}{$ci}{parser};
	    $a->{chordsinfo}{$ci}{ns_canon} =
	      "[ " . join(" ", @{$a->{chordsinfo}{$ci}{parser}{ns_canon}}) . " ]"
	      if $a->{chordsinfo}{$ci}{parser}{ns_canon};
	    $a->{chordsinfo}{$ci}{parser} =
	      ref(delete($a->{chordsinfo}{$ci}{parser}));
	}
    }
    ::dump($a);
}

unless ( caller ) {
    require DDumper;
    binmode STDERR => ':utf8';
    App::Music::ChordPro::Config::configurator();
    my $s = App::Music::ChordPro::Song->new;
    $options->{settings}->{transpose} = 0;
    for ( @ARGV ) {
	if ( /^[a-z]/ ) {
	    $options->{settings}->{transcode} = $_;
	    next;
	}
#	DDumper::DDumper( $s->parse_chord($_) );
	my ( undef, $i ) = $s->parse_chord($_);
	warn("$_ => ", $i->name, " => ", $s->add_chord($i, $i->name eq 'D'), "\n" );
	$xpose++;
    }
    DDumper::DDumper($s->{chordsinfo});
}

1;
