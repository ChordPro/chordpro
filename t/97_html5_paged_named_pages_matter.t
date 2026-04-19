#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use File::Path qw(make_path);
use Test::More;
use ChordPro::Testing;

plan tests => 5;

make_path('out');

my $cover_file = 'out/97_cover.html';
my $front_file = 'out/97_front.html';
my $back_file = 'out/97_back.html';
my $cho_file = 'out/97_html5_paged_named_pages.cho';
my $cfg_file = 'out/97_html5_paged_named_pages.json';
my $out_file = 'out/97_html5_paged_named_pages.html';

open my $cover_fh, '>:utf8', $cover_file or die "Cannot create $cover_file: $!";
print {$cover_fh} "<h1>Cover</h1>";
close $cover_fh;

open my $front_fh, '>:utf8', $front_file or die "Cannot create $front_file: $!";
print {$front_fh} "<h1>Front</h1>";
close $front_fh;

open my $back_fh, '>:utf8', $back_file or die "Cannot create $back_file: $!";
print {$back_fh} "<h1>Back</h1>";
close $back_fh;

open my $cho_fh, '>:utf8', $cho_file or die "Cannot create $cho_file: $!";
print {$cho_fh} <<'EOT';
{title: Matter Song}
[C]Matter line
EOT
close $cho_fh;

open my $cfg_fh, '>:utf8', $cfg_file or die "Cannot create $cfg_file: $!";
print {$cfg_fh} qq|{
  "html5": {
    "mode": "print",
    "cover": "$cover_file",
    "front-matter": "$front_file",
    "back-matter": "$back_file"
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
}|
;
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

like($content, qr/class="[^"]*\bcp-cover\b/, 'cover wrapper present');
like($content, qr/class="[^"]*\bcp-front-matter\b/, 'front matter wrapper present');
like($content, qr/class="[^"]*\bcp-back-matter\b/, 'back matter wrapper present');
like($content, qr/\@page\s+cover\b/, 'named page rule for cover present');

unlink $cover_file, $front_file, $back_file, $cho_file, $cfg_file, $out_file;
