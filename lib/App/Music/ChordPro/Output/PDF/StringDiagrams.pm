#! perl

use strict;

package App::Music::ChordPro::Output::PDF::StringDiagrams;

use App::Music::ChordPro::Chords;

sub new {
    my ( $pkg, $ps ) = @_;

    my $ctl = $ps->{kbdiagrams};

    my $show = $ctl->{show};
    unless ( $show =~ /^(?:top|bottom|right|below)$/i ) {
	die("pdf.diagrams.show is \"$show\", must be one of ".
	    "\"top\", \"bottom\", \"right\", or \"below\"\n");
    }

    bless { ps => $ps } => $pkg;
}

# The vertical space the diagram requires.
sub vsp0 {
    my ( $self, $elt, $ps ) = @_;
    $ps->{fonts}->{diagram}->{size} * 1.2
      + 0.40 * $ps->{diagrams}->{width}
	+ $ps->{diagrams}->{vcells} * $ps->{diagrams}->{height};
}

# The advance height.
sub vsp1 {
    my ( $self, $elt, $ps ) = @_;
    $ps->{diagrams}->{vspace} * $ps->{diagrams}->{height};
}

# The vertical space the diagram requires, including advance height.
sub vsp {
    my ( $self, $elt, $ps ) = @_;
    $self->vsp0( $elt, $ps ) + $self->vsp1( $elt, $ps );
}

# The horizontal space the diagram requires.
sub hsp0 {
    my ( $self, $elt, $ps ) = @_;
    (App::Music::ChordPro::Chords::strings() - 1) * $ps->{diagrams}->{width};
}

# The advance width.
sub hsp1 {
    my ( $self, $elt, $ps ) = @_;
    $ps->{diagrams}->{hspace} * $ps->{diagrams}->{width};
}

# The horizontal space the diagram requires, including advance width.
sub hsp {
    my ( $self, $elt, $ps ) = @_;
    $self->hsp0( $elt, $ps ) + $self->hsp1( $elt, $ps );
}

my @Roman = qw( I II III IV V VI VI VII VIII IX X XI XII );

sub font_bl {
    goto &App::Music::ChordPro::Output::PDF::font_bl;
}

