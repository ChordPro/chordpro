#! perl

use strict;
use warnings;
use Test::More;

my $test;
++$test; ok( $] >= 5.010,
	     "Perl $] is too old, version 5.10 or later is required." );
++$test; use_ok( "App::Music::ChordPro", 0.71  );
++$test; use_ok( "Wx",   0.9912 );

done_testing($test);
