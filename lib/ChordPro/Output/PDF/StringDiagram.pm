#! perl

use v5.26;
use Object::Pad;
use utf8;

my $dcache;			# cache core grids
my $pdf = "";			# for cache flush

class ChordPro::Output::PDF::StringDiagram;

field $ps	:param;

field $config;
field $pr;

field $gw;			# width of a cell, pt
field $gh;			# height of a cell, pt
field $lw;			# fraction of cell width
field $nutwidth;		# width (in linewidth) of the top nut
field $nw;			# extra width for the top nut, pt
field $vc;			# cells, vertical
field $strings;			# number of strings
field $hc;			# cells, horizontal (= strings)
field $dot;			# dot size, fraction of cell width
field $bsz;			# barre size, fraction of dot
field $fsh;			# show fingers (0, 1, "below")
field $fg;			# foreground color

ADJUST {
    $config	  = $::config;
    $strings	  = $config->diagram_strings;
    $pr		  = $ps->{pr};
    my $ctl	  = $ps->{diagrams};
    $gw		  = $ctl->{width} || 6;
    $gh		  = $ctl->{height} || 6;
    $lw		  = ($ctl->{linewidth} || 0.10) * $gw;
    $nutwidth     = $ctl->{nutwidth} || 1;
    $nw		  = ($nutwidth-1) * $lw;
    $vc		  = $ctl->{vcells} || 4;
    $hc		  = $strings;
    $dot	  = $ctl->{dotsize} * ( $gh < $gw ? $gh : $gw );
    $bsz	  = $ctl->{barwidth} * $dot;
    $fsh	  = $ctl->{fingers} || 0;
    $dcache = {} if $pr->{pdf} ne $pdf;
    $pdf          = $pr->{pdf};
}

use constant DIAG_DEBUG => 0;

# The vertical space the diagram requires.
method vsp0( $elt, $dummy = 0 ) {
    $ps->{fonts}->{diagram}->{size} * $ps->{spacing}->{diagramchords}
      + $nutwidth * $lw + 0.40 * $gw
      + $vc * $gh
      + ( $fsh eq "below" ? $ps->{fonts}->{diagram}->{size} : 0 )
      ;
}

# The advance height.
method vsp1( $elt, $dummy = 0 ) {
    $ps->{diagrams}->{vspace} * $gh;
}

# The vertical space the diagram requires, including advance height.
method vsp( $elt, $dummy = 0 ) {
    $self->vsp0($elt) + $self->vsp1($elt);
}

# The horizontal space the diagram requires.
method hsp0( $elt, $dummy = 0 ) {
    ($strings - 1) * $gw;
}

# The advance width.
method hsp1( $elt, $dummy = 0 ) {
    $ps->{diagrams}->{hspace} * $gw;
}

# The horizontal space the diagram requires, including advance width.
method hsp( $elt, $dummy = 0 ) {
    $self->hsp0($elt) + $self->hsp1($elt);
}

sub font_bl ($font) {
    ChordPro::Output::PDF::font_bl($font);
}

# The actual draw method.
method draw( $info, $x, $y, $dummy=0 ) {
    return unless $info;

    my $font = $ps->{fonts}->{diagram};

    my $xo = $self->diagram_xo($info);
    my @bb = $xo->bbox;
    warn("BB [ @bb ] $x $y\n") if DIAG_DEBUG;
    $pr->{pdfgfx}->object( $xo, $x,

			   $y - ($font->{size} * $ps->{spacing}->{diagramchords} + $dot/2 + $lw) );

    # Draw name.
    my $w = $gw * ($strings - 1);
    $pr->setfont($font);
    my $name = $info->chord_display;
    $name = "<span color='$fg'>$name</span>"
      if $info->{diagram};
    $pr->text( $name, $x + ($w - $pr->strwidth($name))/2, $y-font_bl($font) );
}

# Returns the complete diagram as an xo. This includes the core grid,
# finger/fret positions, open and muted string indicators.
# The bounding box includes space form the open and muted string indicators
# and dots on the first and last strings, even when absent.
# The bbox includes basefret and fingers (below) if present.
# Origin is top left of the grid.
# Note that the chord name is not part of the diagram.

