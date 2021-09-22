#! perl

use strict;

if ( -d "t" ) {
    chdir "t";
    $0 =~ s;(^|/)t/;$1;;
}

@::params = qw( 30 basic01 cho );

require "./00_basic.pl";
