#! perl

use v5.26;
use Object::Pad;
use utf8;

my $dcache;			# cache core grids
my $pdf = "";			# for cache flush

class ChordPro::Output::PDF::KeyboardDiagram;

field $ps	:param;

field $config;
field $pr;

field $kw;
field $kh;
field $lw;
field $fg;
field $keys;
field $base;
field $base_k;
field $show;
field $pressed;

ADJUST {
    $config	  = $::config;
    $pr		  = $ps->{pr};
    my $ctl	  = $ps->{kbdiagrams};
    $kw		  = $ctl->{width} || 6;
    $kh		  = $ctl->{height} || 6;
    $lw		  = ($ctl->{linewidth} || 0.10) * $kw;
    $keys	  = $ctl->{keys};
    $base	  = $ctl->{base};
    $show	  = $ctl->{show};
    $pressed	  = $ctl->{pressed};
    $dcache = {} if $pr->{pdf} ne $pdf;
    $pdf          = $pr->{pdf};

    unless ( $keys =~ /^(?:7|10|14|17|21)$/ ) {
	die("pdf.kbdiagrams.keys is $keys, must be one of 7, 10, 14, 17, or 21\n");
    }

    unless ( $base =~ /^(?:C|F)$/i ) {
	die("pdf.kbdiagrams.base is \"$base\", must be \"C\" or \"F\"\n");
    }
    if ( uc($base) eq 'C' ) {
	$base = $base_k = 0;
    }
    else {			# must be 'F'
	$base_k = 3;
	$base = 5;
    }

    unless ( $show =~ /^(?:top|bottom|right|below)$/i ) {
	die("pdf.kbdiagrams.show is \"$show\", must be one of ".
	    "\"top\", \"bottom\", \"right\", or \"below\"\n");
    }
}

use constant DIAG_DEBUG => 0;

# The vertical space the diagram requires.
method vsp0 ( $elt, $dummy = 0 ) {
    $ps->{fonts}->{diagram}->{size} * 1.2 + $kh + $lw;
}

# The advance height.
method vsp1 ( $elt, $dummy = 0 ) {
    $ps->{kbdiagrams}->{vspace} * $kh;
}

# The vertical space the diagram requires, including advance height.
method vsp ( $elt, $dummy = 0 ) {
    $self->vsp0($elt) + $self->vsp1($elt);
}

# The horizontal space the diagram requires.
method hsp0 ( $elt, $dummy = 0 ) {
    $lw + $keys * $kw;
}

# The advance width.
method hsp1 ( $elt, $dummy = 0 ) {
    $ps->{kbdiagrams}->{hspace} * $kw;
}

# The horizontal space the diagram requires, including advance width.
method hsp ( $elt, $dummy = 0 ) {
    $self->hsp0($elt) + $self->hsp1($ps);
}

sub font_bl ($font) {
    &ChordPro::Output::PDF::font_bl($font);
}

my %keytypes =
  (  0 => [0,"L"],		# Left
     1 => [0,"B"],		# Black
     2 => [1,"M"],		# Middle
     3 => [1,"B"],
     4 => [2,"R"],		# Right
     5 => [3,"L"],
     6 => [3,"B"],
     7 => [4,"M"],
     8 => [4,"B"],
     9 => [5,"M"],
    10 => [5,"B"],
    11 => [6,"R"] );


# The actual draw method.
method draw ( $info, $x, $y, $dummy = 0 ) {
    return unless $info;
    my $w = $lw + $kw * $keys;
    $fg = $info->{diagram} // $ps->{theme}->{foreground};

    # Get (or infer) keys.
    my @keys = @{ChordPro::Chords::get_keys($info)};
    unless ( @keys ) {
	warn("PDF: No diagram for chord \"", $info->name, "\"\n");
    }

    my $font = $ps->{fonts}->{diagram};

    my $xo = $self->diagram_xo($info);
    my @bb = $xo->bbox;
    warn("BB [ @bb ] $x $y\n") if DIAG_DEBUG;
    $pr->{pdfgfx}->object( $xo, $x,
			   $y - ($font->{size} * 1.2 + $lw) );

    # Draw font name.
    $pr->setfont($font);
    my $name = $info->chord_display;
    $name .= "?" unless @keys;
    $name = "<span color='$fg'>$name</span>"
      if $info->{diagram};
    $pr->text( $name, $x + ($w - $pr->strwidth($name))/2, $y - font_bl($font) );
}

# Returns the complete diagram as an xo. This includes the core grid
# and pressed keys.
# Bounding box origin is top left of the grid.
# Note that the chord name is not part of the diagram.