# The actual draw method.
sub draw {
    my ( $self, $info, $x, $y, $ps ) = @_;
    return unless $info;

    my $x0 = $x;

    my $gw = $ps->{diagrams}->{width};
    my $gh = $ps->{diagrams}->{height};
    my $dot = 0.80 * $gw;
    my $lw  = ($ps->{diagrams}->{linewidth} || 0.10) * $gw;
    my $pr = $ps->{pr};

    my $strings = App::Music::ChordPro::Chords::strings();
    my $w = $gw * ($strings - 1);

    # Draw font name.
    my $font = $ps->{fonts}->{diagram};
    $pr->setfont($font);
    my $name = App::Music::ChordPro::Output::PDF::chord_display($info);
    $name .= "*"
      unless $info->{origin} ne "user"
	|| $::config->{diagrams}->{show} eq "user";
    $pr->text( $name, $x + ($w - $pr->strwidth($name))/2, $y - font_bl($font) );
    $y -= $font->{size} * 1.2 + $dot/2 + $lw;
    if ( $info->{base} + $info->{baselabeloffset} > 1 ) {
	# my $i = @Roman[$info->{base}] . "  ";
	my $i = sprintf("%d  ", $info->{base} + $info->{baselabeloffset});
	$pr->setfont( $ps->{fonts}->{diagram_base}, $gh );
	$pr->text( $i, $x-$pr->strwidth($i),
		   $y-($info->{baselabeloffset}*$gh)-0.85*$gh,
		   $ps->{fonts}->{diagram_base}, 1.2*$gh );
    }

    my $v = $ps->{diagrams}->{vcells};
    my $h = $strings;

    # Draw the grid.
    my $xo = $self->grid_xo($ps);
    $pr->{pdfgfx}->formimage( $xo, $x, $y-$v*$gh, 1 );

    # The numbercolor property of the chordfingers is used for the
    # background of the underlying dot (the numbers are transparent).
    my $fcf = $ps->{fonts}->{chordfingers};
    my $fbg = $pr->_bgcolor($fcf->{numbercolor});
    # However, if none we should really use white.
    $fbg = "white" if $fbg eq "none";

    # Bar detection.
    my $bar;
    if ( $info->{fingers} && $fbg ne $ps->{theme}->{foreground} ) {
	my %h;
	my $str = 0;
	my $got = 0;
	foreach ( @{ $info->{fingers} } ) {
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
	    foreach (sort keys %$bar ) {
		my @bi = @{ $bar->{$_} };
		if ( $bi[-2] == $bi[-1] ) { # not a bar
		    delete $bar->{$_};
		    next;
		}
		# Print the bar line.
		$pr->hline( $x+$bi[2]*$gw, $y-$bi[1]*$gh+$gh/2,
			    ($bi[3]-$bi[2])*$gw,
			    6*$lw, $ps->{theme}->{foreground} );
	    }
	}
    }

    # Process the strings and fingers.
    $x -= $gw/2;
    my $oflo;			# to detect out of range frets

    for my $sx ( 0 .. @{ $info->{frets} }-1 ) {
	my $fret = $info->{frets}->[$sx];
	my $fing;
	$fing = $info->{fingers}->[$sx] if $info->{fingers};

	# For bars, only the first and last finger.
	if ( $fing && $bar && $bar->{$fing} ) {
	    next unless $sx == $bar->{$fing}->[2]
	      || $sx == $bar->{$fing}->[3];
	}

	if ( $fret > 0 ) {
	    if ( $fret > $v && !$oflo++ ) {
		warn("Diagram $info->{name}: ",
		     "Fret position $fret exceeds diagram size $v\n");
	    }
	    if ( $fing && $fing > 0 && $fbg ne $ps->{theme}->{foreground} ) {
		# The dingbat glyphs are open, so we need am explicit
		# background circle.
		$pr->circle( $x+$gw/2, $y-$fret*$gh+$gh/2, $dot/2, 1,
			     $fbg, $ps->{theme}->{foreground} );
		my $dot = $dot/0.7;
		my $glyph = pack( "C", 0xca + $fing - 1 );
		$pr->setfont( $fcf, $dot );
		$pr->text( $glyph,
			   $x+$gw/2-$pr->strwidth($glyph)/2,
			   $y-$fret*$gh+$gh/2-$pr->strwidth($glyph)/2+$lw/2,
			   $fcf, $dot );
	    }
	    else {
		$pr->circle( $x+$gw/2, $y-$fret*$gh+$gh/2, $dot/2, 1,
			     $ps->{theme}->{foreground}, $ps->{theme}->{foreground});
	    }
	}
	elsif ( $fret < 0 ) {
	    $pr->cross( $x+$gw/2, $y+$lw+$gh/3, $dot/3, $lw,
			$ps->{theme}->{foreground} );
	}
	elsif ( $info->{base} > 0 ) {
	    $pr->circle( $x+$gw/2, $y+$lw+$gh/3, $dot/3, $lw,
			 undef, $ps->{theme}->{foreground} );
	}
    }
    continue {
	$x += $gw;
    }

    return $gw * ( $ps->{diagrams}->{hspace} + $strings );
}

sub grid_xo {
    my ( $self, $ps ) = @_;

    my $gw = $ps->{diagrams}->{width};
    my $gh = $ps->{diagrams}->{height};
    my $lw  = ($ps->{diagrams}->{linewidth} || 0.10) * $gw;
    my $v = $ps->{diagrams}->{vcells};
    my $strings = App::Music::ChordPro::Chords::strings();

    return $self->{grids}->{$gw,$gh,$lw,$v,$strings} //= do
      {
	my $w = $gw * ($strings - 1);
	my $h = $strings;

	my $form = $ps->{pr}->{pdf}->xo_form;

	# Bounding box must take linewidth into account.
	my @bb = ( -$lw/2, -$lw/2, ($h-1)*$gw+$lw/2, $v*$gh+$lw/2 );
	$form->bbox(@bb);

	# Pseudo-object to access low level drawing routines.
	my $dc = bless { pdfgfx => $form } =>
	  App::Music::ChordPro::Output::PDF::Writer::;

	# Draw the grid.
	$dc->rectxy( @bb, 0, 'red' ) if 0;
	my $color = $ps->{theme}->{foreground};
	$dc->hline( 0, ($v-$_)*$gh, $w, $lw, $color ) for 0..$v;
	$dc->vline( $_*$gw, $v*$gh, $gh*$v, $lw, $color) for 0..$h-1;

	$form;
      };
}

1;
