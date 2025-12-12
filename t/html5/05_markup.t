#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Songbook;

plan tests => 18;

use_ok('ChordPro::Output::HTML5');

# Create HTML5 backend
my $html5 = ChordPro::Output::HTML5->new(
    config => $config,
    options => { output => undef },
);
ok($html5, "HTML5 object created");

# Test markup processing method exists
can_ok($html5, 'process_text_with_markup');

# Test plain text (no markup)
{
    my $plain = "Hello World";
    my $result = $html5->process_text_with_markup($plain);
    is($result, "Hello World", "Plain text unchanged");
}

# Test basic bold markup
{
    my $bold = "<b>Bold text</b>";
    my $result = $html5->process_text_with_markup($bold);
    like($result, qr/font-weight:bold/, "Bold markup rendered");
    like($result, qr/Bold text/, "Bold text content preserved");
}

# Test italic markup
{
    my $italic = "<i>Italic text</i>";
    my $result = $html5->process_text_with_markup($italic);
    like($result, qr/font-style:italic/, "Italic markup rendered");
}

# Test color markup
{
    my $colored = '<span color="red">Red text</span>';
    my $result = $html5->process_text_with_markup($colored);
    like($result, qr/color:red/, "Color markup rendered");
}

# Test hex color
{
    my $hex = '<span foreground="#FF0000">Hex color</span>';
    my $result = $html5->process_text_with_markup($hex);
    like($result, qr/color:#ff0000/i, "Hex color markup rendered");
}

# Test background color
{
    my $bg = '<span background="yellow">Highlighted</span>';
    my $result = $html5->process_text_with_markup($bg);
    like($result, qr/background-color:yellow/, "Background color markup rendered");
}

# Test size markup
{
    my $sized = '<span size="larger">Large text</span>';
    my $result = $html5->process_text_with_markup($sized);
    like($result, qr/font-size:/, "Size markup rendered");
}

# Test subscript
{
    my $sub = 'H<sub>2</sub>O';
    my $result = $html5->process_text_with_markup($sub);
    like($result, qr/font-size:.*2.*O/, "Subscript rendered");
}

# Test superscript
{
    my $sup = 'E=mc<sup>2</sup>';
    my $result = $html5->process_text_with_markup($sup);
    like($result, qr/font-size:.*2/, "Superscript rendered");
}

# Test underline
{
    my $underline = '<u>Underlined text</u>';
    my $result = $html5->process_text_with_markup($underline);
    like($result, qr/text-decoration-line:underline/, "Underline markup rendered");
}

# Test strikethrough
{
    my $strike = '<s>Strikethrough text</s>';
    my $result = $html5->process_text_with_markup($strike);
    like($result, qr/text-decoration-line:line-through/, "Strikethrough markup rendered");
}

# Test combined markup
{
    my $combined = '<span color="blue" weight="bold">Blue bold</span>';
    my $result = $html5->process_text_with_markup($combined);
    like($result, qr/color:blue/, "Combined markup - color preserved");
    like($result, qr/font-weight:bold/, "Combined markup - bold preserved");
}

# Test HTML escaping of plain text
{
    my $html_chars = "Text with <>&\"' characters";
    my $result = $html5->process_text_with_markup($html_chars);
    like($result, qr/&lt;/, "< escaped in plain text");
}

