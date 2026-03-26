#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use ChordPro::Testing;
use ChordPro::Utils qw( :xp );
use ChordPro::Chords::Transpose;

plan tests => 5 * (10+14+4+1);

use ChordPro::Song;
my $s = ChordPro::Song->new;

sub t {
    my ( $id, $left, $right, $xp, $dir, $forced ) = @_;
    my $key;
    if ( $left =~ /^(.+k)(.*)/ ) {
	$key = $2;
	$left = $1
    }
    my $l = parse_transpose($left);
    $l->set_key( $s->parse_chord($key) ) if $key;
    ok( defined $l, "$id: parse $left -> " . $l->_data_printer );
    $key = undef;
    if ( $right =~ /^(.+k)(.*)/ ) {
	$key = $2;
	$right = $1
    }
    my $r = parse_transpose($right);
    $r->set_key( $s->parse_chord($key) ) if $key;
    ok( defined $r, "$id: parse $right -> " . $r->_data_printer  );
    my $res = $l + $r;
    is( $res->xp,     $xp,     "$id: $res (xp " . $res->xp .     " <> $xp)" );
    is( $res->dir,    $dir,    "$id: $res (dir " . $res->dir .    " <> $dir)" );
    is( $res->forced, $forced, "$id: $res (forced " . $res->forced . " <> $forced)" );
}

# None.
t( " 0  0 0",   "0",   "0",     0,  0,  XP_FOLLOW );
t( " 1  0 1",   "1",   "0",     1,  1,  XP_FOLLOW );
t( " 0  1 1",   "0",   "1",     1,  1,  XP_FOLLOW );
# Follows.
t( " 1  1  2",   "1",   "1",    2,  1,  XP_FOLLOW );
# Implicit does not overrule implicit
t( " 2 -1  1",   "2",  "-1",    1 , 1,  XP_FOLLOW );
t( "-2  1 -1",   "-2",   "1",  -1, -1,  XP_FOLLOW );
# Implicit does not overrule explicit.
t( " 1f 1  2f",  "1f",  "1",    2, -1,  XP_FLAT );
# Explicit overrules implicit.
t( " 1  1f 2f",  "1",   "1f",   2, -1,  XP_FLAT );
t( " 1b 1# 2s",  "1b",  "1#",   2,  1,  XP_SHARP );
t( " 1♯ 1♭ 2s",  "1♯",  "1♭",  2, -1,  XP_FLAT );

# Sharps.
# Default behaviour is to enforce common notations (e.g. Bb instead of A#).
# With an exception for C# and F#.
for ( qw( D E ), "F#", "Gb", qw( G A B ) ) {
    t( " 0k$_ 0 0", "0k$_", "0", 0, 1, XP_KEY );
}
{
    local $::config->{keys}->{flats} = 1;
    # Without exception for C# and F#.
    for ( "C#", "Db", "F#", "Gb" ) {
	t( " 0k$_ 0 0", "0k$_", "0", 0, -1, XP_KEY );
    }
}

# Flats.
for ( qw( C ), "C#", qw( Db Eb F Ab Bb ) ) {
    t( " 0k$_ 0 0", "0k$_", "0k", 0, -1, XP_KEY );
}

#
t( " 0  -4 -4",   "0",   "-4",    -4,  -1,  XP_FOLLOW );
