#! perl

use v5.26;
use Object::Pad;
use utf8;
use Carp;

class SVGPDF::G :isa(SVGPDF::Element);

method process () {
    my $atts = $self->atts;
    my $xo   = $self->xo;
    return if $atts->{omit};	# for testing/debugging.

    if ( defined $atts->{id} ) {
	$self->root->defs->{ "#" . $atts->{id} } = $self;
    }

    my ( $tf )  = $self->get_params( $atts, "transform:s" );

    $self->_dbg( $self->name, " ====" );

    $self->_dbg( "+ xo save" );
    $xo->save;

    $self->set_transform($tf);
    $self->traverse;

    $xo->restore;
    $self->_dbg( "- xo restore" );

    $self->css_pop;
}


1;
