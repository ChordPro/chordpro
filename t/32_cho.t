#! perl

use strict;
use Test::More tests => 1;

my $base = "32_cho";

if ( -d "t" ) {
    chdir "t";
    $0 =~ s;(^|/)t/;$1;;
}

use lib "../script";
require "differ.pl";

# Some basic tests.

@ARGV = qw( --noconfig --nouserconfig --nosysconfig );

my $out = "$base.cho";

push( @ARGV, "--lyrics-only" );
push( @ARGV, "30_cho.cho", "--output=out/$out" );

require "chordii.pl";

ok( !differ( "out/$out", "ref/$out" ) );
