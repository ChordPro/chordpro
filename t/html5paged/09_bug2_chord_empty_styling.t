#!/usr/bin/perl

# Bug 1: First word appears in upper position when songline has no leading chord
#
# Symptom: When a song line doesn't start with a chord, first word renders too high
# Root Cause: .cp-chord-empty { display: none; } collapsed the chord spacer in flexbox
# Solution: Changed to visibility: hidden; to preserve vertical spacing alignment

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Songbook;

plan tests => 10;

use_ok('ChordPro::Output::HTML5');

# Create HTML5 backend
my $html5 = ChordPro::Output::HTML5->new(
    config => $config,
    options => { output => undef },
);
ok($html5, "HTML5 object created");

# Test song with line that has NO leading chord (triggers the bug)
my $song_data = <<'EOD';
{title: Chord Empty Test}
{subtitle: Bug 1 Regression Test}

{start_of_verse}
First line with no chord at start
[C]Second line starts with chord
Some [G]lyrics with chord in middle
{end_of_verse}
EOD

my $s = ChordPro::Songbook->new;
$s->parse_file(\$song_data, { nosongline => 1 });
ok(scalar(@{$s->{songs}}) == 1, "Song parsed");

my $song = $s->{songs}[0];

# Generate CSS (this is where .cp-chord-empty rule lives)
my $css = $html5->generate_default_css();
ok($css, "CSS generated");

# Test 4: Verify .cp-chord-empty uses visibility: hidden (preserves space for alignment)
like($css, qr/\.cp-chord-empty[^}]*visibility:\s*hidden/,
     "CSS contains .cp-chord-empty { visibility: hidden; }");

# Test 5: Verify it does NOT use display: none (that caused the misalignment bug)
unlike($css, qr/\.cp-chord-empty[^}]*display:\s*none/i,
       "CSS does NOT contain .cp-chord-empty { display: none; } (bug fixed)");

# Generate song HTML
my $output = $html5->generate_song($song);
ok($output, "HTML5 output generated");

# Test 7: Verify song structure contains songlines
like($output, qr/<div class="cp-songline"/, "Output contains songlines");

# Test 8: Verify lyrics are present
like($output, qr/First line with no chord/, "First line lyrics present");

# Test 9: Verify chord-empty class used for empty chord slots
like($output, qr/cp-chord-empty/, "Output uses cp-chord-empty class for empty chord positions");

diag("Bug 1 regression test: Chord-empty styling (visibility:hidden) - PASSED");
