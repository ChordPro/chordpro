#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Config;

plan tests => 16+3;

sub Config::new {
    my ( $pkg, $init ) = @_;
    bless { %$init } => 'ChordPro::Config';
}

# Array merge.
*amerge = \&ChordPro::Config::amerge;
is_deeply( amerge([],         [qw(x y z)]),         [qw(x y z)] );
is_deeply( amerge([qw(a b c)],[qw(x y z)]),         [qw(x y z)] );
is_deeply( amerge([qw(a b c)],[qw(prepend x y z)]), [qw(x y z a b c)] );
is_deeply( amerge([qw(a b c)],[qw(prepend)]),       [qw(a b c)] );
is_deeply( amerge([qw(a b c)],[qw(append x y z)]),  [qw(a b c x y z)] );
is_deeply( amerge([qw(a b c)],[qw(append)]),        [qw(a b c)] );
is_deeply( amerge([qw(a b c)],[]),                  [] );

# Upgrade non-array to [array].
is_deeply( amerge([qw(a b c)],'x'),                 [qw(x)] );
is_deeply( amerge([qw(a b c)],{ x => 'y'} ),        [ { x => 'y' } ] );
is_deeply( amerge(undef,      'x'),                 [qw(x)] );

# Modifying the array.
is_deeply( amerge([qw(a b c)],{'<' =>'x'}),         [qw(x a b c)] );
is_deeply( amerge([qw(a b c)],{'<1'=>'x'}),         [qw(a x b c)] );
is_deeply( amerge([qw(a b c)],{ '1'=>'x'}),         [qw(a x c)] );
is_deeply( amerge([qw(a b c)],{'>1'=>'x'}),         [qw(a b x c)] );
is_deeply( amerge([qw(a b c)],{'>' =>'x'}),         [qw(a b c x)] );
is_deeply( amerge([qw(a b c)],{'-1'=>'x'}),         [qw(a b x)] );


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

