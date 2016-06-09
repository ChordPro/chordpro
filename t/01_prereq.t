#! perl

use strict;
use warnings;
use Test::More;

my $test;
++$test; ok( $] >= 5.010,
	     "Perl $] is too old, version 5.10 or later is required." );
++$test; use_ok( "IO::String", 1.08  ); # for Font::TTF
++$test; use_ok( "Font::TTF",  1.05  ); # for PDF::API2
++$test; use_ok( "PDF::API2",  2.021 );
++$test; use_ok( "JSON::PP",   2.237 );

done_testing($test);
