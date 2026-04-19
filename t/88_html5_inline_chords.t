#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use File::Path qw(make_path);
use ChordPro::Testing;

plan tests => 4;

make_path('out');

my $input = 'html5_inline_chords.cho';
my $out = 'out/html5_inline_chords.html';
my $cfg = 'out/html5_inline_chords.json';

open my $cfg_fh, '>:utf8', $cfg or die "Cannot create $cfg: $!";
print {$cfg_fh} '{"settings":{"inline-chords":"[%s]","inline-annotations":"(%s)"}}';
close $cfg_fh;

@ARGV = (
    '--no-default-configs',
    '--generate', 'HTML5',
    '--config', $cfg,
    '--output', $out,
    $input,
);
::run();

ok(-f $out, 'HTML5 output generated');

open my $out_fh, '<:utf8', $out or die "Cannot open $out: $!";
my $content = do { local $/; <$out_fh> };
close $out_fh;

like($content, qr/cp-inline-chords/, 'Inline chord mode enabled');
like($content, qr/class="cp-inline-chord">\[C\]/, 'Chord rendered inline with format');
like($content, qr/class="cp-inline-annotation">\(N\.C\.\)/, 'Annotation rendered inline with format');

unlink $out;
unlink $cfg;
