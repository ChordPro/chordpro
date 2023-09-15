#! perl

use v5.26;
use Object::Pad;
use utf8;
use Carp;

class SVGPDF::Circle :isa(SVGPDF::Element);

method process () {
    my $atts = $self->atts;
    my $xo   = $self->xo;
    return if $atts->{omit};	# for testing/debugging.

    my ( $cx, $cy, $r, $tf ) =
      $self->get_params( $atts, qw( cx:H cy:V r:U transform:s ) );

    $self->_dbg( $self->name, " cx=$cx cy=$cy r=$r" );
    $self->_dbg( "+ xo save" );
    $xo->save;

    $self->set_graphics;
    $self->set_transform($tf) if $tf;
    $xo->circle( $cx, $cy, $r );
    $self->_paintsub->();

    $self->_dbg( "- xo restore" );
    $xo->restore;
    $self->css_pop;
}


1;
