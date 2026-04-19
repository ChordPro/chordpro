#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use File::Path qw(make_path);
use ChordPro::Testing;

plan tests => 3;

make_path('out');

my $input = 'html5_comment_box.cho';
my $out = 'out/html5_comment_box.html';

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

like($content, qr/class="cp-comment_box"/, 'Comment box element rendered');
like($content, qr/\.cp-comment_box\s*\{[^}]*border:\s*1pt\s+solid/s, 'Comment box CSS adds border');

unlink $out;
