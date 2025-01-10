#!/usr/bin/perl

use strict;
use warnings;
use lib "../../lib";
use ChordPro::Version;
my $vv = $ChordPro::Version::VERSION;

my ( $maj, $min, $mm, $aux ) = $vv =~ /^(\d+)\.(\d+)(?:\.(\d+))?(?:_(\d+))?/;

my $v0 = "$maj.0";

@ARGV = qw( Info.plist ) unless @ARGV;

$^I = ".bak";

my $resetbuildnum = 0;

my $todo = "";
while ( <> ) {
    if ( m;<key>CFBundleInfoDictionaryVersion</key>;i ) {
	$todo = $v0;
    }
    elsif ( m;<key>CFBundleShortVersionString</key>;i ) {
	$todo = $vv;
    }
    elsif ( m;<key>CFBundleVersion</key>;i ) {
	$todo = $vv;
    }
    elsif ( $todo ) {
	s;<string>.*?</string>;<string>$todo</string>;i;
	$todo = "";
    }
}
continue {
    print;
}
