#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use File::Path qw(make_path);
use ChordPro::Testing;

plan tests => 4;

make_path('out');

my $input = 'html5_volta.cho';
my $out = 'out/html5_volta.html';

@ARGV = (
    '--no-default-configs',
    '--generate', 'HTML5',
    '--output', $out,
    $input,
);
::run();

ok(-f $out, 'HTML5 output generated');

open my $out_fh, '<:utf8', $out or die "Cannot open $out: $!";
my $content = do { local $/; <$out_fh> };
close $out_fh;

like($content, qr/cp-grid-full-svg/, 'Volta grid rendered as SVG (universal path)');
like($content, qr/data-volta(?:="1"|%3D%221%22)/, 'Volta data attribute present in SVG');
like($content, qr/\.cp-grid-volta::before/, 'Volta CSS added');

unlink $out;
