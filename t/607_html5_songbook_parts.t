#!/usr/bin/perl

# HTML5 paged songbook parts (cover/front/back matter) test

use strict;
use warnings;
use utf8;

use File::Path qw(make_path);
use ChordPro::Testing;

plan tests => 6;

make_path('out');

my $cho_file = 'out/html5_parts_test.cho';
my $cfg_file = 'out/html5_parts_config.json';
my $out_file = 'out/html5_parts_output.html';

my $cover_file = 'out/html5_cover.html';
my $front_file = 'out/html5_front.html';
my $back_file = 'out/html5_back.html';

open my $cover_fh, '>:utf8', $cover_file or die "Cannot create $cover_file: $!";
print $cover_fh '<div id="cover-content">Cover Page</div>';
close $cover_fh;

open my $front_fh, '>:utf8', $front_file or die "Cannot create $front_file: $!";
print $front_fh '<div id="front-content">Front Matter</div>';
close $front_fh;

open my $back_fh, '>:utf8', $back_file or die "Cannot create $back_file: $!";
print $back_fh '<div id="back-content">Back Matter</div>';
close $back_fh;

open my $cho_fh, '>:utf8', $cho_file or die "Cannot create $cho_file: $!";
print $cho_fh <<'EOT';
{title: Parts Song}
{artist: Test Artist}

[C]Song body
EOT
close $cho_fh;

open my $cfg_fh, '>:utf8', $cfg_file or die "Cannot create $cfg_file: $!";
print $cfg_fh <<'EOC';
{
  "html5": {
    "mode": "print",
    "cover": "out/html5_cover.html",
    "front-matter": "out/html5_front.html",
    "back-matter": "out/html5_back.html"
  },
  "pdf": {
    "papersize": "a4",
    "margintop": 80,
    "marginbottom": 40,
    "marginleft": 40,
    "marginright": 40,
    "headspace": 60,
    "footspace": 20,
    "formats": {
      "default": { "footer": ["%{title}", "%{page}", ""] }
    }
  }
}
EOC
close $cfg_fh;

@ARGV = (
    '--no-default-configs',
    '--generate', 'HTML5',
    '--config', $cfg_file,
    '--output', $out_file,
    $cho_file,
);
::run();

ok(-f $out_file, 'HTML5 output generated');

open my $out_fh, '<:utf8', $out_file or die "Cannot open $out_file: $!";
my $content = do { local $/; <$out_fh> };
close $out_fh;

like($content, qr/class="[^"]*\bcp-cover\b/, 'Cover wrapper present');
like($content, qr/class="[^"]*\bcp-front-matter\b/, 'Front matter wrapper present');
like($content, qr/class="[^"]*\bcp-back-matter\b/, 'Back matter wrapper present');

my $cover_pos = index($content, 'cover-content');
my $front_pos = index($content, 'front-content');
my $song_pos = index($content, 'Song body');
my $back_pos = index($content, 'back-content');

ok($cover_pos > -1 && $front_pos > -1 && $song_pos > -1 && $back_pos > -1,
   'All content markers found');

ok($cover_pos < $front_pos && $front_pos < $song_pos && $song_pos < $back_pos,
   'Cover/front/song/back order preserved');

unlink $cover_file, $front_file, $back_file, $cho_file, $cfg_file, $out_file;
