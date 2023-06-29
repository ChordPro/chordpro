#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Config;
use ChordPro::Songbook;

plan tests => 2;

!$config && diag("$@");
ok($config, "Configuration set up");

my $s = ChordPro::Songbook->new;
ok($s, "Song set up");

