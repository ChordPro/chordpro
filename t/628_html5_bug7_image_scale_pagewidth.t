#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Songbook;

plan tests => 6;

use_ok('ChordPro::Output::HTML5');

my $html5 = ChordPro::Output::HTML5->new(
    config  => $config,
    options => { output => undef },
);

ok($html5, "HTML5 backend created");

my $song_data = <<'EOD';
{title: Image Scale Page Width}
{image src="chordpro.png" scale="50%"}
EOD

my $s = ChordPro::Songbook->new;
$s->parse_file(\$song_data, { nosongline => 1 });
ok(scalar(@{$s->{songs}}) == 1, "Song parsed");

my $song = $s->{songs}[0];
my $output = $html5->generate_song($song);
ok($output, "HTML5 output generated");

like(
    $output,
    qr/<img[^>]*style="[^"]*width:\s*50%[^"]*"/s,
    "Scale uses page width percentage"
);

unlike(
    $output,
    qr/<img[^>]*\swidth="/s,
    "Scale ignores explicit width attribute"
);
