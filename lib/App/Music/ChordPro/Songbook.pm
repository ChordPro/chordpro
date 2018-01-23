#!/usr/bin/perl

package App::Music::ChordPro::Songbook;

use strict;
use warnings;

use App::Music::ChordPro;
use App::Music::ChordPro::Chords;
use App::Music::ChordPro::Output::Common;

use Carp;

sub new {
    my ($pkg) = @_;
    bless { songs => [ ] }, $pkg;
}

# Parser context.
my $def_context = "";
my $in_context = $def_context;
my $grid_arg;
my $grid_cells;

# Local transposition.
my $xpose = 0;

# Chord type for this song, used to detect mixing types.
my $chordtype;

# Used chords, in order of appearance.
my @used_chords;

# Chorus lines, if any.
my @chorus;

# Keep track of unknown chords, to avoid dup warnings.
my %warned_chords;

my $re_meta;			# for metadata

# Normally, transposition and subtitutions are handled by the parser.
my $no_transpose;		# NYI
my $no_substitute;

my $diag;			# for diagnostics

sub parsefile {
    my ( $self, $filename, $options ) = @_;
    $options //= {};

    my $lines = ::loadfile( $filename, $options );
    $diag->{format} = $options->{diagformat}
      || $::config->{diagnostics}->{format};
    $diag->{file} = $options->{_filesource};

    my $linecnt = 0;
    while ( @$lines ) {
	my $song = $self->parse_song( $lines, \$linecnt, $options );
#	if ( exists($self->{songs}->[-1]->{body}) ) {
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
    my ( $self, $lines, $linecnt, $options ) = @_;

    $no_transpose = $options->{'no-transpose'};
    $no_substitute = $options->{'no-substitute'};

    $song = App::Music::ChordPro::Song->new
      ( source => { file => $diag->{file}, line => 1 + $$linecnt },
	structure => "linear",
      );

    $xpose = 0;
    $grid_arg = '1+4x4+1';
    $in_context = $def_context;
    @used_chords = ();
    %warned_chords = ();
    undef $chordtype;
    App::Music::ChordPro::Chords::reset_song_chords();

    # Build regex for the known metadata items.
    if ( $::config->{metadata}->{keys} ) {
	$re_meta = '^(' .
	  join( '|', map { quotemeta } @{$::config->{metadata}->{keys}} )
	    . ')$';
	$re_meta = qr/$re_meta/;
    }
    else {
	undef $re_meta;
    }

    while ( @$lines ) {
	$diag->{line} = ++$$linecnt;
	$diag->{orig} = $_ = shift(@$lines);

	if ( /^\s*\{(new_song|ns)\}\s*$/ ) {
	    last if $song->{body};
	    next;
	}

	if ( /^#/ ) {
	    # Collect pre-title stuff separately.
	    if ( exists $song->{title} ) {
		$self->add( type => "ignore", text => $_ );
	    }
	    else {
		push( @{ $song->{preamble} }, $_ );
	    }
	    next;
	}

	# For practical reasons: a prime should always be an apostroph.
	s/'/\x{2019}/g;

	# For now, directives should go on their own lines.
	if ( /^\s*\{(.*)\}\s*$/ ) {
	    $self->add( type => "ignore",
			text => $_ )
	      unless
	    $options->{_legacy}
	      ? $self->global_directive( $1, 1 )
	      : $self->directive($1);
	    next;
	}

	if ( $in_context eq "tab" ) {
	    $self->add( type => "tabline", text => $_ );
	    next;
	}

	if ( $in_context eq "grid" ) {
	    $self->add( type => "gridline", $self->decompose_grid($_) );
	    next;
	}

	if ( /\S/ ) {
	    $self->add( type => "songline", $self->decompose($_) );
	}
	elsif ( exists $song->{title} ) {
	    $self->add( type => "empty" );
	}
	else {
	    # Collect pre-title stuff separately.
	    push( @{ $song->{preamble} }, $_ );
	}
    }
    do_warn("Unterminated context in song: $in_context")
      if $in_context;

    my $diagrams;
    if ( exists($song->{settings}->{diagrams} ) ) {
	$diagrams = $song->{settings}->{diagrams};
	$diagrams &&= $::config->{diagrams}->{show} || "all";
    }
    else {
	$diagrams = $::config->{diagrams}->{show};
    }

    if ( $diagrams =~ /^(user|all)$/
	 && defined($chordtype)
	 && $chordtype =~ /^[RN]$/ ) {
	$diag->{orig} = "(End of Song)";
	do_warn("Chord diagrams suppressed for Nasville/Roman chords");
	$diagrams = "none";
    }

    if ( $diagrams =~ /^(user|all)$/ ) {
	my %h;
	@used_chords = map { $h{$_}++ ? () : $_ } @used_chords;

	if ( $diagrams eq "user" ) {
	    @used_chords =
	    grep { safe_chord_info($_)->{origin} == 1 } @used_chords;
	}

	if ( $::config->{diagrams}->{sorted} ) {
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

    # Global transposition.
    $song->transpose( $options->{transpose} );

    # $song->structurize;

    return $song;
}

sub add {
    my $self = shift;
    push( @{$song->{body}},
	  { context => $in_context,
	    @_ } );
    push( @chorus, { context => $in_context, @_ } )
      if $in_context eq "chorus";
}

sub chord {
    my ( $self, $c ) = @_;
    return $c unless length($c);
    my $parens = $c =~ s/^\((.*)\)$/$1/;

    my $info = App::Music::ChordPro::Chords::identify($c);
    if ( $info->{system} ) {
	if ( defined $chordtype ) {
	    if ( $chordtype ne $info->{system} ) {
		$chordtype = $info->{system};
		do_warn("Mixed chord systems detected in song");
	    }
	}
	else {
	    $chordtype = $info->{system};
	}
    }
    elsif ( $info->{warning} && ! $warned_chords{$c}++ ) {
	do_warn("Mysterious chord: $c")
	  unless $c =~ /^n\.?c\.?$/i;
    }
    elsif ( $info->{error} && ! $warned_chords{$c}++ ) {
	do_warn("Unrecognizable chord: $c")
	  unless $c =~ /^n\.?c\.?$/i;
    }

    # Local transpose, if requested.
    if ( $xpose ) {
	$_ = App::Music::ChordPro::Chords::transpose( $c, $xpose )
	  and
	    $c = $_;
    }

    push( @used_chords, $c );

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
    my ($self, $line) = @_;
    $line =~ s/\s+$//;
    my @a = split(/(\[.*?\])/, $line, -1);

    die(msg("Illegal line")."\n") unless @a; #### TODO

    if ( @a == 1 ) {
	return ( phrases => [ $line ] );
    }

    shift(@a) if $a[0] eq "";
    unshift(@a, '[]') if $a[0] !~ /^\[/;


    my @phrases;
    my @chords;
    while ( @a ) {
	my $t = shift(@a);
	$t =~ s/^\[(.*)\]$/$1/;
	push(@chords, $self->chord($t));
	push(@phrases, shift(@a));
    }

    return ( phrases => \@phrases, chords  => \@chords );
}

sub cdecompose {
    my ( $self, $line ) = @_;
    $line = App::Music::ChordPro::Output::Common::fmt_subst( $song,
						     $line )
      unless $no_substitute;
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

sub dir_split {
    my ( $d ) = @_;
    $d =~ s/^[: ]+//;
    $d =~ s/\s+$//;
    my $dir = lc($d);
    my $arg = "";
    if ( $d =~ /^(.*?)[: ]\s*(.*)/ ) {
	( $dir, $arg ) = ( lc($1), $2 );
    }
    $dir =~ s/[: ]+$//;
    ( $dir, $arg );
}

sub directive {
    my ($self, $d) = @_;
    my ( $dir, $arg ) = dir_split($d);

    # Context flags.

    if    ( $dir eq "soc" ) { $dir = "start_of_chorus" }
    elsif ( $dir eq "sot" ) { $dir = "start_of_tab"    }
    elsif ( $dir eq "eoc" ) { $dir = "end_of_chorus"   }
    elsif ( $dir eq "eot" ) { $dir = "end_of_tab"      }

    if ( $dir =~ /^start_of_(\w+)$/ ) {
	do_warn("Already in " . ucfirst($in_context) . " context\n")
	  if $in_context;
	$in_context = $1;
	$arg = $grid_arg if $in_context eq "grid" && $arg eq "";
	if ( $in_context eq "grid" && $arg &&
	     $arg =~ m/^
		       (?: (\d+) \+)?
		       (\d+) (?: x (\d+) )?
		       (?:\+ (\d+) )?
		       $/x ) {
	    do_warn("Invalid grid params: $arg (must be non-zero)"), return
	      unless $2;
	    $self->add( type => "set",
			name => "gridparams",
			value => [ $2, $3, $1, $4 ] );
	    $grid_arg = $arg;
	    $grid_cells = [ $2 * ( $3//1 ), ($1//0), ($4//0) ];
	}
	elsif ( $arg && $arg ne "" ) {
	    $self->add( type  => "set",
			name  => "tag",
			value => $arg );
	}
	else {
	    do_warn("Garbage in start_of_$1: $arg (ignored)\n")
	      if $arg;
	}
	@chorus = () if $in_context eq "chorus";
	return 1;
    }
    if ( $dir =~ /^end_of_(\w+)$/ ) {
	do_warn("Not in " . ucfirst($1) . " context\n")
	  unless $in_context eq $1;
	$in_context = $def_context;
	return 1;
    }
    if ( $dir =~ /^chorus$/i ) {
	if ( $in_context ) {
	    do_warn("{chorus} encountered while in $in_context context -- ignored\n");
	    return 1;
	}
	$self->add( type => "rechorus",
		    @chorus
		    ? ( "chorus" => App::Music::ChordPro::Config::clone(\@chorus),
			"transpose" => $xpose )
		    : (),
		  );
	return 1;
    }

    # Song settings.

    # Breaks.

    if ( $dir =~ /^(?:colb|column_break)$/i ) {
	$self->add( type => "colb" );
	return 1;
    }

    if ( $dir =~ /^(?:new_page|np|new_physical_page|npp)$/i ) {
	$self->add( type => "newpage" );
	return 1;
    }

    if ( $dir =~ /^(?:new_song|ns)$/i ) {
	die("FATAL - cannot start a new song now\n");
    }

    # Comments. Strictly speaking they do not belong here.

    if ( $dir =~ /^(?:comment|c|highlight)$/ ) {
	$self->add( type => "comment", $self->cdecompose($arg),
		    orig => $arg );
	return 1;
    }

    if ( $dir =~ /^(?:comment_italic|ci)$/ ) {
	$self->add( type => "comment_italic", $self->cdecompose($arg),
		    orig => $arg );
	return 1;
    }

    if ( $dir =~ /^(?:comment_box|cb)$/ ) {
	$self->add( type => "comment_box", $self->cdecompose($arg),
		    orig => $arg );
	return 1;
    }

    # Images.
    if ( $dir eq "image" ) {
	use Text::ParseWords qw(shellwords);
	my @args = shellwords($arg);
	my $uri;
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
	    elsif ( /^(title)=(.*)$/i ) {
		$opts{title} = $1;
	    }
	    elsif ( /^(.+)=(.*)$/i ) {
		do_warn( "Unknown image attribute: $1\n" );
		next;
	    }
	    else {
		$uri = $_;
	    }
	}
	unless ( $uri ) {
	    do_warn( "Missing image source\n" );
	    return;
	}
	$self->add( type => "image",
		    uri  => $uri,
		    opts => \%opts );
	return 1;
    }

    if ( $dir =~ /^(?:title|t)$/ ) {
	$song->{title} = $arg;
	push( @{ $song->{meta}->{title} }, $arg );
	return 1;
    }

    if ( $dir =~ /^(?:subtitle|st)$/ ) {
	push( @{ $song->{subtitle} }, $arg );
	push( @{ $song->{meta}->{subtitle} }, $arg );
	return 1;
    }

    # Metadata extensions (legacy). Should use meta instead.
    # Only accept the list from config.
    if ( $re_meta && $dir =~ $re_meta ) {
	if ( $xpose && $1 eq "key" ) {
	    $arg = App::Music::ChordPro::Chords::transpose( $arg, $xpose );
	}
	push( @{ $song->{meta}->{$1} }, $arg );
	return 1;
    }

    # More metadata.
    if ( $dir =~ /^(meta)$/ ) {
	if ( $arg =~ /([^ :]+)[ :]+(.*)/ ) {
	    my $key = lc $1;
	    my $val = $2;
	    if ( $xpose && $key eq "key" ) {
		$val = App::Music::ChordPro::Chords::transpose( $val, $xpose );
	    }
	    if ( $re_meta && $key =~ $re_meta ) {
		# Known.
		push( @{ $song->{meta}->{$key} }, $val );
	    }
	    elsif ( $::config->{metadata}->{strict} ) {
		# Unknown, and strict.
		do_warn("Unknown metadata item: $key");
		return;
	    }
	    else {
		# Allow.
		push( @{ $song->{meta}->{$key} }, $val );
	    }
	}
	else {
	    do_warn("Incomplete meta directive: $d\n");
	    return;
	}
	return 1;
    }

    return 1 if $self->global_directive( $d, 0 );

    # Warn about unknowns, unless they are x_... form.
    do_warn("Unknown directive: $d\n") unless $d =~ /^x_/;
    return;
}

my %propstack;

sub global_directive {
    my ($self, $d, $legacy ) = @_;
    my ( $dir, $arg ) = dir_split($d);

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

    if ( $dir =~ /^(?:grid|g)$/ ) {
	$song->{settings}->{diagrams} = 1;
	return 1;
    }
    if ( $dir =~ /^(?:no_grid|ng)$/ ) {
	$song->{settings}->{diagrams} = 0;
	return 1;
    }

    if ( $d =~ /^transpose[: ]+([-+]?\d+)\s*$/ ) {
	return if $legacy;
	$propstack{transpose} //= [];
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
	return 1;
    }
    if ( $dir =~ /^transpose\s*$/ ) {
	return if $legacy;
	$propstack{transpose} //= [];
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
	return 1;
    }

    # More private hacks.
    if ( $d =~ /^([-+])([-\w.]+)$/i ) {
	return if $legacy;
	$self->add( type => "set",
		    name => $2,
		    value => $1 eq "+" ? 1 : 0,
		  );
	return 1;
    }

    if ( $dir =~ /^\+([-\w.]+)$/ ) {
	return if $legacy;
	$self->add( type => "set",
		    name => $1,
		    value => $arg,
		  );
	return 1;
    }

    # Formatting.
    if ( $dir =~ /^(text|chord|tab|grid|diagrams|title|footer|toc)(font|size|colou?r)$/ ) {
	my $item = $1;
	my $prop = $2;
	my $value = $arg;
	return if $legacy
	  && ! ( $item =~ /^(text|chord|tab)$/ && $prop =~ /^(font|size)$/ );

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

    if ( $dir =~ /^define|chord$/ ) {
	my $show = $dir eq "chord";
	return if $legacy && $show;

	# Split the arguments and keep a copy for error messages.
	my @a = split( /[: ]+/, $arg );
	my @orig = @a;

	# Result structure.
	my $res = { name => shift(@a) };

	my $strings = App::Music::ChordPro::Chords::strings;
	my $fail = 0;

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
		$ci = { name => $res->{name},
			base => $res->{base} ? $res->{base} : 0,
			strings => $res->{frets},
			$res->{fingers} ? ( fingers => $res->{fingers} ) : (),
		      };
	    }
	    else {
		$ci = $res->{name};
	    }
	    # Combine consecutive entries.
	    if ( $song->{body}->[-1]->{type} eq "diagrams" ) {
		push( @{ $song->{body}->[-1]->{chords} },
		      $ci );
	    }
	    else {
		$self->add( type => "diagrams",
			    show => "user",
			    origin => "chord",
			    chords => [ $ci ] );
	    }
	}
	elsif ( $res->{frets} || $res->{base} || $res->{fingers} ) {
	    $res->{base} ||= 1;
	    push( @{$song->{define}}, $res );
	    if ( $res->{frets} ) {
		my $res =
		  App::Music::ChordPro::Chords::add_song_chord
		      ( $res->{name}, $res->{base}, $res->{frets}, $res->{fingers} );
		if ( $res ) {
		    do_warn("Invalid chord: ", $res->{name}, ": ", $res, "\n");
		    return 1;
		}
	    }
	    else {
		App::Music::ChordPro::Chords::add_unknown_chord( $res->{name} );
	    }
	}
	else {
	    unless ( App::Music::ChordPro::Chords::chord_info($res->{name}) ) {
		do_warn("Unknown chord: $res->{name}\n");
		return 1;
	    }
	}

	return 1;
    }

    return;
}

sub transpose {
    my ( $self, $xpose ) = @_;
    return unless $xpose;

    foreach my $song ( @{ $self->{songs} } ) {
	$song->transpose($xpose);
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
    my ( $self, $xpose ) = @_;

    # Transpose meta data (key).
    if ( exists $self->{meta} && exists $self->{meta}->{key} ) {
	foreach ( @{ $self->{meta}->{key} } ) {
	    $_ = $self->xpchord( $_, $xpose );
	}
    }

    # Transpose song chords.
    if ( exists $self->{chords} ) {
	foreach my $item ( $self->{chords} ) {
	    $self->_transpose( $item, $xpose );
	}
    }

    # Transpose body contents.
    if ( exists $self->{body} ) {
	foreach my $item ( @{ $self->{body} } ) {
	    $self->_transpose( $item, $xpose );
	}
    }
}

sub _transpose {
    my ( $self, $item, $xpose ) = @_;
    $xpose //= 0;

    if ( $item->{type} eq "rechorus" ) {
	return unless $item->{chorus};
	for ( @{ $item->{chorus} } ) {
	    $self->_transpose( $_, $xpose + $item->{transpose} );
	}
	return;
    }
    return unless $xpose;

    if ( $item->{type} eq "songline" ) {
	# Prevent chords to be autovivified.
	# The ChordPro backend relies on it.
	return unless exists $item->{chords};

	foreach ( @{ $item->{chords} } ) {
	    $_ = $self->xpchord( $_, $xpose );
	}
	return;
    }

    if ( $item->{type} =~ /^comment/ ) {
	return unless $item->{chords};
	foreach ( @{ $item->{chords} } ) {
	    $_ = $self->xpchord( $_, $xpose );
	}
	return;
    }

    if ( $item->{type} eq "gridline" ) {
	foreach ( @{ $item->{tokens} } ) {
	    return unless $_->{class} eq "chord";
	    $_->{chord} = $self->xpchord( $_->{chord}, $xpose );
	}
	if ( $item->{margin} && exists $item->{margin}->{chords} ) {
	    foreach ( @{ $item->{margin}->{chords} } ) {
		$_ = $self->xpchord( $_, $xpose );
	    }
	}
	if ( $item->{comment} && exists $item->{comment}->{chords} ) {
	    foreach ( @{ $item->{comment}->{chords} } ) {
		$_ = $self->xpchord( $_, $xpose );
	    }
	}
	return;
    }

    if ( $item->{type} eq "diagrams" ) {
	foreach ( @{ $item->{chords} } ) {
	    $_ = $self->xpchord( $_, $xpose );
	}
	return;
    }
}

sub xpchord {
    my ( $self, $c, $xpose ) = @_;
    return $c unless length($c) && $xpose;
    return $c if ref $c;
    my $parens = $c =~ s/^\((.*)\)$/$1/;
    my $xc = App::Music::ChordPro::Chords::transpose( $c, $xpose );
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
