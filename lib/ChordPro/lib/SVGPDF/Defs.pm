#! perl

use v5.26;
use Object::Pad;
use utf8;
use Carp;

class SVGPDF::Defs :isa(SVGPDF::Element);

method process () {
    my $atts = $self->atts;
    my $xo   = $self->xo;
    return if $atts->{omit};	# for testing/debugging.

    $self->_dbg( "+", $self->name, " ====" );

    for ( $self->get_children ) {
	next if ref($_) eq 'SVGPDF::TextElement';
	my $id  = $_->atts->{id};
	unless ( defined($id) ) {
	    warn("SVG: Missing id for ", $_->name, " in defs (skipped)\n")
	      if $self->root->verbose && $_->name ne "style";
	    next;
	}
	$self->_dbg( "defs: \"$id\" (", $_->name, ")" );
	$self->root->defs->{ "#$id" } = $_;
    }

    $self->_dbg( "-" );
}


1;
