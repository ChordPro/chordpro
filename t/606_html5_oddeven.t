#!/usr/bin/perl

# HTML5 paged odd/even page CSS generation test

use strict;
use warnings;
use utf8;

use ChordPro::Testing;

plan tests => 5;

use_ok('ChordPro::Output::HTML5');

$config->unlock;
$config->{html5} //= {};
$config->{html5}->{mode} = 'print';
$config->{pdf} //= {};
$config->{pdf}->{formats} = {
    'default-even' => {
        footer => [ '', '', '%{page}' ],
    },
    'default-odd' => {
        footer => [ '', '', '%{page}' ],
    },
};
$config->lock;

my $backend = ChordPro::Output::HTML5->new(
    config => $config,
    options => { output => undef },
);

my $css = $backend->generate_default_css(1);

like($css, qr/\@page\s*:left\b/, 'Generates @page :left selector');
like($css, qr/\@page\s*:right\b/, 'Generates @page :right selector');
like($css, qr/\@bottom-left\b[\s\S]*counter\(page\)/, 'Left page footer uses counter(page)');
like($css, qr/\@bottom-right\b[\s\S]*counter\(page\)/, 'Right page footer uses counter(page)');
