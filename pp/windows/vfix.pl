#!/usr/bin/perl

use strict;
use warnings;
use lib "../../lib";
use ChordPro::Version;
my $vv = $ChordPro::Version::VERSION;

my ( $maj, $min, $aux ) = $vv =~ /^(\d+)\.(\d+)(?:[._](\d+))?/;

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
	   /ex && warn($_);
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
	    warn($_);
	    next;
	}
	if ( /^(\s*VALUE\s+"FileVersion",\s+)/ ) {
	    $_ = "$1\"$vv\"\n";
	    warn($_);
	    next;
	}
	if ( /^(\s*VALUE\s+"ProductVersion",\s+)/ ) {
	    $_ = "$1\"" . $vv =~ s/_.*//r . "\"\n";
	    next;
	}
	if ( /^(\s*VALUE\s+"Comments",\s+)/ ) {
	    $_ = $1;
	    if ( $vv =~ /_/ ) {
		$_ .= q{"Development version, use at your own risk"};
	    }
	    else {
		$_ .= q{"https://chordpro.org"};
	    }
	    $_ .= "\n";
	    next;
	}
	if ( /^(\s*VALUE\s+"LegalCopyright",\s+)/ ) {
	    $_ = $1;
	    my @tm = localtime(time);
	    $_ .= q{"Copyright 2010,};
	    $_ .= 1900+$tm[5];
	    $_ .= q{ The ChordPro Team"};
	    $_ .= "\n";
	    next;
	}
    }
    continue {
	print;
    }
}


