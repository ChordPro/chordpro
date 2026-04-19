#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Songbook;

plan tests => 23;

use_ok('ChordPro::Output::HTML5');

# Test: PDF Config Compatibility
# Validates theme colors, spacing, chorus bars, and grid styling

# =============================================================================
# Test 1: Theme Color Resolution with Defaults
# =============================================================================

my $backend1 = ChordPro::Output::HTML5->new(
    config => { %$config, html5 => { mode => 'print' } },
    options => { output => undef },
);

my $theme1 = $backend1->_resolve_theme_colors();
ok($theme1, "Theme colors resolved");
is($theme1->{foreground}, 'black', "Default foreground is black");
is($theme1->{'foreground-medium'}, 'grey70', "Default foreground-medium is grey70");
is($theme1->{'foreground-light'}, 'grey90', "Default foreground-light is grey90");
is($theme1->{background}, 'none', "Default background is none");

# =============================================================================
# Test 2: Spacing Resolution with Defaults
# =============================================================================

my $spacing1 = $backend1->_resolve_spacing();
ok($spacing1, "Spacing resolved");
is($spacing1->{title}, 1.2, "Default title spacing is 1.2");
is($spacing1->{lyrics}, 1.2, "Default lyrics spacing is 1.2");
is($spacing1->{chords}, 1.2, "Default chords spacing is 1.2");
is($spacing1->{grid}, 1.2, "Default grid spacing is 1.2");
is($spacing1->{tab}, 1, "Default tab spacing is 1.0");

# =============================================================================
# Test 3: Chorus Styles Resolution with Defaults
# =============================================================================

my $chorus1 = $backend1->_resolve_chorus_styles();
ok($chorus1, "Chorus styles resolved");
is($chorus1->{indent}, 0, "Default chorus indent is 0");
is($chorus1->{bar_offset}, 8, "Default bar offset is 8");
is($chorus1->{bar_width}, 1, "Default bar width is 1");
is($chorus1->{bar_color}, 'black', "Default bar color resolves to theme foreground");

# =============================================================================
# Test 4: Grid Styles Resolution with Defaults
# =============================================================================

my $grid1 = $backend1->_resolve_grid_styles();
ok($grid1, "Grid styles resolved");
is($grid1->{symbols_color}, 'blue', "Default symbols color is blue");
is($grid1->{volta_color}, 'blue', "Default volta color is blue");

# =============================================================================
# Test 5: Color Conversion Helper
# =============================================================================

is($backend1->_convert_color_to_css('#FF0000'), '#FF0000', "Hex color passes through");
is($backend1->_convert_color_to_css('red'), 'red', "Named color passes through");
is($backend1->_convert_color_to_css('rgb(255,0,0)'), 'rgb(255,0,0)', "RGB color passes through");

1;
