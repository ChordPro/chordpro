#!/usr/bin/perl

package ChordPro::Output::JSON;

use strict;
use warnings;
use JSON::PP;

sub generate_songbook {
    my ( $self, $sb ) = @_;
    my @book;
    my $pp = JSON::PP->new->canonical->indent(4)->utf8(0)->pretty;
    $pp->convert_blessed;

    *UNIVERSAL::TO_JSON = sub {
        my $obj = "".$_[0];
        return $obj =~ /=HASH\(/
          ? { %{$_[0]} }
            : $obj =~ /=ARRAY\(/
              ? [ @{$_[0]} ]
                : undef
                  ;
    };

    my $json = $pp->encode($sb);
    [ split(/\n/, $json) ];
}

1;
