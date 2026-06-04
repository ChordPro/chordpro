#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Songbook;

plan tests => 13;

use_ok('ChordPro::Output::HTML5');

# Test configuration with headers/footers
my $test_config = {
    %$config,
    pdf => {
        formats => {
            'first' => {
                'header' => [
                    ['%{title}', '', 'Page %{page}'],
                ],
                'footer' => [
                    ['', 'First Page', ''],
                ],
            },
            'default' => {
                'header' => [
                    ['%{title}', '', '%{page}'],
                ],
                'footer' => [
                    ['', '%{subtitle}', ''],
                ],
            },
        },
    },
};

my $paged = ChordPro::Output::HTML5->new(
    config => $test_config,
    options => { output => undef },
);
ok($paged, "HTML5 with custom config created");

# Test _format_content_string method
can_ok($paged, '_format_content_string');

# Test simple text
{
    my $result = $paged->_format_content_string('Hello');
    is($result, '"Hello"', "Simple text formatted");
}

# Test %{page} substitution
{
    my $result = $paged->_format_content_string('Page %{page}');
    like($result, qr/counter\(page\)/, "Page counter substituted");
}

# Test %{title} substitution
{
    my $result = $paged->_format_content_string('%{title}');
    like($result, qr/string\(song-title\)/, "Title string substituted");
}

# Test %{artist} substitution
{
    my $result = $paged->_format_content_string('By %{artist}');
    like($result, qr/string\(song-artist\)/, "Artist string substituted");
}

# Test %{subtitle} substitution
{
    my $result = $paged->_format_content_string('%{subtitle}');
    like($result, qr/string\(song-subtitle\)/, "Subtitle string substituted");
}

# Test mixed content
{
    my $result = $paged->_format_content_string('%{title} - Page %{page}');
    like($result, qr/string\(song-title\)/, "Mixed - title part");
    like($result, qr/counter\(page\)/, "Mixed - page part");
}

# Test _generate_margin_boxes method exists
can_ok($paged, '_generate_margin_boxes');

# Test _generate_format_rule method exists
can_ok($paged, '_generate_format_rule');

# Test _generate_format_rules method exists
can_ok($paged, '_generate_format_rules');

# Note: Full headers/footers functionality is tested in 03_integration.t
# where we generate complete documents with @page rules

