#! perl

use strict;

if ( -d "t" ) {
    chdir "t";
    $0 =~ s;(^|/)t/;$1;;
}

@::params = qw( 60 60_transpose crd );

require "./00_basic.pl";
