#! perl

package App::Music::ChordPro::Output::PDFMarkup::StringDiagrams;

use App::Music::ChordPro::Chords;

sub new {
    my ( $pkg, %init ) = @_;
    bless { %init || () } => $pkg;
}

# The vertical space the diagram requires.
sub vsp {
    my ( $self, $elt, $ps ) = @_;
    $ps->{fonts}->{diagram}->{size} * 1.2
      + 0.40 * $ps->{diagrams}->{width}
	+ $ps->{diagrams}->{vcells} * $ps->{diagrams}->{height}
	  + $ps->{diagrams}->{vspace} * $ps->{diagrams}->{height};
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
    goto &App::Music::ChordPro::Output::PDFMarkup::PDF::font_bl;
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
    my $name = $info->{name};
    $name .= "*"
      unless $info->{origin} ne "user"
	|| $::config->{diagrams}->{show} eq "user";
    $pr->text( $name, $x + ($w - $pr->strwidth($name))/2, $y - font_bl($font) );
    $y -= $font->{size} * 1.2 + $dot/2 + $lw;

    if ( $info->{base} > 1 ) {
	# my $i = @Roman[$info->{base}] . "  ";
	my $i = sprintf("%d  ", $info->{base});
	$pr->setfont( $ps->{fonts}->{diagram_base}, $gh );
	$pr->text( $i, $x-$pr->strwidth($i), $y-0.85*$gh,
		   $ps->{fonts}->{diagram_base}, 1.2*$gh );
    }

    my $v = $ps->{diagrams}->{vcells};
    my $h = $strings;

    # Draw the grid.
    $pr->hline( $x, $y - $_*$gh, $w, $lw ) for 0..$v;
    $pr->vline( $x0 + $_*$gw, $y, $gh*$v, $lw ) for 0..$h-1;

    # Bar detection.
    my $bar;
    if ( $info->{fingers} ) {
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
			    6*$lw, "black" );
	    }
	}
    }

    # Process the strings and fingers.
    $x -= $gw/2;
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
	    my $glyph = "\x{6c}";
	    if ( $fing && $fing > 0 ) {
		# The dingbat glyphs are open, so we need a white
		# background circle.
		$pr->circle( $x+$gw/2, $y-$fret*$gh+$gh/2, $dot/2, 1,
			     "white", "black" );
		$glyph = pack( "C", 0xca + $fing - 1 );
	    }
	    my $dot = $dot/0.7;
	    $pr->setfont( $ps->{fonts}->{chordfingers}, $dot );
	    $pr->text( $glyph,
		       $x+$gw/2-$pr->strwidth($glyph)/2,
		       $y-$fret*$gh+$gh/2-$pr->strwidth($glyph)/2+$lw/2,
		       $ps->{fonts}->{chordfingers}, $dot ) ;
	}
	elsif ( $fret < 0 ) {
	    $pr->cross( $x+$gw/2, $y+$lw+$gh/3, $dot/3, $lw, "black");
	}
	elsif ( $info->{base} > 0 ) {
	    $pr->circle( $x+$gw/2, $y+$lw+$gh/3, $dot/3, $lw,
			 undef, "black");
	}
    }
    continue {
	$x += $gw;
    }

    return $gw * ( $ps->{diagrams}->{hspace} + $strings );
}

1;
