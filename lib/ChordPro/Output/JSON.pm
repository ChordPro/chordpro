#!/usr/bin/perl

package ChordPro::Output::JSON;

use strict;
use warnings;
use JSON::PP;
use Ref::Util qw( is_hashref is_arrayref );

sub generate_songbook {
    my ( $self, $sb ) = @_;
    my @book;
    my $pp = JSON::PP->new->canonical->indent(4)->utf8(0)->pretty;
    $pp->convert_blessed;

    *UNIVERSAL::TO_JSON = sub {
	if ( JSON::PP::is_bool($_[0]) ) {
	    return $_[0] ? "true" : "false"
	}
        return is_hashref($_[0])
          ? { %{$_[0]} }
            : is_arrayref($_[0])
              ? [ @{$_[0]} ]
                : "OBJ($_[0])"
                  ;
    };

    my $json = $pp->encode( { sb => $sb });

    return [ split(/\n/, $json) ];
}

1;
