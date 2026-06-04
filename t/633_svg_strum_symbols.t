#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Test::More;
use ChordPro::Testing;
use ChordPro::Symbols qw(symbol);
use ChordPro::Output::SVG::Strum::SVGPrimitives;
use ChordPro::Output::SVG::Strum::Tokens;
use ChordPro::Output::SVG::Strum::StrumlineRenderer;

plan tests => 8;

is(
    ChordPro::Output::SVG::Strum::SVGPrimitives::svg_font_stack(),
    'ChordProSymbols',
    'SVG strum font stack defaults to ChordProSymbols'
);

my $svg = ChordPro::Output::SVG::Strum::StrumlineRenderer::strumline_svg_from_text(
    text => '|: d+ :|',
    show_bars => 1,
);

like(
    $svg,
    qr/style="font-family:ChordProSymbols"/,
    'Strumline SVG root uses ChordProSymbols'
);

is(
    ChordPro::Output::SVG::Strum::Tokens::bar_unicode('|'),
    symbol('bar'),
    'Single bar glyph comes from ChordPro::Symbols'
);

is(
    ChordPro::Output::SVG::Strum::Tokens::bar_unicode('||'),
    symbol('double-bar') . symbol('end-bar'),
    'Double bar fallback glyphs come from ChordPro::Symbols'
);

is(
    ChordPro::Output::SVG::Strum::Tokens::bar_unicode('|:'),
    symbol('repeat-start'),
    'Repeat-start glyph comes from ChordPro::Symbols'
);

is(
    ChordPro::Output::SVG::Strum::Tokens::bar_unicode(':|'),
    symbol('repeat-end'),
    'Repeat-end glyph comes from ChordPro::Symbols'
);

is(
    ChordPro::Output::SVG::Strum::Tokens::bar_unicode(':|:'),
    symbol('repeat-end') . symbol('repeat-start'),
    'Repeat-both fallback glyphs come from ChordPro::Symbols'
);

is(
    ChordPro::Output::SVG::Strum::Tokens::bar_unicode('|.'),
    symbol('end-bar'),
    'End-bar glyph comes from ChordPro::Symbols'
);
