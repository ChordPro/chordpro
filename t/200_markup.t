#!/usr/bin/perl

# https://github.com/ChordPro/chordpro/issues/111

use strict;
use warnings;
use utf8;
use Test::More tests => 2;

use App::Music::ChordPro::Output::PDF;

*defrag = \&App::Music::ChordPro::Output::PDF::defrag;

my $res;

$res = defrag( [ "<i>Comin’ for to carry me ", "home.</i>" ] );

my $xp = [ "<i>Comin’ for to carry me </i>", "<i>home.</i>" ];

is_deeply( $res, $xp, "defrag1");

$res = defrag( [ "<i>Comin’ for to <b>carry me ", "home.</b></i>" ] );

$xp = [ "<i>Comin’ for to <b>carry me </b></i>", "<i><b>home.</b></i>" ];

is_deeply( $res, $xp, "defrag2");
