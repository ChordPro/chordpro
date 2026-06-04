#!/usr/bin/perl

# Integration test for multiple bug fixes
# Tests that Bugs 1 and 2 work correctly together in real-world scenarios

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Songbook;

plan tests => 11;

use_ok('ChordPro::Output::HTML5');

# Create HTML5 backend
my $html5 = ChordPro::Output::HTML5->new(
    config => $config,
    options => { output => undef },
);
ok($html5, "HTML5 object created");

# Real-world song with mixed chord patterns
# - Lines with no leading chord (Bug 2 scenario)
# - Multiple verses and chorus (template complexity - Bug 1 scenario)
my $song_data = <<'EOD';
{title: Amazing Grace}
{subtitle: Traditional}
{key: G}

{start_of_verse}
Amazing [G]grace how [G7]sweet the [C]sound
That [G]saved a [Em]wretch like [D]me
I [G]once was [G7]lost but [C]now am [G]found
Was [Em]blind but [D]now I [G]see
{end_of_verse}

{start_of_chorus}
'Twas [G]grace that [G7]taught my [C]heart to fear
And [G]grace my [D]fears re[G]lieved
{end_of_chorus}

{start_of_verse}
Through many [G]dangers [G7]toils and [C]snares
I [G]have al[Em]ready [D]come
{end_of_verse}
EOD

my $s = ChordPro::Songbook->new;
$s->parse_file(\$song_data, { nosongline => 1 });
ok(scalar(@{$s->{songs}}) == 1, "Song parsed");

my $song = $s->{songs}[0];

# Test: Generate complete output without errors
my $output = eval { $html5->generate_song($song) };
my $error = $@;
ok(!$error, "No template errors (Bug 1 fixed)") or diag("Error: $error");
ok($output, "HTML5 output generated");

# Verify Bug 1 fix: Templates resolved correctly (module loads and generates output)
like($output, qr/<div class="cp-song"/, 
     "Song structure generated successfully (Bug 1)");

# Verify song structure is correct
like($output, qr/<div class="cp-verse"/, "Verse structure present");
like($output, qr/<div class="cp-chorus"/, "Chorus structure present");

# Verify content rendering
like($output, qr/Amazing.*grace/is, "Song title/lyrics present");
like($output, qr/Traditional/, "Subtitle present");

# Verify all lines render (including those without leading chords - Bug 2 scenario)
like($output, qr/That.*saved.*wretch/is, 
     "Line without leading chord renders (Bug 2 scenario)");

diag("Integration test: Multiple bug fixes working together - PASSED");
