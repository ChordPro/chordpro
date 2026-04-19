#!/usr/bin/perl

# Test HTML5 format configuration (headers/footers)
# Tests Phase 3: Headers & Footers Configuration

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Songbook;

plan tests => 22;

use_ok('ChordPro::Output::HTML5');

# =================================================================
# Test 1: Basic format configuration parsing
# =================================================================

my $config_basic = {
    %$config,
    html5 => { mode => 'print' },
    pdf => {
        papersize => 'a4',
        formats => {
            default => {
                title => ['', '', ''],
                subtitle => ['', '', ''],
                footer => ['%{title}', '', '%{page}'],
            },
            title => {
                title => ['', '%{title}', ''],
                subtitle => ['', '%{subtitle}', ''],
                footer => ['', '', '%{page}'],
            },
            first => {
                footer => ['', '', ''],
            },
        },
    },
};

my $backend = ChordPro::Output::HTML5->new(
    config => $config_basic,
    options => { output => undef },
);
ok($backend, "Backend created with format config");

# Generate CSS and check for format rules
my $css = $backend->generate_paged_css();
ok($css, "CSS generated");

# Test default format footer
like($css, qr/\@page.*\{/, "Has \@page rule");
like($css, qr/\@bottom-left/, "Has \@bottom-left margin box");
like($css, qr/\@bottom-right/, "Has \@bottom-right margin box");
like($css, qr/counter\(page\)/, "Has page counter");
like($css, qr/string\(song-title\)/, "Has song-title string reference");

# =================================================================
# Test 2: Title page format
# =================================================================

like($css, qr/\@page title/, "Has title page format");
like($css, qr/\@top-center.*string\(song-title\)/s, "Title page has centered title");

# =================================================================
# Test 3: First page format
# =================================================================

like($css, qr/\@page :first/, "Has first page format");

# =================================================================
# Test 4: Three-part format (left, center, right)
# =================================================================

my $config_three_part = {
    %$config,
    html5 => { mode => 'print' },
    pdf => {
        formats => {
            default => {
                footer => ['Left Text', 'Center Text', 'Right Text'],
            },
        },
    },
};

my $backend2 = ChordPro::Output::HTML5->new(
    config => $config_three_part,
    options => { output => undef },
);

my $css2 = $backend2->generate_paged_css();
like($css2, qr/"Left Text"/, "Left text present");
like($css2, qr/"Center Text"/, "Center text present");
like($css2, qr/"Right Text"/, "Right text present");
like($css2, qr/\@bottom-left/, "Has left margin box");
like($css2, qr/\@bottom-center/, "Has center margin box");
like($css2, qr/\@bottom-right/, "Has right margin box");

# =================================================================
# Test 5: Complex format strings with multiple metadata
# =================================================================

my $config_complex = {
    %$config,
    html5 => { mode => 'print' },
    pdf => {
        formats => {
            default => {
                title => ['%{artist}', '%{title}', '%{album}'],
                footer => ['Page %{page} of %{pages}', '%{subtitle}', '%{copyright}'],
            },
        },
    },
};

my $backend3 = ChordPro::Output::HTML5->new(
    config => $config_complex,
    options => { output => undef },
);

my $css3 = $backend3->generate_paged_css();
like($css3, qr/string\(song-artist\)/, "Artist metadata");
like($css3, qr/string\(song-album\)/, "Album metadata");
like($css3, qr/string\(song-subtitle\)/, "Subtitle metadata");

# =================================================================
# Test 6: Empty and false formats
# =================================================================

my $config_empty = {
    %$config,
    html5 => { mode => 'print' },
    pdf => {
        formats => {
            first => {
                footer => 0,
            },
            filler => {
                title => 0,
                footer => 0,
            },
        },
    },
};

my $backend4 = ChordPro::Output::HTML5->new(
    config => $config_empty,
    options => { output => undef },
);

my $css4 = $backend4->generate_paged_css();
# Empty formats should not generate margin boxes for that page type
ok($css4, "CSS generated with false formats");

# =================================================================
# Test 7: Song metadata in headers with actual song
# =================================================================

my $song_data = <<'EOD';
{title: My Test Song}
{subtitle: A Wonderful Subtitle}
{artist: Test Artist}

{start_of_verse}
[C]Test lyrics
{end_of_verse}
EOD

my $sb = ChordPro::Songbook->new;
$sb->parse_file(\$song_data, { nosongline => 1 });
my $song = $sb->{songs}[0];

# Generate HTML with song and check metadata is available
my $html = $backend->generate_song($song);
like($html, qr/data-title="My Test Song"/, "Song has title metadata attribute")
    or diag("HTML doesn't contain expected metadata");

