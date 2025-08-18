#! perl

use strict;
use warnings;

use Test::More;

if ( -d "t" ) {
    chdir "t";
    $0 =~ s;(^|/)t/;$1;;
}

use lib "../script";

my $test;

++$test; use_ok("ChordPro");
++$test; use_ok("ChordPro::Config");
++$test; use_ok("ChordPro::Files");
++$test; use_ok("ChordPro::Utils");
++$test; use_ok("ChordPro::Testing");
++$test; use_ok("ChordPro::Songbook");
++$test; use_ok("ChordPro::Output::Debug");
++$test; use_ok("ChordPro::Output::Text");
++$test; use_ok("ChordPro::Output::ChordPro");
++$test; use_ok("ChordPro::Output::HTML");
++$test; use_ok("ChordPro::Output::PDF");

diag( "Testing ChordPro $ChordPro::VERSION, Perl $], $^X" );

my $rt = ::runtimeinfo();
for ( split( /\n/, $rt ) ) {
    diag($_);
}

done_testing($test);
