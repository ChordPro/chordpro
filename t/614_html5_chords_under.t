#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use File::Path qw(make_path);
use ChordPro::Testing;

plan tests => 3;

make_path('out');

my $input = 'html5_chords_under.cho';
my $out = 'out/html5_chords_under.html';
my $cfg = 'out/html5_chords_under.json';

open my $cfg_fh, '>:utf8', $cfg or die "Cannot create $cfg: $!";
print {$cfg_fh} '{"settings":{"chords-under":true}}';
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

like($content, qr/flex-direction:\s*column-reverse/, 'CSS enables chords-under layout');
like($content, qr/padding-top:\s*var\(--cp-spacing-chord\)/, 'Chords-under adjusts chord spacing');

unlink $out;
unlink $cfg;
