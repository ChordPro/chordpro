#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Paths;

plan tests => 13;

for my $face ( qw( ChordPro ) ) {
    for my $style ( qw( Symbols ) ) {
	my $font = "$face$style.ttf";
	ok( -s CP->findres( $font, class => "fonts" ), $font );
    }
}

for my $face ( qw( Serif ) ) {
    for my $style ( "", qw( Bold Italic BoldItalic ) ) {
	my $font = "Free$face$style.ttf";
	ok( -s CP->findres( $font, class => "fonts" ), $font );
    }
}

for my $face ( qw( Sans Mono ) ) {
    for my $style ( "", qw( Bold Oblique BoldOblique ) ) {
	my $font = "Free$face$style.ttf";
	ok( -s CP->findres( $font, class => "fonts" ), $font );
    }
}
