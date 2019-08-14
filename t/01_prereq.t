#! perl

use strict;
use warnings;
use Test::More;

my $test;
++$test; ok( $] >= 5.010001,
	     "Perl version $] is newer than 5.010.001" );
++$test; use_ok( "Cairo", 1.106 );
++$test; use_ok( "Pango", 1.227  );
diag("Using Cairo/Pango for PDF generation");
++$test; use_ok( "JSON::PP",   2.237 );
++$test; use_ok( "String::Interpolate::Named", 0.05 );
++$test; use_ok( "File::LoadLines", 0.02 );
++$test; use_ok( "Image::Info", 1.41 );

done_testing($test);
