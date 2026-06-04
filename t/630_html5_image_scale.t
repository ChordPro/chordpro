#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Songbook;
use File::Temp qw(tempdir);

plan tests => 5;

use_ok('ChordPro::Output::HTML5');

my $html5 = ChordPro::Output::HTML5->new(
    config  => $config,
    options => { output => undef },
);
ok($html5, 'HTML5 backend created');

my $tmpdir = tempdir(CLEANUP => 1);
my $img_path = "$tmpdir/test.png";
my $png_data = pack("H*",
    "89504e470d0a1a0a0000000d49484452" .
    "00000001000000010802000000907753" .
    "de0000000c4944415408d763f8cf0000" .
    "000200016540cd730000000049454e44" .
    "ae426082"
);
open my $fh, '>:raw', $img_path or die "Cannot write test image: $!";
print $fh $png_data;
close $fh;

my $song_data = <<EOD;
{title: Image Scale Test}

{image: $img_path scale=0.5}
EOD

my $songbook = ChordPro::Songbook->new;
$songbook->parse_file(\$song_data, { nosongline => 1 });
my $song = $songbook->{songs}[0];

my $output = $html5->generate_song($song);
ok($output, 'Song rendered with scaled image');
like($output, qr/style="[^"]*width:\s*50%/,
    'Image scale renders width 50%');

my $img = $html5->render_image('data:image/png;base64,AAAA', {
    scale => 0.25,
    class => 'cp-delegate',
});
like($img, qr/style="[^"]*width:\s*25%/,
    'render_image applies scale width');
