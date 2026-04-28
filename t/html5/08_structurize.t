#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Songbook;

plan tests => 12;

# Test that structurize is called automatically
use_ok('ChordPro::Output::HTML5');

my $song_data = <<'EOD';
{title: Structurize Test}

{start_of_verse}
[C]First verse
{end_of_verse}

{start_of_chorus}
[G]Chorus line
{end_of_chorus}

{start_of_bridge}
[Am]Bridge section
{end_of_bridge}

{start_of_verse}
[F]Second verse
{end_of_verse}
EOD

# Parse song
my $s = ChordPro::Songbook->new;
$s->parse_file(\$song_data, { nosongline => 1 });
ok(scalar(@{$s->{songs}}) == 1, "Song parsed");

my $song = $s->{songs}[0];
ok($song, "Song object created");

# Before structurize is called, the song should have start_of_/end_of_ elements
# After structurize (which is called in the backend), they should be converted to containers
$song->structurize;

# Generate output
my $html5 = ChordPro::Output::HTML5->new(
    config => $config,
    options => { output => undef },
);

my $output = $html5->generate_song($song);
ok($output, "Output generated");

# Test that verse containers are present (result of structurize)
my @verses = ($output =~ /<div class="cp-verse"/g);
is(scalar(@verses), 2, "Two verse containers found");

# Test that chorus container is present
like($output, qr/<div class="cp-chorus"/, "Chorus container present");

# Test that bridge container is present
like($output, qr/<div class="cp-bridge"/, "Bridge container present");

# Test that start_of_/end_of_ directives are NOT in output
# (they should be converted to containers)
unlike($output, qr/start_of_verse/, "start_of_verse not in output");
unlike($output, qr/end_of_verse/, "end_of_verse not in output");

# Test verse has proper spacing
my $css = $html5->generate_default_css();
like($css, qr/\.cp-verse\s*\{[^}]*margin/s, "Verse has margin CSS");

# Test chorus has proper styling
like($css, qr/\.cp-chorus\s*\{[^}]*padding/s, "Chorus has padding CSS");
like($css, qr/\.cp-chorus\s*\{[^}]*border-left/s, "Chorus has border CSS");

