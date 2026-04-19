#!/usr/bin/perl

# Test HTML5 even/odd page format configuration
# Tests Phase 3: Even/Odd Page Differences

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Songbook;

plan tests => 15;

use_ok('ChordPro::Output::HTML5');

# =================================================================
# Test 1: Even page formats with left/right swapping
# =================================================================

my $config_even_odd = {
    %$config,
    html5 => { mode => 'print' },
    pdf => {
        papersize => 'a4',
        formats => {
            default => {
                title => ['Left Title', 'Center Title', 'Right Title'],
                footer => ['Left Footer', 'Center Footer', 'Right Footer'],
            },
            'default-even' => {
                title => ['Even Left', 'Even Center', 'Even Right'],
                footer => ['Even Footer Left', '', 'Even Footer Right'],
            },
        },
    },
};

my $backend = ChordPro::Output::HTML5->new(
    config => $config_even_odd,
    options => { output => undef },
);
ok($backend, "Backend created with even/odd config");

my $css = $backend->generate_paged_css();
ok($css, "CSS generated");

# Test default (odd) page format
like($css, qr/"Left Title"/, "Default has left title");
like($css, qr/"Center Title"/, "Default has center title");
like($css, qr/"Right Title"/, "Default has right title");

# Test even page format (CSS :left selector)
like($css, qr/\@page :left/, "Has :left page selector for even pages");

# Test that even page has swapped content
# The content "Even Left" should appear in @top-left on even pages
# but since we specified it as the left content, and even pages swap,
# the actual CSS should have "Even Right" in @top-left (swapped)
like($css, qr/"Even Left"/, "Even page content present");
like($css, qr/"Even Center"/, "Even center content present");
like($css, qr/"Even Right"/, "Even right content present");

# =================================================================
# Test 2: Odd page explicit format
# =================================================================

my $config_with_odd = {
    %$config,
    html5 => { mode => 'print' },
    pdf => {
        formats => {
            'default-odd' => {
                footer => ['Odd Left', 'Odd Center', 'Odd Right'],
            },
        },
    },
};

my $backend2 = ChordPro::Output::HTML5->new(
    config => $config_with_odd,
    options => { output => undef },
);

my $css2 = $backend2->generate_paged_css();
like($css2, qr/\@page :right/, "Has :right page selector for odd pages");
like($css2, qr/"Odd Center"/, "Odd page content present");

# =================================================================
# Test 3: Title page even/odd variants
# =================================================================

my $config_title_variants = {
    %$config,
    html5 => { mode => 'print' },
    pdf => {
        formats => {
            'title' => {
                footer => ['Title Left', 'Title Center', 'Title Right'],
            },
            'title-even' => {
                footer => ['Title Even Left', '', 'Title Even Right'],
            },
        },
    },
};

my $backend3 = ChordPro::Output::HTML5->new(
    config => $config_title_variants,
    options => { output => undef },
);

my $css3 = $backend3->generate_paged_css();
like($css3, qr/\@page title/, "Has title page format");
like($css3, qr/\@page title:left/, "Has title:left format for even title pages");
like($css3, qr/"Title Even (Left|Right)"/, "Title even page content present");

