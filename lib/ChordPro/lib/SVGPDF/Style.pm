#! perl

use v5.26;
use Object::Pad;
use utf8;
use Carp;

class SVGPDF::Style :isa(SVGPDF::Element);

method process () {
    my $atts = $self->atts;
    my $xo   = $self->xo;
    return if $atts->{omit};	# for testing/debugging.

    $self->_dbg( "+", $self->name, " ====" );

    my $cdata = "";
    for my $t ( $self->get_children ) {
	croak("# ASSERT: non-text child in style")
	  unless ref($t) eq "SVGPDF::TextElement";
	$cdata .= $t->content;
    }
    if ( $cdata =~ /\S/ ) {
	$self->root->css->read_string($cdata);
    }

    # Ok?

    $self->_dbg( "-" );
}


1;
