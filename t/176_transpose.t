#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use ChordPro::Testing;
use ChordPro::Utils qw( :xp );
use ChordPro::Chords::Transpose ();

plan tests => 3 * ( 10+14+4+18+18+1+1);

use ChordPro::Song;
my $s = ChordPro::Song->new;

our $config;

sub test($$$) {
    my ( $left, $right, $xp ) = @_;
    my $id = "$left $right $xp";
    my $l = parse_transpose($left);
    ok( defined $l, "$id: parse $left -> " . $l->_data_printer );
    my $r = parse_transpose($right);
    ok( defined $r, "$id: parse $right -> " . $r->_data_printer  );
    my $res = $l + $r;
    is( "$res",     $xp,     "$id: $left $right $res <> $xp");
}

# Extended version of ChordPro::Chords::Transpose::parse_transpose.
sub parse_transpose {
    my ( $xp ) = @_;

    return unless $xp =~ m;^([-+]?\d+)([s#♯fb♭k]?)\s*(.*)$;;

    my $res = ChordPro::Chords::Transpose::parse_transpose($1.$2);
    return unless defined $res;
    $res->set_key( $s->parse_chord($3) ) if $3;

    return $res;
}

# None.
test(   "0",   "0",   "0" );
test(   "1",   "0",   "+1+" );
test(   "0",   "1",   "+1+" );
# Follows.
test(   "1",   "1",   "+2+" );
# Implicit does not overrule implicit
test(   "2",  "-1",    "+1+" );
test(   "-2",   "1",  "-1-" );
# Implicit does not overrule explicit.
test(  "1f",  "1",    "+2f-" );
# Explicit overrules implicit.
test(  "1",   "1f",   "+2f-" );
test(  "1b",  "1#",   "+2s+" );
test(  "1♯",  "1♭",  "+2f-" );

# Sharps.
# Default behaviour is to enforce common notations (e.g. Bb instead of A#).
# With an exception for F# (depends on keys.flats).
for ( qw( D E ), "F#", "Gb", qw( G A B ) ) {
    my $k = $_;
    $k = "F#" if $k eq "Gb";
    test( "0k$_",  "0",  "0k$k+" );
    test( "0s$_",  "0k", "0k$k+" );
    test( "0f$_",  "0k", "0k$k+" );
}
{
    local $::config->{keys}->{flats} = 1;
    # Without exception for F#.
    for ( "C#", "Db", "F#", "Gb" ) {
	my $k = $_;
	$k = "Db" if $k eq "C#";
	$k = "Gb" if $k eq "F#";
	test( "0k$_",  "0",  "0k$k-" );
	test( "0s$_",  "0k", "0k$k-" );
	test( "0f$_",  "0k", "0k$k-" );
    }
}

# Flats.
for ( qw( C ), "C#", qw( Db Eb F Ab Bb ) ) {
    my $k = $_;
    my $d = "-";
    $k = "Db" if $k eq "C#";
    $d = "+" if $k eq "C";
    test( "0k$_",  "0",  "0k$k$d" );
    test( "0s$_",  "0k", "0k$k$d" );
    test( "0f$_",  "0k", "0k$k$d" );
}

#
test(  0, -4, "-4-" );

#$config->{keys}->{flats} = 1;
test( "0 C", "+6k", "+6kC+" );
