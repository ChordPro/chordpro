#! perl

package ChordPro::Output::PDF::Grid;

use strict;
use warnings;
use Carp;
use feature 'state';
use feature 'signatures';
no warnings 'experimental::signatures';
use ChordPro::Utils qw( is_ttrue );

sub gridline( $elt, $x, $y, $cellwidth, $barwidth, $margin, $ps, %opts ) {

    # Grid context.

    my $pr = $ps->{pr};
    my $fonts = $ps->{fonts};

    # Use the chords font for the chords, and for the symbols size.
    my $fchord = { %{ $fonts->{grid} || $fonts->{chord} } };
    my $schord = $fonts->{gridstrum};
    delete($fchord->{background});
    $y -= $pr->font_bl($fchord);

    pr_label_maybe( $ps, $x, $y );

    $x += $barwidth;
    $cellwidth += $barwidth;

    $elt->{tokens} //= [ {} ];

    my $firstbar;
    my $lastbar;
    foreach my $i ( 0 .. $#{ $elt->{tokens} } ) {
	next unless is_bar( $elt->{tokens}->[$i] );
	$lastbar = $i;
	$firstbar //= $i;
    }

    my $prevbar = -1;
    my @tokens = @{ $elt->{tokens} };
    my $t;

    if ( $margin->[0] ) {
	$x -= $barwidth;
	my $t = $elt->{margin};
	if ( $t && $t->{chords} ) {
	    if ( 0 && $::config->{settings}->{'chords-as-chords'} ) {
		my $x = $x;
		for ( 0..$#{ $t->{chords} } ) {
		    $x = $pr->text( $t->{chords}->[$_]->chord_display,
				    $x, $y, $fonts->{chord} )
		      unless $t->{chords}->[$_] eq "";
		    $x = $pr->text( $t->{phrases}->[$_],
				    $x, $y, $fonts->{grid_margin} )
		}
	    }
	    else {
		$t->{text} = "";
		for ( 0..$#{ $t->{chords} } ) {
		    $t->{text} .= $t->{chords}->[$_]->chord_display
		      unless $t->{chords}->[$_] eq "";
		    $t->{text} .= $t->{phrases}->[$_];
		}
		$pr->text( $t->{text}, $x, $y, $fonts->{grid_margin} );
	    }
	}
	elsif ( $t ) {
	    $pr->text( $t->{text}, $x, $y, $fonts->{grid_margin} );
	}
	$x += $margin->[0] * $cellwidth + $barwidth;
    }

    my $ctl = $pr->{ps}->{grids}->{cellbar};
    my $col = $pr->{ps}->{grids}->{symbols}->{color};
    $opts{subtype} //= $opts{type} eq "gridline" ? "cellbars" : "";
    my $needcell = ( $opts{type} eq "gridline"
		     || $opts{subtype} eq "cellbars" ) && $ctl->{width};

    state $prevvoltastart;
    my $align;
    if ( $prevvoltastart && @tokens
	 && $tokens[0]->{class} eq "bar" && $tokens[0]->{align} ) {
	$align = $prevvoltastart;
    }
    $prevvoltastart = 0;

    my $voltastart;
    foreach my $i ( 0 .. $#tokens ) {
	my $token = $tokens[$i];
	my $sz = $fchord->{size};

	if ( $token->{class} eq "bar" ) {
	    $x -= $barwidth;
	    if ( $voltastart ) {
		pr_voltafinish( $voltastart, $y, $x - $voltastart, $sz, $col, $pr );
		$voltastart = 0;
	    }

	    $t = $token->{symbol};
	    if ( 0 ) {
		$t = "{" if $t eq "|:";
		$t = "}" if $t eq ":|";
		$t = "}{" if $t eq ":|:";
	    }
	    else {
		$t = "|:" if $t eq "{";
		$t = ":|" if $t eq "}";
		$t = ":|:" if $t eq "}{";
	    }

	    my $lcr = -1;	# left, center, right
	    $lcr = 0 if $i > $firstbar;
	    $lcr = 1 if $i == $lastbar;

	    unless ( $opts{subtype} eq "cellbars" ) {
		$x += $barwidth;
		$prevbar = $i;
		$needcell = 0;
		next;
	    }

	    if ( $t eq "|" || $t eq ":|" ) {
		if ( $token->{volta} ) {
		    if ( $align ) {
			$x = $align;
			$lcr = 0;
		    }
		    $voltastart =
		    pr_rptvolta( $x, $y, $lcr, $sz, $col, $pr, $token );
		    $prevvoltastart ||= $x;
		}
		elsif ( $t eq ":|" ) {
		    pr_rptend( $x, $y, $lcr, $sz, $col, $pr );
		}
		else {
		    pr_barline( $x, $y, $lcr, $sz, $col, $pr );
		}
	    }
	    elsif ( $t eq "||" ) {
		pr_dbarline( $x, $y, $lcr, $sz, $col, $pr );
	    }
	    elsif ( $t eq "|:" ) {
		pr_rptstart( $x, $y, $lcr, $sz, $col, $pr );
	    }
	    elsif ( $t eq ":|:" ) {
		pr_rptendstart( $x, $y, $lcr, $sz, $col, $pr );
	    }
	    elsif ( $t eq "|." ) {
		pr_endline( $x, $y, $lcr, $sz, $col, $pr );
	    }
	    elsif ( $t eq " %" ) { # repeat2Bars
		pr_repeat( $x+$sz/2, $y, 0, $sz, $col, $pr );
	    }
	    elsif ( $t eq " %%" ) { # repeat2Bars
		pr_repeat2( $x+$sz/2, $y, 0, $sz, $col, $pr );
	    }
	    else {
		die($t);	# can't happen
	    }
	    $x += $barwidth;
	    $prevbar = $i;
	    $needcell = 0;
	    next;
	}

	if ( $token->{class} eq "repeat2" ) {
	    # For repeat2Bars, change the next bar line to pseudo-bar.
	    my $k = $prevbar + 1;
	    while ( $k <= $#tokens
		    && !is_bar($tokens[$k]) ) {
		$k++;
	    }
	    $tokens[$k] = { symbol => " %%", class => "bar" };
	    $x += $cellwidth;
	    $needcell = 0;
	    next;
	}

	pr_cellline( $x-$barwidth, $y, 0, $sz, $ctl->{width},
		     $pr->_fgcolor($ctl->{color}), $pr )
	  if $needcell;
	$needcell = ( $opts{type} eq "gridline"
		      || $opts{subtype} eq "cellbars" ) && $ctl->{width};

	if ( $token->{class} eq "chord" || $token->{class} eq "chords" ) {
	    my $tok = $token->{chords} // [ $token->{chord} ];
	    my $cellwidth = $cellwidth / @$tok;
	    for my $t ( @$tok ) {
		$x += $cellwidth, next if $t eq '';
		my $text = $t eq '/' ? $t : $t->chord_display;
		$pr->text( $text, $x, $y,
			   $t->info->is_gridstrum ? $schord : $fchord );
		$x += $cellwidth;
	    }
	}
	elsif ( exists $token->{chord} ) {
	    # I'm not sure why not testing for class = chord...
	    warn("Chord token without class\n")
	      unless $token->{class} eq "chord";
	    my $t = $token->{chord};
	    $t = $t->chord_display;
	    $pr->text( $t, $x, $y, $fchord )
	      unless $token eq ".";
	    $x += $cellwidth;
	}
	elsif ( $token->{class} eq "slash" ) {
	    $pr->text( "/", $x, $y, $fchord );
	    $x += $cellwidth;
	}
	elsif ( $token->{class} eq "space" ) {
	    $x += $cellwidth;
	}
	elsif ( $token->{class} eq "repeat1" ) {
	    $t = $token->{symbol};
	    my $k = $prevbar + 1;
	    while ( $k <= $#tokens
		    && !is_bar($tokens[$k]) ) {
		$k++;
	    }
	    pr_repeat( $x + ($k - $prevbar - 1)*$cellwidth/2, $y,
		       0, $fchord->{size}, $col, $pr );
	    $x += $cellwidth;
	}
	if ( $x > $ps->{papersize}->[0] ) {
	    # This should be signalled by the parser.
	    # warn("PDF: Too few cells for content\n");
	    last;
	}
    }

    if ( $margin->[1] && $elt->{comment} ) {
	my $t = $elt->{comment};
	if ( $t->{chords} ) {
	    $t->{text} = "";
	    for ( 0..$#{ $t->{chords} } ) {
		$t->{text} .= $t->{chords}->[$_]->chord_display . $t->{phrases}->[$_];
	    }
	}
	$pr->text( " " . $t->{text}, $x, $y, $fonts->{grid_margin} );
    }
}

