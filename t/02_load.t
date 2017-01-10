#! perl

use strict;
use warnings;
use Test::More;

if ( -d "t" ) {
    chdir "t";
    $0 =~ s;(^|/)t/;$1;;
}

use lib "../script";

$::__EMBEDDED__ = 1;

my $test;

++$test; use_ok("App::Music::ChordPro::Wx::Main");

diag( "Testing App::Music::ChordPro::Wx $App::Music::ChordPro::VERSION, Perl $], $^X" );

done_testing($test);
