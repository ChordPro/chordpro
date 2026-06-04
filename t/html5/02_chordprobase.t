#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Songbook;
use ChordPro::Song;

plan tests => 15;

# Test ChordProBase.pm functionality through HTML5 subclass
use_ok('ChordPro::Output::HTML5');

# Create a simple song with some content
my $song = ChordPro::Song->new();
ok($song, "Song created");

# Use config from ChordPro::Testing
my $options = { output => undef };

# Create HTML5 object
my $html5 = ChordPro::Output::HTML5->new(
    config => $config,
    options => $options,
);

# Test ChordProBase.pm reader methods
# (current_context may be undef initially)
can_ok($html5, 'current_context');
ok(defined($html5->is_lyrics_only), "is_lyrics_only() returns boolean");
ok(defined($html5->is_single_space), "is_single_space() returns boolean");

# Test that abstract methods are implemented
can_ok($html5, 'render_chord');
can_ok($html5, 'render_songline');
can_ok($html5, 'render_grid_line');

# Test dispatch_element method exists
can_ok($html5, 'dispatch_element');

# Test various handle_* methods (ChordProBase functionality)
can_ok($html5, 'handle_songline');
can_ok($html5, 'handle_chorus');
can_ok($html5, 'handle_verse');
can_ok($html5, 'handle_comment');
can_ok($html5, 'handle_set');
can_ok($html5, 'handle_diagrams');

done_testing();
