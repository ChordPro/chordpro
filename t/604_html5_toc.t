#!/usr/bin/perl

# HTML5 paged TOC generation test

use strict;
use warnings;
use utf8;

use File::Path qw(make_path);
use ChordPro::Testing;

plan tests => 6;

make_path('out');

my $cho_file = 'out/html5_toc_test.cho';
my $cfg_file = 'out/html5_toc_config.json';
my $out_file = 'out/html5_toc_output.html';

open my $cho_fh, '>:utf8', $cho_file or die "Cannot create $cho_file: $!";
print $cho_fh <<'EOT';
{title: Alpha Song}
{artist: Artist A}

[C]Alpha line

{new_song}
{title: Bravo Song}
{artist: Artist B}

[G]Bravo line
EOT
close $cho_fh;

open my $cfg_fh, '>:utf8', $cfg_file or die "Cannot create $cfg_file: $!";
print $cfg_fh <<'EOC';
{
  "html5": { "mode": "print" },
  "contents": [
    {
      "name": "table_of_contents",
      "fields": ["songindex"],
      "label": "Table of Contents",
      "line": "%{title}",
      "pageno": "%{page}",
      "omit": false
    }
  ],
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

like($content, qr/class="cp-toc"/, 'TOC container present');
like($content, qr/<a[^>]*class=["'][^"']*cp-toc-entry\b/, 'TOC entry elements present');
like($content, qr/href="#cp-song-1"/, 'TOC entry references first song');
like($content, qr/target-counter\(attr\(href\), page\)/, 'TOC uses target-counter for page numbers');
like($content, qr/class="page-counter-reset"/, 'Page counter reset marker present when TOC exists');

unlink $cho_file, $cfg_file, $out_file;
