#! perl

use strict;
use warnings;
use Test::More;

my $pdfapi = "PDF::API2";
my $pdfapiv = "2.020";
eval { require PDF::Builder;
       # We need to explicitly check here, since 3.004 will bail out.
       PDF::Builder->VERSION("3.005");
       $pdfapiv = "3.005";
       $pdfapi = "PDF::Builder";
};

my $test;
++$test; ok( $] >= 5.010,
	     "Perl version $] is newer than 5.010." );
++$test; use_ok( "IO::String", 1.08  ); # for Font::TTF
++$test; use_ok( "Font::TTF",  1.04  ); # for PDF::API2
++$test; use_ok( $pdfapi,  $pdfapiv );
diag("Using $pdfapi for PDF generation");
++$test; use_ok( "JSON::PP",   2.237 );

done_testing($test);
