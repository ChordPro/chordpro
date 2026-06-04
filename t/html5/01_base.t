#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Songbook;
use ChordPro::Song;

plan tests => 12;

# Test Base.pm functionality through a concrete subclass
use_ok('ChordPro::Output::HTML5');

# Create a simple song for testing
my $song = ChordPro::Song->new();
ok($song, "Song created");

# Use config from ChordPro::Testing
ok($config, "Config loaded");

my $options = { output => undef };

# Test HTML5 object creation (tests Base.pm constructor)
my $html5 = ChordPro::Output::HTML5->new(
    config => $config,
    options => $options,
);
ok($html5, "HTML5 object created");

# Test Base.pm reader methods
ok(ref($html5->config), "config() returns blessed object");
is(ref($html5->options), 'HASH', "options() returns hash ref");

# Test song getter (Base.pm functionality)
can_ok($html5, 'song');
ok(!defined($html5->song), "song() initially undefined");

# Test that config is a ChordPro::Config object
isa_ok($html5->config, 'ChordPro::Config', "config is correct type");

# Test that the object has expected methods from Base.pm
can_ok($html5, 'config_has');
can_ok($html5, 'config_get');

# Test that generate_songbook method exists (abstract method implemented)
can_ok($html5, 'generate_songbook');
