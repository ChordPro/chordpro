#!/usr/bin/perl

# Test HTML5 backend with Object::Pad architecture

use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/lib";

# Mock the global config and options that ChordPro uses
package main;

our $config = {
    settings => {
        'lyrics-only' => 0,
    },
};

our $options = {
    'single-space' => 0,
    verbose => 1,
};

package main;

use ChordPro::Output::HTML5;

# Mock song structure
my $song = {
    title => "Amazing Grace",
    subtitle => ["Traditional Hymn"],
    artist => ["John Newton"],
    composer => ["John Newton"],
    body => [
        # Verse 1
        {
            type => 'verse',
            body => [
                {
                    type => 'songline',
                    phrases => ['A', 'mazing ', 'grace! How ', 'sweet the ', 'sound'],
                    chords => [
                        mock_chord('G'),
                        mock_chord('G/B'),
                        mock_chord('C'),
                        mock_chord('G'),
                        undef,
                    ],
                },
                {
                    type => 'songline',
                    phrases => ['That ', 'saved a ', 'wretch like ', 'me!'],
                    chords => [
                        mock_chord('G'),
                        mock_chord('Em'),
                        mock_chord('D'),
                        undef,
                    ],
                },
            ],
        },
        # Comment
        {
            type => 'comment',
            text => 'Simple and beautiful',
        },
        # Chorus
        {
            type => 'chorus',
            body => [
                {
                    type => 'songline',
                    phrases => ["'Twas ", 'grace that ', 'taught my ', 'heart to fear,'],
                    chords => [
                        mock_chord('G'),
                        mock_chord('C'),
                        mock_chord('G'),
                        undef,
                    ],
                },
                {
                    type => 'songline',
                    phrases => ['And ', 'grace my ', 'fears relieved;'],
                    chords => [
                        mock_chord('Em'),
                        mock_chord('D'),
                        undef,
                    ],
                },
            ],
        },
    ],
};

my $songbook = {
    songs => [$song],
};

# Call the backend as ChordPro does (class method)
my $output = ChordPro::Output::HTML5->generate_songbook($songbook);

# Write output
binmode STDOUT, ':utf8';
print join('', @$output);

sub mock_chord {
    my ($name) = @_;
    return bless {
        key => $name,
        name => $name,
    }, 'MockChord';
}

package MockChord;

sub key { return $_[0]->{key}; }
sub name { return $_[0]->{name}; }

1;
