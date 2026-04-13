#! perl

use strict;

if ( -d "t" ) {
    chdir "t";
    $0 =~ s;(^|/)t/;$1;;
}

@::params = qw( 060 060_transpose crd );

require "./000_basic.pl";
