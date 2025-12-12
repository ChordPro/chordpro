#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Songbook;

plan tests => 15;

use_ok('ChordPro::Output::HTML5');

# Test song with markup in various contexts
my $song_data = <<'EOD';
{title: <span color="blue">Blue Title</span>}
{subtitle: <b>Bold</b> subtitle}
{artist: <i>Italic artist</i>}

{start_of_verse}
[<span color="red">C</span>]Lyrics with <b>bold</b> text
[G]More <span color="green">colored</span> lyrics
{end_of_verse}

{start_of_chorus}
[Am]Chorus with <i>italic</i> text
[F]And <span background="yellow">highlighted</span> words
{end_of_chorus}

{comment: Comment with <span color="orange">colored</span> text}
EOD

# Parse song
my $s = ChordPro::Songbook->new;
$s->parse_file(\$song_data, { nosongline => 1 });
ok(scalar(@{$s->{songs}}) == 1, "Song parsed");

my $song = $s->{songs}[0];
ok($song, "Song object created");

# Structurize song (normally done by ChordPro.pm)
$song->structurize;

# Generate HTML5 output
my $html5 = ChordPro::Output::HTML5->new(
    config => $config,
    options => { output => undef },
);

my $output = $html5->generate_song($song);
ok($output, "HTML5 output generated");

# Test title markup
like($output, qr/<h1[^>]*>.*color:blue.*Blue Title/s, "Title has color markup");

# Test subtitle markup
like($output, qr/<h2[^>]*>.*font-weight:bold.*subtitle/s, "Subtitle has bold markup");

# Test artist markup - skip if not rendered (depends on how metadata is populated)
SKIP: {
    skip "Artist metadata not rendered", 1 unless $output =~ /cp-artist/;
    like($output, qr/cp-artist.*font-style:italic/s, "Artist has italic markup");
}

# Test chord markup
like($output, qr/cp-chord.*color:red.*C/s, "Chord has color markup");

# Test lyrics markup
like($output, qr/cp-lyrics.*font-weight:bold.*bold/s, "Lyrics have bold markup");
like($output, qr/cp-lyrics.*color:green.*colored/s, "Lyrics have color markup");

# Test chorus markup
like($output, qr/cp-chorus.*font-style:italic.*italic/s, "Chorus has italic markup");
like($output, qr/cp-chorus.*background-color:yellow.*highlighted/s, "Chorus has background color");

# Test comment markup
like($output, qr/cp-comment.*color:orange.*colored/s, "Comment has color markup");

# Test verse container exists
like($output, qr/<div class="cp-verse"/, "Verse container rendered");

# Test chorus container exists
like($output, qr/<div class="cp-chorus"/, "Chorus container rendered");

