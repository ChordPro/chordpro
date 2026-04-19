#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use File::Path qw(make_path);
use Test::More;
use ChordPro::Testing;

plan tests => 6;

make_path('out');

my $cho_file = 'out/98_html5_toc_numbers.cho';
my $cfg_file = 'out/98_html5_toc_numbers.json';
my $out_file = 'out/98_html5_toc_numbers.html';

open my $cho_fh, '>:utf8', $cho_file or die "Cannot create $cho_file: $!";
print {$cho_fh} <<'EOT';
{title: Alpha Song}
[C]Alpha line

{new_song}
{title: Bravo Song}
[G]Bravo line
EOT
close $cho_fh;

open my $cfg_fh, '>:utf8', $cfg_file or die "Cannot create $cfg_file: $!";
print {$cfg_fh} <<'EOC';
{
  "html5": {
    "mode": "print",
    "paged": {
      "templates": { "css": "html5/paged/css/base.tt" }
    }
  },
  "contents": [
    {
      "name": "table_of_contents",
      "fields": ["songindex"],
      "label": "Table of Contents",
      "line": "%{title} %{page}",
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
like($content, qr/class="cp-toc-entry"[^>]*href="#cp-song-1"/, 'TOC entry link present');
unlike($content, qr/class="cp-toc-entry[^"]*cp-toc-page-target/, 'TOC avoids duplicate page numbers when line includes page');
like($content, qr/page:\s*toc;/, 'TOC pages use named page');
like($content, qr/\@page\s+toc[\s\S]*?\@bottom-right[\s\S]*?content:\s*none;/, 'TOC pages suppress margin page numbers');

unlink $cho_file, $cfg_file, $out_file;
