#!/usr/bin/perl

use utf8;

package main;

our $options;
our $config;

package ChordPro::Song;

use strict;
use warnings;

use ChordPro;
use ChordPro::Paths;
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

our $re_chords;			# for chords
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
my @diag;			# keep track of includes
my $lineinfo;			# keep lineinfo
my $assetid = "001";		# for assets

# Constructor.

sub new {
    my ( $pkg, $opts ) = @_;

    my $filesource = $opts->{filesource} || $opts->{_filesource};

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

    $diag->{format} = $opts->{diagformat} // $config->{diagnostics}->{format};
    $diag->{file}   = $filesource;
    $diag->{line}   = 0;
    $diag->{orig}   = "(at start of song)";

    bless { chordsinfo => {},
	    meta       => {},
	    generate   => $opts->{generate},
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
	    my $prename = "__PRECFG__";
	    my $precfg = ChordPro::Config->new( json_load( $cf, $prename ) );
	    $precfg->precheck($prename);
	    push( @configs, $precfg->prep_configs($prename) );
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
	    warn("Config[song]: $cf\n") if $options->{verbose};
	    my $have = ChordPro::Config::get_config( CP->findcfg($cf) );
	    die("Missing config: $cf\n") unless $have;
	    push( @configs, $have->prep_configs($cf) );
	}
	else {
	    for ( "prp", "json" ) {
		( my $cf = $diag->{file} ) =~ s/\.\w+$/.$_/;
		$cf .= ".$_" if $cf eq $diag->{file};
		next unless -s $cf;
		warn("Config[song]: $cf\n") if $options->{verbose};
		my $have = ChordPro::Config::get_config($cf);
		push( @configs, $have->prep_configs($cf) );
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
	prpadd2cfg( $config, %$defs );
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

    # Remove inactive delegates.
    while ( my ($k,$v) = each %{ $config->{delegates} } ) {
	delete( $config->{delegates}->{$k} )
	  if $v->{type} eq 'none';
    }

    # And lock the config.
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
	    if ( my $file = CP->findres("config/notes/$target.json") ) {
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

	# Uncomment this to allow \uDXXX\uDYYY (surrogate) escapes.
	s/ \\u(d[89ab][[:xdigit:]]{2})\\u(d[cdef][[:xdigit:]]{2})
	 / pack('U*', 0x10000 + (hex($1) - 0xD800) * 0x400 + (hex($2) - 0xDC00) )
	   /igex;

	# Uncomment this to allow \uXXXX escapes.
	s/\\u([0-9a-f]{4})/chr(hex("0x$1"))/ige;
	# Uncomment this to allow \u{XX...} escapes.
	s/\\u\{([0-9a-f]+)\}/chr(hex("0x$1"))/ige;

	$diag->{orig} = $_;
	# Get rid of TABs.
	s/\t/ /g;

	if ( $config->{debug}->{echo} ) {
	    warn(sprintf("==[%3d]=> %s\n", $diag->{line}, $diag->{orig} ) );
	}

	for my $pp ( "all", "env-$in_context" ) {
	    if ( $prep->{$pp} ) {
		$config->{debug}->{pp} && warn("PRE:  ", $_, "\n");
		$prep->{$pp}->($_);
		$config->{debug}->{pp} && warn("POST: ", $_, "\n");
		if ( /\n/ ) {
		    my @a = split( /\n/, $_ );
		    $_ = shift(@a);
		    unshift( @$lines, @a );
		    $skipcnt += @a;
		}
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

	if ( /^\s*\{((?:new_song|ns)\b.*)\}\s*$/ ) {
	    if ( $self->{body} ) {
		unshift( @$lines, $_ );
		$$linecnt--;
		last;
	    }
	    my $dir = $self->parse_directive($1);
	    next unless my $kv = parse_kv($dir->{arg}//"");
	    if ( defined $kv->{toc} ) {
		$self->{meta}->{_TOC} = [ $kv->{toc} ];
	    }
	    if ( $kv->{forceifempty} ) {
		push( @{ $self->{body} },
		      { type => "set",
			name => "forceifempty",
			value => $kv->{forceifempty} } );
	    }
	    next;
	}

	if ( /^#/ ) {

	    # Handle assets.
	    my $kw = "";
	    my $kv = {};
	    if ( /^##(image|asset|include)(?:-(.+))?:\s+(.*)/i
		 && $self->selected($2) ) {
		$kw = lc($1);
		$kv = parse_kv($3);
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
		  { type     => "image",
		    data     => $data,
		    subtype  => $info->{file_ext},
		    width    => $info->{width},
		    height   => $info->{height},
		    opts     => $kv,
		  };

		if ( $config->{debug}->{images} ) {
		    warn( "asset[$id] type=image/$info->{file_ext} ",
			  length($data), " bytes, ",
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
		unless ( exists $config->{delegates}->{$type} ) {
		    do_warn("Unhandled type for asset: $type\n");
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
		  { data => \@data,
		    type    => "image",
		    subtype => $type,
		    module  => $config->{delegates}->{$type}->{module},
		    handler => $config->{delegates}->{$type}->{handler},
		    opts    => $kv,
		  };
		if ( $config->{debug}->{images} ) {
		    warn("asset[$id] type=image/$type ",
			 scalar(@data), " lines",
			 $kv->{persist} ? ", persist" : "",
			 "\n");
		}
		next;
	    }

	    if ( $kw eq "include" ) {
		if ( $kv->{end} ) {
		    $diag = pop( @diag );
		    $$linecnt = $diag->{line};
		}
		else {
		    my $uri = $kv->{src};
		    if ( $uri && CP->is_here($uri) ) {
			my $found = CP->siblingres( $diag->{file}, $uri, class => "include" );
			if ( $found ) {
			    $uri = $found;
			}
			else {
			    do_warn("Missing include for \"$uri\"");
			    $uri = undef;
			}
		    }
		    if ( $uri ) {
			unshift( @$lines, loadlines($uri), "##include: end=1" );
			push( @diag, { %$diag } );
			$diag->{file} = $uri;
			$diag->{line} = $$linecnt = 0;
			$diag->{orig}   = "(including $uri)";
		    }
		}
		next;
	    }

	    # Currently the ChordPro backend is the only one that
	    # cares about comment lines.
	    # Collect pre-title stuff separately.
	    next unless exists $config->{lc $self->{generate}}
	      && exists $config->{lc $self->{generate}}->{comments}
	      && $config->{lc $self->{generate}}->{comments} eq "retain";

	    if ( exists $self->{title} || $fragment ) {
		$self->add( type => "ignore", text => $_ );
	    }
	    else {
		push( @{ $self->{preamble} }, $_ );
	    }
	    next;
	}

	# Tab content goes literally.
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
		# A subsequent {start_of_XXX} will open a new item

		my $d = $config->{delegates}->{$in_context};
		if ( $d->{type} eq "image" ) {
		    local $_;
		    my $a = pop( @{ $self->{body} } );
		    delete( $a->{context} );
		    my $id = $a->{id};
		    my $opts = {};
		    unless ( $id ) {
			my $pkg = 'ChordPro::Delegate::' . $a->{delegate};
			eval "require $pkg" || warn($@);
			if ( my $c = $pkg->can("options") ) {
			    $opts = $c->($a->{data});
			    $id = $opts->{id};
			}
		    }
		    $opts = $a->{opts} = { %$opts, %{$a->{opts}} };
		    unless ( is_true($opts->{omit}) ) {
			if ( $opts->{align} && $opts->{x} && $opts->{x} =~ /\%$/ ) {
			    do_warn( "Useless combination of x percentage with align (align ignored)" );
			    delete $opts->{align};
	}

			my $def = !!$id;
			$id //= "_Image".$assetid++;

			if ( defined $opts->{spread} ) {
			    $def++;
			    if ( exists $self->{spreadimage} ) {
				do_warn("Skipping superfluous spread image");
			    }
			    else {
				$self->{spreadimage} =
				  { id => $id, space => $opts->{spread} };
				warn("Got spread image $id with space=$opts->{spread}\n")
				  if $config->{debug}->{images};
			    }
			}

			# Move to assets.
			$self->{assets}->{$id} = $a;
			if ( $def ) {
			    my $label = delete $a->{label};
			    do_warn("Label \"$label\" ignored on non-displaying $in_context section\n")
			      if $label;
			}
			else {
			    my $label = delete $opts->{label};
			    $self->add( type => "set",
					name => "label",
					value => $label )
			      if $label && $label ne "";
			    $self->add( type => "image",
					opts => $opts,
					id => $id );
			    if ( $opts->{label} ) {
				push( @labels, $opts->{label} )
				  unless $in_context eq "chorus"
				  && !$config->{settings}->{choruslabels};
			    }
			}
		    }
		}
	    }
	    else {
		# Add to an open item.
		if ( $self->{body} && @{ $self->{body} }
		     && $self->{body}->[-1]->{context} eq $in_context
		     && $self->{body}->[-1]->{open} ) {
		    push( @{$self->{body}->[-1]->{data}},
			  fmt_subst( $self, $_ ) );
		}

		# Else start new item.
		else {
		    croak("Reopening delegate");
		}
		next;
	    }
	}

	# For now, directives should go on their own lines.
	if ( /^\s*\{(.*)\}\s*$/ ) {
	    my $dir = $1;
	    if ( $prep->{directive} ) {
		$config->{debug}->{pp} && warn("PRE:  ", $_, "\n");
		$prep->{directive}->($dir);
		$config->{debug}->{pp} && warn("POST: {", $dir, "}\n");
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
		$config->{debug}->{pp} && warn("PRE:  ", $_, "\n");
		$prep->{songline}->($_);
		$config->{debug}->{pp} && warn("POST: ", $_, "\n");
	    }
	    if ( $config->{settings}->{flowtext}
		 && @{ $self->{body}//[] } ) {
		my $prev = $self->{body}->[-1];
		my $this = { $self->decompose($_) };
		if ( $prev->{type} eq "songline"
		     && !$prev->{chords}
		     && !$this->{chords} ) {
		    $prev->{phrases}->[0] .= " " . $this->{phrases}->[0];
		}
		else {
		    $self->add( type => "songline", %$this );
		}
	    }
	    else {
		$self->add( type => "songline", $self->decompose($_) );
	    }
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

    ::dump($self->{assets}, as => "Assets, Pass 1")
      if $config->{debug}->{assets} & 1;
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
	$suppress{$info->name} = $info->{origin} ne "song";
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
	sub byname { ChordPro::Chords::chordcompare($a,$b) }
	@used_chords = sort byname @used_chords;
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

    $self->dump(0) if $config->{debug}->{song} > 0;
    $self->dump(2) if $config->{debug}->{song} < 0;
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
		    push( @$memchords, $chord eq "" ? "" : $chord );
		    warn("Chord memorized for $in_context\[$memcrdinx]: ",
			 $memchords->[-1], "\n")
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
		push( @chords, $self->chord($memchords->[$memcrdinx]) );
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
    local $re_chords = qr/(\[.*?\])/;

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
		last if /\<\/span>/
		  && ! /\<\/span>.*?\<span/;
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

my %directives = (
		  chord		     => \&define_chord,
		  chorus	     => \&dir_chorus,
		  column_break	     => \&dir_column_break,
		  columns	     => \&dir_columns,
		  comment	     => \&dir_comment,
		  comment_box	     => \&dir_comment,
		  comment_italic     => \&dir_comment,
		  define	     => \&define_chord,
		  diagrams	     => \&dir_diagrams,
		  end_of_bridge	     => undef,
		  end_of_chorus	     => undef,
		  end_of_grid	     => undef,
		  end_of_tab	     => undef,
		  end_of_verse	     => undef,
		  grid		     => \&dir_grid,
		  highlight	     => \&dir_comment,
		  image		     => \&dir_image,
		  meta		     => \&dir_meta,
		  new_page	     => \&dir_new_page,
		  new_physical_page  => \&dir_new_page,
		  new_song	     => \&dir_new_song,
		  no_grid	     => \&dir_no_grid,
		  pagesize	     => \&dir_papersize,
		  pagetype	     => \&dir_papersize,
		  start_of_bridge    => undef,
		  start_of_chorus    => undef,
		  start_of_grid	     => undef,
		  start_of_tab	     => undef,
		  start_of_verse     => undef,
		  subtitle	     => \&dir_subtitle,
		  title		     => \&dir_title,
		  titles	     => \&dir_titles,
		  transpose	     => \&dir_transpose,
   );
# NOTE: Flex: start_of_... end_of_... x_...

my %abbrevs = (
   c	      => "comment",
   cb	      => "comment_box",
   cf	      => "chordfont",
   ci	      => "comment_italic",
   col	      => "colums",
   colb	      => "column_break",
   cs	      => "chordsize",
   eob	      => "end_of_bridge",
   eoc	      => "end_of_chorus",
   eog	      => "end_of_grid",
   eot	      => "end_of_tab",
   eov	      => "end_of_verse",
   g	      => "diagrams",
   ng	      => "no_grid",
   np	      => "new_page",
   npp	      => "new_physical_page",
   ns	      => "new_song",
   sob	      => "start_of_bridge",
   soc	      => "start_of_chorus",
   sog	      => "start_of_grid",
   sot	      => "start_of_tab",
   sov	      => "start_of_verse",
   st	      => "subtitle",
   t	      => "title",
   tf         => "textfont",
   ts         => "textsize",
	      );

# Use by: runtimeinfo.
sub _directives { \%directives }
sub _directive_abbrevs { \%abbrevs }

my $dirpat;

sub parse_directive {
    my ( $self, $d ) = @_;

    # Pattern for all recognized directives.
    unless ( $dirpat ) {
	$dirpat =
	  '(?:' .
	  join( '|', keys(%directives),
		     @{$config->{metadata}->{keys}},
		     keys(%abbrevs),
		     '(?:start|end)_of_\w+',
		     '(?:(?:text|chord|chorus|tab|grid|diagrams|title|footer|toc)'.
		     '(?:font|size|colou?r))',
		) . ')';
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
	unless ( $self->selected($2) ) {
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

    if ( $dir =~ /^start_of_(.*)/
	 && exists $config->{delegates}->{$1}
	 && $config->{delegates}->{$1}->{type} eq 'omit' ) {
	return { name => $dir, arg => $arg, omit => 2 };
    }

    return { name => $dir, arg => $arg, omit => 0 }
}

# Process a selector.
sub selected {
    my ( $self, $sel ) = @_;
    return 1 unless defined $sel;
    my $negate = $sel =~ s/\!$//;
    $sel = ( $sel eq lc($config->{instrument}->{type}) )
      ||
      ( $sel eq lc($config->{user}->{name})
	||
	( $self->{meta}->{lc $sel} && is_true($self->{meta}->{lc $sel}->[0]) )
      );
    $sel = !$sel if $negate;
    return $sel;
}

sub directive {
    my ( $self, $d ) = @_;

    my $dd = $self->parse_directive($d);
    return 1 if $dd->{omit} == 1;

    my $dir = $dd->{name};
    my $arg = $dd->{arg};
    if ( $arg ne "" ) {
	$arg = fmt_subst( $self, $arg );
	if ( $arg !~ /\S/ ) { 	# expansion yields empty
	    if ( $dir =~ /^start_of_/ ) {
		$dd->{omit} = 2;
	    }
	    else {
		return 1;
	    }
	}
    }

    if ( $directives{$dir} ) {
	return $directives{$dir}->( $self, $dir, $arg, $dd->{arg} );
    }

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
	    my $kv = parse_kv( $arg, "shape" );
	    my $shape = $kv->{shape};
	    if ( $shape eq "" ) {
		$self->add( type => "set",
			    name => "gridparams",
			    value => $grid_arg );
	    }
	    elsif ( $shape =~ m/^
			      (?: (\d+) \+)?
			      (\d+) (?: x (\d+) )?
			      (?:\+ (\d+) )?
			      (?:[:\s+] (.*)? )? $/x ) {
		do_warn("Invalid grid params: $shape (must be non-zero)"), return
		  unless $2;
		$grid_arg = [ $2, $3//1, $1//0, $4//0 ];
		$self->add( type => "set",
			    name => "gridparams",
			    value =>  [ @$grid_arg, $5||"" ] );
		push( @labels, $5 ) if length($5||"");
	    }
	    elsif ( $shape ne "" ) {
		$self->add( type => "set",
			    name => "gridparams",
			    value =>  [ @$grid_arg, $shape ] );
		push( @labels, $shape );
	    }
	    if ( ($kv->{label}//"") ne "" ) {
		$self->add( type  => "set",
			    name  => "label",
			    value => $kv->{label} );
		push( @labels, $kv->{label} );
	    }
	    $grid_cells = [ $grid_arg->[0] * $grid_arg->[1],
			    $grid_arg->[2],  $grid_arg->[3] ];
	}
	elsif ( exists $config->{delegates}->{$in_context} ) {
	    my $d = $config->{delegates}->{$in_context};
	    my %opts;
	    if ( $xpose || $config->{settings}->{transpose} ) {
		$opts{transpose} =
		  $xpose + ($config->{settings}->{transpose}//0 );
	    }
	    my $kv = parse_kv( $arg, "label" );
	    delete $kv->{label} if ($kv->{label}//"") eq "";
	    $self->add( type     => "image",
			subtype  => "delegate",
			delegate => $d->{module},
			handler  => $d->{handler},
			data     => [ ],
			opts     => { %opts, %$kv },
			exists($kv->{id}) ? ( id => $kv->{id} ) : (),
			open     => 1 );
	    push( @labels, $kv->{label} ) if exists $kv->{label};
	}
	elsif ( $arg ne "" ) {
	    my $kv = parse_kv( $arg, "label" );
	    my $label = delete $kv->{label};
	    if ( %$kv ) {
		# Assume a mistake.
		do_warn("Garbage in start_of_$in_context: $arg (ignored)\n");
	    }
	    else {
		$self->add( type  => "set",
			    name  => "label",
			    value => $label );
		push( @labels, $label)
		  unless $in_context eq "chorus"
		  && !$config->{settings}->{choruslabels};
	    }
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

    # Metadata extensions (legacy). Should use meta instead.
    # Only accept the list from config.
    if ( any { $_ eq $dir } @{ $config->{metadata}->{keys} } ) {
	return $self->dir_meta( "meta", "$dir $arg" );
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

	$config->unlock;
	prpadd2cfg( $config, $1 => $arg );
	$config->lock;

	upd_config();

	return 1;
    }

    # Warn about unknowns, unless they are x_... form.
    do_warn("Unknown directive: $d\n")
      if $config->{settings}->{strict} && $d !~ /^x_/;
    return;
}

sub dir_chorus {
    my ( $self, $dir, $arg ) = @_;

    if ( $in_context ) {
	do_warn("{chorus} encountered while in $in_context context -- ignored\n");
	return 1;
    }

    # Clone the chorus so we can modify the label, if required.
    my $chorus = @chorus ? dclone(\@chorus) : [];

    if ( @$chorus && $arg && $arg ne "" ) {
	my $kv = parse_kv( $arg, "label" );
	my $label = $kv->{label};
	if ( $chorus->[0]->{type} eq "set" && $chorus->[0]->{name} eq "label" ) {
	    $chorus->[0]->{value} = $label;
	}
	elsif ( defined $label ) {
	    unshift( @$chorus,
		     { type => "set",
		       name => "label",
		       value => $label,
		       context => "chorus",
		     } );
	}
	push( @labels, $label )
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

#### Directive handlers ####

# Song settings.

# Breaks.

sub dir_column_break {
    my ( $self, $dir, $arg ) = @_;
    $self->add( type => "colb" );
    return 1;
}

sub dir_new_page {
    my ( $self, $dir, $arg ) = @_;
    $self->add( type => "newpage" );
    return 1;
}

sub dir_new_song {
    my ( $self, $dir, $arg ) = @_;
    die("FATAL - cannot start a new song now\n");
}

# Comments. Strictly speaking they do not belong here.

sub dir_comment {
    my ( $self, $dir, $arg, $orig ) = @_;
    $dir = "comment" if $dir eq "highlight";
    my %res = $self->cdecompose($arg);
    $res{orig} = $orig;
    $self->add( type => $dir, %res )
      unless exists($res{text}) && $res{text} =~ /^[ \t]*$/;
    return 1;
}

sub dir_image {
    my ( $self, $dir, $arg ) = @_;
    return 1 if $::running_under_test && !$arg;
    use Text::ParseWords qw(quotewords);
    my @words = quotewords( '\s+', 1, $arg );
    my $res;
    # Imply src= if word 0 is not kv.
    if ( @words && $words[0] !~ /\w+=/ ) {
	$words[0] = "src=" . $words[0];
	$res = parse_kv( \@words );
    }
    else {
	$res = parse_kv( \@words, "src" );
    }

    my $uri;
    my $id;
    my $chord;
    my $type;
    my %opts;
    while ( my($k,$v) = each(%$res) ) {
	if ( $k =~ /^(title)$/i && $v ne "" ) {
	    $opts{lc($k)} = $v;
	}
	elsif ( $k =~ /^(border|spread|center|persist|omit)$/i
		&& $v =~ /^(\d+)$/ ) {
	    if ( $k eq "center" && $v ) {
		$opts{align} = $k;
	    }
	    else {
		$opts{lc($k)} = $v;
	    }
	}
	elsif ( $k =~ /^(width|height)$/i
		&& $v =~ /^(\d+(?:\.\d+)?\%?)$/ ) {
	    $opts{lc($k)} = $v;
	}
	elsif ( $k =~ /^(x|y)$/i
		&& $v =~ /^(?:base[+-])?([-+]?\d+(?:\.\d+)?\%?)$/ ) {
	    $opts{lc($k)} = $v;
	}
	elsif ( $k =~ /^(scale)$/
		&& $v =~ /^(\d+(?:\.\d+)?)(%)?(?:,(\d+(?:\.\d+)?)(%)?)?$/ ) {
	    $opts{lc($k)} = [ $2 ? $1/100 : $1 ];
	    $opts{lc($k)}->[1] = $3 ? $4 ? $3/100 : $3 : $opts{lc($k)}->[0];
	}
	elsif ( $k =~ /^(center|border|spread|persist|omit)$/i ) {
	    if ( $k eq "center" ) {
		$opts{align} = $k;
	    }
	    else {
		$opts{lc($k)} = $v;
	    }
	}
	elsif ( $k =~ /^(src|uri)$/i && $v ne "" ) {
	    $uri = $v;
	}
	elsif ( $k =~ /^(id)$/i && $v ne "" ) {
	    $id = $v;
	}
	elsif ( $k =~ /^(chord)$/i && $v ne "" ) {
	    $chord = $v;
	}
	elsif ( $k =~ /^(type)$/i && $v ne "" ) {
	    $opts{type} = $v;
	}
	elsif ( $k =~ /^(label|href)$/i && $v ne "" ) {
	    $opts{lc($k)} = $v;
	}
	elsif ( $k =~ /^(anchor)$/i
		&& $v =~ /^(paper|page|column|float|line)$/ ) {
	    $opts{lc($k)} = lc($v);
	}
	elsif ( $k =~ /^(align)$/i
		&& $v =~ /^(center|left|right)$/ ) {
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

    return if is_true($opts{omit});

    unless ( $uri || $id || $chord ) {
	do_warn( "Missing image source\n" );
	return;
    }
    if ( $opts{align} && $opts{x} && $opts{x} =~ /\%$/ ) {
	do_warn( "Useless combination of x percentage with align (align ignored)" );
	delete $opts{align};
    }

    # If the image uri does not have a directory, look it up
    # next to the song, and then in the images folder of the
    # resources.
    if ( $uri && CP->is_here($uri) ) {
	my $found = CP->siblingres( $diag->{file}, $uri, class => "images" )
	  || CP->siblingres( $diag->{file}, $uri, class => "icons" );
	if ( $found ) {
	    $uri = $found;
	}
	else {
	    do_warn("Missing image for \"$uri\"");
	    return;
	}
    }
    $uri = "chord:$chord" if $chord;

    my $aid = $id || "_Image".$assetid++;

    if ( defined $opts{spread} ) {
	if ( exists $self->{spreadimage} ) {
	    do_warn("Skipping superfluous spread image");
	}
	else {
	    $self->{spreadimage} =
	      { id => $aid, space => $opts{spread} };
	    warn("Got spread image $aid with $opts{spread} space\n")
	      if $config->{debug}->{images};
	}
    }

    # Store as asset.
    if ( $uri ) {
	my $opts;
	for ( qw( type persist href ) ) {
	    $opts->{$_} = $opts{$_} if defined $opts{$_};
	    delete $opts{$_};
	}
	for ( qw( spread ) ) {
	    $opts->{$_} = $opts{$_} if defined $opts{$_};
	}

	if ( $id && %opts ) {
	    do_warn("Asset definition \"$id\" does not take attributes",
		   " (" . join(" ",sort keys %opts) . ")");
	    return;
	}

	$self->{assets} //= {};
	my $a;
	if ( $uri =~ /\.(\w+)$/ && exists $config->{delegates}->{$1} ) {
	    my $d = $config->{delegates}->{$1};
	    $a = { type      => "image",
		   subtype   => "delegate",
		   delegate  => $d->{module},
		   handler   => $d->{handler},
		   uri       => $uri,
		 };
	}
	else {
	    $a = { type      => "image",
		   uri       => $uri,
		 };
	}
	$a->{opts} = $opts if $opts;
	$self->{assets}->{$aid} = $a;

	if ( $config->{debug}->{images} ) {
	    warn("asset[$aid] type=image uri=$uri",
		 $a->{subtype} ? " subtype=$a->{subtype}" : (),
		 $a->{delegate} ? " delegate=$a->{delegate}" : (),
		 $opts->{persist} ? " persist" : (),
		 "\n");
	}
	return if $id || defined $opts{spread};	# defining only
    }

    if ( $opts{label} ) {
	$self->add( type      => "set",
		    name      => "label",
		    value     => $opts{label},
		    context   => "image" );
	push( @labels, $opts{label} );
    }

    $self->add( type      => "image",
		id        => $aid,
		opts      => \%opts );
    return 1;
}

sub dir_title {
    my ( $self, $dir, $arg ) = @_;
    $self->{title} = $arg;
    push( @{ $self->{meta}->{title} }, $arg );
    return 1;
}

sub dir_subtitle {
    my ( $self, $dir, $arg ) = @_;
    push( @{ $self->{subtitle} }, $arg );
    push( @{ $self->{meta}->{subtitle} }, $arg );
    return 1;
}

# Metadata.

sub dir_meta {
    my ( $self, $dir, $arg ) = @_;

    if ( $arg =~ /([^ :]+)[ :]+(.*)/ ) {
	my $key = lc $1;
	my @vals = ( $2 );
	if ( $config->{metadata}->{autosplit} ) {
	    @vals = map { s/s\+$//; $_ }
	      split( quotemeta($config->{metadata}->{separator}), $vals[0] );
	}
	else {
	    pop(@vals) if $vals[0] eq '';
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
		my $info = do {
		    # When transcoding to nash/roman, parse_chord will
		    # complain about a missing key. Fake one.
		    local( $self->{meta}->{key} ) = [ '_dummy_' ];
		    local( $self->{chordsinfo}->{_dummy_} ) = { root_ord => 0 };
		    $self->parse_chord($val);
		};
		do_warn("Illegal key: \"$val\"\n"), next unless $info;
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
	do_warn("Incomplete meta directive: $dir $arg\n")
	  if $config->{settings}->{strict};
	return;
    }
    return 1;
}

# Song / Global settings.

sub dir_titles {
    my ( $self, $dir, $arg ) = @_;

    unless ( $arg =~ /^(left|right|center|centre)$/i ) {
	do_warn("Invalid argument for titles directive: $arg\n");
	return 1;
    }
    $self->{settings}->{titles} = lc($1) eq "centre" ? "center" : lc($1);
    return 1;
}

sub dir_columns {
    my ( $self, $dir, $arg ) = @_;

    unless ( $arg =~ /^(\d+)$/ ) {
	do_warn("Invalid argument for columns directive: $arg (should be a number)\n");
	return 1;
    }
    # If there a column specifications in the config, retain them
    # if the number of columns match.
    unless( ref($config->{settings}->{columns}) eq 'ARRAY'
	    && $arg == @{$config->{settings}->{columns}}
	  ) {
	$self->{settings}->{columns} = $arg;
    }
    return 1;
}

sub dir_papersize {
    my ( $self, $dir, $arg ) = @_;
    $self->{settings}->{papersize} = $arg;
    return 1;
}

sub dir_diagrams {	# AKA grid
    my ( $self, $dir, $arg ) = @_;

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

sub dir_grid {
    my ( $self, $dir, $arg ) = @_;
    $self->{settings}->{diagrams} = 1;
    return 1;
}

sub dir_no_grid {
    my ( $self, $dir, $arg ) = @_;
    $self->{settings}->{diagrams} = 0;
    return 1;
}

sub dir_transpose {
    my ( $self, $dir, $arg ) = @_;

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

#### End of directive handlers ####

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
		$self->add( type  => "control",
			    name  => "$item-size",
			    value =>
			    @{ $propstack{"$item-size"} }
			    ? $propstack{"$item-size"}->[-1]
			    : undef )
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
	    while ( @a && $a[0] =~ /^(?:-?[0-9]+|[-xXN])$/ && @f < $strings ) {
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
	  for qw( parser root qual ext bass
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
	return ChordPro::Chord::NC->new( { name => $info->name } )
	  if $info->is_nc;
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
    $full ||= 0;

    if ( $full == 2 ) {
	return ::dump($self->{body});
    }
    my $a = dclone($self);
    $a->{config} = ref(delete($a->{config}));
    unless ( $full ) {
	for my $ci ( keys %{$a->{chordsinfo}} ) {
	    $a->{chordsinfo}{$ci} = $a->{chordsinfo}{$ci}->simplify;
	}
    }
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
