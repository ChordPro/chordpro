#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use File::Path qw(make_path);
use ChordPro::Testing;

plan tests => 4;

make_path('out');

my $input = 'html5_section_labels.cho';
my $out = 'out/html5_section_labels.html';

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

like($content, qr/data-label="Verse 1"/, 'Verse section includes data-label');
like($content, qr/data-label="Chorus"/, 'Chorus section includes data-label');
like($content, qr/\.cp-verse\[data-label\]::before/, 'Section label CSS added');

unlink $out;
