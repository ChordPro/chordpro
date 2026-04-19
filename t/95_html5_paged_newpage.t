#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use File::Path qw(make_path);
use Test::More;
use ChordPro::Testing;

plan tests => 3;

make_path('out');

my $cho_file = 'out/95_html5_paged_newpage.cho';
my $cfg_file = 'out/95_html5_paged_newpage.json';
my $out_file = 'out/95_html5_paged_newpage.html';

open my $cho_fh, '>:utf8', $cho_file or die "Cannot create $cho_file: $!";
print {$cho_fh} <<'EOT';
{title: Newpage Break}
[C]First page

{new_page}
[G]Second page
EOT
close $cho_fh;

open my $cfg_fh, '>:utf8', $cfg_file or die "Cannot create $cfg_file: $!";
print {$cfg_fh} <<'EOC';
{
  "html5": {
    "mode": "print",
    "paged": {
      "newpage": {
        "page-break": "right"
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

like($content, qr/class="cp-new-page\b[^"]*cp-page-break-before-right\b/, 'newpage uses right-target break class');
like($content, qr/\.cp-new-page\.cp-page-break-before-right[^\{]*\{[^}]*break-before:\s*right;/s, 'paged CSS includes break-before right for newpage');


unlink $cho_file, $cfg_file, $out_file;
