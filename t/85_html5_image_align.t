#!/usr/bin/perl

# HTML5 image alignment and scaling test

use strict;
use warnings;
use utf8;

use MIME::Base64 qw(decode_base64);
use File::Path qw(make_path);
use ChordPro::Testing;

plan tests => 6;

make_path('out');

my $png_file = 'out/html5_image_test.png';
my $cho_file = 'out/html5_image_align.cho';
my $out_file = 'out/html5_image_align.html';

my $png_data = decode_base64(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAASsJTYQAAAAASUVORK5CYII='
);

open my $png_fh, '>:raw', $png_file or die "Cannot create $png_file: $!";
print $png_fh $png_data;
close $png_fh;

open my $cho_fh, '>:utf8', $cho_file or die "Cannot create $cho_file: $!";
print $cho_fh <<'EOT';
{title: Image Align Test}

{image: out/html5_image_test.png align=center}
{image: out/html5_image_test.png align=left}
{image: out/html5_image_test.png align=right}
{image: out/html5_image_test.png width=200 scale=0.5}
{image: out/html5_image_test.png scale=0.5}
EOT
close $cho_fh;

@ARGV = (
    '--no-default-configs',
    '--generate', 'HTML5',
    '--output', $out_file,
    $cho_file,
);
::run();

ok(-f $out_file, 'HTML5 output generated');

open my $out_fh, '<:utf8', $out_file or die "Cannot open $out_file: $!";
my $content = do { local $/; <$out_fh> };
close $out_fh;

like($content, qr/class="cp-image-container cp-image-align-center"/, 'Center-aligned image container');
like($content, qr/class="cp-image-container cp-image-align-left"/, 'Left-aligned image container');
like($content, qr/class="cp-image-container cp-image-align-right"/, 'Right-aligned image container');
like($content, qr/width="100"/, 'Scaled width applied from width + scale');
like($content, qr/style="width: 50%"/, 'Scaled width applied from scale only');

unlink $png_file, $cho_file, $out_file;