sub is_bar( $elt ) {
    exists( $elt->{class} ) && $elt->{class} eq "bar";
}

# Location and size of vertical bars
sub yh( $y, $h, $pr ) {
    my $d = $pr->{ps}->{grids}->{stretch} || 0.825;
    return ( $y + 0.9 * $h,
	     $h * $d * $pr->{ps}->{spacing}->{grid} );
}

sub pr_cellline( $x, $y, $lcr, $sz, $w, $col, $pr ) {
    $x -= $w / 2;
    $pr->vline( $x, yh($y,$sz,$pr), $w, $col );
}

sub pr_barline( $x, $y, $lcr, $sz, $col, $pr ) {
    my $w = $sz / 10;		# glyph width = $w
    $x -= $w / 2;
    $x += $w if $lcr < 0;
    $pr->vline( $x, yh($y,$sz,$pr), $w, $col );
}

sub pr_dbarline( $x, $y, $lcr, $sz, $col, $pr ) {
    my $w = $sz / 10;		# glyph width = 3 * $w
    $x -= 0.5 + $w * ($lcr + 1);
#    $x -= $w * (( 0.5, 1.5, 2.5 )[1+$lcr]);
    $pr->vline( $x, yh($y,$sz,$pr), $w, $col );
    $x += 2 * $w;
    $pr->vline( $x, yh($y,$sz,$pr), $w, $col );
}

