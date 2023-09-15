#! perl

use v5.26;
use Object::Pad;
use utf8;
use Carp;

class SVGPDF::Rect :isa(SVGPDF::Element);

method process () {
    my $atts = $self->atts;
    my $xo   = $self->xo;
    return if $atts->{omit};	# for testing/debugging.

    my ( $x, $y, $w, $h, $rx, $ry, $tf ) =
      $self->get_params( $atts, qw( x:H y:V width:H height:V rx:U ry:U transform:s ) );

    $self->_dbg( $self->name, " x=$x y=$y w=$w h=$h" );
    $self->_dbg( "+ xo save" );
    $xo->save;

    $self->set_graphics;
    $self->set_transform($tf) if $tf;

    unless ( $rx || $ry ) {
	$xo->rectangle( $x, $y, $x+$w, $y+$h );
    }
    else {
	# https://svgwg.org/svg2-draft/shapes.html#RectElement
	# Resolve percentages.
	if ( $rx ) {
	    $rx = $1 * $w if $rx =~ /^([-+,\d]+)\%$/;
	}
	if ( $ry ) {
	    $ry = $1 * $h if $ry =~ /^([-+,\d]+)\%$/;
	}
	# Default one to the other.
	$rx ||= $ry; $ry ||= $rx;
	# Maximize to half of the width/height.
	if ( $rx > $w/2 ) {
	    $rx = $w/2;
	}
	if ( $ry > $h/2 ) {
	    $ry = $h/2;
	}
	$self->_dbg( $self->name, "(rounded) rx=$rx ry=$ry" );

	$xo->move( $x+$rx, $y );
	$xo->hline( $x + $w - $rx );
	$xo->arc( $x+$w-$rx, $y+$ry,    $rx, $ry, -90,   0 );
	$xo->vline( $y + $h - $ry );
	$xo->arc( $x+$w-$rx, $y+$h-$ry, $rx, $ry,   0,  90 );
	$xo->hline( $x + $rx );
	$xo->arc( $x+$rx, $y+$h-$ry,    $rx, $ry,  90, 180 );
	$xo->vline( $y + $ry );
	$xo->arc( $x+$rx, $y+$ry,       $rx, $ry, 180, 270 );
	$xo->close;
    }

    $self->_paintsub->();

    $self->_dbg( "- xo restore" );
    $xo->restore;
    $self->css_pop;
}

1;
