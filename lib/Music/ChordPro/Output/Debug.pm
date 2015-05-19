#!/usr/bin/perl

package Music::ChordPro::Output::Debug;

use strict;
use warnings;
use Data::Dumper;

sub generate_songbook {
    my ($self, $sb, $options) = @_;
    my @book;

    push( @book, Data::Dumper->Dump( [ $sb, $options ], [ "song", "options" ] ) );
    \@book;
}

1;
