#! perl

use strict;

package ChordPro::Logger;

use feature 'signatures';
no warnings 'experimental::signatures';

# die    => fatal
# warn ? => error
# warn ! => warning
# warn   => informational

sub _warn(@msg) {
    my $msg = shift(@msg);
    $msg =~ s/^[?!]//;
    if ( $ENV{CHORDPRO_CARP_VERBOSE} ) {
	$msg .= join( '', @msg );
	$msg =~ s/\n+$//;
	Carp::cluck( $msg );
    }
    else {
	CORE::warn( $msg, @msg );
    }
}

sub _die(@msg) {
    my $msg = shift(@msg);
    $msg =~ s/^[?!]//;		# ignore, it's fatal anyway
    if ( $ENV{CHORDPRO_CARP_VERBOSE} ) {
	$msg .= join( '', @msg );
	$msg =~ s/\n+$//;
	Carp::croak( $msg );
    }
    else {
	CORE::die( $msg, @msg );
    }
}

BEGIN {
    *CORE::GLOBAL::warn = \&_warn;
    *CORE::GLOBAL::die = \&_die;
}

1;

package main;

unless ( caller ) {
    use Carp qw(carp verbose);
    sub a($x) { b($x) }
    sub b($x) { c($x) }
    sub c($x) { carp($x) }
    a("Hi");
}