method diagram_xo ($info) {
    return unless $info;

    my $col = $pressed // "red";
    $fg = $info->{diagram} // $fg // $ps->{theme}->{foreground};
    my $w = $lw + $kw * $keys;
    my $v = $kh;

    # Get (or infer) keys.
    my @keys = @{ChordPro::Chords::get_keys($info)};
    unless ( @keys ) {
	warn("PDF: No diagram for chord \"", $info->name, "\"\n");
    }

    my $xo = $pdf->xo_form;

    # Draw the core grid.
    $xo->line_width($lw);
    my $xg = $self->grid_xo;
    $xo->bbox( $xg->bbox );
    $xo->object( $xg, 0, 0, 1 );

    my $kk = ( $keys % 7 == 0 )
      ? 12 * int( $keys / 7 )
      : $keys == 10 ? 17 : 29;

    # Vertical offsets in the key image.
    my $t  = 0;
    my $m  = $t - $kh / 2;
    my $b  = $t - $kh;

    # Horizontal offsets in the key image.
    my $l  = 0;
    my $ml = $l + 1 * $kw / 3;
    my $mr = $l + 2 * $kw / 3;
    my $r  = $l + $kw; # 3 * $kw / 3;
    my $xr = $l + 4 * $kw / 3;

    # Don't use theme colour, use black & white.
    $xo->stroke_color($fg);
    $xo->fill_color($col);

    # Shift down if would start in 2nd octave.
    my $kd = -int(($keys[0] + $info->{root_ord}) / 12) * 12;
    # Adjust for diagram start.
    $kd+=12 if ($keys[0] + $info->{root_ord}) < $base;

    for my $key ( @keys ) {
	$key += $kd + $info->{root_ord};
	$key += 12 if $key < 0;
	$key -= 12 while $key >= $kk;
	# Get octave and reduce.
	my $o = int( $key / 12 ); # octave
	$key %= 12;

	# Get the key type.
	my ($pos,$type) = @{$keytypes{$key}};

	# Adjust for diagram start.
	$pos -= $base_k;

	# Reduce to single octave and scale.
	$pos += 7, $o-- while $pos < 0;
	$pos %= 7;
	$pos += 7 * $o if $o >= 1;

	# Actual displacement.
	my $pkw = $pos * $kw;

	# Draw the keys.
	if ( $type eq "L" ) {
	    $xo->move( $pkw + $l,  $b );
	    $xo->polyline( $pkw + $l,  $t,
			   $pkw + $mr, $t,
			   $pkw + $mr, $m,
			   $pkw + $r,  $m,
			   $pkw + $r,  $b )->close->fillstroke;
	}
	elsif ( $type eq "R" ) {
	    $xo->move( $pkw + $l,  $b );
	    $xo->polyline( $pkw + $l,  $m,
			   $pkw + $ml, $m,
			   $pkw + $ml, $t,
			   $pkw + $r,  $t,
			   $pkw + $r,  $b )->close->fillstroke;
	}
	elsif ( $type eq "M" ) {
	    $xo->move( $pkw + $l,  $b );
	    $xo->polyline( $pkw + $l,  $m,
			   $pkw + $ml, $m,
			   $pkw + $ml, $t,
			   $pkw + $mr, $t,
			   $pkw + $mr, $m,
			   $pkw + $r,  $m,
			   $pkw + $r,  $b )->close->fillstroke;
	}
	else {
	    $xo->rectangle( $pkw + $mr,  $m,
			    $pkw + $xr,  $t )->fillstroke;
	}
    }
#    $xo->fillstroke;
    $xo;
}

use constant DIAG_GRID_XO => 0;

method grid_xo {

    return $dcache->{$kw,$kh,$fg,$lw,$keys} //= do {

	my $w = $kw * $keys;	# total width, excl linewidth
	my $h = $kh;		# total height, excl linewidth

	my $xo = $pdf->xo_form;

	# Bounding box must take linewidth into account.
	# Origin is top left, so y runs negative.
	my $xp = DIAG_GRID_XO ? 2 : 0;
	my @bb = ( -$lw/2 - $xp, $lw/2 + $xp,
		   $w + $lw/2 + $xp, -($h + $lw/2) - $xp );
	$xo->bbox(@bb);
	$xo->line_width($lw);

	if ( DIAG_GRID_XO ) {
	    # Draw the grid.
	    $xo->fill_color('yellow');
	    $xo->rectangle(@bb)->fill;
	}

	$xo->stroke_color($fg);
	$xo->fill_color($fg);

	$xo->rectangle( 0, 0, $w, -$h );
	for ( 1 .. $keys-1 ) {
	    $xo->move( $_*$kw, 0 );
	    $xo->vline(-$h);
	}
	$xo->stroke;
	for my $i (  1,  2,  4,  5,  6,  8,  9, 11,
		    12, 13, 15, 16, 18, 19, 20, 22, 23 ) {
	    next if $i < $base_k;
	    last if $i > $keys + $base_k;
	    my $x = ($i-$base_k-1)*$kw+2*$kw/3;
	    $xo->rectangle( $x, -$kh/2, $x + 2*$kw/3, 0 )->fillstroke;
	}

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
