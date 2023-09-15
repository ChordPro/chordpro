#! perl

use v5.26;
use Object::Pad;
use utf8;

class SVGPDF::FontManager;

use Carp;
use List::Util qw( any uniq );
use Text::ParseWords qw( quotewords );

field $svg	:mutator :param;
field $fc       :mutator;
field $td       :accessor;

# Set a font according to the style.
#
# Strategy: First see if there was a @font-face defined. If so, use it.
# Then dispatch to user callback, if specified.
# Otherwise, try builtin fonts.

method set_font ( $xo, $style ) {
    my ( $font, $size, $src ) = $self->find_font($style);
    $xo->font( $font, $size );
}

method find_font ( $style ) {

    my $stl    = lc( $style->{'font-style'}  // "normal" );
    my $weight = lc( $style->{'font-weight'} // "normal" );
    ####TODO: normalize styles and weights.

    # Process the font-families, if any.
    for ( ffsplit( $style->{'font-family'} // [] ) ) {
	my $family = lc($_);

	# Check against @font-faces, if any.
	for ( @{ $style->{'@font-face'}//[] } ) {
	    next unless $_->{'font-family'};
	    next unless $_->{src};
	    next if $_->{'font-style'} && $style->{'font-style'}
	      && $_->{'font-style'} ne $style->{'font-style'};
	    next if $_->{'font-weight'} && $style->{'font-weight'}
	      && $_->{'font-weight'} ne $style->{'font-weight'};

	    # Matching style and weight, check against families.
	    for my $fam ( ffsplit($_->{'font-family'}) ) {
		$fam = lc($fam);
		next unless $family eq $fam;

		# Yeah! We have a match!
		my $key = join( "|", $fam, $stl, $weight );
		# Font in cache?
		if ( my $f = $fc->{$key} ) {
		    return ( $f->{font},
			     $style->{'font-size'} || 12,
			     $f->{src} );
		}

		# Fetch font from source.
		my $src = $_->{src};
		####TODO: Multiple sources
		if ( $src =~ /^\s*url\s*\((["'])data:application\/octet-stream;base64,(.*?)\1\s*\)/is ) {

		    my $data = $2;

		    # To load font data from net and data urls.
		    use File::Temp qw( tempfile tempdir );
		    use MIME::Base64 qw( decode_base64 );
		    $td //= tempdir( CLEANUP => 1 );

		    my $sfx;	# suffix for font file name
		    if ( $src =~ /\bformat\((["'])(.*?)\1\)/ ) {
			$sfx =
			  lc($2) eq "truetype" ? ".ttf" :
			  lc($2) eq "opentype" ? ".otf" :
			  '';
		    }
		    # No (or unknown) format, skip.
		    next unless $sfx;

		    my ($fh,$fn) = tempfile( "${td}SVGXXXX", SUFFIX => $sfx );
		    binmode( $fh => ':raw' );
		    print $fh decode_base64($data);
		    close($fh);
		    my $font = eval { $svg->pdf->font($fn) };
		    croak($@) if $@;
		    my $f = $fc->{$key} =
		      { font => $font,
			src => 'data' };
		    return ( $f->{font},
			     $style->{'font-size'} || 12,
			     $f->{src} );
		}
		elsif ( $src =~ /^\s*url\s*\((["'])(.*?\.[ot]tf)\1\s*\)/is ) {
		    my $fn = $2;
		    my $font = eval { $svg->pdf->font($fn) };
		    croak($@) if $@;
		    my $f = $fc->{$key} =
		      { font => $font,
			src => $fn };
		    return ( $f->{font},
			     $style->{'font-size'} || 12,
			     $f->{src} );
		}
		else {
		    croak("\@font-face: Unhandled src \"", substr($src,0,50), "...\"");
		}
	    }
	}
    }

    my $key = join( "|", $style->{'font-family'}, $stl, $weight );
    # Font in cache?
    if ( my $f = $fc->{$key} ) {
	return ( $f->{font},
		 $style->{'font-size'} || 12,
		 $f->{src} );
    }

    if ( my $cb = $svg->fc ) {
	my $font;
	unless ( ref($cb) eq 'ARRAY' ) {
	    $cb = [ $cb ];
	}
	# Run callbacks.
	for ( @$cb ) {
	    eval { $font = $_->( $svg, $svg->pdf, $style ) };
	    croak($@) if $@;
	    last if $font;
	}

	if ( $font ) {
	    my $src = "Callback($key)";
	    $fc->{$key} = { font => $font, src => $src };
	    return ( $font,
		     $style->{'font-size'} || 12,
		     $src );
	}
    }

    # No @font-face, no (or failed) callbacks, we're on our own.

    my $fn = $style->{'font-family'} // "Times-Roman";
    my $sz = $style->{'font-size'} || 12;
    my $em = $style->{'font-style'}
      && $style->{'font-style'} =~ /^(italic|oblique)$/ || '';
    my $bd = $style->{'font-weight'}
      && $style->{'font-weight'} =~ /^(bold|black)$/ || '';

    for ( ffsplit($fn) ) {
	$fn = lc($_);

	if ( $fn =~ /^(sans|helvetica|(?:text,)?sans-serif)$/ ) {
	    $fn = $bd
	      ? $em ? "Helvetica-BoldOblique" : "Helvetica-Bold"
	      : $em ? "Helvetica-Oblique" : "Helvetica";
	}
	elsif ( $fn eq "text" || $fn =~ /^mono(?:-?space)?$/ ) {
	    $fn = $bd
	      ? $em ? "Courier-BoldOblique" : "Courier-Bold"
	      : $em ? "Courier-Oblique" : "Courier";
	}
	elsif ( $fn =~ /^abc2svg(?:\.ttf)?/ or $fn eq "music" ) {
	    $fn = "abc2svg.ttf";
	}
	elsif ( $fn =~ /^musejazz\s*text$/ ) {
	    $fn = "MuseJazzText.otf";
	}
	elsif ( $fn =~ /^(serif|times|(?:text,)?serif)$/ ) {
	    $fn = $bd
	      ? $em ? "Times-BoldItalic" : "Times-Bold"
	      : $em ? "Times-Italic" : "Times-Roman";
	}
	else {
	    undef $fn;
	}
	last if $fn;
	# Retry other families, if any.
    }

    unless ( $fn ) {
	# Nothing found...
	$fn = $bd
	  ? $em ? "Times-BoldItalic" : "Times-Bold"
	  : $em ? "Times-Italic" : "Times-Roman";
    }

    my $font = $fc->{$fn} //= do {
	unless ( $fn =~ /\.\w+$/ ) {
	    my $t = "";
	    $t .= "italic, " if $em;
	    $t .= "bold, "   if $bd;
	    $t = " (" . substr($t, 0, length($t)-2) . ")" if $t;
	    warn("SVG: Font ", $style->{'font-family'}//"<none>",
		 "$t - falling back to built-in font $fn with limited glyphs!\n")
	}
	{ font => $svg->pdf->font($fn), src => $fn };
    };
    return ( $font->{font}, $sz, $font->{src} );
}

sub ffsplit ( $family ) {
    # I hope this traps most (ab)uses of quotes and commas.
    $family =~ s/^\s+//;
    $family =~ s/\s+$//;
    map { s/,+$//r } uniq quotewords( qr/(\s+|\s*,\s*)/, 0, $family);
}


1;
