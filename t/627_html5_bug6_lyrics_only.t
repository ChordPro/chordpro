#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Songbook;

plan tests => 5;

use_ok('ChordPro::Output::HTML5');

my $html5 = ChordPro::Output::HTML5->new(
    config  => $config,
    options => { output => undef },
);
ok($html5, "HTML5 backend created");

my $song_data = <<'EOD';
{title: Lyrics Only Line}

{start_of_verse}
Und trank am Wein sich satt.
[C]This line has chords
{end_of_verse}
EOD

my $s = ChordPro::Songbook->new;
$s->parse_file(\$song_data, { nosongline => 1 });
my $song = $s->{songs}[0];

my $output = $html5->generate_song($song);
ok($output, "HTML5 output generated");

like(
    $output,
    qr/<div class="cp-songline cp-lyrics-only">.*Und trank am Wein sich satt\./s,
    "Lyrics-only line renders without chord pairs"
);

unlike(
    $output,
    qr/<div class="cp-songline cp-lyrics-only">.*cp-chord-empty/s,
    "Lyrics-only line does not include chord placeholders"
);
