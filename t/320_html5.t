#!/usr/bin/perl

# Test HTML5 backend basic functionality

use strict;
use warnings;
use utf8;
use Test::More tests => 3;

-d "t" && chdir "t";
require "./00_basic.pl";

use_ok('ChordPro::Output::HTML5');

# Create minimal config
my $config = {
    html5 => {
        styles => {
            embed => 1,
        },
    },
};

# Create minimal song structure
my $song = {
    title => "Test Song",
    subtitle => ["A Simple Test"],
    artist => ["Test Artist"],
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
};

# Create backend instance
my $backend = ChordPro::Output::HTML5->new(
    config => $config,
    options => {},
);

ok($backend, "HTML5 backend created");

# Generate output
my $output = $backend->generate_song($song);

ok($output && @$output > 0, "HTML5 backend generates output");

# Test output contains key elements
my $html = join('', @$output);
like($html, qr/<h1 class="cp-title">Test Song<\/h1>/, "Contains title");
like($html, qr/<h2 class="cp-subtitle">A Simple Test<\/h2>/, "Contains subtitle");
like($html, qr/class="cp-chord">C<\/span>/, "Contains chord");
like($html, qr/class="cp-lyrics">Hel<\/span>/, "Contains lyrics");
like($html, qr/class="cp-comment">This is a comment<\/div>/, "Contains comment");

done_testing();
