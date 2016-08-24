#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Test::More tests => 2;

use App::Music::ChordPro::Config;
use App::Music::ChordPro::Songbook;

my $config;

eval {
  $config = App::Music::ChordPro::Config::configurator;
};
!$config && diag("$@");
ok($config, "Configuration set up");

my $s = App::Music::ChordPro::Songbook->new;
ok($s, "Song set up");

