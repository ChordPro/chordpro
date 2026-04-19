#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use File::Path qw(make_path);
use ChordPro::Testing;

plan tests => 4;

make_path('out');

my $input = 'html5_keyboard.cho';
my $out = 'out/html5_keyboard.html';
my $cfg = 'out/html5_keyboard.json';

open my $cfg_fh, '>:utf8', $cfg or die "Cannot create $cfg: $!";
print {$cfg_fh} '{"instrument":{"type":"keyboard"},"diagrams":{"show":"all"}}';
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

like($content, qr/cp-chord-diagrams/, 'Chord diagrams section present');
like($content, qr/diagram-key-white/, 'Keyboard diagram renders white keys');
like($content, qr/diagram-key-pressed/, 'Keyboard diagram highlights pressed keys');

unlink $out;
unlink $cfg;
