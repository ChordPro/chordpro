#!/usr/bin/perl

# Test HTML5 backend basic functionality

use strict;
use warnings;
use utf8;
use Test::More;

use lib '../lib';
use lib '../blib/lib';

use_ok('ChordPro::Output::HTML5');
use_ok('ChordPro::Song');

# Create minimal config
$::config = {
    html5 => {
        styles => {
            embed => 1,
        },
    },
    settings => {},
};
$::options = {};

# Create proper song object
my $song = bless {
    title => "Test Song",
    subtitle => ["A Simple Test"],
    meta => {
        artist => ["Test Artist"],
    },
    body => [
        {
            type => "songline",
            phrases => ["Hel", "lo ", "world"],
            chords => [
                bless({ key => "C", name => "C" }, 'ChordPro::Chord::Common'),
                bless({ key => "G", name => "G" }, 'ChordPro::Chord::Common'),
                bless({ key => "Am", name => "Am" }, 'ChordPro::Chord::Common'),
            ],
        },
        {
            type => "comment",
            text => "This is a comment",
        },
    ],
    structure => "linear",
}, 'ChordPro::Song';

# Create backend instance
my $backend = ChordPro::Output::HTML5->new(
    config => $::config,
    options => $::options,
);

ok($backend, "HTML5 backend created");

# Generate output
my $output = $backend->generate_song($song);

ok($output && length($output) > 0, "HTML5 backend generates output");

# Test output contains key elements
like($output, qr/<h1 class="cp-title">Test Song<\/h1>/, "Contains title");
like($output, qr/<h2 class="cp-subtitle">A Simple Test<\/h2>/, "Contains subtitle");
like($output, qr/class="cp-chord">C<\/span>/, "Contains chord");
like($output, qr/class="cp-lyrics">Hel<\/span>/, "Contains lyrics");
like($output, qr/class="cp-comment">This is a comment<\/div>/, "Contains comment");

done_testing();
