#!/usr/bin/perl

package main;

our $options;
our $config;

package App::Music::ChordPro::Songbook;

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

sub new {
    my ($pkg) = @_;
    bless { songs => [ ] }, $pkg;
}

# Parser context.
my $def_context = "";
my $in_context = $def_context;
my $skip_context = 0;
my $grid_arg;
my $grid_cells;

# Local transposition.
my $xpose = 0;

# Used chords, in order of appearance.
my @used_chords;
my %used_chords;

# Chorus lines, if any.
my @chorus;
my $chorus_xpose = 0;

# Memorized chords.
my %memchords;			# all sections
my $memchords;			# current section
my $memcrdinx;			# chords tally
my $memorizing;			# if memorizing (a.o.t. recalling)

# Keep track of unknown chords, to avoid dup warnings.
my %warned_chords;

my $re_chords;			# for chords

my @labels;			# labels used

# Normally, transposition and subtitutions are handled by the parser.
my $decapo;
my $no_transpose;		# NYI
my $no_substitute;

my $diag;			# for diagnostics
my $lineinfo;			# keep lineinfo

sub ::break() {}

sub parse_file {
    my ( $self, $filename, $opts ) = @_;
    $opts //= {};
    my $meta = { %{$config->{meta}}, %{delete $opts->{meta}//{}} };

    # Loadlines sets $opts->{_filesource}.
    my $lines = loadlines( $filename, $opts );
    # Sense crd input and convert if necessary.
    if ( !$options->{fragment}
	 and any { /\S/ } @$lines	# non-blank lines
	 and $options->{crd} || !any { /^{\w+/ } @$lines ) {
	require App::Music::ChordPro::A2Crd;
	$lines = App::Music::ChordPro::A2Crd::a2crd( { lines => $lines } );
    }

    # Note: $opts are used by the tests only.
    $opts //= {};
    $diag->{format} = $opts->{diagformat} // $config->{diagnostics}->{format};
    $diag->{file}   = $opts->{_filesource};
    $lineinfo = $config->{settings}->{lineinfo};

    # Used by tests.
    for ( "transpose", "no-substitute", "no-transpose" ) {
	next unless exists $opts->{$_};
	$options->{$_} = $opts->{$_};
    }

    my $linecnt = 0;
    while ( @$lines ) {
	my $song = $self->parse_song( $lines, \$linecnt, {%$meta} );
#	if ( exists($self->{songs}->[-1]->{body}) ) {
	    $song->{meta}->{songindex} = 1 + @{ $self->{songs} };
	    push( @{ $self->{songs} }, $song );
#	}
#	else {
#	    $self->{songs} = [ $song ];
#	}
    }
    return 1;
}

my $song;			# current song

sub parse_song {
    my ( $self, $lines, $linecnt, $meta ) = @_;
    die("OOPS! Wrong meta") unless ref($meta) eq 'HASH';
    local $config = dclone($config);

    # Load song-specific config, if any.
    if ( $diag->{file} ) {
	my $t = join("|",@{$config->{tuning}});
	my $have;
	if ( $meta && $meta->{__config} ) {
	    my $cf = delete($meta->{__config})->[0];
	    die("Missing config: $cf\n") unless -s $cf;
	    warn("Config[song]: $cf\n") if $options->{verbose};
	    $have = App::Music::ChordPro::Config::get_config($cf);
	}
	else {
	    for ( "prp", "json" ) {
		( my $cf = $diag->{file} ) =~ s/\.\w+$/.$_/;
		next unless -s $cf;
		warn("Config[song]: $cf\n") if $options->{verbose};
		$have = App::Music::ChordPro::Config::get_config($cf);
		last;
	    }
	}
	if ( $have ) {
	    my $chords = $have->{chords};
	    $config->augment($have);
	    if ( $t ne join("|",@{$config->{tuning}}) ) {
		my $res =
		  App::Music::ChordPro::Chords::set_tuning($config);
		warn( "Invalid tuning in config: ", $res, "\n" ) if $res;
	    }
	    App::Music::ChordPro::Chords->reset_parser;
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
	}
    }

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
    $decapo = $options->{decapo} || $config->{settings}->{decapo};
    my $fragment = $options->{fragment};

    $song = App::Music::ChordPro::Song->new
      ( source => { file => $diag->{file}, line => 1 + $$linecnt },
	system => $config->{notes}->{system},
	structure => "linear",
	config => $config,
	$meta ? ( meta => $meta ) : (),
	chordsinfo => {},
      );
    $self->{song} = $song;

    $xpose = 0;
    $grid_arg = [ 4, 4, 1, 1 ];	# 1+4x4+1
    $in_context = $def_context;
    @used_chords = ();
    %used_chords = ();
    %warned_chords = ();
    %memchords = ();
    App::Music::ChordPro::Chords::reset_song_chords();
    @labels = ();
    @chorus = ();

    # Preprocessor.
    my $prep;
    if ( $config->{parser} ) {
	foreach my $linetype ( keys %{ $config->{parser}->{preprocess} } ) {
	    my @targets;
	    my $code;
	    foreach ( @{ $config->{parser}->{preprocess}->{$linetype} } ) {
		if ( $_->{pattern} ) {
		    push( @targets, $_->{pattern} );
		    # Subsequent targets override.
		    $code->{$_->{pattern}} = $_->{replace};
		}
		else {
		    push( @targets, quotemeta($_->{target}) );
		    # Subsequent targets override.
		    $code->{quotemeta($_->{target})} = quotemeta($_->{replace});
		}
	    }
	    if ( @targets ) {
		my $t = "sub { for (\$_[0]) {\n";
		$t .= "s\0" . $_ . "\0" . $code->{$_} . "\0g;\n" for @targets;
		$t .= "}}";
		$prep->{$linetype} = eval $t;
		die( "CODE : $t\n$@" ) if $@;
	    }
	}
    }

    # Pre-fill meta data, if any. TODO? ALREADY DONE?
    if ( $options->{meta} ) {
	while ( my ($k, $v ) = each( %{ $options->{meta} } ) ) {
	    $song->{meta}->{$k} = [ $v ];
	}
    }

    # Build regexp to split out chords.
    if ( $config->{settings}->{memorize} ) {
	$re_chords = qr/(\[.*?\]|\^)/;
    }
    else {
	$re_chords = qr/(\[.*?\])/;
    }

    while ( @$lines ) {
	$diag->{line} = ++$$linecnt;
	$diag->{orig} = $_ = shift(@$lines);

	if ( $prep->{all} ) {
	    # warn("PRE:  ", $_, "\n");
	    $prep->{all}->($_);
	    # warn("POST: ", $_, "\n");
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
	    last if $song->{body};
	    next;
	}

	if ( /^#/ ) {
	    if ( /^##image:\s+id=(\S+)/ ) {
		my $id = $1;

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
		$song->{assets} //= {};
		$song->{assets}->{$id} =
		  { data => $data, type => $info->{file_ext},
		    width => $info->{width}, height => $info->{height},
		  };

		next;
	    }
	    # Collect pre-title stuff separately.
	    if ( exists $song->{title} || $fragment ) {
		$self->add( type => "ignore", text => $_ );
	    }
	    else {
		push( @{ $song->{preamble} }, $_ );
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
		delete $song->{body}->[-1]->{open};
		# A subsequent {start_of_XXX} will reopen a new item
	    }
	    else {
		# Add to an open item.
		if ( $song->{body} && @{ $song->{body} }
		     && $song->{body}->[-1]->{context} eq $in_context
		     && $song->{body}->[-1]->{open} ) {
		    push( @{$song->{body}->[-1]->{data}}, $_ );
		}

		# Else start new item.
		else {
		    my %opts;
		    if ( $xpose || $options->{transpose} ) {
			$opts{transpose} =
			  $xpose + ($options->{transpose}//0 );
		    }
		    $self->add( type => "delegate",
				subtype => $config->{delegates}->{$in_context}->{type},
				handler => $config->{delegates}->{$in_context}->{handler},
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
	    $self->add( type => "ignore",
			text => $_ )
	      unless $self->directive($1);
	    next;
	}

	if ( /\S/ && !$fragment && !exists $song->{title} ) {
	    do_warn("Missing {title} -- prepare for surprising results");
	    $song->{title} = "Untitled";
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
	elsif ( exists $song->{title} || $fragment ) {
	    $self->add( type => "empty" );
	}
	else {
	    # Collect pre-title stuff separately.
	    push( @{ $song->{preamble} }, $_ );
	}
    }
    do_warn("Unterminated context in song: $in_context")
      if $in_context;

    if ( @labels ) {
	$song->{labels} = [ @labels ];
    }

    my $diagrams;
    if ( exists($song->{settings}->{diagrams} ) ) {
	$diagrams = $song->{settings}->{diagrams};
	$diagrams &&= $config->{diagrams}->{show} || "all";
    }
    else {
	$diagrams = $config->{diagrams}->{show};
    }

    my $target = $config->{settings}->{transcode} || $song->{system};
    if ( $diagrams =~ /^(user|all)$/
	 && !App::Music::ChordPro::Chords::Parser->get_parser($target,1)->has_diagrams ) {
	$diag->{orig} = "(End of Song)";
	do_warn( "Chord diagrams suppressed for " .
		 ucfirst($target) . " chords" ) unless $options->{silent};
	$diagrams = "none";
    }

    if ( $diagrams =~ /^(user|all)$/ ) {
	my %h;
	@used_chords = map { $h{$_}++ ? () : $_ } @used_chords;

	if ( $diagrams eq "user" && @{$song->{define}} ) {
	    @used_chords =
	    map { $_->{name} } @{$song->{define}};
	}

	if ( $config->{diagrams}->{sorted} ) {
	    @used_chords =
	      sort App::Music::ChordPro::Chords::chordcompare @used_chords;
	}
	$song->{chords} =
	  { type   => "diagrams",
	    origin => "song",
	    show   => $diagrams,
	    chords => [ @used_chords ],
	  };
    }
    $song->{chordsinfo} = { %used_chords };

    my $xp = $options->{transpose};
    my $xc = $config->{settings}->{transcode};
    if ( $xc && App::Music::ChordPro::Chords::Parser->get_parser($xc,1)->movable ) {
	if ( $song->{meta}->{key}
	     && ( my $i = App::Music::ChordPro::Chords::parse_chord($song->{meta}->{key}->[0]) ) ) {
	    $xp = - $i->{root_ord};
	    delete $song->{meta}->{key};
	}
	else {
	   $xp = 0;
	}
    }

    # Global transposition and transcoding.
    $song->transpose( $xp, $xc );

    # $song->structurize;

    ::dump( do {
	my $a = dclone($song);
	$a->{config} = ref(delete($a->{config}));
	$a->{chordsinfo}{$_}{parser} = ref(delete($a->{chordsinfo}{$_}{parser}))
	  for keys %{$a->{chordsinfo}};
	$a;
	} ) if eval { $config->{debug}->{song} };

    return $song;
}

sub add {
    my $self = shift;
    return if $skip_context;
    push( @{$song->{body}},
	  { context => $in_context,
	    $lineinfo ? ( line => $diag->{line} ) : (),
	    @_ } );
    if ( $in_context eq "chorus" ) {
	push( @chorus, { context => $in_context, @_ } );
	$chorus_xpose = $xpose;
    }
}

sub chord {
    my ( $self, $c ) = @_;
    return $c unless length($c);
    return $c if $c =~ /^\*/;
    my $parens = $c =~ s/^\((.*)\)$/$1/;

    my $info = App::Music::ChordPro::Chords::identify($c);
    unless ( $info->{system} ) {
	if ( $info->{error} && ! $warned_chords{$c}++ ) {
	    do_warn( $info->{error} ) unless $c =~ /^n\.?c\.?$/i;
	}
    }

    # Local transpose, if requested.
    if ( $xpose ) {
	$_ = App::Music::ChordPro::Chords::transpose( $c, $xpose )
	  and
	    $c = $_;
    }

    push( @used_chords, $c ) unless $info->{isnote};
    $used_chords{$c} = $info unless $info->{error};

    return $parens ? "($c)" : $c;
}

sub safe_chord_info {
    my ( $chord ) = @_;
    my $info = App::Music::ChordPro::Chords::chord_info($chord);
    $info->{origin} //= 1;
    return $info;
}

sub cxpose {
    my ( $self, $t ) = @_;
    $t =~ s/\[(.+?)\]/$self->chord($1)/ge;
    return $t;
}

sub decompose {
    my ($self, $orig) = @_;
    my $line = fmt_subst( $self->{song}, $orig );
    undef $orig if $orig eq $line;
    $line =~ s/\s+$//;
    my @a = split( $re_chords, $line, -1);

#    die(msg("Illegal line")."\n") unless @a; #### TODO

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
    $line = fmt_subst( $song, $line ) unless $no_substitute;
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
   ci	      => "comment_italic",
   colb	      => "column_break",
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
	unless ( $sel eq $config->{instrument}->{type}
		 or
		 $sel eq $config->{user}->{name} ) {
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
	$arg = fmt_subst( $self->{song}, $arg );
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
	@chorus = (), $chorus_xpose = 0 if $in_context eq "chorus";
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
	    push( @labels, $arg );
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
	my $chorus =
	  @chorus ? App::Music::ChordPro::Config::clone(\@chorus) : [];

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
	    push( @labels, $arg );
	}
	$self->add( type => "rechorus",
		    @$chorus
		    ? ( "chorus" => $chorus,
			"transpose" => $xpose - $chorus_xpose )
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
	use Text::ParseWords qw(shellwords);
	my @args = shellwords($arg);
	my $uri;
	my $id;
	my %opts;
	foreach ( @args ) {
	    if ( /^(width|height|border|center)=(\d+)$/i ) {
		$opts{lc($1)} = $2;
	    }
	    elsif ( /^(scale)=(\d(?:\.\d+)?)$/i ) {
		$opts{lc($1)} = $2;
	    }
	    elsif ( /^(center|border)$/i ) {
		$opts{lc($_)} = 1;
	    }
	    elsif ( /^(src|uri)=(.+)$/i ) {
		$uri = $2;
	    }
	    elsif ( /^(id)=(.+)$/i ) {
		$id = $2;
	    }
	    elsif ( /^(title)=(.*)$/i ) {
		$opts{title} = $2;
	    }
	    elsif ( /^(.+)=(.*)$/i ) {
		do_warn( "Unknown image attribute: $1\n" );
		next;
	    }
	    else {
		$uri = $_;
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
	$song->{title} = $arg;
	push( @{ $song->{meta}->{title} }, $arg );
	return 1;
    }

    if ( $dir eq "subtitle" ) {
	push( @{ $song->{subtitle} }, $arg );
	push( @{ $song->{meta}->{subtitle} }, $arg );
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
	    my $val = $2;

	    # User and instrument cannot be set here.
	    if ( $key eq "user" || $key eq "instrument" ) {
		do_warn("\"$key\" can be set from config only.\n");
		return 1;
	    }

	    if ( $key eq "key" ) {
		$val =~ s/[\[\]]//g;
#		push( @{ $song->{meta}->{_orig_key} }, $val );
		my $xp = $xpose;
		$xp += $options->{transpose} if $options->{transpose};
		$val = App::Music::ChordPro::Chords::transpose( $val, $xp )
		  if $xp;
	    }
	    elsif ( $key eq "capo" ) {
		do_warn("Multiple capo settings may yield surprising results.")
		  if exists $song->{meta}->{capo};
		if ( $decapo ) {
		    $xpose += $val;
		    my $xp = $xpose;
		    $xp += $options->{transpose} if $options->{transpose};
		    for ( qw( key key_actual key_from ) ) {
			next unless exists $song->{meta}->{$_};
			$song->{meta}->{$_}->[-1] =
			  App::Music::ChordPro::Chords::transpose( $song->{meta}->{$_}->[-1], $xp )
		    }
		    return 1;
		}
		undef $val if $val == 0;
	    }
	    elsif ( $key eq "duration" && $val ) {
		$val = duration($val);
	    }

	    if ( $config->{metadata}->{strict}
		 && ! any { $_ eq $key } @{ $config->{metadata}->{keys} } ) {
		# Unknown, and strict.
		do_warn("Unknown metadata item: $key");
		return;
	    }

	    push( @{ $song->{meta}->{$key} }, $val ) if defined $val;
	}
	else {
	    do_warn("Incomplete meta directive: $d\n");
	    return;
	}
	return 1;
    }

    # Song / Global settings.

    if ( $dir eq "titles"
	 && $arg =~ /^(left|right|center|centre)$/i ) {
	$song->{settings}->{titles} =
	  lc($1) eq "centre" ? "center" : lc($1);
	return 1;
    }

    if ( $dir eq "columns"
	 && $arg =~ /^(\d+)$/ ) {
	$song->{settings}->{columns} = $arg;
	return 1;
    }

    if ( $dir eq "pagetype" || $dir eq "pagesize" ) {
	$song->{settings}->{papersize} = $arg;
	return 1;
    }

    if ( $dir eq "grid" ) {
	$song->{settings}->{diagrams} = 1;
	return 1;
    }
    if ( $dir eq "no_grid" ) {
	$song->{settings}->{diagrams} = 0;
	return 1;
    }

    if ( $dir eq "transpose" ) {
	$propstack{transpose} //= [];

	if ( $arg =~ /^([-+]?\d+)\s*$/ ) {
	    push( @{ $propstack{transpose} }, $xpose );
	    my %a = ( type => "control",
		      name => "transpose",
		      previous => $xpose,
		    );
	    my $m = $song->{meta};
	    if ( $m->{key} ) {
		$m->{key_actual} =
		  [ App::Music::ChordPro::Chords::transpose( $m->{key}->[-1],
							     $xpose+$1 ) ];
		$m->{key_from} =
		  [ App::Music::ChordPro::Chords::transpose( $m->{key}->[-1],
							     $xpose ) ];
	    }
	    $xpose += $1;
	    $self->add( %a, value => $xpose ) if $no_transpose;
	}
	else {
	    my %a = ( type => "control",
		      name => "transpose",
		      previous => $xpose,
		    );
	    my $m = $song->{meta};
	    if ( $m->{key} ) {
		$m->{key_from} =
		  [ App::Music::ChordPro::Chords::transpose( $m->{key}->[-1],
							     $xpose ) ];
	    }
	    if ( @{ $propstack{transpose} } ) {
		$xpose = pop( @{ $propstack{transpose} } );
	    }
	    else {
		$xpose = 0;
	    }
	    if ( $m->{key} ) {
		$m->{key_actual} =
		  [ App::Music::ChordPro::Chords::transpose( $m->{key}->[-1],
							     $xpose ) ];
	    }
	    $self->add( %a, value => $xpose ) if $no_transpose;
	}
	return 1;
    }

    # More private hacks.
    if ( $d =~ /^([-+])([-\w.]+)$/i ) {
	if ( $2 eq "dumpmeta" ) {
	    warn(::dump($song->{meta}));
	}
	$self->add( type => "set",
		    name => $2,
		    value => $1 eq "+" ? 1 : 0,
		  );
	return 1;
    }

    if ( $dir =~ /^\+([-\w.]+(?:\.[<>])?)$/ ) {
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

	# Result structure.
	my $res = { name => $a[0] };
	my $info = App::Music::ChordPro::Chords::parse_chord($a[0]);
#	unless ( $info ) {
#	    do_warn("Unrecogized chord name: $a[0]\n");
#	    $fail++;
#	}
	shift(@a);

	my $strings = App::Music::ChordPro::Chords::strings;

	while ( @a ) {
	    my $a = shift(@a);

	    # base-fret N
	    if ( $a eq "base-fret" ) {
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
		while ( @a && $a[0] =~ /^[0-9---xXN]$/ ) {
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
		while ( @a && $a[0] =~ /^[0-9---xXN]$/ ) {
		    push( @f, shift(@a) );
		}
		if ( @f == $strings ) {
		    $res->{fingers} = [ map { $_ =~ /^\d+/ ? $_ : -1 } @f ];
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

	if ( ( $res->{fingers} || $res->{base} ) && ! $res->{frets} ) {
	    do_warn("Missing fret positions: $res->{name}\n");
	    return 1;
	}

	if ( $show) {
	    my $ci;
	    if ( $res->{frets} || $res->{base} || $res->{fingers} ) {
		$ci = { name  => $res->{name},
			base  => $res->{base} ? $res->{base} : 1,
			frets => $res->{frets},
			$res->{fingers} ? ( fingers => $res->{fingers} ) : (),
		      };
	    }
	    else {
		$ci = $res->{name};
	    }
	    # Combine consecutive entries.
	    if ( defined($song->{body})
		 && $song->{body}->[-1]->{type} eq "diagrams" ) {
		push( @{ $song->{body}->[-1]->{chords} },
		      $ci );
	    }
	    else {
		$self->add( type => "diagrams",
			    show => "user",
			    origin => "chord",
			    chords => [ $ci ] );
	    }
	    return 1;
	}

	if ( $res->{frets} || $res->{fingers} || $res->{keys} ) {
	    $res->{base} ||= 1;
	    push( @{$song->{define}}, $res );
	    my $ret =
	      App::Music::ChordPro::Chords::add_song_chord($res);
	    if ( $ret ) {
		do_warn("Invalid chord: ", $res->{name}, ": ", $ret, "\n");
		return 1;
	    }
	}
	else {
	    App::Music::ChordPro::Chords::add_unknown_chord( $res->{name} );
	}

	$song->{chordsinfo}->{$info->{name}} = $info if $info;

	return 1;
    }

    # Warn about unknowns, unless they are x_... form.
    do_warn("Unknown directive: $d\n") unless $d =~ /^x_/;
    return;
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

sub transpose {
    my ( $self, $xpose, $xcode ) = @_;
    return unless $xpose || $xcode;

    foreach my $song ( @{ $self->{songs} } ) {
	$song->transpose( $xpose, $xcode );
    }
}

sub structurize {
    my ( $self ) = @_;

    foreach my $song ( @{ $self->{songs} } ) {
	$song->structurize;
    }
}

sub get_color {
    $_[0];
}

sub msg {
    my $m = join("", @_);
    $m =~ s/\n+$//;
    my $t = $diag->{format};
    $t =~ s/\%f/$diag->{file}/g;
    $t =~ s/\%n/$diag->{line}/g;
    $t =~ s/\%l/$diag->{orig}/g;
    $t =~ s/\%m/$m/g;
    $t =~ s/\\n/\n/g;
    $t =~ s/\\t/\t/g;
    $t;
}

sub do_warn {
    warn(msg(@_)."\n");
}

################################################################

package App::Music::ChordPro::Song;

sub new {
    my ( $pkg, %init ) = @_;
    bless { structure => "linear", settings => {}, %init }, $pkg;
}

sub transpose {
    my ( $self, $xpose, $xcode ) = @_;

    $xpose ||= 0;
    my $xp = 0;
    if ( exists $self->{meta} && exists $self->{meta}->{capo}
	 && $decapo ) {
	$xp = $self->{meta}->{capo}->[-1];
	delete $self->{meta}->{capo};
    }

    # Transpose meta data (key).
    if ( exists $self->{meta} && exists $self->{meta}->{key} ) {
	foreach ( @{ $self->{meta}->{key} } ) {
#	    push( @{ $self->{meta}->{_orig_key} }, $_ );
	    $_ = $self->xpchord( $_, 0, $xcode );
	}
    }

    # Transpose song chords.
    if ( exists $self->{chords} ) {
	foreach my $item ( $self->{chords} ) {
	    $self->_transpose( $item, $xp+$xpose, $xcode );
	}
    }

    # Transpose song chordsinfo.
    if ( exists $self->{chordsinfo} ) {
	my %new;
	while ( my ($k,$v) = each( %{$self->{chordsinfo}} ) ) {
	    $v = $v->transpose( $xp+$xpose );
	    my $name = $self->xpchord($v->{name}, $xpose, $xcode);
	    $v->{name} = $name;
	    $new{$name} = $v;
	}
	$self->{chordsinfo} = \%new;
    }

    # Transpose body contents.
    if ( exists $self->{body} ) {
	foreach my $item ( @{ $self->{body} } ) {
	    $self->_transpose( $item, $xp+$xpose, $xcode );
	}
    }
}

sub _transpose {
    my ( $self, $item, $xpose, $xcode ) = @_;
    $xpose //= 0;

    if ( $item->{type} eq "rechorus" ) {
	return unless $item->{chorus};
	for ( @{ $item->{chorus} } ) {
	    $self->_transpose( $_, $xpose + $item->{transpose}, $xcode );
	}
	return;
    }
    return unless $xpose || $xcode;

    if ( $item->{type} eq "songline" ) {
	# Prevent chords to be autovivified.
	# The ChordPro backend relies on it.
	return unless exists $item->{chords};

	foreach ( @{ $item->{chords} } ) {
	    $_ = $self->xpchord( $_, $xpose, $xcode );
	}
	return;
    }

    if ( $item->{type} =~ /^comment/ ) {
	return unless $item->{chords};
	foreach ( @{ $item->{chords} } ) {
	    $_ = $self->xpchord( $_, $xpose, $xcode );
	}
	return;
    }

    if ( $item->{type} eq "gridline" ) {
	foreach ( @{ $item->{tokens} } ) {
	    next unless $_->{class} eq "chord";
	    $_->{chord} = $self->xpchord( $_->{chord}, $xpose, $xcode );
	}
	if ( $item->{margin} && exists $item->{margin}->{chords} ) {
	    foreach ( @{ $item->{margin}->{chords} } ) {
		$_ = $self->xpchord( $_, $xpose, $xcode );
	    }
	}
	if ( $item->{comment} && exists $item->{comment}->{chords} ) {
	    foreach ( @{ $item->{comment}->{chords} } ) {
		$_ = $self->xpchord( $_, $xpose, $xcode );
	    }
	}
	return;
    }

    if ( $item->{type} eq "diagrams" ) {
	foreach ( @{ $item->{chords} } ) {
	    $_ = $self->xpchord( $_, $xpose, $xcode );
	}
	return;
    }
}

sub xpchord {
    my ( $self, $c, $xpose, $xcode ) = @_;
    return $c unless length($c) && ($xpose || $xcode);
    return $c if ref $c;
    my $parens = $c =~ s/^\((.*)\)$/$1/;
    my $xc = App::Music::ChordPro::Chords::transpose( $c, $xpose, $xcode );
    $xc ||= $c;
    return $parens ? "($xc)" : $xc;
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

1;
