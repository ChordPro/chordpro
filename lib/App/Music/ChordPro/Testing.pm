#! perl

use strict;
use warnings;
use utf8;
use Carp;

package App::Music::ChordPro::Testing;

use base 'Exporter';
our @EXPORT;
use Test::More ();

sub import {
    my $pkg = shift;
    Test::More->export_to_level(1);
    $pkg->export_to_level( 1, @EXPORT );
}

sub is_deeply {
    my ( $got, $expect, $tag ) = @_;

    if ( ref($got) eq 'HASH' && ref($expect) eq 'HASH' ) {
	for ( qw( config ) ) {
	    delete $got->{$_} unless exists $expect->{$_};
	}
    }

    Test::More::is_deeply( $got, $expect, $tag );
}

push( @EXPORT, 'is_deeply' );

1;
