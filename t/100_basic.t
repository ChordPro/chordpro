#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use App::Music::ChordPro::Testing;
use App::Music::ChordPro::Config;
use App::Music::ChordPro::Songbook;

plan tests => 2;

!$config && diag("$@");
ok($config, "Configuration set up");

my $s = App::Music::ChordPro::Songbook->new;
ok($s, "Song set up");