sub pr_rptstart( $x, $y, $lcr, $sz, $col, $pr ) {
    my $w = $sz / 10;		# glyph width = 3 * $w
    $x -= 0.5;
    $x += $w if $lcr < 0;
    $pr->vline( $x, yh($y,$sz,$pr), $w, $col );
    $x += 2 * $w;
    $y += 0.55 * $sz;
    $pr->line( $x, $y, $x, $y+$w, $w, $col );
    $y -= 0.4 * $sz;
    $pr->line( $x, $y, $x, $y+$w, $w, $col );
}

sub pr_rptvolta( $x, $y, $lcr, $sz, $symcol, $pr, $token ) {
    my $w = $sz / 10;		# glyph width = 3 * $w
    my $col = $pr->{ps}->{grids}->{volta}->{color};
    $x += $w if $lcr < 0;
    if ( $token->{symbol} eq ":|" ) {
	pr_rptend( $x, $y, $lcr, $sz, $col, $pr );
    }
    else {
	pr_barline( $x, $y, 0, $sz, $col, $pr );
    }
    my $ret = $x -= $w / 2;
    my $font = $pr->{ps}->{fonts}->{grid};
    $pr->setfont($font);
    $pr->text( "<span color='$col'><sup>" . $token->{volta} . "</sup></span>",
	       $x+$w, $y, $font );
    $ret;
}

sub pr_voltafinish( $x, $y, $width, $sz, $symcol, $pr ) {
    my $w = $sz / 10;		# glyph width = 3 * $w
    my ( $col, $span ) = @{$pr->{ps}->{grids}->{volta}}{qw(color span)};
    $pr->hline( $x, $y+0.9*$sz+$w/4, $width*$span, $w/2, $col  );
}

sub pr_rptend( $x, $y, $lcr, $sz, $col, $pr ) {
    my $w = $sz / 10;		# glyph width = 3 * $w
    $x -= 2.5 * $w if $lcr >= 0;
    $x += $w if $lcr < 0;
    $pr->vline( $x + 2*$w, yh($y,$sz,$pr), $w, $col );
    $y += 0.55 * $sz;
    $pr->line( $x, $y, $x, $y+$w, $w, $col );
    $y -= 0.4 * $sz;
    $pr->line( $x, $y, $x, $y+$w, $w, $col );
}

sub pr_rptendstart( $x, $y, $lcr, $sz, $col, $pr ) {
    my $w = $sz / 10;		# glyph width = 5 * $w
    $lcr = 0;			# center
    $x -= 2.5 * $w * ($lcr + 1);
    $x += $w if $lcr < 0;
    $pr->vline( $x + 2*$w, yh($y,$sz,$pr), $w, $col );
    $y += 0.55 * $sz;
    $pr->line( $x,      $y, $x     , $y+$w, $w, $col );
    $pr->line( $x+4*$w, $y, $x+4*$w, $y+$w, $w, $col );
    $y -= 0.4 * $sz;
    $pr->line( $x,      $y, $x,      $y+$w, $w, $col );
    $pr->line( $x+4*$w, $y, $x+4*$w, $y+$w, $w, $col );
}

sub pr_repeat( $x, $y, $lcr, $sz, $col, $pr ) {
    my $w = $sz / 3;		# glyph width = 3 * $w
    $x -= 1.5 * $w;
    my $lw = $sz / 10;
    $x -= $w / 2;
    $pr->line( $x, $y+0.2*$sz, $x + $w, $y+0.7*$sz, $lw );
    $pr->line( $x, $y+0.6*$sz, $x + 0.07*$sz , $y+0.7*$sz, $lw );
    $x += $w;
    $pr->line( $x - 0.05*$sz, $y+0.2*$sz, $x + 0.02*$sz, $y+0.3*$sz, $lw );
}

sub pr_repeat2( $x, $y, $lcr, $sz, $col, $pr ) {
    my $w = $sz / 4;		# glyph width = 4 * $w
    $x -= 2.7 * $w;
    my $lw = $sz / 10;
    $x -= $w / 2;
    $pr->line( $x, $y+0.2*$sz, $x + $w, $y+0.7*$sz, $lw );
    $pr->line( $x, $y+0.6*$sz, $x + 0.07*$sz , $y+0.7*$sz, $lw );
    $x += $w;
    $pr->line( $x - $w/4, $y+0.2*$sz, $x + 0.75*$w, $y+0.7*$sz, $lw );
    $x += 0.75 * $w;
    $pr->line( $x - 0.05*$sz, $y+0.2*$sz, $x + 0.02*$sz, $y+0.3*$sz, $lw );
}

sub pr_endline( $x, $y, $lcr, $sz, $col, $pr ) {
    my $w = $sz / 10;		# glyph width = 2 * $w
    $x -= 0.5 * $w * ($lcr + 1);
    $x += $w if $lcr < 0;
    $pr->vline( $x, yh($y,$sz,$pr), 2*$w );
}

################ Hooks ################

*pr_label_maybe = *ChordPro::Output::PDF::Song::pr_label_maybe;

1;
