#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use File::Path qw(make_path);
use Test::More;
use ChordPro::Testing;

plan tests => 5;

make_path('out');

my $cho_file = 'out/96_html5_paged_recto_verso.cho';
my $cfg_file = 'out/96_html5_paged_recto_verso.json';
my $out_file = 'out/96_html5_paged_recto_verso.html';

open my $cho_fh, '>:utf8', $cho_file or die "Cannot create $cho_file: $!";
print {$cho_fh} <<'EOT';
{title: Recto Break}
[C]First song

{new_song}
{title: Second Song}
[G]Second song
EOT
close $cho_fh;

open my $cfg_fh, '>:utf8', $cfg_file or die "Cannot create $cfg_file: $!";
print {$cfg_fh} <<'EOC';
{
  "html5": {
    "mode": "print",
    "paged": {
      "song": {
        "page-break": "before-recto"
      }
    }
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

like($content, qr/class="cp-song-break\b[^"]*cp-page-break-before-recto\b/, 'song break uses recto break class');
like($content, qr/class="cp-song\b[^"]*cp-page-break-before-recto\b/, 'song uses recto break class');
like($content, qr/\.cp-song-break\.cp-page-break-before-recto\s*\{[^}]*break-before:\s*recto;/s, 'paged CSS includes break-before recto');
like($content, qr/\@page\s*:blank\s*\{[^}]*content:\s*none;/s, 'blank page rules suppress margin content');

unlink $cho_file, $cfg_file, $out_file;
