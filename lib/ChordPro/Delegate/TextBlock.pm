#! perl

use v5.26;
use strict;
use warnings;
use feature qw( signatures );
no warnings "experimental::signatures";
use utf8;

package ChordPro::Delegate::TextBlock;

use ChordPro::Utils;

sub DEBUG() { $::config->{debug}->{txtblk} }

sub txt2xform( $s, $pw, $elt ) {

    my $ps = $s->{_ps};
    my $pr = $ps->{pr};

    my $font = $ps->{fonts}->{text};

    my $data = $elt->{data};
    my $height = 0;
    my $width = 0;
    my $x = 0;
    my $y = 0;
    my $flush = $elt->{opts}->{flush} // "left";
    # New xo, and put it in text mode.
    my $xo = $pr->{pdf}->xo_form;
    $xo->textstart;

    if ( $flush eq "right" ) {
	for ( @$data ) {
	    my $w = $pr->strwidth( $_, $font );
	    $width = $w if $w > $width;
	}
	for ( reverse @$data ) {
	    my ( $w, $h ) = $pr->strwidth( $_, $font );
	    $height += $h * $ps->{spacing}->{lyrics};
	    # We know that after a call to strwidth there is a tmplayout...
	    $pr->{tmplayout}->show( $x + $width-$w, $height, $xo );
	}
    }
    elsif ( $flush eq "center" ) {
	for ( @$data ) {
	    my $w = $pr->strwidth( $_, $font );
	    $width = $w if $w > $width;
	}
	for ( reverse @$data ) {
	    my ( $w, $h ) = $pr->strwidth( $_, $font );
	    $height += $h * $ps->{spacing}->{lyrics};
	    # We know that after a call to strwidth there is a tmplayout...
	    $pr->{tmplayout}->show( $x + ($width-$w)/2, $height, $xo );
	}
    }
    else {			# assume left
	for ( reverse @$data ) {
	    my ( $w, $h ) = $pr->strwidth( $_, $font );
	    $width = $w if $w > $width;
	    $height += $h * $ps->{spacing}->{lyrics};
	    # We know that after a call to strwidth there is a tmplayout...
	    $pr->{tmplayout}->show( $x, $height, $xo );
	}
    }

    # Finish.
    $xo->textend;
    $xo->bbox( 0, 0, $width, $height );

    return
      { type      => "image",
	subtype   => "xoform",
	line      => $elt->{line},
	data      => $xo,
	width     => $width,
	height    => $height,
	opts      => {
		      align => "left"
		     },
      };
}

# Pre-scan.
sub options( $data ) { {} }

1;
