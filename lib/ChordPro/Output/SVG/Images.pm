#! perl

use v5.26;
use utf8;
use Carp;
use Object::Pad;

class ChordPro::Output::SVG::Images;

method alert :common ( $size ) {

    my $scale  = $size / 20;
    my $width  = $size;
    my $height = int(18 * $scale);

    return <<ESVG;
<?xml version="1.0" encoding="utf-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="$width" height="$height" viewBox="0 0 $width $height">
  <g stroke="red" fill="none" stroke-width="2" transform="scale($scale,$scale)">
    <polygon points="1 17 19 17 10 1" stroke-linejoin="round"/>
    <rect x="9" y="13" width="2" height="2" stroke="none" fill="red"/>
    <polygon points="9 12 8.5 7 11.5 7 11 12" stroke="none" fill="red"/>
  </g>
</svg>
ESVG

}

################ Export ################

# For convenience.

use Exporter 'import';
our @EXPORT;

sub SVG() { __PACKAGE__ }

push( @EXPORT, 'SVG' );

1;
