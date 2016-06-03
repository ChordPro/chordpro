#! perl

use strict;
use warnings;
use Test::More;

my $test;
++$test; use_ok( "Font::TTF",  1.05  );
++$test; use_ok( "PDF::API2",  2.021 );
++$test; use_ok( "Clone",      0.38  );
++$test; use_ok( "IO::String", 1.08  );
++$test; use_ok( "JSON::PP",   2.237 );

done_testing($test);
