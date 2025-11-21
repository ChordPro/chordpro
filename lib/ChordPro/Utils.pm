#! perl

package ChordPro::Utils;

use v5.26;
use utf8;
use Carp;
use feature qw( signatures );
no warnings "experimental::signatures";
use Ref::Util qw( is_arrayref is_hashref );

use Exporter 'import';
our @EXPORT;
our @EXPORT_OK;
our %EXPORT_TAGS;

use ChordPro::Files;

################ Filenames ################

use File::Glob ( ":bsd_glob" );

# Derived from Path::ExpandTilde.

use constant BSD_GLOB_FLAGS => GLOB_NOCHECK | GLOB_QUOTE | GLOB_TILDE | GLOB_ERR
  # add GLOB_NOCASE as in File::Glob
  | ($^O =~ m/\A(?:MSWin32|VMS|os2|dos|riscos)\z/ ? GLOB_NOCASE : 0);

# File::Glob did not try %USERPROFILE% (set in Windows NT derivatives) for ~ before 5.16
use constant WINDOWS_USERPROFILE => is_msw && $] < 5.016;

sub expand_tilde ( $dir ) {

    return undef unless defined $dir;
    return fn_canonpath($dir) unless $dir =~ m/^~/;

    # Parse path into segments.
    my ( $volume, $directories, $file ) = fn_splitpath( $dir, 1 );
    my @parts = fn_splitdir($directories);
    my $first = shift( @parts );
    return fn_canonpath($dir) unless defined $first;

    # Expand first segment.
    my $expanded;
    if ( WINDOWS_USERPROFILE and $first eq '~' ) {
	$expanded = $ENV{HOME} || $ENV{USERPROFILE};
    }
    else {
	( my $pattern = $first ) =~ s/([\\*?{[])/\\$1/g;
	($expanded) = bsd_glob( $pattern, BSD_GLOB_FLAGS );
	croak( "Failed to expand $first: $!") if GLOB_ERROR;
    }
    return fn_canonpath($dir)
      if !defined $expanded or $expanded eq $first;

    # Replace first segment with new path.
    ( $volume, $directories ) = fn_splitpath( $expanded, 1 );
    $directories = fn_catdir( $directories, @parts );
    return fn_catpath($volume, $directories, $file);
}

push( @EXPORT, 'expand_tilde' );

sub sys ( @cmd ) {
    warn("+ @cmd\n") if $::options->{trace};
    # Use outer defined subroutine, depends on Wx or not.
    my $res = ::sys(@cmd);
    warn( sprintf("=%02x=> @cmd", $res), "\n" ) if $res;
    return $res;
}

push( @EXPORT, 'sys' );

################ (Pre)Processing ################

sub make_preprocessor ( $prp ) {
    return unless $prp;

    my $prep;
    foreach my $linetype ( keys %{ $prp } ) {
	my @targets;
	my $code = "";
	foreach ( @{ $prp->{$linetype} } ) {
	    my $flags = $_->{flags} // "g";
	    $code .= "m\0" . $_->{select} . "\0 && "
	      if $_->{select};
	    if ( $_->{pattern} ) {
		$code .= "s\0" . $_->{pattern} . "\0"
		  . $_->{replace} . "\0$flags;\n";
	    }
	    else {
		$code .= "s\0" . quotemeta($_->{target}) . "\0"
		  . quotemeta($_->{replace}) . "\0$flags;\n";
	    }
	}
	if ( $code ) {
	    my $t = "sub { for (\$_[0]) {\n" . $code . "}}";
	    $prep->{$linetype} = eval $t;
	    die( "CODE : $t\n$@" ) if $@;
	}
    }
    $prep;
}

push( @EXPORT, 'make_preprocessor' );

################ Utilities ################

# Split (pseudo) command line into key/value pairs.

# Similar to JavaScript, we do not distinguish single- and double
# quoted strings.
# \\ \' \" yield \ ' " (JS)
# \n yields a newline (convenience)
# Everything else yields the character following the backslash (JS)

my %esc = ( n => "\n", '\\' => '\\', '"' => '"', "'" => "'" );

sub parse_kv ( $line, $kdef = undef ) {

    my @words;
    if ( is_arrayref($line) ) {
	@words = @$line;
    }
    else {
	# Strip.
	$line =~ s/^\s+//;
	$line =~ s/\s+$//;

	# If it doesn't look like key=value, use the default key (if any).
	if ( $kdef && $line !~ /^\w+=(?:['"]|[-+]?\d|\w)/ ) {
	    return { $kdef => $line };
	}

	use Text::ParseWords qw(quotewords);
	@words = quotewords( '\s+', 1, $line );
    }

    my $res = {};
    foreach ( @words ) {

	# Quoted values.
	if ( /^(.*?)=(["'])(.*)\2$/ ) {
	    my ( $k, $v ) = ( $1, $3 );
	    $res->{$k} = $v =~ s;\\(.);$esc{$1}//$1;segr;
	}

	# Unquoted values.
	elsif ( /^(.*?)=(.+)$/ ) {
	    $res->{$1} = $2;
	}

	# Negated keywords.
	elsif ( /^no[-_]?(.+)/ ) {
	    $res->{$1} = 0;
	}

	# Standalone keywords.
	else {
	    $res->{$_}++;
	}
    }

    return $res;
}

push( @EXPORT, 'parse_kv' );

# Split (pseudo) command lines into key/value pairs.

#### LEGACY -- WILL BE REMOVED ####

sub parse_kvm ( @lines ) {

    if ( is_macos() ) {
	# MacOS has the nasty habit to smartify quotes.
	@lines = map { s/“/"/g; s/”/"/g; s/‘/'/g; s/’/'/gr;} @lines;
    }

    use Text::ParseWords qw(quotewords);
    my @words = quotewords( '\s+', 1, @lines );
    parse_kv( \@words );
}

push( @EXPORT, 'parse_kvm' );

# Odd/even.

sub is_odd( $arg ) {
    ( $arg % 2 ) != 0;
}
sub is_even( $arg ) {
    ( $arg % 2 ) == 0;
}

push( @EXPORT, qw( is_odd is_even ) );

# Map true/false etc to true / false.

sub is_true ( $arg ) {
    return 0 if !defined($arg) || $arg eq '';
    return 0 if $arg =~ /^(false|null|no|none|off|\s+|0)$/i;
    return !!$arg;
}

push( @EXPORT, 'is_true' );

# Stricter form of true.
sub is_ttrue ( $arg ) {
    return 0 if !defined($arg);
    $arg =~ /^(on|true|1)$/i;
}

push( @EXPORT, 'is_ttrue' );

# Fix apos -> quote.

sub fq ( $arg ) {
    $arg =~ s/'/\x{2019}/g;
    $arg;
}

push( @EXPORT, 'fq' );

# Quote a string if needed unless forced.

sub qquote ( $arg, $force = 0 ) {
    for ( $arg ) {
	s/([\\\"])/\\$1/g;
	s/([[:^print:]])/sprintf("\\u%04x", ord($1))/ge;
	return $_ unless /[\\\s]/ || $force;
	return qq("$_");
    }
}

push( @EXPORT, 'qquote' );

# Safely print values.

use Scalar::Util qw(looks_like_number);

# We want overload:
# sub pv( $val )
# sub pv( $label, $val )

sub pv {
    my $val   = pop;
    my $label = pop // "";

    my $suppressundef;
    if ( $label =~ /\?$/ ) {
	$suppressundef++;
	$label = $';
    }
    if ( defined $val ) {
	if ( looks_like_number($val) ) {
	    $val = sprintf("%.3f", $val);
	    $val =~ s/0+$//;
	    $val =~ s/\.$//;
	}
	else {
	    $val = qquote( $val, 1 );
	}
    }
    else {
	return "" if $suppressundef;
	$val = "<undef>"
    }
    defined wantarray ? $label.$val : warn($label.$val."\n");
}

push( @EXPORT, 'pv' );

# Processing JSON.

sub json_load( $json, $source = "<builtin>" ) {
    my $info = json_parser();
    if ( $info->{parser} eq "JSON::Relaxed" ) {
	state $pp = JSON::Relaxed::Parser->new( croak_on_error => 0,
						strict => 0,
						prp => 1 );
	my $data = $pp->decode($json."\n");
	return $data unless $pp->is_error;
	$source .= ": " if $source;
	die("${source}JSON error: " . $pp->err_msg . "\n");
    }
    else {
	state $pp = JSON::PP->new;

	# Glue lines, so we have at lease some relaxation.
	$json =~ s/"\s*\\\n\s*"//g;

	$pp->relaxed if $info->{relaxed};
	$pp->decode($json."\n");
    }
}

# JSON parser, what and how (also used by runtimeinfo().
sub json_parser() {
    my $relax = $ENV{CHORDPRO_JSON_RELAXED} // 2;
    if ( $relax > 1 ) {
	require JSON::Relaxed;
	return { parser  => "JSON::Relaxed",
		 version => $JSON::Relaxed::VERSION }
    }
    else {
	require JSON::PP;
	return { parser  => "JSON::PP",
		 relaxed => $relax,
		 version => $JSON::PP::VERSION }
    }
}

push( @EXPORT, qw(json_parser json_load) );

# Like prp2cfg, but updates.
# Also allows array pre/append and JSON data.
# Useful error messages are signalled with exceptions.

push( @EXPORT, 'prpadd2cfg' );

sub prpadd2cfg ( $cfg, @defs ) {
    $cfg //= {};
    state $specials = { false => 0, true => 1, null => undef };

    while ( @defs ) {
	my $key   = shift(@defs);
	my $value = shift(@defs);
	# warn("K:$key V:$value\n");

	# Check and process the value, if needed.
	if ( exists $specials->{$value} ) {
	    $value = $specials->{$value};
	    # warn("Value => $value\n");
	}
	elsif ( !( ref($value)
		   || $value !~ /[\[\{\]\}]/ ) ) {
	    # Not simple, assume JSON struct.
	    $value = json_load( $value, $value );
	    # use DDP; p($value, as => "Value ->");
	}

	# Note that ':' is not oficially supported by RRJson.
	my @keys = split( /[:.]/, $key );
	my $lastkey = pop(@keys);

	# Handle pdf.fonts.xxx shortcuts.
	if ( join( ".", @keys ) eq "pdf.fonts" ) {
	    my $s = { pdf => { fonts => { $lastkey => $value } } };
	    ChordPro::Config::expand_font_shortcuts($s);
	    $value = $s->{pdf}{fonts}{$lastkey};
	}

	my $cur = \$cfg;		# current pointer in struct
	my $errkey = "";		# error trail
	if ( $keys[0] eq "chords" ) {
	    # Chords are not in the config, but elsewhere.
	    $cur = \ChordPro::Chords::config_chords();
	    $errkey = "chords.";
	    shift(@keys);
	}

	# Step through the keys.
	foreach ( @keys ) {
	    if ( is_arrayref($$cur) ) {
		my $ok;
		if ( /^[<>]?[-+]?\d+$/ ) {
		    $cur = \($$cur->[$_]);
		    $ok++;
		}
		elsif ( ! exists( $$cur->[0]->{name} ) ) {
		    die("Array ", substr($errkey,0,-1),
			" requires integer index (got \"$_\")\n");
		}
		else {
		    for my $i ( 0..@{$$cur} ) {
			if ( $$cur->[$i]->{name} eq $_ ) {
			    $cur = \($$cur->[$i]);
			    $ok++;
			    last;
			}
		    }
		}
		unless ( $ok ) {
		    die("Array ", substr($errkey,0,-1),
				" has no matching element with name \"$_\"\n");
		}
	    }
	    elsif ( is_hashref($$cur) ) {
		$cur = \($$cur->{$_});
	    }
	    else {
		die("Key ", substr($errkey,0,-1),
		    " ", ref($$cur),
		    " does not refer to an array or hash\n");
	    }
	    $errkey .= "$_."

	}

	# Final key.
	if ( is_arrayref($$cur) ) {
	    if ( $lastkey =~ />([-+]?\d+)?$/ ) {	# append
		if ( defined $1 ) {
		    splice( @{$$cur},
			    $1 >= 0 ? 1+$1 : 1+@{$$cur}+$1, 0, $value );
		}
		else {
		    push( @{$$cur}, $value );
		}
	    }
	    elsif ( $lastkey =~ /<([-+]?\d+)?$/ ) {	# prepend
		if ( defined $1 ) {
		    splice( @{$$cur}, $1, 0, $value );
		}
		else {
		    unshift( @{$$cur}, $value );
		}
	    }
	    elsif ( $lastkey =~ /\/([-+]?\d+)?$/ ) {	# remove
		if ( defined $1 ) {
		    splice( @{$$cur}, $1, 1 );
		}
		else {
		    pop( @{$$cur} );
		}
	    }
	    else {					# replace
		die("Array $errkey requires integer index (got \"$lastkey\")\n")
		  unless $lastkey =~ /^[-+]?\d+$/;
		$$cur->[$lastkey] = $value;
	    }
	}
	elsif ( is_hashref($$cur) ) {
	    if ( $errkey =~ /^chords\./ ) {
		# Chords must be defined.
		ChordPro::Chords::add_config_chord( { name => $lastkey,
						      %$value } );
	    }
	    else {
		$$cur->{$lastkey} = $value;
	    }
	}
	else {
	    die("Key ", substr($errkey,0,-1),
		" is scalar, not ",
		$lastkey =~ /^(?:[-+]?\d+|[<>])$/ ? "array" : "hash",
		"\n");
	}
    }

    # The structure has been modified, but also return for covenience.
    return $cfg;
}

push( @EXPORT, 'prpadd2cfg' );

# Remove markup.
sub demarkup ( $t ) {
    return join( '', grep { ! /^\</ } splitmarkup($t) );
}
push( @EXPORT, 'demarkup' );

# Split into markup/nonmarkup segments.
sub splitmarkup ( $t ) {
    my @t = split( qr;(</?(?:[-\w]+|span\s.*?)>);, $t );
    return @t;
}
push( @EXPORT, 'splitmarkup' );

# For conditional filling of hashes.
sub maybe ( $key, $value, @rest ) {
    if (defined $key and defined $value) {
	return ( $key, $value, @rest );
    }
    else {
	( defined($key) || @rest ) ? @rest : ();
    }
}
push( @EXPORT, "maybe" );

# Min/Max.
use List::Util ();
*min = \&List::Util::min;
*max = \&List::Util::max;

push( @EXPORT, "min", "max" );

# Plural
sub plural( $n, $tag, $plural=undef ) {
    $plural //= $tag . "s";
    ( $n || "no" ) . ( $n == 1 ? $tag : $plural );
}

push( @EXPORT, "plural" );

# Dimensions.
# Fontsize allows typical font units, and defaults to ref 12.
sub fontsize( $size, $ref=12 ) {
    if ( $size && $size =~ /^([.\d]+)(%|e[mx]|p[tx])$/ ) {
	return $ref/100 * $1 if $2 eq '%';
	return $ref     * $1 if $2 eq 'em';
	return $ref/2   * $1 if $2 eq 'ex';
	return $1            if $2 eq 'pt';
	return $1 * 0.75     if $2 eq 'px';
    }
    $size || $ref;
}

push( @EXPORT, "fontsize" );

# Dimension allows arbitrary units, and defaults to ref 12.
sub dimension( $size, %sz ) {
    return unless defined $size;
    my $ref;
    if ( ( $ref = $sz{fsize} )
	 && $size =~ /^([.\d]+)(%|e[mx])$/ ) {
	return $ref/100 * $1  if $2 eq '%';
	return $ref     * $1  if $2 eq 'em';
	return $ref/2   * $1  if $2 eq 'ex';
    }
    if ( ( $ref = $sz{width} )
	 && $size =~ /^([.\d]+)(%)$/ ) {
	return $ref/100 * $1  if $2 eq '%';
    }
    if ( $size =~ /^([.\d]+)(p[tx]|[cm]m|in|)$/ ) {
	return $1             if $2 eq 'pt';
	return $1 * 0.75      if $2 eq 'px';
	return $1 * 72 / 2.54 if $2 eq 'cm';
	return $1 * 72 / 25.4 if $2 eq 'mm';
	return $1 * 72        if $2 eq 'in';
	return $1             if $2 eq '';
    }
    $size;			# let someone else croak
}

push( @EXPORT, "dimension" );

# Checking font names against the PDF corefonts.

my %corefonts =
  (
   ( map { lc($_) => $_ }
     "Times-Roman",
     "Times-Bold",
     "Times-Italic",
     "Times-BoldItalic",
     "Helvetica",
     "Helvetica-Bold",
     "Helvetica-Oblique",
     "Helvetica-BoldOblique",
     "Courier",
     "Courier-Bold",
     "Courier-Oblique",
     "Courier-BoldOblique",
     "Symbol",
     "ZapfDingbats" ),
);

sub is_corefont {
    $corefonts{lc $_[0]};
}

push( @EXPORT, "is_corefont" );

# Progress reporting.

use Ref::Util qw(is_coderef);

# Progress can return a false result to allow caller to stop.

sub progress(%args) {
    state $callback;
    state $phase = "";
    state $index = 0;
    state $total = '';
    unless ( %args ) {		# reset
	undef $callback;
	$phase = "";
	$index = 0;
	return;
    }

    $callback = $args{callback} if exists $args{callback};
    return 1 unless $callback;

    if ( exists $args{phase} ) {
	$index = 0 if $phase ne $args{phase};
	$phase = $args{phase};
    }
    if ( exists $args{index} ) {
	$index = $args{index};

	# Use index<0 to only set callback/phase.
	$index = 0, $total = '', return if $index < 0;
    }
    if ( exists $args{total} ) {
	$total = $args{total};
    }

    my $args = { phase => $phase, index => $index, total => $total, %args };

    my $ret = ++$index;
    if ( is_coderef($callback) ) {
	$ret = eval { $callback->(%$args) };
	if ( $@ ) {
	    warn($@);
	    undef $callback;
	}
    }
    else {
	if ( $callback eq "warn" ) {
	    # Simple progress message. Suppress if $index = 0 or total = 1.
	    $callback =
	      '%{index=0||' .
	      '%{total=1||Progress[%{phase}]: %{index}%{total|/%{}}%{msg| - %{}}}' .
	      '}';
	}
	my $msg = ChordPro::Output::Common::fmt_subst
	  ( { meta => $args }, $callback );
	$msg =~ s/\n+$//;
	warn( $msg, "\n" ) if $msg;
    }

    return $ret;
}

push( @EXPORT, "progress" );

# Common items for property directives ({textsize} etc.).

sub propitems() {
    qw(  chord chorus diagrams footer grid label tab text title toc );
}

sub propitems_re() {
    my $re = join( '|', propitems() );
    qr/(?:$re)/;
}

push( @EXPORT, "propitems_re" );
push( @EXPORT_OK, "propitems" );

# For debugging encoding problems.

sub as( $s ) {
    return "<undef>" unless defined $s;
    $s =~ s{ ( [^\x{20}-\x{7f}] ) }
	   { join( '', map { sprintf '\x{%02x}', ord $_ } split //, $1) }gex;
    return $s;
}

push( @EXPORT_OK, "as" );

sub enumerated( @s ) {
    return "" unless @s;
    my $last = pop(@s);
    my $ret = "";
    $ret .= join(", ", @s) . " and " if @s;
    $ret .= $last;
    return $ret;
}

push( @EXPORT_OK, "enumerated" );

# Determine image type.

sub _detect_image_format( $test ) {

    for ( ref($test) ? $$test : $test ) {
	/^GIF\d\d[a-z]/            and return 'gif';
	/^\xFF\xD8\xFF/            and return 'jpeg';
	/^\x89PNG\x0D\x0A\x1A\x0A/ and return 'png';
	/^\s*P[1-6]/               and return 'pnm';
	/^II\x2A\x00/              and return 'tiff';
	/^MM\x00\x2A/              and return 'tiff';
	/^<svg\s/is                and return 'svg';
    }

    # Not recognized.
    return;
}

sub detect_image_format( $test ) {
    my $format = _detect_image_format($test);

    if ( $format ) {
	return { file_ext => $format, error => "" };
    }
    return { file_ext => "", error => "Unrecognized image type." };
}

push( @EXPORT_OK, "detect_image_format" );

# Transpose types

sub XP_DEFAULT() { 0 }
sub XP_FOLLOW()  { 0 }
sub XP_SHARP()   { 1 }
sub XP_FLAT()    { 2 }

$EXPORT_TAGS{"xp"} = [ qw( XP_DEFAULT XP_FOLLOW XP_SHARP XP_FLAT ) ];
push( @EXPORT_OK, @{ $EXPORT_TAGS{"xp"} } );

=cut

1;
