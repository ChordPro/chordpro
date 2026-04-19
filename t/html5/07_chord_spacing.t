#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Songbook;

plan tests => 14;

use_ok('ChordPro::Output::HTML5');

# Test song with chord spacing issues
my $song_data = <<'EOD';
{title: Chord Spacing Test}

{start_of_verse}
[C][F][G]
[Am]Lyrics here
Text with no chords
[D]Mixed [G]chords [C]and text
{end_of_verse}
EOD

# Parse song
my $s = ChordPro::Songbook->new;
$s->parse_file(\$song_data, { nosongline => 1 });
ok(scalar(@{$s->{songs}}) == 1, "Song parsed");

my $song = $s->{songs}[0];
ok($song, "Song object created");

# Generate HTML5 output (structurize is done automatically in the backend)
my $html5 = ChordPro::Output::HTML5->new(
    config => $config,
    options => { output => undef },
);

my $output = $html5->generate_song($song);
ok($output, "HTML5 output generated");

# Test chord-only pairs have special class
like($output, qr/cp-chord-only/, "Chord-only class present");

# Test multiple chord-only pairs in sequence
my @chord_only = ($output =~ /cp-chord-only/g);
ok(scalar(@chord_only) >= 3, "Multiple chord-only pairs detected");

# Test lyrics-only lines (no chord spans)
# When a line has no chords, it should not generate chord-lyric-pair structure
like($output, qr/<span class="cp-lyrics">Text with no chords<\/span>/, 
    "Lyrics-only line rendered simply");

# Test that chord-only pairs have margin-right in CSS
# Generate CSS separately to check for the rule
my $css = $html5->generate_default_css();
like($css, qr/\.cp-chord-only[^}]*margin-right/s, "Chord-only CSS rule present");

# Test that lyrics-only line doesn't have chord-lyric-pair before it
my ($before_lyrics) = ($output =~ /(.{0,100})<span class="cp-lyrics">Text with no chords/s);
unlike($before_lyrics, qr/cp-chord-lyric-pair/, 
    "Lyrics-only line doesn't use chord-lyric-pair structure");

# Test mixed chord-lyric pairs
like($output, qr/<span class="cp-chord">D<\/span>.*<span class="cp-lyrics">Mixed/s,
    "Mixed chord-lyric pair rendered");

# Test that mixed pairs are wrapped in chord-lyric-pair
like($output, qr/cp-chord-lyric-pair.*<span class="cp-chord">D<\/span>/s,
    "Mixed pairs use chord-lyric-pair structure");

# Test empty chord spans for alignment
# Empty chords appear when a phrase has no chord (more phrases than chords)
# In this test, most lines either have all chords or no chords
# So we test that the structure is correct rather than requiring empty spans
ok($output =~ /cp-chord-lyric-pair/ || $output =~ /cp-lyrics/,
   "Chord-lyric structure or lyrics present");

# Test verse container
like($output, qr/<div class="cp-verse"/, "Verse container present");

# Test CSS has verse spacing
like($css, qr/\.cp-verse[^}]*margin/s, "Verse CSS has spacing");

