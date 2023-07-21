#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Songbook;
use ChordPro::Song;

$config->{debug}->{chords} = 0;
$config->{debug}->{x1} = 0;
bless $config => ChordPro::Config::;
my $tests = 0;

my $sb = ChordPro::Songbook->new;
my $s = ChordPro::Song->new;

my $info = $s->parse_chord("Am7");
my $chord = $info->name;
is ( $info->name, "Am7", "$chord name" );
is ( $info->root, "A", "$chord root" );
is ( $info->qual, "m", "$chord qual" );
is ( $info->ext,  "7", "$chord ext" );
is ( $info->bass, "",  "$chord bass" );
is ( $info->canonical,   "Am7", "show $chord" );
is ( $info->chord_display, "Am7", "display $chord" );
$tests += 7;

$info = $s->parse_chord("Bes");
$chord = $info->name;
is ( $info->name, "Bes", "$chord name" );
is ( $info->root, "Bes", "$chord root" );
is ( $info->qual, "", "$chord qual" );
is ( $info->ext,  "", "$chord ext" );
is ( $info->bass, "",  "$chord bass" );
is ( $info->canonical,   "Bb", "show $chord" );
is ( $info->chord_display, "Bes", "display $chord" );
is ( $info->base, undef, "no base for $chord" );
$tests += 8;

my $def = "Bes";
$s->define_chord( "define", $def );
$info = $s->parse_chord("Bes");
$chord = $info->name;
is ( $info->name, "Bes", "$chord name" );
is ( $info->root, "Bes", "$chord root" );
is ( $info->qual, "", "$chord qual" );
is ( $info->ext,  "", "$chord ext" );
is ( $info->bass, "",  "$chord bass" );
is ( $info->canonical,   "Bb", "show $chord" );
is ( $info->chord_display, "Bes", "display $chord" );
is ( $info->base, 1, "$chord base" );
$tests += 8;

$def .= " base-fret 2";
$s->define_chord( "define", $def );
$info = $s->parse_chord("Bes");
$chord = $info->name;
is ( $info->name, "Bes", "$chord name" );
is ( $info->root, "Bes", "$chord root" );
is ( $info->qual, "", "$chord qual" );
is ( $info->ext,  "", "$chord ext" );
is ( $info->bass, "",  "$chord bass" );
is ( $info->canonical,   "Bb", "show $chord" );
is ( $info->chord_display, "Bes", "display $chord" );
is ( $info->base, 2, "$chord base" );
$tests += 8;

$def .= " frets 0 0 1 1 1 0";
$s->define_chord( "define", $def );
$info = $s->parse_chord("Bes");
$chord = $info->name;
is ( $info->name, "Bes", "$chord name" );
is_deeply ( $info->frets, [0,0,1,1,1,0], "$chord frets" );
$tests += 2;

$def .= " fingers 1 1 2 3 4 1";
$s->define_chord( "define", $def );
$info = $s->parse_chord("Bes");
$chord = $info->name;
is ( $info->name, "Bes", "$chord name" );
is_deeply ( $info->fingers, [1,1,2,3,4,1], "$chord fingers" );
$tests += 2;

$def .= " keys 4 7 0";
$s->define_chord( "define", $def );
$info = $s->parse_chord("Bes");
$chord = $info->name;
is ( $info->name, "Bes", "$chord name" );
is_deeply ( $info->kbkeys, [4,7,0], "$chord keys" );
$tests += 2;

for ( qw( on true 1 ) ) {
    $s->define_chord( "define", "$def diagram $_" );
    $info = $s->parse_chord("Bes");
    is ( $info->diagram, undef, "diagram $_ stripped" );
    $tests++;
}

for ( qw( off false 0 ) ) {
    $s->define_chord( "define", "$def diagram $_" );
    $info = $s->parse_chord("Bes");
    is ( $info->diagram, 0, "diagram $_ is 0" );
    $tests++;
}

$s->define_chord( "define", "$def diagram red" );
$info = $s->parse_chord("Bes");
$chord = $info->name;
is ( $info->diagram, "red", "$chord diagram" );
$tests++;


done_testing($tests);
