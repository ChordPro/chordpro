#!/usr/bin/perl

package ChordPro::Output::Debug;

use strict;
use warnings;
use Data::Dumper;

sub generate_songbook {
    my ( $self, $sb ) = @_;

    if ( ( $::options->{'backend-option'}->{structure} // '' ) eq 'structured' ) {
	foreach ( @{$sb->{songs}} ) {
	    $_->structurize;
	}
    }
    $Data::Dumper::Sortkeys = 1;
    $Data::Dumper::Indent = 1;
    my @book;
    push( @book, Data::Dumper->Dump( [ $sb, $::options ], [ "song", "options" ] ) );
    \@book;
}

1;
