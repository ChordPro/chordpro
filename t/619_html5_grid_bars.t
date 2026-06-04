#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use File::Path qw(make_path);
use ChordPro::Testing;
use URI::Escape qw(uri_unescape);

plan tests => 9;

make_path('out');

my $input = 'html5_grid_bars.cho';
my $out = 'out/html5_grid_bars.html';

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

like($content, qr/cp-grid-bar-repeat-start/, 'Repeat start bar class present');
like($content, qr/cp-grid-bar-repeat-end/, 'Repeat end bar class present');
like($content, qr/cp-grid-bar-repeat-both/, 'Repeat both bar class present');
like($content, qr/cp-grid-bar-double/, 'Double bar class present');
like($content, qr/cp-grid-bar-end/, 'End bar class present');

my ($uri) = ($content =~ /class="cp-grid-full-svg"[^>]*src="(data:image\/svg\+xml;charset=utf-8,[^"]+)"/);
ok($uri, 'Full-grid SVG data URI captured');

my $svg = uri_unescape($uri // '');
$svg =~ s/^data:image\/svg\+xml;charset=utf-8,//;

like($svg, qr/<use\b[^>]*href="#bar-single"/,
    'Single bar rendered via icon <use>');
unlike($svg, qr/<text\b[^>]*font-size="6"[^>]*>[𝄀𝄁𝄂𝄃𝄆𝄇]+<\/text>/u,
    'No duplicate legacy Unicode bar text for icon-rendered bars');

unlink $out;
