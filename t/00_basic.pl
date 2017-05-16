#! perl

use strict;
use Test::More;

require "./differ.pl";

mkdir("out") unless -d "out";

use App::Music::ChordPro;

my $test;

my ( $num, $basic, $backend ) = @::params;
my $base = "${num}_${backend}";

my @argv = ( "--no-default-configs", "$basic.cho" );

# Some basic tests.

my $out = "${base}_" . ++$test . ".$backend";

@ARGV = ( @argv, "--no-single-space", "--output=out/$out" );

::run();

ok( !differ( "out/$out", "ref/$out" ) );

# Single space.

$out = "${base}_" . ++$test . ".$backend";

@ARGV = ( @argv, "--single-space", "--output=out/$out" );

::run();

ok( !differ( "out/$out", "ref/$out" ) );

# Lyrics only.

$out = "${base}_" . ++$test . ".$backend";

@ARGV = ( @argv, "--lyrics-only", "--output=out/$out" );

::run();

ok( !differ( "out/$out", "ref/$out" ) );

done_testing($test);
