#!/usr/bin/perl

# HTML5 annotation rendering test

use strict;
use warnings;
use utf8;

use File::Path qw(make_path);
use ChordPro::Testing;

plan tests => 6;

make_path('out');

my $cho_file = 'out/html5_annotations_test.cho';
my $cfg_file = 'out/html5_annotations_config.json';
my $out_file = 'out/html5_annotations_output.html';

open my $cho_fh, '>:utf8', $cho_file or die "Cannot create $cho_file: $!";
print $cho_fh <<'EOT';
{title: Annotation Test}

[*N.C.]No chord
[C]Regular chord
[*riff]Guitar part
EOT
close $cho_fh;

open my $cfg_fh, '>:utf8', $cfg_file or die "Cannot create $cfg_file: $!";
print $cfg_fh <<'EOC';
{
  "diagrams": { "show": "all", "sorted": false }
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

like($content, qr/class="cp-annotation">N\.C\./, 'Annotation class applied');
like($content, qr/class="cp-annotation">riff/i, 'Annotation class applied to riff');
like($content, qr/class="cp-chord">C/, 'Chord class applied to standard chord');

my ($diag_html) = $content =~ /<div class="cp-chord-diagrams[^"]*">([\s\S]*?)<\/div>\s*<\/div>/;
ok(defined $diag_html, 'Chord diagrams section present');
unlike($diag_html, qr/N\.C\./, 'Annotations excluded from chord diagrams');

unlink $cho_file, $cfg_file, $out_file;
