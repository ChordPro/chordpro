#! perl

use strict;

package main;

our $config;

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
    $ps->{fonts}->{diagram}->{size} * $ps->{spacing}->{diagramchords}
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
    ($config->diagram_strings - 1) * $ps->{diagrams}->{width};
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

# my @Roman = qw( I II III IV V VI VI VII VIII IX X XI XII );

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
    my $bflw = 5*$lw;
    my $bfy = $bflw/3;
    my $pr = $ps->{pr};

    my $strings = $config->diagram_strings;
    my $w = $gw * ($strings - 1);

    # Draw font name.
    my $font = $ps->{fonts}->{diagram};
    $pr->setfont($font);
    my $name = $info->chord_display
      ( App::Music::ChordPro::Output::PDF::has_musicsyms($font) );
    # $name .= "*"
    #   unless $info->{origin} ne "user"
    #     || $::config->{diagrams}->{show} eq "user";
    $pr->text( $name, $x + ($w - $pr->strwidth($name))/2, $y - font_bl($font) );
    $y -= $font->{size} * $ps->{spacing}->{diagramchords} + $dot/2 + $lw;
    if ( $info->{base} + $info->{baselabeloffset} > 1 ) {
	# my $i = @Roman[$info->{base}] . "  ";
	my $i = sprintf("%d  ", $info->{base} + $info->{baselabeloffset});
	$pr->setfont( $ps->{fonts}->{diagram_base}, $gh );
	$pr->text( $i, $x-$pr->strwidth($i),
		   $y-$bfy - $bflw/2 - ($info->{baselabeloffset}*$gh)-0.85*$gh,
		   $ps->{fonts}->{diagram_base}, $ps->{spacing}->{diagramchords}*$gh );
	$pr->setfont($font);
    }

    my $v = $ps->{diagrams}->{vcells};
    my $h = $strings;

    my $basefretno = ($info->{base} + $info->{baselabeloffset});
    # Draw the grid.
    my $xo = $self->grid_xo($ps, $basefretno);

    my $crosshairs = sub {
	my ( $x, $y, $col ) = @_;
	for ( $pr->{pdfgfx}  ) {
	    $_->save;
	    $_->linewidth(0.1);
	    $_->strokecolor($col//"black");
	    $_->move($x-10,$y);
	    $_->hline($x+20);
	    $_->stroke;
	    $_->move($x,$y+10);
	    $_->vline($y-20);
	    $_->stroke;
	    $_->restore;
	}
    };

    $pr->{pdfgfx}->formimage( $xo, $x, $y-$bfy-$v*$gh, 1 );

    # The numbercolor property of the chordfingers is used for the
    # background of the underlying dot (the numbers are transparent).
    my $fcf = $ps->{fonts}->{chordfingers};
    my $fbg = $pr->_bgcolor($fcf->{numbercolor});
    # However, if none we should really use white.
    $fbg = "white" if $fbg eq "none";

    my $fingers;
    $fingers = $info->{fingers} if $ps->{diagrams}->{fingers};

    # Bar detection.
    my $bar;
    if ( $fingers && $fbg ne $ps->{theme}->{foreground} ) {
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
	    foreach (sort keys %$bar ) {
		my @bi = @{ $bar->{$_} };
		if ( $bi[-2] == $bi[-1] ) { # not a bar
		    delete $bar->{$_};
		    next;
		}
		# Print the bar line. Need linecap 0.
		$pr->hline( $x+$bi[2]*$gw, $y-$bfy -$bflw/2 -$bi[1]*$gh+$gh/2,
			    ($bi[3]-$bi[2])*$gw,
			    $dot, $ps->{theme}->{foreground}, 0 );
	    }
	}
    }

    # Process the strings and fingers.
    $x -= $gw/2;
    my $oflo;			# to detect out of range frets

    my $g_none = "/";		# unnumbered

    # All symbols from the chordfingers font are equal size: a circle
    # of 824 (1000-2*88) centered horizontally in the box, with a
    # decender of 55.
    # To get it vertically centered we must lower it by 455 (1000/2-55).
    $pr->setfont($fcf,$dot);
    my $g_width = $pr->strwidth("1");
    my $g_lower = -0.455*$g_width;
#    warn("GW dot=$dot, width=$g_width, lower=$g_lower\n");
#    my $e = $fcf->{fd}->{font}->extents("1",10);
#    use DDumper; DDumper($e);

    for my $sx ( 0 .. @{ $info->{frets} }-1 ) {
	my $fret = $info->{frets}->[$sx];
	my $fing = -1;
	$fing = $fingers->[$sx] // -1 if $fingers;

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

	    my $glyph;
	    if ( $fbg eq $ps->{theme}->{foreground} ) {
		$glyph = $g_none;
	    }
	    elsif ( $fing =~ /^[A-Z0-9]$/ ) {
		# Leave it to the user to interpret sensibly.
		$glyph = $fing;
	    }
	    elsif ( $fing =~ /-\d+$/ ) {
		$glyph = $g_none;
	    }
	    else {
		warn("Diagram $info->{name}: ",
		     "Invalid finger position $fing, ignored\n");
		$glyph = $g_none;
	    }

	    # The glyphs are open, so we need am explicit
	    # background circle to prevent the grid peeping through.
	    # OTOH, for the unnumbered dot, we need a foreground circle.
	    $pr->circle( $x+$gw/2, $y-$bfy-$bflw/2-$fret*$gh+$gh/2, $dot/2.2, 1,
			 $glyph eq $g_none ? $ps->{theme}->{foreground} : $fbg,
			 "none");

	    $pr->setfont( $fcf, $dot );
	    $pr->text( $glyph,
			$x,
			$y - $bfy - $bflw/2-$fret*$gh + $gh/2 + $g_lower,
			$fcf, $dot/0.8 );
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
    my ( $self, $ps, $basefretno ) = @_;

    my $gw = $ps->{diagrams}->{width};
    my $gh = $ps->{diagrams}->{height};
    my $lw  = ($ps->{diagrams}->{linewidth} || 0.10) * $gw;
    my $bflw = 5 * $lw;
    my $bfno = $basefretno;
    my $v = $ps->{diagrams}->{vcells};
    my $strings = $config->diagram_strings;

    return $self->{grids}->{$gw,$gh,$lw, $bflw, $bfno, $v,$strings} //= do
      {
	my $w = $gw * ($strings - 1);
	my $h = $strings;

	my $form = $ps->{pr}->{pdf}->xo_form;

	# Bounding box must take linewidth into account.
	my @bb = ( -$lw/2, -$lw/2 -$bflw, ($h-1)*$gw+$lw/2, $v*$gh+$lw/2 +$bflw );
	$form->bbox(@bb);

	# Pseudo-object to access low level drawing routines.
	my $dc = bless { pdfgfx => $form } =>
	  App::Music::ChordPro::Output::PDF::Writer::;

	# Draw the grid.
	$dc->rectxy( @bb, 0, 'red' ) if 0;
	my $color = $ps->{theme}->{foreground};
	for (0..$v) {
		if ($bfno<=1 && $_==0) {
		$dc->hline( 0, ($v-$_)*$gh, $w, $bflw, $color );
		}
		else {
		$dc->hline( 0, ($v-$_)*$gh-$bflw/2, $w, $lw, $color );
		}
	}
	
	$dc->vline( $_*$gw, $v*$gh-$bflw/2, $gh*$v, $lw, $color) for 0..$h-1;

	$form;
      };
}

1;
