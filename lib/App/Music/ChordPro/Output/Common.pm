#!/usr/bin/perl

package App::Music::ChordPro::Output::Common;

use strict;
use warnings;
use App::Music::ChordPro::Chords;
use String::Interpolate::Named;
use utf8;

sub fmt_subst {
    my ( $s, $t ) = @_;
    my $res = "";
    my $m = $s->{meta};

    # Derived item(s).
    $m->{_key} = $m->{key} if exists $m->{key};
    if ( $m->{key} && $m->{capo} && (my $capo = $m->{capo}->[-1]) ) {
	$m->{_key} =
	  [ map { App::Music::ChordPro::Chords::transpose( $_, $capo ) }
	        @{$m->{key}} ];
    }

    interpolate( { %$s, args => $m,
		   separator => $::config->{metadata}->{separator} },
		 $t );
}

1;
