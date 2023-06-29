#! perl

use strict;

package main;

our $config;

package ChordPro::Output::PDF::KeyboardDiagrams;

sub new {
    my ( $pkg, $ps ) = @_;

    my $ctl = $ps->{kbdiagrams};
    my $kw  = $ctl->{width};
    my $kh  = $ctl->{height};

    my $keys = $ctl->{keys};
    unless ( $keys =~ /^(?:7|10|14|17|21)$/ ) {
	die("pdf.kbdiagrams.keys is $keys, must be one of 7, 10, 14, 17, or 21\n");
    }

    my $base = $ctl->{base};
    unless ( $base =~ /^(?:C|F)$/i ) {
	die("pdf.kbdiagrams.base is \"$base\", must be \"C\" or \"F\"\n");
    }

    my $show = $ctl->{show};
    unless ( $show =~ /^(?:top|bottom|right|below)$/i ) {
	die("pdf.kbdiagrams.show is \"$show\", must be one of ".
	    "\"top\", \"bottom\", \"right\", or \"below\"\n");
    }

    bless {} => $pkg;
}

# The vertical space the diagram requires.
sub vsp0 {
    my ( $self, $elt, $ps ) = @_;
    my $ctl = $ps->{kbdiagrams};
    my $kw = $ctl->{width};
    my $kh = $ctl->{height};
    my $lw  = ($ctl->{linewidth} || 0.10) * $kw;
    $ps->{fonts}->{diagram}->{size} * 1.2 + $kh + $lw;
}

# The advance height.
sub vsp1 {
    my ( $self, $elt, $ps ) = @_;
    my $ctl = $ps->{kbdiagrams};
    $ctl->{vspace} * $ctl->{height};
}

# The vertical space the diagram requires, including advance height.
sub vsp {
    my ( $self, $elt, $ps ) = @_;
    $self->vsp0( $elt, $ps ) + $self->vsp1( $elt, $ps );
}

# The horizontal space the diagram requires.
sub hsp0 {
    my ( $self, $elt, $ps ) = @_;
    my $ctl = $ps->{kbdiagrams};
    my $kw = $ctl->{width};
    my $kh = $ctl->{height};
    my $lw  = ($ctl->{linewidth} || 0.10) * $kw;
    $lw + $ctl->{keys} * $kw;
}

# The advance width.
sub hsp1 {
    my ( $self, $elt, $ps ) = @_;
    my $ctl = $ps->{kbdiagrams};
    my $kw = $ctl->{width};
    $ctl->{hspace} * $kw;
}

# The horizontal space the diagram requires, including advance width.
sub hsp {
    my ( $self, $elt, $ps ) = @_;
    $self->hsp0( $elt, $ps ) + $self->hsp1( $elt, $ps );
}

