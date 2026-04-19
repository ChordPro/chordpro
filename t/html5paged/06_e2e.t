#!/usr/bin/perl

# End-to-end test for HTML5 headers/footers
# Generates actual HTML output and verifies complete document structure

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Songbook;

plan tests => 13;

use_ok('ChordPro::Output::HTML5');

# =================================================================
# Create test configuration with complete format specification
# =================================================================

my $test_config = {
    %$config,
    html5 => { mode => 'print' },
    pdf => {
        papersize => 'a4',
        margintop => 80,
        marginbottom => 40,
        marginleft => 40,
        marginright => 40,
        formats => {
            default => {
                title => ['', '', ''],
                subtitle => ['', '', ''],
                footer => ['%{title}', '', 'Page %{page}'],
            },
            title => {
                title => ['', '%{title}', ''],
                subtitle => ['', '%{subtitle}', ''],
                footer => ['%{artist}', '', 'Page %{page}'],
            },
            first => {
                footer => ['', 'First Page', ''],
            },
        },
    },
};

# =================================================================
# Create test songbook with multiple songs
# =================================================================

my $song1_data = <<'EOD';
{title: Amazing Grace}
{subtitle: Traditional Hymn}
{artist: John Newton}

{start_of_verse}
[G]Amazing grace, how [C]sweet the [G]sound
That saved a wretch like [D]me
[G]I once was lost, but [C]now I'm [G]found
Was blind but [D]now I [G]see
{end_of_verse}

{start_of_chorus}
[G]How sweet the [D]sound
[G]That saved a [C]wretch like [G]me
{end_of_chorus}
EOD

my $song2_data = <<'EOD';
{title: Swing Low Sweet Chariot}
{subtitle: Spiritual}
{artist: Traditional}

{start_of_verse}
[D]Swing low, sweet [G]chari[D]ot
Comin' for to carry me [A7]home
[D7]Swing low, sweet [G]chari[D]ot
Comin' for to [A7]carry me [D]home
{end_of_verse}
EOD

# Parse songbook
my $sb = ChordPro::Songbook->new;
$sb->parse_file(\$song1_data, { nosongline => 1 });
$sb->parse_file(\$song2_data, { nosongline => 1 });

ok(scalar(@{$sb->{songs}}) == 2, "Two songs parsed");

# =================================================================
# Generate complete HTML document
# =================================================================

my $backend = ChordPro::Output::HTML5->new(
    config => $test_config,
    options => { output => undef },
);

my $html_lines = ChordPro::Output::HTML5->generate_songbook($sb);
ok($html_lines, "Songbook generated");

my $html = join('', @$html_lines);
ok(length($html) > 0, "HTML has content");

# =================================================================
# Test document structure
# =================================================================

like($html, qr/<!DOCTYPE html>/i, "Has HTML5 doctype");
like($html, qr/<script.*pagedjs/i, "Includes paged.js script");
like($html, qr/<style>/i, "Has style section");

# =================================================================
# Test @page CSS rules are present
# =================================================================

like($html, qr/\@page\s+\{/, "Has \@page rule");
like($html, qr/\@bottom-left/, "Has \@bottom-left margin box");
like($html, qr/counter\(page\)/, "Has page counter");

# =================================================================
# Test song metadata in HTML
# =================================================================

like($html, qr/data-title="Amazing Grace"/, "First song has metadata attribute");
like($html, qr/data-title="Swing Low Sweet Chariot"/, "Second song has metadata attribute");

# =================================================================
# Test string-set CSS declarations
# =================================================================

like($html, qr/string-set:\s*song-title\s+attr\(data-title\)/, "Has string-set for song-title");

