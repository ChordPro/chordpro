#! perl

use v5.26;
use Object::Pad;
use utf8;
use Carp;

class SVGPDF::Polygon :isa(SVGPDF::Polyline);

method process () {
    $self->process_polyline(1);
}

1;