method diagram_xo( $info ) {
    return unless $info;
    $fg = $info->{diagram} // $config->{pdf}->{theme}->{foreground};

    my $x = 0;
    my $w = $gw * ($strings - 1);
    my $baselabeloffset = $info->{baselabeloffset} || 0;
    my $basefretno = $info->{base} + $baselabeloffset;
    my $basefont;		# for base label
    my $basesize;		# for base label

    # Get the core grid.
    my $xg = $self->grid_xo;
    my @xgbb = $xg->bbox;

    my $xo = $pdf->xo_form;
    my @bb = ( 0,
	       0.77 * $dot + 2*$lw,
	       $w + $dot/2,
	       $xgbb[3] );

    if ( $basefretno > 1 ) {
	$basefont = $ps->{fonts}->{diagram_base}->{fd}->{font};
	$basesize = $gh/0.85;
	$basefretno = sprintf( "%2d", $basefretno );
	$bb[0] -= $basefont->width("xx$basefretno") * $basesize;
    }
    else {
	$basefretno = "";
	$bb[0] -= $dot/2;
    }
    if ( $fsh eq "below" && $info->{fingers} ) {
	$bb[3] -= $gh + $lw;
    }
    $xo->bbox(@bb);
    $xo->line_width($lw);
    $xo->stroke_color($fg);
    $xo->fill_color($fg);

    if ( DIAG_DEBUG ) {
	# Draw the grid.
	$xo->save;
	$xo->fill_color('yellow');
	$xo->rectangle($xo->bbox)->fill;
	$xo->object( $xg, 0, 0, 1 );
	$xo->fill_color('red');
	my $lw = $lw/2;
	$xo->rectangle( -$lw, -$lw, $lw, $lw )->fill;
	$xo->restore;
    }
    else {
	$xo->object( $xg, 0, 0, 1 );
    }

    # Draw extended nut if base = 1.
    if ( $info->{base} <= 1 ) {
	if ( $nutwidth > 1 ) {
	    for ( 0 .. $nutwidth-2 ) {
		$xo->move( -$lw/2, -$_*$lw );
		$xo->hline( $w + $lw/2 );
	    }
	    $xo->stroke;
	}
    }

    # Draw first fret number, if > 1.
    if ( $basefretno ) {
	$xo->textstart;
	$xo->font( $basefont, $basesize );
	$xo->translate( -$basefont->width("x") * 0.85 * $basesize,
			-$nw - ($baselabeloffset+0.85)*$gh );
	$xo->text( $basefretno, align => "right" );
	$xo->textend;
    }

    my $fingers;
    $fingers = $info->{fingers} if $fsh;

    # Bar detection.
    my $bar = {};
    if ( $fingers ) {
	my %h;
	my $str = 0;
	my $got = 0;
	foreach ( @{ $fingers } ) {
	    $str++, next unless $info->{frets}->[$str] > 0;
	    if ( $bar->{$_} ) {
		# Same finger on multiple strings -> bar.
		$got++;
		$bar->{$_}->[-1] = $str;
	    }
	    else {
		# Register.
		$bar->{$_} = [ $_, $info->{frets}->[$str], $str, $str ];
	    }
	    $str++;
	}
	if ( $got ) {
	    $xo->save;
	    $xo->line_width($bsz)->line_cap(0);
	    foreach ( sort keys %$bar ) {
		my @bi = @{ $bar->{$_} };
		if ( $bi[-2] == $bi[-1] ) { # not a bar
		    delete $bar->{$_};
		    next;
		}
		# Print the bar line.
		$x = $bi[2]*$gw;
		$xo->move( $x, -$nw -$bi[1]*$gh+$gh/2 );
		$xo->hline( $x+($bi[3]-$bi[2])*$gw);
	    }
	    $xo->stroke->restore;
	}
    }

    my $oflo;			# to detect out of range frets

    # Color of the dots and numbers.
    my $fbg = "";		# numbers
    my $ffg = "";		# dots
    unless ( $fsh eq "below" ) {
	# The numbercolor property of the chordfingers is used for the
	# color of the dot numbers.
	my $fcf = $ps->{fonts}->{chordfingers};
	$fbg = $pr->_bgcolor($fcf->{numbercolor});
	$ffg = $pr->_bgcolor($fcf->{color});
	# However, if none we should really use white.
	$fbg = "white" if $fbg eq "none";
    }

    $x = -$gw;
    for my $sx ( 0 .. $strings-1 ) {
	$x += $gw;
	my $fret = $info->{frets}->[$sx];
	my $fing = -1;
	$fing = $fingers->[$sx] // -1 if $fingers;

	# For bars, only the first and last finger.
	if ( $fing && $bar->{$fing} ) {
	    next unless $sx == $bar->{$fing}->[2] || $sx == $bar->{$fing}->[3];
	}

	if ( $fret > 0 ) {
	    if ( $fret > $vc && !$oflo++ ) {
		warn("Diagram $info->{name}: ",
		     "Fret position $fret exceeds diagram size $vc\n");
		next;
	    }
	    $xo->fill_color($ffg);
	    $xo->circle( $x, -$nw - ($fret-0.5)*$gh, $dot/2 )->fill;

	}
	elsif ( $fret < 0 ) {
	    $xo->move( $x - $dot/3, 0.77 * $dot + $lw );
	    $xo->line( $x + $dot/3, 0.1 * $gh + $lw );
	    $xo->move( $x + $dot/3, 0.77 * $dot  + $lw );
	    $xo->line( $x - $dot/3, 0.1 * $gh + $lw );
	    $xo->stroke;
	}
	elsif ( $info->{base} > 0 ) {
	    $xo->circle( $x, 3.5*$gh/10 + $lw, $dot/3 )->stroke;
	}
    }

    # Show the fingers, if any.
    if ( $fingers && @$fingers ) {
	my $font = $ps->{fonts}->{diagram}->{fd}->{font};
	my $size = $dot;
	my $asc;		# space if "below"

	$x = -$gw;
	my $did = 0;
	for my $sx ( 0 .. $strings-1 ) {
	    last if $fbg eq $fg;
	    $x += $gw;
	    my $fret = $info->{frets}->[$sx];
	    next unless $fret > 0;
	    my $fing = $fingers->[$sx];
	    next unless $fing > 0;

	    # For barre, only the first and last finger.
	    if ( $bar->{$fing} && $fsh ne "below" ) {
		next unless ( $sx == $bar->{$fing}->[2]
			      || $sx == $bar->{$fing}->[3] );
	    }

	    unless ( $did++ ) {
		if ( $fsh eq "below" ) {
		    $size *= 1.4;
		}
		else {
		    $xo->fill_color($fbg);
		}
		$xo->textstart;
		$xo->font( $font, $size );
		$asc = $font->ascender/1000 * $size;
	    }
	    if ( $fsh eq "below" ) {
		$xo->translate( $x, -$nw - $lw - ($vc+1)*$gh  );
	    }
	    else {
		$xo->translate( $x, -$nw - ($fret-0.5)*$gh - $dot/3 );
	    }
	    $xo->text( $fing, align => "center" );
	}
	$xo->textend if $did;
    }

    return $xo;
}

