#! perl

use strict;

if ( -d "t" ) {
    chdir "t";
    $0 =~ s;(^|/)t/;$1;;
}

@::params = qw( 021 basic02 crd );

require "./000_basic.pl";
