#! perl

use strict;

package ChordPro::Logger;

use feature 'signatures';
no warnings 'experimental::signatures';

use Carp;
$Carp::Internal{ (__PACKAGE__) }++;

# die    => fatal
# warn ? => error
# warn ! => warning
# warn   => informational

sub _warn(@msg) {
    __warn( \&CORE::warn, @msg );
}
sub _die(@msg) {
    __warn( \&CORE::die, @msg );
}

sub __warn( $proc, @msg ) {
    my $msg = shift(@msg);
    $msg =~ s/^[?!]//;
    if ( $ENV{CHORDPRO_CARP_VERBOSE} ) {
	$msg .= join( '', @msg );
	$msg =~ s/\n+$//;
	Carp::cluck( $msg );
    }
    else {
	$msg .= "@msg";
	if ( $msg =~ /\n$/ ) {
	    $msg = Carp::shortmess($msg);
	    chomp($msg);
	    $msg =~ s/ at .*line \d+.$//;
	}
	else {
	    chomp($msg);
	    $msg = Carp::shortmess($msg);
	    chomp($msg);
	}
	$proc->($msg);
    }
}

BEGIN {
    *CORE::GLOBAL::warn = \&_warn;
    *CORE::GLOBAL::die = \&_die;
}

1;

package main;

unless ( caller ) {
    require Carp;
    sub a($x) { b($x) }
    sub b($x) { c($x) }
    sub c($x) { Carp::cluck($x) }
    a("Hi");
}

