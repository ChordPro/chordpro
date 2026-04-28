#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Songbook;

plan tests => 8;

use_ok('ChordPro::Output::HTML5');

# Test full document generation with headers/footers
my $test_config = {
    %$config,
    pdf => {
        formats => {
            'first' => {
                'header' => [
                    ['%{title}', 'Songbook', 'Page %{page}'],
                ],
                'footer' => [
                    ['', 'First Page Footer', ''],
                ],
            },
            'default' => {
                'header' => [
                    ['%{title}', '', '%{page}'],
                ],
                'footer' => [
                    ['By %{artist}', '', ''],
                ],
            },
        },
    },
};

my $song_data = <<'EOD';
{title: Integration Test Song}
{subtitle: Testing Headers and Footers}
{artist: Test Artist}

{start_of_verse}
[C]First verse with some text
[G]More lyrics here
{end_of_verse}

{start_of_chorus}
[Am]Chorus section
[F]With different chords
{end_of_chorus}
EOD

my $s = ChordPro::Songbook->new;
$s->parse_file(\$song_data, { nosongline => 1 });
ok(scalar(@{$s->{songs}}) == 1, "Song parsed");

my $paged = ChordPro::Output::HTML5->new(
    config => $test_config,
    options => { output => undef },
);

my $song = $s->{songs}[0];

# Generate full document to test headers/footers
my $doc_begin = $paged->render_document_begin({ title => 'Test Songbook', songs => 1 });
my $song_output = $paged->generate_song($song);
my $doc_end = $paged->render_document_end();
my $output = $doc_begin . $song_output . $doc_end;

ok($output, "Full output generated");

# Test that output is valid HTML5
like($output, qr/<!DOCTYPE html>/i, "Has HTML5 doctype");
like($output, qr/<html/, "Has html tag");

# Test verse container
like($song_output, qr/<div class="cp-verse"/, "Verse container present");

# Test chorus container
like($song_output, qr/<div class="cp-chorus"/, "Chorus container present");

# Test markup support works in paged output
my $markup_song = <<'EOD';
{title: <span color="red">Red Title</span>}

{start_of_verse}
[<span color="blue">C</span>]<b>Bold</b> lyrics
{end_of_verse}
EOD

my $s2 = ChordPro::Songbook->new;
$s2->parse_file(\$markup_song, { nosongline => 1 });

my $markup_output = $paged->generate_song($s2->{songs}[0]);
like($markup_output, qr/color:red.*Red Title/s, "Markup in title works with paged output");

