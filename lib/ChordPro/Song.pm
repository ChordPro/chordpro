#!/usr/bin/perl

package main;

our $options;
our $config;

package ChordPro::Song;

use strict;
use warnings;

use ChordPro;
use ChordPro::Chords;
use ChordPro::Chords::Appearance;
use ChordPro::Chords::Parser;
use ChordPro::Output::Common;
use ChordPro::Utils;

use Carp;
use List::Util qw(any);
use File::LoadLines;
use Storable qw(dclone);
use feature 'state';
use Text::ParseWords qw(quotewords);
use File::Basename qw(basename);

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
my $xcmov;			# transcode to movable system
my $no_substitute;

# Stack for properties like textsize.
my %propstack;

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
    %propstack = ();
    ChordPro::Chords::reset_song_chords();
    @labels = ();
    @chorus = ();
    $capo = undef;
    $xcmov = undef;
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
    my ( $self, $lines, $linecnt, $meta, $defs ) = @_;
    die("OOPS! Wrong meta") unless ref($meta) eq 'HASH';
    local $config = dclone($config);

    warn("Processing song ", $diag->{file}, "...\n") if $options->{verbose};
    ::break();
    my @configs;
    #
    if ( $lines->[0] =~ /^##config:\s*json/ ) {
	my $cf = "";
	shift(@$lines);
	$$linecnt++;
	while ( @$lines ) {
	    if ( $lines->[0] =~ /^# (.*)/ ) {
		$cf .= $1 . "\n";
		shift(@$lines);
		$$linecnt++;
	    }
	    else {
		last;
	    }
	}
	if ( $cf ) {
	    my $pp = JSON::PP->new->relaxed;
	    my $precfg = $pp->decode($cf);
	    my $prename = "__PRECFG__";
	    ChordPro::Config::precheck( $precfg, $prename );
	    push( @configs, ChordPro::Config::prep_configs( $precfg, $prename) );
	}
    }
    # Load song-specific config, if any.
    if ( !$options->{nosongconfig} && $diag->{file} ) {
	if ( $options->{verbose} ) {
	    my $this = ChordPro::Chords::get_parser();
	    $this = defined($this) ? $this->{system} : "";
	    print STDERR ("Parsers at start of ", $diag->{file}, ":");
	    print STDERR ( $this eq $_ ? " *" : " ", "$_")
	      for keys %{ ChordPro::Chords::Parser->parsers };
	    print STDERR ("\n");
	}
	if ( $meta && $meta->{__config} ) {
	    my $cf = delete($meta->{__config})->[0];
	    die("Missing config: $cf\n") unless -s $cf;
	    warn("Config[song]: $cf\n") if $options->{verbose};
	    my $have = ChordPro::Config::get_config($cf);
	    push( @configs, ChordPro::Config::prep_configs( $have, $cf) );
	}
	else {
	    for ( "prp", "json" ) {
		( my $cf = $diag->{file} ) =~ s/\.\w+$/.$_/;
		$cf .= ".$_" if $cf eq $diag->{file};
		next unless -s $cf;
		warn("Config[song]: $cf\n") if $options->{verbose};
		my $have = ChordPro::Config::get_config($cf);
		push( @configs, ChordPro::Config::prep_configs( $have, $cf) );
		last;
	    }
	}
    }
    my $tuncheck = join("|",@{$config->{tuning}});
    foreach my $have ( @configs ) {
	warn("Config[song*]: ", $have->{_src}, "\n") if $options->{verbose};
	my $chords = $have->{chords};
	$config->augment($have);
	if ( $tuncheck ne join("|",@{$config->{tuning}}) ) {
	    my $res =
	      ChordPro::Chords::set_tuning($config);
	    warn( "Invalid tuning in config: ", $res, "\n" ) if $res;
	}
	ChordPro::Chords::reset_parser();
	ChordPro::Chords::Parser->reset_parsers;
	if ( $chords ) {
	    my $c = $chords;
	    if ( @$c && $c->[0] eq "append" ) {
		shift(@$c);
	    }
	    foreach ( @$c ) {
		my $res =
		  ChordPro::Chords::add_config_chord($_);
		warn( "Invalid chord in config: ",
		      $_->{name}, ": ", $res, "\n" ) if $res;
	    }
	}
	if ( $options->{verbose} > 1 ) {
	    warn( "Processed ", scalar(@$chords), " chord entries\n")
	      if $chords;
	    warn( "Totals: ",
		  ChordPro::Chords::chord_stats(), "\n" );
	}
	if ( 0 && $options->{verbose} ) {
	    my $this = ChordPro::Chords::get_parser()->{system};
	    print STDERR ("Parsers after local config:");
	    print STDERR ( $this eq $_ ? " *" : " ", "$_")
	      for keys %{ ChordPro::Chords::Parser->parsers };
	    print STDERR ("\n");
	}
    }

    $config->unlock;

    if ( %$defs ) {
	my $c = $config->hmerge( prp2cfg( $defs, $config ) );
	bless $c => ref($config);
	$config = $c;
    }

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
	unless ( ChordPro::Chords::Parser->have_parser($target) ) {
	    if ( my $file = ::rsc_or_file("config/notes/$target.json") ) {
		for ( ChordPro::Config::get_config($file) ) {
		    my $new = $config->hmerge($_);
		    local $config = $new;
		    ChordPro::Chords::Parser->new($new);
		}
	    }
	}
	unless ( ChordPro::Chords::Parser->have_parser($target) ) {
	    die("No transcoder for ", $target, "\n");
	}
	warn("Got transcoder for $target\n") if $::options->{verbose};
	ChordPro::Chords::set_parser($target);
	my $p = ChordPro::Chords::get_parser;
	$xcmov = $p->movable;
	if ( $target ne $p->{system} ) {
	    ::dump(ChordPro::Chords::Parser->parsers);
	    warn("OOPS parser mixup, $target <> ",
		ChordPro::Chords::get_parser->{system})
	}
	ChordPro::Chords::set_parser($self->{system});
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
    $target //= $self->{system};

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

	$_ = shift(@$lines);
	while ( /\\\Z/ && @$lines ) {
	    chop;
	    my $cont = shift(@$lines);
	    $$linecnt++;
	    $cont =~ s/^\s+//;
	    $_ .= $cont;
	}

	# Uncomment this to allow \uXXXX escapes.
	s/\\u([0-9a-f]{4})/chr(hex("0x$1"))/ige;
	# Uncomment this to allow \u{XX...} escapes.
	# s/\\u\{([0-9a-f]+)\}/chr(hex("0x$1"))/ige;

	$diag->{orig} = $_;
	# Get rid of TABs.
	s/\t/ /g;

	if ( $config->{debug}->{echo} ) {
	    warn(sprintf("==[%3d]=> %s\n", $diag->{line}, $diag->{orig} ) );
	}

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
		    $kv->{persist} ? ( persist => 1 ) : (),
		  };

		if ( $config->{debug}->{images} ) {
		    warn("asset[$id] ", length($data), " bytes, ",
			 "width=$info->{width}, height=$info->{height}",
			 $kv->{persist} ? ", persist" : "",
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
		if ( $config->{delegates}->{$in_context}->{omit} ) {
		}
		else {
		    delete $self->{body}->[-1]->{open};
		    # A subsequent {start_of_XXX} will reopen a new item
		}
	    }
	    elsif ( $config->{delegates}->{$in_context}->{omit} ) {
		next;
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

	# For now, directives should go on their own lines.
	if ( /^\s*\{(.*)\}\s*$/ ) {
	    my $dir = $1;
	    if ( $prep->{directive} ) {
		# warn("PRE:  ", $_, "\n");
		$prep->{directive}->($dir);
		# warn("POST: ", $_, "\n");
	    }
	    $self->add( type => "ignore",
			text => $_ )
	      unless $self->directive($dir);
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

    # Suppress chords that the user considers 'easy'.
    my %suppress;
    my $xc = $config->{settings}->{transcode};
    for (  @{ $config->{diagrams}->{suppress} } ) {
	my $info = ChordPro::Chords::known_chord($_);
	warn("Unknown chord \"$_\" in suppress list\n"), next
	  unless $info;
	# Note we do transcode, but we do not transpose.
	if ( $xc ) {
	    $info = $info->transcode($xc);
	}
	$suppress{$info->name} = 1;
    }
    # Suppress chords that the user don't want.
    while ( my ($k,$v) = each %{ $self->{chordsinfo} } ) {
	$suppress{$k} = 1 if !is_true($v->{diagram}//1);
    }
    @used_chords = map { $suppress{$_} ? () : $_ } @used_chords;

    my $diagrams;
    if ( exists($self->{settings}->{diagrams} ) ) {
	$diagrams = $self->{settings}->{diagrams};
	$diagrams &&= $config->{diagrams}->{show} || "all";
    }
    else {
	$diagrams = $config->{diagrams}->{show};
    }

    if ( $diagrams =~ /^(user|all)$/
	 && !ChordPro::Chords::Parser->get_parser($target,1)->has_diagrams ) {
	do_warn( "Chord diagrams suppressed for " .
		 ucfirst($target) . " chords" ) unless $options->{silent};
	$diagrams = "none";
    }

    if ( $diagrams eq "user" ) {

	if ( $self->{define} && @{$self->{define}} ) {
	    my %h = map { demarkup($_) => 1 } @used_chords;
	    @used_chords =
	      map { $h{$_->{name}} ? $_->{name} : () } @{$self->{define}};
	}
	else {
	    @used_chords = ();
	}
    }
    else {
	my %h;
	@used_chords = map { $h{$_}++ ? () : $_ }
	  map { demarkup($_) } @used_chords;
    }

    if ( $config->{diagrams}->{sorted} ) {
	@used_chords =
	  sort ChordPro::Chords::chordcompare @used_chords;
    }

    # For headings, footers, table of contents, ...
    $self->{meta}->{chords} //= [ @used_chords ];
    $self->{meta}->{numchords} = [ scalar(@{$self->{meta}->{chords}}) ];

    if ( $diagrams =~ /^(user|all)$/ ) {
	$self->{chords} =
	  { type   => "diagrams",
	    origin => "song",
	    show   => $diagrams,
	    chords => [ @used_chords ],
	  };

	if ( %warned_chords ) {
	    my @a = sort ChordPro::Chords::chordcompare
	      keys(%warned_chords);
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

# Parses a chord and adds it to the song.
# It understands markup, parenthesized chords and annotations.
# Returns the chord Appearance.
sub chord {
    my ( $self, $orig ) = @_;
    Carp::confess unless length($orig);

    # Intercept annotations.
    if ( $orig =~ /^\*(.+)/ || $orig =~ /^(\||\s+)$/ ) {
	my $i = ChordPro::Chord::Annotation->new
	  ( { name => $orig, text => $1 } );
	return
	  ChordPro::Chords::Appearance->new
	    ( key => $self->add_chord($i), info => $i, orig => $orig );
    }

    # Check for markup.
    my $markup = $orig;
    my $c = demarkup($orig);
    if ( $markup eq $c ) { 	# no markup
	undef $markup;
    }

    # Special treatment for parenthesized chords.
    $c =~ s/^\((.*)\)$/$1/;
    do_warn("Double parens in chord: \"$orig\"")
      if $c =~ s/^\((.*)\)$/$1/;

    # We have a 'bare' chord now. Parse it.
    my $info = $self->parse_chord($c);
    unless ( defined $info ) {
	# Warning was given.
	# Make annotation.
	my $i = ChordPro::Chord::Annotation->new
	  ( { name => $orig, text => $orig } );
	return
	  ChordPro::Chords::Appearance->new
	    ( key => $self->add_chord($i), info => $i, orig => $orig );
    }

    my $ap = ChordPro::Chords::Appearance->new( orig => $orig );

    # Handle markup, if any.
    if ( $markup ) {
	if ( $markup =~ s/\>\Q$c\E\</>%{formatted}</
	     ||
	     $markup =~ s/\>\(\Q$c\E\)\</>(%{formatted})</ ) {
	}
	else {
	    do_warn("Invalid markup in chord: \"$markup\"\n");
	}
	$ap->format = $markup;
    }
    elsif ( (my $m = $orig) =~ s/\Q$c\E/%{formatted}/ ) {
	$ap->format = $m unless $m eq "%{formatted}";
    }

    # After parsing, the chord can be changed by transpose/code.
    # info->name is the new key.
    $ap->key = $self->add_chord( $info, $c = $info->name );
    $ap->info = $info;

    unless ( $info->is_nc || $info->is_note ) {
#	if ( $info->is_keyboard ) {
	if ( $::config->{instrument}->{type} eq "keyboard" ) {
	    push( @used_chords, $c );
	}
	elsif ( $info->{origin} ) {
	    # Include if we have diagram info.
	    push( @used_chords, $c ) if $info->has_diagram;
	}
	elsif ( $::running_under_test ) {
	    # Tests run without config and chords, so pretend.
	    push( @used_chords, $c );
	}
	elsif ( ! ( $info->is_rootless
		    || $info->has_diagram
		    || !$info->parser->has_diagrams
		  ) ) {
	    do_warn("Unknown chord: $c")
	      unless $warned_chords{$c}++;
	}
    }

    return $ap;
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
	    push(@chords, $chord eq "" ? "" : $self->chord($chord));
	    if ( $memchords && !$dummy ) {
		if ( $memcrdinx == 0 ) {
		    $memorizing++;
		}
		if ( $memorizing ) {
		    push( @$memchords, $chords[-1] );
		    warn("Chord memorized for $in_context\[$memcrdinx]: ",
			 $chords[-1], "\n")
		      if $config->{debug}->{chords};
		}
		$memcrdinx++;
	    }
	}

	# Recall memorized chords.
	elsif ( $memchords && $in_context ) {
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
		push( @chords, $self->chord($memchords->[$memcrdinx]->chord_display));
		warn("Chord recall $in_context\[$memcrdinx]: ", $chords[-1], "\n")
		  if $config->{debug}->{chords};
	    }
	    $memcrdinx++;
	}

	# Not memorizing.
	else {
	    # do_warn("No chords memorized for $in_context");
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

    my @tokens;
    my @t = split( ' ', $line );

    # Unfortunately, <span xxx> gets split too.
    while ( @t ) {
	$_ = shift(@t);
	push( @tokens, $_ );
	if ( /\<span$/ ) {
	    while ( @t ) {
		$_ = shift(@t);
		$tokens[-1] .= " " . $_;
		last if /\<\/span>/;
	    }
	}
    }

    my $nbt = 0;		# non-bar tokens
    foreach ( @tokens ) {
	if ( $_ eq "|:" || $_ eq "{" ) {
	    $_ = { symbol => $_, class => "bar" };
	}
	elsif ( /^\|(\d+)(>?)$/ ) {
	    $_ = { symbol => '|', volta => $1, class => "bar" };
	    $_->{align} = 1 if $2;
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
	    # Multiple chords in a cell?
	    my @a = split( /~/, $_, -1 );
	    if ( @a == 1) {
		# Normal case, single chord.
		$_ = { chord => $self->chord($_), class => "chord" };
	    }
	    else {
		# Multiple chords.
		$_ = { chords =>
		       [ map { ( $_ eq '.' || $_ eq '' )
				 ? ''
				 : $_ eq "/"
				   ? "/"
				   : $self->chord($_) } @a ],
		       class => "chords" };
	    }
	    $nbt++;
	}
    }
    if ( $nbt > $grid_cells->[0] ) {
	do_warn( "Too few cells for grid content" );
    }
    return ( tokens => \@tokens, %res );
}

################ Parsing directives ################

my @directives = qw(
    chord
    chordcolour
    chordfont
    chordsize
    chorus
    column_break
    columns
    comment
    comment_box
    comment_italic
    define
    end_of_bridge
    end_of_chorus
    end_of_grid
    end_of_tab
    end_of_verse
    footersize
    footercolour
    footerfont
    grid
    highlight
    image
    meta
    new_page
    new_physical_page
    new_song
    no_grid
    pagetype
    start_of_bridge
    start_of_chorus
    start_of_grid
    start_of_tab
    start_of_verse
    subtitle
    tabcolour
    tabfont
    tabsize
    textcolour
    textfont
    textsize
    title
    titlesize
    titlecolour
    titlefont
    titles
    tocsize
    toccolour
    tocfont
    transpose
   );
# NOTE: Flex: start_of_... end_of_... x_...

my %abbrevs = (
   c	      => "comment",
   cb	      => "comment_box",
   cf	      => "chordfont",
   ci	      => "comment_italic",
   colb	      => "column_break",
   cs	      => "chordsize",
   grid       => "diagrams",	# not really an abbrev
   eob	      => "end_of_bridge",
   eoc	      => "end_of_chorus",
   eot	      => "end_of_tab",
   eov	      => "end_of_verse",
   g	      => "diagrams",
   highlight  => "comment",	# not really an abbrev
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

my $dirpat;

sub parse_directive {
    my ( $self, $d ) = @_;

    # Pattern for all recognized directives.
    unless ( $dirpat ) {
	$dirpat =
	  '(?:' .
	  join( '|', @directives,
		     @{$config->{metadata}->{keys}},
		     keys(%abbrevs),
		'(?:start|end)_of_\w+' ) .
		  ')';
	$dirpat = qr/$dirpat/;
    }

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
    if ( $dir =~ /^($dirpat)-(.+)$/ ) {
	$dir = $abbrevs{$1} // $1;
	my $sel = $2;
	my $negate = $sel =~ s/\!$//;
	$sel = ( $sel eq lc($config->{instrument}->{type}) )
	       ||
	       ( $sel eq lc($config->{user}->{name})
	       ||
	       ( $self->{meta}->{lc $sel} && is_true($self->{meta}->{lc $sel}->[0]) )
	       );
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
			my $info = $self->{chordsinfo}->{$_->key};
			next if $info->is_annotation;
			$info = $info->transpose($xp, $xpose <=> 0) if $xp;
			$info = $info->new($info);
			$_ = ChordPro::Chords::Appearance->new
			  ( key => $self->add_chord($info),
			    info => $info,
			    maybe format => $_->format
			  );
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
	    if ( $k =~ /^(title)$/i && $v ne "" ) {
		$opts{lc($k)} = $v;
	    }
	    elsif ( $k =~ /^(border|spread|center)$/i && $v =~ /^(\d+)$/ ) {
		$opts{lc($k)} = $v;
	    }
	    elsif ( $k =~ /^(width|height)$/i && $v =~ /^(\d+(?:\.\d+)?\%?)$/ ) {
		$opts{lc($k)} = $v;
	    }
	    elsif ( $k =~ /^(x|y)$/i && $v =~ /^([-+]?\d+(?:\.\d+)?\%?)$/ ) {
		$opts{lc($k)} = $v;
	    }
	    elsif ( $k =~ /^(scale)$/ && $v =~ /^(\d+(?:\.\d+)?)(%)?$/ ) {
		$opts{lc($k)} = $2 ? $1/100 : $1;
	    }
	    elsif ( $k =~ /^(center|border|spread)$/i ) {
		$opts{lc($k)} = $v;
	    }
	    elsif ( $k =~ /^(src|uri)$/i && $v ne "" ) {
		$uri = $v;
	    }
	    elsif ( $k =~ /^(id)$/i && $v ne "" ) {
		$id = $v;
	    }
	    elsif ( $k =~ /^(anchor)$/i
		    && $v =~ /^(paper|page|column|float|line)$/ ) {
		$opts{lc($k)} = lc($v);
	    }
	    elsif ( $uri ) {
		do_warn( "Unknown image attribute: $k\n" );
		next;
	    }
	    # Assume just an image file uri.
	    else {
		$uri = $k;
	    }
	}

	# If the image name does not have a directory, look it up
	# next to the song, and then in the images folder of the
	# CHORDPRO_LIB.
	if ( $uri && $uri !~ m;^([a-z]:)?[/\\];i ) { # not abs
	    use File::Basename qw(dirname);
	    L: for ( dirname($diag->{file}) ) {
		$uri = "$_/$uri", last if -s "$_/$uri";
		for ( ::rsc_or_file("images/$uri") ) {
		    last unless $_;
		    $uri = $_, last L if -s $_;
		}
		do_warn("Missing image for \"$uri\"");
	    }
	}

	# uri + id -> define asset
	if ( $uri && $id ) {
	    # Define a new asset.
	    if ( %opts ) {
		do_warn("Asset definition \"$id\" does not take attributes");
		return;
	    }
	    use Image::Info;
	    open( my $fd, '<:raw', $uri );
	    unless ( $fd ) {
		do_warn("$uri: $!");
		return;
	    }
	    my $data = do { local $/; <$fd> };
	    # Get info.
	    my $info = Image::Info::image_info(\$data);
	    if ( $info->{error} ) {
		do_warn($info->{error});
		return;
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
	    return 1;
	}

	$uri = "id=$id" if $id;
	unless ( $uri ) {
	    do_warn( "Missing image source\n" );
	    return;
	}
	$self->add( type => $uri =~ /\.svg$/ ? "svg" : "image",
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
		    my $info = $self->parse_chord($val);
		    my $name = $info->name;
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
	# If there a column specifications in the config, retain them
	# if the number of columns match.
	unless( ref($config->{settings}->{columns}) eq 'ARRAY'
	     && $arg == @{$config->{settings}->{columns}}
	   ) {
	    $self->{settings}->{columns} = $arg;
	}
	return 1;
    }

    if ( $dir eq "pagetype" || $dir eq "pagesize" ) {
	$self->{settings}->{papersize} = $arg;
	return 1;
    }

    if ( $dir eq "diagrams" ) {	# AKA grid
	if ( $arg ne "" ) {
	    $self->{settings}->{diagrams} = !!is_true($arg);
	    $self->{settings}->{diagrampos} = lc($arg)
	      if $arg =~ /^(right|bottom|top|below)$/i;
	}
	else {
	    $self->{settings}->{diagrams} = 1;
	}
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
		my $xpk = $self->{chordsinfo}->{$key}->transpose($xp, $xp <=> 0);
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

	# Turn hash.array into hash.array.> (append).
	if ( ref($o) eq 'HASH' && ref($o->{$lk}) eq 'ARRAY' ) {
	    $c = \($$c->{$lk});
	    $o = $o->{$lk};
	    $lk = '>';
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

    # Formatting. {chordsize XX} and such.
    if ( $dir =~ m/ ^( text | chord | chorus | tab | grid | diagrams
		       | title | footer | toc )
		     ( font | size | colou?r )
		     $/x ) {
	my $item = $1;
	my $prop = $2;

	$self->propset( $item, $prop, $arg );

	# Derived props.
	$self->propset( "chorus", $prop, $arg ) if $item eq "text";

	#::dump( { %propstack, line => $diag->{line} } );
	return 1;
    }

    # define A: base-fret N frets N N N N N N fingers N N N N N N
    # define: A base-fret N frets N N N N N N fingers N N N N N N
    # optional: base-fret N (defaults to 1)
    # optional: N N N N N N (for unknown chords)
    # optional: fingers N N N N N N

    if ( $dir eq "define" or $dir eq "chord" ) {

	return $self->define_chord( $dir, $arg );
    }

    # Warn about unknowns, unless they are x_... form.
    do_warn("Unknown directive: $d\n")
      if $config->{settings}->{strict} && $d !~ /^x_/;
    return;
}

sub propset {
    my ( $self, $item, $prop, $value ) = @_;
    $prop = "color" if $prop eq "colour";
    my $name = "$item-$prop";
    $propstack{$name} //= [];

    if ( $value eq "" ) {
	# Pop current value from stack.
	if ( @{ $propstack{$name} } ) {
	    my $old = pop( @{ $propstack{$name} } );
	    # A trailing number after a font directive means there
	    # was also a size saved. Pop it.
	    if ( $prop eq "font" && $old =~ /\s(\d+(?:\.\d+)?)$/ ) {
		pop( @{ $propstack{"$item-size"} } );
	    }
	}
	else {
	    do_warn("No saved value for property $item$prop\n" )
	}
	# Use new current value, if any.
	if ( @{ $propstack{$name} } ) {
	    $value = $propstack{$name}->[-1]
	}
	else {
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
    if ( $prop eq "color" ) {
	my $v;
	unless ( $v = get_color($value) ) {
	    do_warn("Illegal value \"$value\" for $item$prop\n");
	    return 1;
	}
	$value = $v;
    }
    $value = $prop eq "font" ? $value : lc($value);
    $self->add( type  => "control",
		name  => $name,
		value => $value );
    push( @{ $propstack{$name} }, $value );

    # A trailing number after a font directive is an implicit size
    # directive.
    if ( $prop eq 'font' && $value =~ /\s(\d+(?:\.\d+)?)$/ ) {
	$self->add( type  => "control",
		    name  => "$item-size",
		    value => $1 );
	push( @{ $propstack{"$item-size"} }, $1 );
    }
}

sub add_chord {
    my ( $self, $info, $new_id ) = @_;

    if ( $new_id ) {
	if ( $new_id eq "1" ) {
	    state $id = "ch0000";
	    $new_id = " $id";
	    $id++;
	}
    }
    else {
	$new_id = $info->name;
    }
    $self->{chordsinfo}->{$new_id} = $info->new($info);

    return $new_id;
}

sub define_chord {
    my ( $self, $dir, $args ) = @_;

    # Split the arguments and keep a copy for error messages.
    # Note that quotewords returns an empty result if it gets confused,
    # so fall back to the ancient split method if so.
    $args =~ s/^\s+//;
    $args =~ s/\s+$//;
    my @a = quotewords( '[: ]+', 0, $args );
    @a = split( /[: ]+/, $args ) unless @a;

    my @orig = @a;
    my $show = $dir eq "chord";
    my $fail = 0;
    my $name = shift(@a);
    my $strings = $config->diagram_strings;

    # Process the options.
    my %kv = ( name => $name );
    while ( @a ) {
	my $a = shift(@a);

	# Copy existing definition.
	if ( $a eq "copy" || $a eq "copyall" ) {
	    if ( my $i = ChordPro::Chords::known_chord($a[0]) ) {
		$kv{$a} = $a[0];
		$kv{orig} = $i;
		shift(@a);
	    }
	    else {
		do_warn("Unknown chord to copy: $a[0]\n");
		$fail++;
		last;
	    }
	}

	# display
	elsif ( $a eq "display" && @a ) {
	    $kv{display} = demarkup($a[0]);
	    do_warn( "\"display\" should not contain markup, use \"format\"" )
	      unless $kv{display} eq shift(@a);
	    $kv{display} = $self->parse_chord($kv{display},1);
	    delete $kv{display} unless defined $kv{display};
	}

	# format
	elsif ( $a eq "format" && @a ) {
	    $kv{format} = shift(@a);
	}

	# base-fret N
	elsif ( $a eq "base-fret" ) {
	    if ( $a[0] =~ /^\d+$/ ) {
		$kv{base} = shift(@a);
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
	    while ( @a && $a[0] =~ /^(?:[0-9]+|[-xXN])$/ && @f < $strings ) {
		push( @f, shift(@a) );
	    }
	    if ( @f == $strings ) {
		$kv{frets} = [ map { $_ =~ /^\d+/ ? $_ : -1 } @f ];
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
	    while ( @a && @f < $strings ) {
		local $_ = shift(@a);
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
		    unshift( @a, $_ );
		    last;
		}
	    }
	    if ( @f == $strings ) {
		$kv{fingers} = \@f;
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
		$kv{keys} = \@f;
	    }
	    else {
		do_warn("Invalid or missing keys\n");
		$fail++;
		last;
	    }
	}

	elsif ( $a eq "diagram" && @a > 0 ) {
	    if ( $show && !is_true($a[0]) ) {
		do_warn("Useless diagram suppression");
		next;
	    }
	    $kv{diagram} = shift(@a);
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
    # All options are verified and stored in %kv;

    # Result structure.
    my $res = { name => $name };

    # Try to find info.
    my $info = $self->parse_chord( $name, "def" );
    if ( $info ) {
	# Copy the chord info.
	$res->{$_} //= $info->{$_} // ''
	  for qw( root qual ext bass
		  root_canon qual_canon ext_canon bass_canon
		  root_ord root_mod bass_ord bass_mod
	       );
	if ( $show ) {
	    $res->{$_} //= $info->{$_}
	      for qw( base frets fingers keys );
	}
    }
    else {
	$res->{parser} = ChordPro::Chords::get_parser();
    }

    # Copy existing definition.
    for ( $kv{copyall} // $kv{copy} ) {
	next unless defined;
	$res->{copy} = $_;
	my $orig = $res->{orig} = $kv{orig};
	$res->{$_} //= $orig->{$_}
	  for qw( base frets fingers keys );
	if ( $kv{copyall} ) {
	    $res->{$_} //= $orig->{$_}
	      for qw( display format );
	}
    }
    for ( qw( display format ) ) {
	$res->{$_} = $kv{$_} if defined $kv{$_};
    }

    # If we've got diagram visibility, remove it if true.
    if ( defined $kv{diagram} ) {
	for ( my $v = $kv{diagram} ) {
	    if ( is_true($v) ) {
		if ( is_ttrue($v) ) {
		    next;
		}
	    }
	    else {
		$v = 0;
	    }
	    $res->{diagram} = $v;
	}
    }

    # Copy rest of options.
    for ( qw( base frets fingers keys display format ) ) {
	next unless defined $kv{$_};
	$res->{$_} = $kv{$_};
    }

    # At this time, $res is still just a hash. Time to make a chord.
    $res->{base} ||= 1;
    $res = ChordPro::Chord::Common->new
      ( { %$res, origin => $show ? "inline" : "song" } );
    $res->{parser} //= ChordPro::Chords::get_parser();

    if ( $show) {
	my $ci = $res->clone;
	my $chidx = $self->add_chord( $ci, 1 );
	# Combine consecutive entries.
	if ( defined($self->{body})
	     && $self->{body}->[-1]->{type} eq "diagrams" ) {
	    push( @{ $self->{body}->[-1]->{chords} }, $chidx );
	}
	else {
	    $self->add( type   => "diagrams",
			show   => "user",
			origin => "chord",
			chords => [ $chidx ] );
	}
	return 1;
    }

    my $def = {};
    for ( qw( name base frets fingers keys display format diagram ) ) {
	next unless defined $res->{$_};
	$def->{$_} = $res->{$_};
    }
    push( @{$self->{define}}, $def );
    my $ret = ChordPro::Chords::add_song_chord($res);
    if ( $ret ) {
	do_warn("Invalid chord: ", $res->{name}, ": ", $ret, "\n");
	return 1;
    }
    $info = ChordPro::Chords::known_chord($res->{name});
    croak("We just entered it?? ", $res->{name}) unless $info;

    $info->dump if $config->{debug}->{x1};

    return 1;
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

sub _diag {
    my ( $self, %d ) = @_;
    $diag->{$_} = $d{$_} for keys(%d);
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

# Parse a chord.
# Handles transpose/transcode.
# Returns the chord object.
# No parens or annotations, please.
sub parse_chord {
    my ( $self, $chord, $def ) = @_;

    my $debug = $config->{debug}->{chords};

    warn("Parsing chord: \"$chord\"\n") if $debug;
    my $info;
    my $xp = $xpose + $config->{settings}->{transpose};
    $xp += $capo if $capo && $decapo;
    my $xc = $config->{settings}->{transcode};
    my $global_dir = $config->{settings}->{transpose} <=> 0;
    my $unk;

    # When called from {define} ignore xc/xp.
    $xc = $xp = '' if $def;

    $info = ChordPro::Chords::known_chord($chord);
    if ( $info ) {
	warn( "Parsing chord: \"$chord\" found \"",
	      $info->name, "\" in ", $info->{_via}, "\n" ) if $debug > 1;
	$info->dump if $debug > 1;
    }
    else {
	$info = ChordPro::Chords::parse_chord($chord);
	warn( "Parsing chord: \"$chord\" parsed ok [",
	      $info->{system},
	      "]\n" ) if $info && $debug > 1;
    }
    $unk = !defined $info;

    if ( ( $def || $xp || $xc )
	 &&
	 ! ($info && $info->is_xpxc ) ) {
	local $::config->{settings}->{chordnames} = "relaxed";
	$info = ChordPro::Chords::parse_chord($chord);
    }

    unless ( ( $info && $info->is_xpxc )
	     ||
	     ( $def && !( $xc || $xp ) ) ) {
	do_warn( "Cannot parse",
		 $xp ? "/transpose" : "",
		 $xc ? "/transcode" : "",
		 " chord \"$chord\"\n" )
	  if $xp || $xc || $config->{debug}->{chords};
    }

    if ( $xp && $info ) {
	# For transpose/transcode, chord must be wellformed.
	my $i = $info->transpose( $xp,
				  $xpose_dir // $global_dir);
	# Prevent self-references.
	$i->{xp} = $info unless $i eq $info;
	$info = $i;
	warn( "Parsing chord: \"$chord\" transposed ",
	      sprintf("%+d", $xp), " to \"",
	      $info->name, "\"\n" ) if $debug > 1;
    }
    # else: warning has been given.

    if ( $info ) { # TODO roman?
	# Look it up now, the name may change by transcode.
	if ( my $i = ChordPro::Chords::known_chord($info) ) {
	    warn( "Parsing chord: \"$chord\" found ",
		  $i->name, " for ", $info->name,
		  " in ", $i->{_via}, "\n" ) if $debug > 1;
	    $info = $i->new({ %$i, name => $info->name,
			      $info->{xp} ? ( xp => $info->{xp} ) : (),
			      $info->{xc} ? ( xc => $info->{xc} ) : (),
			    }) ;
	    $unk = 0;
	}
	elsif ( $config->{instrument}->{type} eq 'keyboard'
		&& ( my $k = ChordPro::Chords::get_keys($info) ) ) {
	    warn( "Parsing chord: \"$chord\" \"", $info->name, "\" not found ",
		  "but we know what to do\n" ) if $debug > 1;
	    $info = $info->new({ %$info, keys => $k }) ;
	    $unk = 0;
	}
	else {
	    warn( "Parsing chord: \"$chord\" \"", $info->name,
		  "\" not found in song/config chords\n" ) if $debug;
#	    warn("XX \'", $info->agnostic, "\'\n");
	    $unk = 1;
	}
    }

    if ( $xc && $info ) {
	my $key_ord;
	$key_ord = $self->{chordsinfo}->{$self->{meta}->{key}->[-1]}->{root_ord}
	  if $self->{meta}->{key};
	if ( $xcmov && !defined $key_ord ) {
	    do_warn("Warning: Transcoding to $xc without key may yield unexpected results\n");
	    undef $xcmov;
	}
	my $i = $info->transcode( $xc, $key_ord );
	# Prevent self-references.
	$i->{xc} = $info unless $i eq $info;
	$info = $i;
	warn( "Parsing chord: \"$chord\" transcoded to ",
	      $info->name,
	      " (", $info->{system}, ")",
	      "\n" ) if $debug > 1;
	if ( my $i = ChordPro::Chords::known_chord($info) ) {
	    warn( "Parsing chord: \"$chord\" found \"",
		  $info->name, "\" in song/config chords\n" ) if $debug > 1;
	    $unk = 0;
	}
    }
    # else: warning has been given.

    if ( ! $info ) {
	if ( my $i = ChordPro::Chords::known_chord($chord) ) {
	    $info = $i;
	    warn( "Parsing chord: \"$chord\" found \"",
		  $chord, "\" in ",
		  $i->{_via}, "\n" ) if $debug > 1;
	    $unk = 0;
	}
    }

    unless ( $info || $def ) {
	if ( $config->{debug}->{chords} || ! $warned_chords{$chord}++ ) {
	    warn("Parsing chord: \"$chord\" unknown\n") if $debug;
	    do_warn( "Unknown chord: \"$chord\"\n" )
	      unless $chord =~ /^n\.?c\.?$/i;
	}
    }

    if ( $info ) {
	warn( "Parsing chord: \"$chord\" okay: \"",
	      $info->name, "\" \"",
	      $info->chord_display, "\"",
	      $unk ? " but unknown" : "",
	      "\n" ) if $debug > 1;
	$self->store_chord($info);
	return $info;
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
	if ( $item->{type} eq "songline" &&  $item->{context} eq '' ){ # A songline should have a context - non means verse
		$item->{context} = 'verse';
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
	    $a->{chordsinfo}{$ci} = $a->{chordsinfo}{$ci}->simplify;
	}
    }
#    require Data::Dump::Filtered;
#    warn Data::Dump::Filtered::dump_filtered($a, sub {
#						 my ( $ctx, $o ) = @_;
#						 my $h = { hide_keys => [ 'parser' ] };
#						 $h->{bless} = ""
#						   if $ctx->class;
#						 $h;
#				      });
    ::dump($a);
}

unless ( caller ) {
    require DDumper;
    binmode STDERR => ':utf8';
    ChordPro::Config::configurator();
    my $s = ChordPro::Song->new;
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
