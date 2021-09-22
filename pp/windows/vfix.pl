#!/usr/bin/perl

use strict;
use warnings;
use lib "../../lib";
use App::Music::ChordPro::Version;
my $vv = $App::Music::ChordPro::Version::VERSION;

my ( $maj, $min, $aux ) = $vv =~ /^(\d+)\.(\d+)(?:_(\d+))?/;

@ARGV = qw( innosetup.iss ) unless @ARGV;

$^I = ".bak";

if ( $ARGV[0] =~ /\.iss$/ ) {

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
}

elsif ( $ARGV[0] =~ /\.rc$/ ) {

    my $resetbuildnum = 0;

    while ( <> ) {
	if ( /^((?:PRODUCT|FILE)VERSION\s+)(\d+),(\d+),(\d+),(\d+)/ ) {
	    $2 != $maj and $resetbuildnum++;
	    $3 != $min and $resetbuildnum++;
	    if ( defined($aux) ) {
		$4 != $aux and $resetbuildnum++;
	    }
	    $_ = sprintf("%s%d,%d,%d,%d\n",
			 $1, $maj, $min, $aux//0, $resetbuildnum ? 1 : 1+$5);
	    next;
	}
	if ( /^(\s*VALUE\s+"(?:Product|File)Version",\s+)/ ) {
	    $_ = "$1 \"$vv\"\n";
	    next;
	}
    }
    continue {
	print;
    }
}


