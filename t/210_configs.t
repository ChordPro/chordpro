#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use App::Music::ChordPro::Testing;
use App::Music::ChordPro::Config;

plan tests => 3;

sub Config::new {
    my ( $pkg, $init ) = @_;
    bless { %$init } => 'App::Music::ChordPro::Config';
}

# Original content.
my $orig = Config->new
  ( { a => { b => [ 'c', 'd' ], e => [[ 'f' ]] }, g => { h => 1, i => 1 } } );

# Actual content, initially a copy of original content.
my $actual = Config->new
  ( { a => { b => [ 'c', 'd' ], e => [[ 'f' ]] }, g => { h => 1, i => 1 } } );

# Augmentation hash.
my $aug = { a => { b => [ 'prepend', 'x' ], e => [ [ 'g' ] ] }, g => { i => 2 } };

# Expected new content.
my $new = Config->new
  ( { a => { b => [ 'x', 'c', 'd' ], e => [[ 'g' ]] }, g => { h => 1, i => 2 } } );

is_deeply( $orig, $actual, "orig = actual" );

$actual->augment($aug);
is_deeply( $actual, $new, "augmented" );

$actual->reduce($orig);
is_deeply( $actual, $aug, "reduced" );
