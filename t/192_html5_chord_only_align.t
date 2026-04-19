#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Songbook;

plan tests => 8;

use_ok('ChordPro::Output::HTML5');

my $html5 = ChordPro::Output::HTML5->new(
    config  => $config,
    options => { output => undef },
);
ok($html5, 'HTML5 backend created');

my $css = $html5->generate_default_css();
ok($css, 'CSS generated');
like(
    $css,
    qr/\.cp-chord-only\s*\{[^}]*align-self:\s*flex-start/s,
    'Chord-only pairs align to the chord line'
);

my $paged_css = $html5->generate_default_css(1);
ok($paged_css, 'Paged CSS generated');
like(
    $paged_css,
    qr/\.cp-chord-only\s*\{[^}]*align-self:\s*flex-start/s,
    'Paged chord-only pairs align to the chord line'
);

my $song_data = <<'EOD';
{title: Chord Only Test}

{start_of_verse}
[C]Lyric [G]line
[Am] [Em]
{end_of_verse}
EOD

my $songbook = ChordPro::Songbook->new;
$songbook->parse_file(\$song_data, { nosongline => 1 });
my $song = $songbook->{songs}[0];

my $output = $html5->generate_song($song);
ok($output, 'Song rendered with chord-only pairs');
like($output, qr/cp-chord-only/, 'Chord-only pairs emit class');
