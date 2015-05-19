#! perl

use strict;
use Test::More tests => 1;

my $base = "21_crd";

if ( -d "t" ) {
    chdir "t";
    $0 =~ s;(^|/)t/;$1;;
}

use lib "../script";
require "differ.pl";

# Some basic tests.

@ARGV = qw( --noconfig --nouserconfig --nosysconfig );

my $out = "$base.crd";

push( @ARGV, "20_crd.cho", "--output=out/$out" );
push( @ARGV, "--single-space" );

require "chordii.pl";

ok( !differ( "out/$out", "ref/$out" ) );
