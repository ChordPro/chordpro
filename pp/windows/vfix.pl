#!/usr/bin/perl

use strict;
use warnings;
use lib "../../lib";
use App::Music::ChordPro::Version;
my $vv = $App::Music::ChordPro::Version::VERSION;

my ( $maj, $min, $aux ) = $vv =~ /^(\d+)\.(\d+)(?:_(\d+))/;

@ARGV = qw( innosetup.iss ) unless @ARGV;

$^I = ".bak";

my $resetbuildnum = 0;

while ( <> ) {
    s/(^#\s+define\s+V_MAJ\s+)(\d+)/$1$maj/ and
    $2 != $maj and $resetbuildnum++;
    s/(^#\s+define\s+V_MIN\s+)(\d+)/$1$min/ and
    $2 != $min and $resetbuildnum++;
    if ( defined($aux) ) {
	s/(^#\s+define\s+V_AUX\s+)(\d+)/$1$aux/ and
	$2 != $aux and $resetbuildnum++;
    }
    s/(^\#\s+define\s+BuildNum\s+)(\d+).*
     /sprintf("%s%d", $1, $resetbuildnum ? 1 : 1+$2)
       /ex;
}
continue {
    print;
}