sub font_bl {
    goto &ChordPro::Output::PDF::font_bl;
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
sub draw {
    my ( $self, $info, $x, $y, $ps ) = @_;
    return unless $info;
    my $x0 = $x;

    # Get (or infer) keys.
    my @keys = @{ChordPro::Chords::get_keys($info)};
    unless ( @keys ) {
	warn("PDF: No diagram for chord \"", $info->name, "\"\n");
    }

    my $ctl = $ps->{kbdiagrams};
    my $kw = $ctl->{width};
    my $kh = $ctl->{height};
    my $lw  = ($ctl->{linewidth} || 0.10) * $kw;
    my $keys = $ctl->{keys};
    my $col = $ctl->{pressed} // "red";
    my $pr = $ps->{pr};
    my $w = $lw + $kw * $keys;
    my $v = $kh;

    # Draw font name.
    my $font = $ps->{fonts}->{diagram};
    $pr->setfont($font);
    my $name = $info->chord_display;
    $name .= "?" unless @keys;
    # $name .= "*"
    #   unless $info->{origin} ne "user"
    #     || $ps->{kbdiagrams}->{show} eq "user";
    $pr->text( $name, $x + ($w - $pr->strwidth($name))/2, $y - font_bl($font) );
    $y -= $font->{size} * 1.2 + $lw;

    # Draw the grid.
    my $xo = $self->grid_xo( $ps, $lw );
    $pr->{pdfgfx}->formimage( $xo, $x, $y-$v, 1 );

    my $kk = ( $keys % 7 == 0 )
      ? 12 * int( $keys / 7 )
      : $keys == 10 ? 17 : 29;

    # Vertical offsets in the key image.
    my $t  = $y;
    my $m  = $y - $kh / 2;
    my $b  = $y - $kh;

    # Horizontal offsets in the key image.
    my $l  = $x;
    my $ml = $x + 1 * $kw / 3;
    my $mr = $x + 2 * $kw / 3;
    my $r  = $x + $kw; # 3 * $kw / 3;
    my $xr = $x + 4 * $kw / 3;

    # Don't use theme colour, use black & white.
    my $fgcol = "black"; # $ps->{theme}->{foreground};

    for my $key ( @keys ) {
	$key += $info->{root_ord};
	$key += 12 if $key < 0;
	$key -= 12 while $key >= $kk;
	# Get octave and reduce.
	my $o = int( $key / 12 ); # octave
	$key %= 12;

	# Get the key type.
	my ($pos,$type) = @{$keytypes{$key}};

	# Adjust for diagram start.
	$pos -= 3 if uc($ctl->{base}) ne 'C'; # must be 'F'

	# Reduce to single octave and scale.
	$pos += 7, $o-- while $pos < 0;
	$pos %= 7;
	$pos += 7 * $o if $o >= 1;

	# Actual displacement.
	my $pkw = $pos * $kw;

	# Draw the keys.
	if ( $type eq "L" ) {
	    $pr->poly( [ $pkw + $l,  $b,
			 $pkw + $l,  $t,
			 $pkw + $mr, $t,
			 $pkw + $mr, $m,
			 $pkw + $r,  $m,
			 $pkw + $r,  $b ],
		       $lw, $col, $fgcol );
	}
	elsif ( $type eq "R" ) {
	    $pr->poly( [ $pkw + $l,  $b,
			 $pkw + $l,  $m,
			 $pkw + $ml, $m,
			 $pkw + $ml, $t,
			 $pkw + $r,  $t,
			 $pkw + $r,  $b ],
		       $lw, $col, $fgcol );
	}
	elsif ( $type eq "M" ) {
	    $pr->poly( [ $pkw + $l,  $b,
			 $pkw + $l,  $m,
			 $pkw + $ml, $m,
			 $pkw + $ml, $t,
			 $pkw + $mr, $t,
			 $pkw + $mr, $m,
			 $pkw + $r,  $m,
			 $pkw + $r,  $b
		       ],
		       $lw, $col, $fgcol );
	}
	else {
	    $pr->rectxy( $pkw + $mr,  $m,
			 $pkw + $xr,  $t,
			 $lw, $col, $fgcol );
	}
    }

    return $w + $ctl->{hspace};
}

sub grid_xo {
    my ( $self, $ps, $lw ) = @_;
    my $ctl  = $ps->{kbdiagrams};
    my $kw   = $ctl->{width};
    my $kh   = $ctl->{height};
       $lw //= ($ctl->{linewidth} || 0.10) * $kw;
    my $keys = $ctl->{keys};
    my $base = uc($ctl->{base}) eq "F" ? 3 : 0;
    # Don't use theme colour, use black & white.
    my $fgcol = "black"; # $ps->{theme}->{foreground};

    return $self->{grids}->{$kw,$kh,$lw,$keys} //= do
      {
	my $w = $kw * $keys;	# total width, excl linewidth
	my $h = $kh;		# total height, excl linewidth

	my $form = $ps->{pr}->{pdf}->xo_form;

	# Bounding box must take linewidth into account.
	my @bb = ( -$lw/2, -$lw/2, $w+$lw/2, $h+$lw/2 );
	$form->bbox(@bb);

	# Pseudo-object to access low level drawing routines.
	my $dc = bless { pdfgfx => $form } =>
	  ChordPro::Output::PDF::Writer::;

	# Draw the grid.
	$dc->rectxy( @bb, 0, 'yellow' ) if 0;
	$dc->rectxy( @bb, 0, 'white' )
	  unless $ps->{theme}->{background} =~ /^white|none|#ffffff$/i;
	$dc->rectxy( 0, 0, $w, $kh, $lw, undef, $fgcol );
	$dc->vline( $_*$kw, $kh, $kh, $lw, $fgcol ) for 1..$keys-1;
	for my $i ( 1, 2, 4, 5, 6, 8, 9, 11, 12, 13, 15, 16, 18, 19, 20, 22, 23 ) {
	    next if $i < $base;
	    last if $i > $keys + $base;
	    my $x = ($i-$base-1)*$kw+2*$kw/3;
	    $dc->rectxy( $x, $kh/2, $x + 2*$kw/3, $kh,
			 $lw, $fgcol,
			 $fgcol );
	}

	$form;
      };
}

1;
