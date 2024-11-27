#! perl

use v5.26;
use Object::Pad;
use utf8;
use Carp;

class SVGPDF::CSS;

field $css    :accessor;
field $errstr :accessor;
field $base   :mutator;
field $ctx    :accessor;
field @stack;
field $ffam   :accessor;

BUILD {
    $css = {};
    $base =
	{ 'font-family'		    => 'serif',
	  'font-size'		    => '10',
	  'color'		    => 'black',
	  'background-color'	    => 'none',
	  'fill'		    => 'currentColor',
	  'stroke'		    => 'none',
	  'line-width'		    => 1,
	};
    $ctx = {};
    $ffam = [];
    $self->push( @_ ) if @_;
}

# Parse a string with one or more styles. Augments.
method read_string ( $string ) {

    state $ffi = "face000";	# for unique font-face ids

    $css->{'*'} //= $base;

    # Flatten whitespace and remove /* comment */ style comments.
    $string =~ s/\s+/ /g;
    $string =~ s!/\*.*?\*\/!!g;

    # Hide semicolon in url(data:application/octet-stream;base64,...)
    $string =~ s/(url\(['"]data:.*?\/.*?);(.*?),/$1\x{ff1b}$2,/g;

    # Split into styles.
    foreach ( grep { /\S/ } split /(?<=\})/, $string ) {
	unless ( /^\s*([^{]+?)\s*\{(.*)\}\s*$/ ) {
	    $errstr = "Invalid or unexpected style data '$_'";
	    return;
	}

	# Split in such a way as to support grouped styles.
	my $style      = $1;
	my $properties = $2;
	$style =~ s/\s{2,}/ /g;
	my @styles =
	  grep { s/\s+/ /g; 1; }
	    grep { /\S/ }
	      split( /\s*,\s*/, $style );
	foreach ( @styles ) {
	    # Give @font-face rules an unique id.
	    if ( $_ eq '@font-face' ) {
		$_ = '@font-'.$ffi;
		$ffi++;
	    }
	    $css->{$_} //= {};
	}

	# Split into properties.
	foreach ( grep { /\S/ } split /\;/, $properties ) {
	    unless ( /^\s*(\*?[\w._-]+)\s*:\s*(.*?)\s*$/ ) {
		$errstr = "Invalid or unexpected property '$_' in style '$style'";
		return;
	    }

	    my $s = lc($1);
	    my %s = ( $s => $2 );

	    # Split font shorthand.
	    if ( $s eq "font" ) {
		use Text::ParseWords qw(shellwords);
		my @spec = shellwords($s{$s});

		foreach my $spec ( @spec ) {
		    $spec =~ s/;$//;
		    if ( $spec =~ /^([.\d]+)px/ ) {
			$s{'font-size'} = $1;
		    }
		    elsif ( $spec eq "bold" ) {
			$s{'font-weight'} = "bold";
		    }
		    elsif ( $spec eq "italic" ) {
			$s{'font-style'} = "italic";
		    }
		    elsif ( $spec eq "bolditalic" ) {
			$s{'font-weight'} = "bold";
			$s{'font-style'} = "italic";
		    }
		    elsif ( $spec =~ /^(?:text,)?serif$/i ) {
			$s{'font-family'} = "serif";
		    }
		    elsif ( $spec =~ /^(?:text,)?sans(?:-serif)?$/i ) {
			$s{'font-family'} = "sans";
		    }

		    # These are for ABC SVG processing.
		    elsif ( $spec =~ /^abc2svg(?:\.ttf)?$/i ) {
			$s{'font-family'} = "abc2svg";
		    }
		    elsif ( lc($spec) =~ /^musejazz\s*text$/i ) {
			$s{'font-family'} = "musejazztext";
		    }
		    else {
			$s{'font-family'} = $spec;
		    }
		}

		# Remove the shorthand if we found something.
		delete($s{$s}) if keys(%s) > 1;
	    }

	    # Split outline shorthand.
	    elsif ( $s eq "outline" ) {
		use Text::ParseWords qw(shellwords);
		my @spec = shellwords($s{$s});

		foreach my $spec ( @spec ) {
		    $spec =~ s/;$//;
		    if ( $spec =~ /^([.\d]+)px/ ) {
			$s{'outline-width'} = $1;
		    }
		    elsif ( $spec =~ /^(dotted|dashed|solid|double|groove|ridge|inset|outset)$/i ) {
			$s{'outline-style'} = $1;
		    }
		    else {
			$s{'outline-color'} = $spec;
		    }
		}

		# Remove the shorthand if we found something.
		delete($s{$s}) if keys(%s) > 1;
	    }

	    foreach my $k ( keys %s ) {
		foreach ( @styles ) {
		    $css->{$_}->{$k} = $s{$k};
		}
	    }
	}
    }

    my @keys = keys( %$css );
    for my $k ( @keys ) {
	if ( $k =~ /^\@font-face/ ) {
	    # Unhide semicolons.
	    s/\x{ff1b}/;/g for values( %{$css->{$k}} );
	    push( @$ffam, $css->{$k} );
	    delete $css->{$k};
	}
    }
    for my $k ( @keys ) {
	next unless $k =~ /^(\S+)\s+(\S+)$/;
	$css->{$1}->{" $2"} //= {};
	$self->merge( $css->{$1}->{" $2"}, $css->{$k} );
	delete ( $css->{$k} );
    }

    1;
}

# Merge hashes (and only hashes), recursive.
method merge ( $left, $right ) {
    return unless defined $right;
    if ( ref($left) eq 'HASH' && ref($right) eq 'HASH' ) {
	for ( keys %$right ) {
	    if ( exists $left->{$_}
		 && ref($left->{$_}) eq 'HASH'
		 && ref($right->{$_}) eq 'HASH' ) {
		$self->merge( $left->{$_}, $right->{$_} );
	    }
	    else {
		$left->{$_} = $right->{$_};
	    }
	}
	return;
    }
    croak("Cannot merge " . ref($left) . " and " . ref($right));
}

method find ( $arg ) {
    $css->{'*'} //= $base;
    my $ret = { %{$css->{'*'}} };
    if ( exists( $css->{_} ) ) {
	$self->merge( $ret, $css->{_} );
    }
    $ctx = $ret;
    $ret->{$arg};
}

method push ( @args ) {
    my $args = ref($args[0]) eq 'HASH' ? $args[0] : { @args };
    $css->{'*'} //= $base;
    my $ret;

    # CSS defaults.
    while ( my($k,$v) = each %{$css->{'*'}} ) {
	$ret->{$k} //= $v;
    }

    ## Parent.
    if ( exists( $css->{_} ) ) {
	$self->merge( $ret, $css->{_} );
    }

    ## Presentation attributes.
    for ( keys %$args ) {
	next if /^(element|class|style|id)$/;
	$ret->{$_} = $args->{$_};
    }

    ## Tag style.
    if ( $args->{element} && exists( $css->{$args->{element}} ) ) {
	$self->merge( $ret, $css->{$args->{element}} );
    }
    if ( $args->{element} && exists( $css->{_}->{" ".$args->{element}} ) ) {
	$self->merge( $ret, $css->{_}->{" ".$args->{element}} );
    }

    ## Class style.
    if ( $args->{class} ) {
	for ( split( ' ', $args->{class} ), "svg" ) {
	    $self->merge( $ret, $css->{".$_"} )
	      if exists( $css->{".$_"} );
	    $self->merge( $ret, $css->{$args->{element}.".$_"} )
	      if $args->{element} && exists( $css->{$args->{element}.".$_"} );
	}
    }

    ## ID (generic).
    if ( $args->{id} && exists( $css->{ "#" . $args->{id} } ) ) {
	$self->merge( $ret, $css->{ "#" . $args->{id} } );
    }

    ## ID (specific).
    if ( $args->{id} && exists( $css->{ $args->{element} . "#" . $args->{id} } ) ) {
	$self->merge( $ret, $css->{ $args->{element} . "#" . $args->{id} } );
    }

    ## Style attribute.
    if ( $args->{style} ) {
	$self->read_string( "__ {" . $args->{style} . "}" )
	  or croak($errstr);
	$self->merge( $ret, delete $css->{__} );
    }

    $ret->{'@font-face'} = $ffam if $ffam;
    push( @stack, { %{$css->{_}//{}} } );
    $self->merge( $css, { _ => $ret } );
    $ctx = $ret;
}

method pop () {
    Carp::croak("CSS stack underflow") unless @stack;
    $ctx = $css->{_} = pop(@stack);
}

method level () {
    0+@stack;
}

1;
