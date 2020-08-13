#! perl

use strict;

if ( -d "t" ) {
    chdir "t";
    $0 =~ s;(^|/)t/;$1;;
}

@::params = qw( 40 basic01 html );

require "./00_basic.pl";