# The core grid. Just the horizontal and vertical lines, with a fitting
# bounding box. Origin is (half linewidth from) top left.
# Grid objects are cached globally.

use constant DIAG_GRID_XO => 0;

method grid_xo {

    return $dcache->{$gw,$gh,$lw,$nw,$fg,$vc,$hc} //= do {

	my $w = $gw * ($hc - 1);
	my $h = $gh * $vc;

	my $xo = $pdf->xo_form;

	# Bounding box must take linewidth into account.
	# Origin is top left, so y runs negative.
	my $xp = DIAG_GRID_XO ? 2 : 0;
	my @bb = ( -$lw/2 - $xp,  $lw/2 + $xp,
		   $w + $lw/2 + $xp, -($vc * $gh + $nw) - $lw/2 - $xp );
	$xo->bbox(@bb);
	$xo->line_width($lw);

	if ( DIAG_GRID_XO ) {
	    # Draw the grid.
	    $xo->fill_color('yellow');
	    $xo->rectangle(@bb)->fill;

	    # Draw additional nuts.
	    if ( 0&& $nutwidth > 1 ) {
		for ( 0 .. $nutwidth-2 ) {
		    $xo->stroke_color( $_ % 2 ? "#c0c0c0" : "#e0e0e0" );
		    $xo->move( -$lw/2, -$_*$lw );
		    $xo->hline( $w + $lw/2 )->stroke;
		}
	    }
	}

	$xo->stroke_color($fg);
	for ( 0 .. $vc ) {
	    $xo->move( -$lw/2, -$_*$gh - $nw);
	    $xo->hline( $w + $lw/2 );
	}
	for ( 0 .. $hc-1 ) {
	    $xo->move( $_*$gw, $lw/2 );
	    $xo->vline( -($gh*$vc + $nw + $lw/2 ) );
	}
	$xo->stroke;

	if ( DIAG_GRID_XO ) {
	    # Show origin.
	    $xo->fill_color('red');
	    my $lw = $lw/2;
	    $xo->rectangle( -$lw, -$lw, $lw, $lw )->fill;
	}

	$xo;
    };
}

1;
