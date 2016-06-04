#! perl

use strict;
use Test::More;
use FindBin;

if ( -d "t" ) {
    chdir "t";
    $0 =~ s;(^|/)t/;$1;;
}
mkdir("out") unless -d "out";

use lib "../script";
require "differ.pl";

$::__EMBEDDED__ = 1;
require "chordpro.pl";

my $test;

my ( $num, $basic, $backend ) =
  $FindBin::Script =~ /^(\d\d)_(\w+)_(\w+)\.t$/;
my $base = "${num}_${backend}";

my @argv = ( "--noconfig", "--nouserconfig", "--nosysconfig", "$basic.cho" );

# Some basic tests.

my $out = "${base}_" . ++$test . ".$backend";

@ARGV = ( @argv, "--no-single-space", "--output=out/$out" );

main( app_setup( "testing", "0.00" ) );

ok( !differ( "out/$out", "ref/$out" ) );

# Single space.

$out = "${base}_" . ++$test . ".$backend";

@ARGV = ( @argv, "--single-space", "--output=out/$out" );

main( app_setup( "testing", "0.00" ) );

ok( !differ( "out/$out", "ref/$out" ) );

# Lyrics only.

$out = "${base}_" . ++$test . ".$backend";

@ARGV = ( @argv, "--lyrics-only", "--output=out/$out" );

main( app_setup( "testing", "0.00" ) );

ok( !differ( "out/$out", "ref/$out" ) );

done_testing($test);
