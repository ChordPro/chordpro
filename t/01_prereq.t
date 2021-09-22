#! perl

use strict;
use warnings;

use Test::More;

my $pdfapi = "PDF::API2";
my $pdfapiv = "2.035";

# PDF::API2 2.033 is ok, 2.035 is better, 2.036 is best.
for ( qw( xPango@1.227 PDF::API2@2.035 PDF::Builder@3.016 ) ) {
    ( $pdfapi, $pdfapiv ) = split( '@', $_ );
    eval "require $pdfapi" or next;
    eval '$pdfapiv = $pdfapi->VERSION($pdfapiv)' or next;
    last;
}

my $test;
++$test; ok( $] >= 5.010001,
	     "Perl version $] is newer than 5.010.001" );

if ( $pdfapi =~ /^pdf/i ) {
    ++$test; use_ok( "IO::String", 1.08  ); # for Font::TTF
    # Font::TTF 1.04 is ok, 1.05 is better, 1.06 is best.
    ++$test; use_ok( "Font::TTF",  1.05  ); # for PDF::API2
    ++$test; use_ok( $pdfapi,  $pdfapiv );
    diag("Using $pdfapi $pdfapiv and Font::TTF $Font::TTF::VERSION for PDF generation");
    ++$test; use_ok( "Text::Layout", 0.012 );
}
else {
    ++$test; use_ok( $pdfapi,  $pdfapiv );
    diag("Using $pdfapi $pdfapiv for PDF generation");
}
++$test; use_ok( "Text::Layout",   0.018 );
#diag("Using Text::Layout $Text::Layout::VERSION");
eval {
    require HarfBuzz::Shaper;
    HarfBuzz::Shaper->VERSION(0.018);
    diag( "Shaping enabled (HarfBuzz::Shaper $HarfBuzz::Shaper::VERSION)" );
    1;
} || diag( "Shaping disabled (HarfBuzz::Shaper not found)" );
++$test; use_ok( "JSON::PP",   2.27203 );
++$test; use_ok( "String::Interpolate::Named", 0.05 );
++$test; use_ok( "File::LoadLines", 0.02 );
++$test; use_ok( "Image::Info", 1.41 );

done_testing($test);
