#! perl

use v5.26;
use Object::Pad;
use utf8;
use Carp;
use Storable;

class SVGPDF::Use :isa(SVGPDF::Element);

method process () {
    my $atts = $self->atts;
    my $xo   = $self->xo;
    return if $atts->{omit};	# for testing/debugging.

    my ( $x, $y, $hr, $tf ) =
      $self->get_params( $atts, qw( x:H y:V href:! transform:s ) );

    my $r = $self->root->defs->{$hr};
    unless ( $r ) {
	warn("SVG: Missing def for use \"$hr\" (skipped)\n");
	$self->css_pop;
	return;
    }

    # Update its xo.
    $r->xo = $self->xo;

    $self->_dbg( $self->name, " \"$hr\" (", $r->name, "), x=$x, y=$y" );

    $self->_dbg("+ xo save");
    $xo->save;
    if ( $x || $y ) {
	$self->_dbg( "translate( %.2f %.2f )", $x, $y );
	$xo->transform( translate => [ $x, $y ] );
    }
    $self->set_transform($tf) if $tf;
    $self->set_graphics;
    $r->process;
    $self->_dbg("- xo restore");
    $xo->restore;
    $self->css_pop;
}


1;
