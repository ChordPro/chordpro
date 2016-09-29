#!/usr/bin/perl

package App::Music::ChordPro::Output::Common;

use strict;
use warnings;

# Substitute %X sequences in title formats.
sub fmt_subst {
    my ( $s, $t, $strict ) = @_;
    my $res = "";
    my $m = $s->{meta};
    while ( $t =~ /^(.*?)\%(.)(.*)/ ) {
	$res .= $1;
	$t = $3;
	my $f = $2;

	if ( $f eq '{' && $t =~ /^(.*?)\}(.*)/ ) {
	    my ( $key, $rest ) = ( lc($1), $2 );
	    ( $key, my $inx ) = ( $1, $2 ) if $key =~ /^(.*)\.(\d+)$/;
	    if ( defined $m->{$key} ) {
		if ( $inx ) {
		    if ( $inx > 0 && $inx <= @{ $m->{$key} } ) {
			$res .= $m->{$key}->[$inx-1];
		    }
		}
		else {
		    $res .= join( $::config->{metadata}->{separator}, @{ $m->{$key} } );
		}
	    }
	    $t = $rest;
	    next;
	}
	next if $strict;

	if ( $f eq '%' ) {
	    $res .= '%';
	}
	elsif ( $f eq 't' ) {
	    $res .= $m->{title}->[0] if $m->{title}->[0];
	}
	elsif ( $f eq 's' ) {
	    $res .= $m->{subtitle}->[0] if $m->{subtitle}->[0];
	}
	elsif ( $f eq 'p' ) {
	    $res .= $s->{page} if $s->{page};
	}
	elsif ( $f eq 'P' ) {
	    $res .= $s->{page};	####FIXME
	}
	else {
	    warn("Ignoring unknown %$f sequence in title.");
	}
    }
    $res . $t;
}

1;
