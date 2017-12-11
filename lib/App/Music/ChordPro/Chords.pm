#! perl

package App::Music::ChordPro::Chords;

use strict;
use warnings;
use utf8;

################ Section: Built-In Chords ################

use constant CHORD_BUILTIN =>  0;
use constant CHORD_CONFIG  =>  1;
use constant CHORD_SONG    =>  2;
use constant N             => -1;
use constant TUNING	   => [ "E2", "A2", "D3", "G3", "B3", "E4" ];
use constant STRINGS	   => scalar(@{TUNING()});

my @builtin_chords =
(
 "C"	       => [  N, 3, 2, 0, 1, 0,	 1 ],
 "C+"	       => [  N, N, 2, 1, 1, 0,	 1 ],
 "C4"	       => [  N, N, 3, 0, 1, 3,	 1 ],
 "C6"	       => [  N, 0, 2, 2, 1, 3,	 1 ],
 "C7"	       => [  0, 3, 2, 3, 1, 0,	 1 ],
 "C9"	       => [  1, 3, 1, 2, 1, 3,	 8 ],
 "C9(11)"      => [  N, 3, 3, 3, 3, N,	 1 ],
 "C11"	       => [  N, 1, 3, 1, 4, 1,	 3 ],
 "Csus"	       => [  N, N, 3, 0, 1, 3,	 1 ],
 "Csus2"       => [  N, 3, 0, 0, 1, N,	 1 ],
 "Csus4"       => [  N, N, 3, 0, 1, 3,	 1 ],
 "Csus9"       => [  N, N, 4, 1, 2, 4,	 7 ],
 "Cmaj"	       => [  0, 3, 2, 0, 1, 0,	 1 ],
 "Cmaj7"       => [  N, 3, 2, 0, 0, 0,	 1 ],
 "Cm"	       => [  N, 1, 3, 3, 2, 1,	 3 ],
 "Cmin"	       => [  N, 1, 3, 3, 2, 1,	 3 ],
 "Cdim"	       => [  N, N, 1, 2, 1, 2,	 1 ],
 "C/B"	       => [  N, 2, 2, 0, 1, 0,	 1 ],
 "Cadd2/B"     => [  N, 2, 0, 0, 1, 0,	 1 ],
 "CaddD"       => [  N, 3, 2, 0, 3, 0,	 1 ],
 "C(addD)"     => [  N, 3, 2, 0, 3, 0,	 1 ],
 "Cadd9"       => [  N, 3, 2, 0, 3, 0,	 1 ],
 "C(add9)"     => [  N, 3, 2, 0, 3, 0,	 1 ],

 "C3"	       => [  N, 1, 3, 3, 2, 1,	 3 ],
 "Cm7"	       => [  N, 1, 3, 1, 2, 1,	 3 ],
 "Cm11"	       => [  N, 1, 3, 1, 4, N,	 3 ],

 "C#"	       => [  N, N, 3, 1, 2, 1,	 1 ],
 "C#+"	       => [  N, N, 3, 2, 2, 1,	 1 ],
 "C#4"	       => [  N, N, 3, 3, 4, 1,	 4 ],
 "C#7"	       => [  N, N, 3, 4, 2, 4,	 1 ],
 "C#7(b5)"     => [  N, 2, 1, 2, 1, 2,	 1 ],
 "C#sus"       => [  N, N, 3, 3, 4, 1,	 4 ],
 "C#sus4"      => [  N, N, 3, 3, 4, 1,	 4 ],
 "C#maj"       => [  N, 4, 3, 1, 1, 1,	 1 ],
 "C#maj7"      => [  N, 4, 3, 1, 1, 1,	 1 ],
 "C#dim"       => [  N, N, 2, 3, 2, 3,	 1 ],
 "C#m"	       => [  N, N, 2, 1, 2, 0,	 1 ],
 "C#min"       => [  N, N, 2, 1, 2, 0,	 1 ],
 "C#add9"      => [  N, 1, 3, 3, 1, 1,	 4 ],
 "C#(add9)"    => [  N, 1, 3, 3, 1, 1,	 4 ],
 "C#m7"	       => [  N, N, 2, 4, 2, 4,	 1 ],

 "Db"	       => [  N, N, 3, 1, 2, 1,	 1 ],
 "Db+"	       => [  N, N, 3, 2, 2, 1,	 1 ],
 "Db7"	       => [  N, N, 3, 4, 2, 4,	 1 ],
 "Dbsus"       => [  N, N, 3, 3, 4, 1,	 4 ],
 "Dbsus4"      => [  N, N, 3, 3, 4, 1,	 4 ],
 "Dbmaj"       => [  N, N, 3, 1, 2, 1,	 1 ],
 "Dbmaj7"      => [  N, 4, 3, 1, 1, 1,	 1 ],
 "Dbdim"       => [  N, N, 2, 3, 2, 3,	 1 ],
 "Dbm"	       => [  N, N, 2, 1, 2, 0,	 1 ],
 "Dbmin"       => [  N, N, 2, 1, 2, 0,	 1 ],
 "Dbm7"	       => [  N, N, 2, 4, 2, 4,	 1 ],

 "D"	       => [  N, N, 0, 2, 3, 2,	 1 ],
 "D+"	       => [  N, N, 0, 3, 3, 2,	 1 ],
 "D4"	       => [  N, N, 0, 2, 3, 3,	 1 ],
 "D6"	       => [  N, 0, 0, 2, 0, 2,	 1 ],
 "D7"	       => [  N, N, 0, 2, 1, 2,	 1 ],
 "D7#9"	       => [  N, 2, 1, 2, 3, 3,	 4 ],
 "D7(#9)"      => [  N, 2, 1, 2, 3, 3,	 4 ],
 "D9"	       => [  1, 3, 1, 2, 1, 3,	10 ],
 "D11"	       => [  3, 0, 0, 2, 1, 0,	 1 ],
 "Dsus"	       => [  N, N, 0, 2, 3, 3,	 1 ],
 "Dsus2"       => [  0, 0, 0, 2, 3, 0,	 1 ],
 "Dsus4"       => [  N, N, 0, 2, 3, 3,	 1 ],
 "D7sus2"      => [  N, 0, 0, 2, 1, 0,	 1 ],
 "D7sus4"      => [  N, 0, 0, 2, 1, 3,	 1 ],
 "Dmaj"	       => [  N, N, 0, 2, 3, 2,	 1 ],
 "Dmaj7"       => [  N, N, 0, 2, 2, 2,	 1 ],
 "Ddim"	       => [  N, N, 0, 1, 0, 1,	 1 ],
 "Dm"	       => [  N, N, 0, 2, 3, 1,	 1 ],
 "Dmin"	       => [  N, N, 0, 2, 3, 1,	 1 ],
 "D/A"	       => [  N, 0, 0, 2, 3, 2,	 1 ],
 "D/B"	       => [  N, 2, 0, 2, 3, 2,	 1 ],
 "D/C"	       => [  N, 3, 0, 2, 3, 2,	 1 ],
 "D/C#"	       => [  N, 4, 0, 2, 3, 2,	 1 ],
 "D/E"	       => [  N, 1, 1, 1, 1, N,	 7 ],
 "D/G"	       => [  3, N, 0, 2, 3, 2,	 1 ],
 "D5/E"	       => [  0, 1, 1, 1, N, N,	 7 ],
 "Dadd9"       => [  0, 0, 0, 2, 3, 2,	 1 ],
 "D(add9)"     => [  0, 0, 0, 2, 3, 2,	 1 ],
 "D9add6"      => [  1, 3, 3, 2, 0, 0,	10 ],
 "D9(add6)"    => [  1, 3, 3, 2, 0, 0,	10 ],

 "Dm6(5b)"     => [  N, N, 0, 1, 0, 1,	 1 ],
 "Dm7"	       => [  N, N, 0, 2, 1, 1,	 1 ],
 "Dm#5"	       => [  N, N, 0, 3, 3, 2,	 1 ],
 "Dm(#5)"      => [  N, N, 0, 3, 3, 2,	 1 ],
 "Dm#7"	       => [  N, N, 0, 2, 2, 1,	 1 ],
 "Dm(#7)"      => [  N, N, 0, 2, 2, 1,	 1 ],
 "Dm/A"	       => [  N, 0, 0, 2, 3, 1,	 1 ],
 "Dm/B"	       => [  N, 2, 0, 2, 3, 1,	 1 ],
 "Dm/C"	       => [  N, 3, 0, 2, 3, 1,	 1 ],
 "Dm/C#"       => [  N, 4, 0, 2, 3, 1,	 1 ],
 "Dm9"	       => [  N, N, 3, 2, 1, 0,	 1 ],

 "D#"	       => [  N, N, 3, 1, 2, 1,	 3 ],
 "D#+"	       => [  N, N, 1, 0, 0, 4,	 1 ],
 "D#4"	       => [  N, N, 1, 3, 4, 4,	 1 ],
 "D#7"	       => [  N, N, 1, 3, 2, 3,	 1 ],
 "D#sus"       => [  N, N, 1, 3, 4, 4,	 1 ],
 "D#sus4"      => [  N, N, 1, 3, 4, 4,	 1 ],
 "D#maj"       => [  N, N, 3, 1, 2, 1,	 3 ],
 "D#maj7"      => [  N, N, 1, 3, 3, 3,	 1 ],
 "D#dim"       => [  N, N, 1, 2, 1, 2,	 1 ],
 "D#m"	       => [  N, N, 4, 3, 4, 2,	 1 ],
 "D#min"       => [  N, N, 4, 3, 4, 2,	 1 ],
 "D#m7"	       => [  N, N, 1, 3, 2, 2,	 1 ],

 "Eb"	       => [  N, N, 3, 1, 2, 1,	 3 ],
 "Eb+"	       => [  N, N, 1, 0, 0, 4,	 1 ],
 "Eb4"	       => [  N, N, 1, 3, 4, 4,	 1 ],
 "Eb7"	       => [  N, N, 1, 3, 2, 3,	 1 ],
 "Ebsus"       => [  N, N, 1, 3, 4, 4,	 1 ],
 "Ebsus4"      => [  N, N, 1, 3, 4, 4,	 1 ],
 "Ebmaj"       => [  N, N, 1, 3, 3, 3,	 1 ],
 "Ebmaj7"      => [  N, N, 1, 3, 3, 3,	 1 ],
 "Ebdim"       => [  N, N, 1, 2, 1, 2,	 1 ],
 "Ebadd9"      => [  N, 1, 1, 3, 4, 1,	 1 ],
 "Eb(add9)"    => [  N, 1, 1, 3, 4, 1,	 1 ],
 "Ebm"	       => [  N, N, 4, 3, 4, 2,	 1 ],
 "Ebmin"       => [  N, N, 4, 3, 4, 2,	 1 ],
 "Ebm7"	       => [  N, N, 1, 3, 2, 2,	 1 ],

 "E"	       => [  0, 2, 2, 1, 0, 0,	 1 ],
 "E+"	       => [  N, N, 2, 1, 1, 0,	 1 ],
 "E5"	       => [  0, 1, 3, 3, N, N,	 7 ],
 "E6"	       => [  N, N, 3, 3, 3, 3,	 9 ],
 "E7"	       => [  0, 2, 2, 1, 3, 0,	 1 ],
 "E7#9"	       => [  0, 2, 2, 1, 3, 3,	 1 ],
 "E7(#9)"      => [  0, 2, 2, 1, 3, 3,	 1 ],
 "E7(5b)"      => [  N, 1, 0, 1, 3, 0,	 1 ],
 "E7b9"	       => [  0, 2, 0, 1, 3, 2,	 1 ],
 "E7(b9)"      => [  0, 2, 0, 1, 3, 2,	 1 ],
 "E7(11)"      => [  0, 2, 2, 2, 3, 0,	 1 ],
 "E9"	       => [  1, 3, 1, 2, 1, 3,	 1 ],
 "E11"	       => [  1, 1, 1, 1, 2, 2,	 1 ],
 "Esus"	       => [  0, 2, 2, 2, 0, 0,	 1 ],
 "Esus4"       => [  0, 2, 2, 2, 0, 0,	 0 ],
 "Emaj"	       => [  0, 2, 2, 1, 0, 0,	 1 ],
 "Emaj7"       => [  0, 2, 1, 1, 0, N,	 1 ],
 "Edim"	       => [  N, N, 2, 3, 2, 3,	 1 ],

 "Em"	       => [  0, 2, 2, 0, 0, 0,	 1 ],
 "Emin"	       => [  0, 2, 2, 0, 0, 0,	 1 ],
 "Em6"	       => [  0, 2, 2, 0, 2, 0,	 1 ],
 "Em7"	       => [  0, 2, 2, 0, 3, 0,	 1 ],
 "Em/B"	       => [  N, 2, 2, 0, 0, 0,	 1 ],
 "Em/D"	       => [  N, N, 0, 0, 0, 0,	 1 ],
 "Em7/D"       => [  N, N, 0, 0, 0, 0,	 1 ],
 "Emsus4"      => [  0, 0, 2, 0, 0, 0,	 1 ],
 "Em(sus4)"    => [  0, 0, 2, 0, 0, 0,	 1 ],
 "Emadd9"      => [  0, 2, 4, 0, 0, 0,	 1 ],
 "Em(add9)"    => [  0, 2, 4, 0, 0, 0,	 1 ],

 "F"	       => [  1, 3, 3, 2, 1, 1,	 1 ],
 "F+"	       => [  N, N, 3, 2, 2, 1,	 1 ],
 "F+7+11"      => [  1, 3, 3, 2, 0, 0,	 1 ],
 "F4"	       => [  N, N, 3, 3, 1, 1,	 1 ],
 "F6"	       => [  N, 3, 3, 2, 3, N,	 1 ],
 "F7"	       => [  1, 3, 1, 2, 1, 1,	 1 ],
 "F9"	       => [  2, 4, 2, 3, 2, 4,	 1 ],
 "F11"	       => [  1, 3, 1, 3, 1, 1,	 1 ],
 "Fsus"	       => [  N, N, 3, 3, 1, 1,	 1 ],
 "Fsus4"       => [  N, N, 3, 3, 1, 1,	 1 ],
 "Fmaj"	       => [  1, 3, 3, 2, 1, 1,	 1 ],
 "Fmaj7"       => [  N, 3, 3, 2, 1, 0,	 1 ],
 "Fdim"	       => [  N, N, 0, 1, 0, 1,	 1 ],
 "Fm"	       => [  1, 3, 3, 1, 1, 1,	 1 ],
 "Fmin"	       => [  1, 3, 3, 1, 1, 1,	 1 ],
 "F/A"	       => [  N, 0, 3, 2, 1, 1,	 1 ],
 "F/C"	       => [  N, N, 3, 2, 1, 1,	 1 ],
 "F/D"	       => [  N, N, 0, 2, 1, 1,	 1 ],
 "F/G"	       => [  3, 3, 3, 2, 1, 1,	 1 ],
 "F7/A"	       => [  N, 0, 3, 0, 1, 1,	 1 ],
 "Fmaj7/A"     => [  N, 0, 3, 2, 1, 0,	 1 ],
 "Fmaj7/C"     => [  N, 3, 3, 2, 1, 0,	 1 ],
 "Fmaj7(+5)"   => [  N, N, 3, 2, 2, 0,	 1 ],
 "Fadd9"       => [  3, 0, 3, 2, 1, 1,	 1 ],
 "F(add9)"     => [  3, 0, 3, 2, 1, 1,	 1 ],
 "FaddG"       => [  1, N, 3, 2, 1, 3,	 1 ],
 "FaddG"       => [  1, N, 3, 2, 1, 3,	 1 ],

 "Fm6"	       => [  N, N, 0, 1, 1, 1,	 1 ],
 "Fm7"	       => [  1, 3, 1, 1, 1, 1,	 1 ],
 "Fmmaj7"      => [  N, 3, 3, 1, 1, 0,	 1 ],

 "F#"	       => [  2, 4, 4, 3, 2, 2,	 1 ],
 "F#+"	       => [  N, N, 4, 3, 3, 2,	 1 ],
 "F#7"	       => [  N, N, 4, 3, 2, 0,	 1 ],
 "F#9"	       => [  N, 1, 2, 1, 2, 2,	 1 ],
 "F#11"	       => [  2, 4, 2, 4, 2, 2,	 1 ],
 "F#sus"       => [  N, N, 4, 4, 2, 2,	 1 ],
 "F#sus4"      => [  N, N, 4, 4, 2, 2,	 1 ],
 "F#maj"       => [  2, 4, 4, 3, 2, 2,	 0 ],
 "F#maj7"      => [  N, N, 4, 3, 2, 1,	 1 ],
 "F#dim"       => [  N, N, 1, 2, 1, 2,	 1 ],
 "F#m"	       => [  2, 4, 4, 2, 2, 2,	 1 ],
 "F#min"       => [  2, 4, 4, 2, 2, 2,	 1 ],
 "F#/E"	       => [  0, 4, 4, 3, 2, 2,	 1 ],
 "F#4"	       => [  N, N, 4, 4, 2, 2,	 1 ],
 "F#m6"	       => [  N, N, 1, 2, 2, 2,	 1 ],
 "F#m7"	       => [  N, N, 2, 2, 2, 2,	 1 ],
 "F#m7-5"      => [  1, 0, 2, 3, 3, 3,	 2 ],
 "F#m/C#m"     => [  N, N, 4, 2, 2, 2,	 1 ],

 "Gb"	       => [  2, 4, 4, 3, 2, 2,	 1 ],
 "Gb+"	       => [  N, N, 4, 3, 3, 2,	 1 ],
 "Gb7"	       => [  N, N, 4, 3, 2, 0,	 1 ],
 "Gb9"	       => [  N, 1, 2, 1, 2, 2,	 1 ],
 "Gbsus"       => [  N, N, 4, 4, 2, 2,	 1 ],
 "Gbsus4"      => [  N, N, 4, 4, 2, 2,	 1 ],
 "Gbmaj"       => [  2, 4, 4, 3, 2, 2,	 1 ],
 "Gbmaj7"      => [  N, N, 4, 3, 2, 1,	 1 ],
 "Gbdim"       => [  N, N, 1, 2, 1, 2,	 1 ],
 "Gbm"	       => [  2, 4, 4, 2, 2, 2,	 1 ],
 "Gbmin"       => [  2, 4, 4, 2, 2, 2,	 1 ],
 "Gbm7"	       => [  N, N, 2, 2, 2, 2,	 1 ],

 "G"	       => [  3, 2, 0, 0, 0, 3,	 1 ],
 "G+"	       => [  N, N, 1, 0, 0, 4,	 1 ],
 "G4"	       => [  N, N, 0, 0, 1, 3,	 1 ],
 "G6"	       => [  3, N, 0, 0, 0, 0,	 1 ],
 "G7"	       => [  3, 2, 0, 0, 0, 1,	 1 ],
 "G7+"	       => [  N, N, 4, 3, 3, 2,	 1 ],
 "G7b9"	       => [  N, N, 0, 1, 0, 1,	 1 ],
 "G7(b9)"      => [  N, N, 0, 1, 0, 1,	 1 ],
 "G7#9"	       => [  1, 3, N, 2, 4, 4,	 3 ],
 "G7(#9)"      => [  1, 3, N, 2, 4, 4,	 3 ],
 "G9"	       => [  3, N, 0, 2, 0, 1,	 1 ],
 "G9(11)"      => [  1, 3, 1, 3, 1, 3,	 3 ],
 "G11"	       => [  3, N, 0, 2, 1, 1,	 1 ],
 "Gsus"	       => [  N, N, 0, 0, 1, 3,	 1 ],
 "Gsus4"       => [  N, N, 0, 0, 1, 1,	 1 ],
 "G6sus4"      => [  0, 2, 0, 0, 1, 0,	 1 ],
 "G6(sus4)"    => [  0, 2, 0, 0, 1, 0,	 1 ],
 "G7sus4"      => [  3, 3, 0, 0, 1, 1,	 1 ],
 "G7(sus4)"    => [  3, 3, 0, 0, 1, 1,	 1 ],
 "Gmaj"	       => [  3, 2, 0, 0, 0, 3,	 1 ],
 "Gmaj7"       => [  N, N, 4, 3, 2, 1,	 2 ],
 "Gmaj7sus4"   => [  N, N, 0, 0, 1, 2,	 1 ],
 "Gmaj9"       => [  1, 1, 4, 1, 2, 1,	 2 ],
 "Gm"	       => [  1, 3, 3, 1, 1, 1,	 3 ],
 "Gmin"	       => [  1, 3, 3, 1, 1, 1,	 3 ],
 "Gdim"	       => [  N, N, 2, 3, 2, 3,	 1 ],
 "Gadd9"       => [  1, 3, N, 2, 1, 3,	 3 ],
 "G(add9)"     => [  1, 3, N, 2, 1, 3,	 3 ],
 "G/A"	       => [  N, 0, 0, 0, 0, 3,	 1 ],
 "G/B"	       => [  N, 2, 0, 0, 0, 3,	 1 ],
 "G/D"	       => [  N, 2, 2, 1, 0, 0,	 4 ],
 "G/F#"	       => [  2, 2, 0, 0, 0, 3,	 1 ],

 "Gm6"	       => [  N, N, 2, 3, 3, 3,	 1 ],
 "Gm7"	       => [  1, 3, 1, 1, 1, 1,	 3 ],
 "Gm/Bb"       => [  3, 2, 2, 1, N, N,	 4 ],

 "G#"	       => [  1, 3, 3, 2, 1, 1,	 4 ],
 "G#+"	       => [  N, N, 2, 1, 1, 0,	 1 ],
 "G#4"	       => [  1, 3, 3, 1, 1, 1,	 4 ],
 "G#7"	       => [  N, N, 1, 1, 1, 2,	 1 ],
 "G#sus"       => [  N, N, 1, 1, 2, 4,	 1 ],
 "G#sus4"      => [  N, N, 1, 1, 2, 4,	 1 ],
 "G#maj"       => [  1, 3, 3, 2, 1, 1,	 4 ],
 "G#maj7"      => [  N, N, 1, 1, 1, 3,	 1 ],
 "G#dim"       => [  N, N, 0, 1, 0, 1,	 1 ],
 "G#m"	       => [  1, 3, 3, 1, 1, 1,	 4 ],
 "G#min"       => [  1, 3, 3, 1, 1, 1,	 4 ],
 "G#m6"	       => [  N, N, 1, 1, 0, 1,	 1 ],
 "G#m7"	       => [  N, N, 1, 1, 1, 1,	 4 ],
 "G#m9maj7"    => [  N, N, 1, 3, 0, 3,	 1 ],
 "G#m9(maj7)"  => [  N, N, 1, 3, 0, 3,	 1 ],

 "Ab"	       => [  1, 3, 3, 2, 1, 1,	 4 ],
 "Ab+"	       => [  N, N, 2, 1, 1, 0,	 1 ],
 "Ab4"	       => [  N, N, 1, 1, 2, 4,	 1 ],
 "Ab7"	       => [  N, N, 1, 1, 1, 2,	 1 ],
 "Ab11"	       => [  1, 3, 1, 3, 1, 1,	 4 ],
 "Absus"       => [  N, N, 1, 1, 2, 4,	 1 ],
 "Absus4"      => [  N, N, 1, 1, 2, 4,	 1 ],
 "Abdim"       => [  N, N, 0, 1, 0, 1,	 1 ],
 "Abmaj"       => [  1, 3, 3, 2, 1, 1,	 4 ],
 "Abmaj7"      => [  N, N, 1, 1, 1, 3,	 1 ],
 "Abm"	       => [  1, 3, 3, 1, 1, 1,	 4 ],
 "Abmin"       => [  1, 3, 3, 1, 1, 1,	 4 ],
 "Abm7"	       => [  N, N, 1, 1, 1, 1,	 4 ],

 "A"	       => [  N, 0, 2, 2, 2, 0,	 1 ],
 "A+"	       => [  N, 0, 3, 2, 2, 1,	 1 ],
 "A4"	       => [  0, 0, 2, 2, 0, 0,	 1 ],
 "A6"	       => [  N, N, 2, 2, 2, 2,	 1 ],
 "A7"	       => [  N, 0, 2, 0, 2, 0,	 1 ],
 "A7+"	       => [  N, N, 3, 2, 2, 1,	 1 ],
 "A7(9+)"      => [  N, 2, 2, 2, 2, 3,	 1 ],
 "A9"	       => [  N, 0, 2, 1, 0, 0,	 1 ],
 "A11"	       => [  N, 4, 2, 4, 3, 3,	 1 ],
 "A13"	       => [  N, 0, 1, 2, 3, 1,	 5 ],
 "A7sus4"      => [  0, 0, 2, 0, 3, 0,	 1 ],
 "A9sus"       => [  N, 0, 2, 1, 0, 0,	 1 ],
 "Asus"	       => [  N, N, 2, 2, 3, 0,	 1 ],
 "Asus2"       => [  0, 0, 2, 2, 0, 0,	 1 ],
 "Asus4"       => [  N, N, 2, 2, 3, 0,	 1 ],
 "Adim"	       => [  N, N, 1, 2, 1, 2,	 1 ],
 "Amaj"	       => [  N, 0, 2, 2, 2, 0,	 1 ],
 "Amaj7"       => [  N, 0, 2, 1, 2, 0,	 1 ],
 "Am"	       => [  N, 0, 2, 2, 1, 0,	 1 ],
 "Amin"	       => [  N, 0, 2, 2, 1, 0,	 1 ],
 "A/C#"	       => [  N, 4, 2, 2, 2, 0,	 1 ],
 "A/D"	       => [  N, N, 0, 0, 2, 2,	 1 ],
 "A/E"	       => [  0, 0, 2, 2, 2, 0,	 1 ],
 "A/F#"	       => [  2, 0, 2, 2, 2, 0,	 1 ],
 "A/G#"	       => [  4, 0, 2, 2, 2, 0,	 1 ],

 "Am#7"	       => [  N, N, 2, 1, 1, 0,	 1 ],
 "Am(7#)"      => [  N, 0, 2, 2, 1, 4,	 1 ],
 "Am6"	       => [  N, 0, 2, 2, 1, 2,	 1 ],
 "Am7"	       => [  N, 0, 2, 2, 1, 3,	 1 ],
 "Am7sus4"     => [  0, 0, 0, 0, 3, 0,	 1 ],
 "Am9"	       => [  N, 0, 1, 1, 1, 3,	 5 ],
 "Am/G"	       => [  3, 0, 2, 2, 1, 0,	 1 ],
 "Amadd9"      => [  0, 2, 2, 2, 1, 0,	 1 ],
 "Am(add9)"    => [  0, 2, 2, 2, 1, 0,	 1 ],

 "A#"	       => [  N, 1, 3, 3, 3, 1,	 1 ],
 "A#+"	       => [  N, N, 0, 3, 3, 2,	 1 ],
 "A#4"	       => [  N, N, 3, 3, 4, 1,	 1 ],
 "A#7"	       => [  N, N, 1, 1, 1, 2,	 3 ],
 "A#sus"       => [  N, N, 3, 3, 4, 1,	 1 ],
 "A#sus4"      => [  N, N, 3, 3, 4, 1,	 1 ],
 "A#maj"       => [  N, 1, 3, 3, 3, 1,	 1 ],
 "A#maj7"      => [  N, 1, 3, 2, 3, N,	 1 ],
 "A#dim"       => [  N, N, 2, 3, 2, 3,	 1 ],
 "A#m"	       => [  N, 1, 3, 3, 2, 1,	 1 ],
 "A#min"       => [  N, 1, 3, 3, 2, 1,	 1 ],
 "A#m7"	       => [  N, 1, 3, 1, 2, 1,	 1 ],

 "Bb"	       => [  N, 1, 3, 3, 3, 1,	 1 ],
 "Bb+"	       => [  N, N, 0, 3, 3, 2,	 1 ],
 "Bb4"	       => [  N, N, 3, 3, 4, 1,	 1 ],
 "Bb6"	       => [  N, N, 3, 3, 3, 3,	 1 ],
 "Bb7"	       => [  N, N, 1, 1, 1, 2,	 3 ],
 "Bb9"	       => [  1, 3, 1, 2, 1, 3,	 6 ],
 "Bb11"	       => [  1, 3, 1, 3, 4, 1,	 6 ],
 "Bbsus"       => [  N, N, 3, 3, 4, 1,	 1 ],
 "Bbsus4"      => [  N, N, 3, 3, 4, 1,	 1 ],
 "Bbmaj"       => [  N, 1, 3, 3, 3, 1,	 1 ],
 "Bbmaj7"      => [  N, 1, 3, 2, 3, N,	 1 ],
 "Bbdim"       => [  N, N, 2, 3, 2, 3,	 1 ],
 "Bbm"	       => [  N, 1, 3, 3, 2, 1,	 1 ],
 "Bbmin"       => [  N, 1, 3, 3, 2, 1,	 1 ],
 "Bbm7"	       => [  N, 1, 3, 1, 2, 1,	 1 ],
 "Bbm9"	       => [  N, N, N, 1, 1, 3,	 6 ],

 "B"	       => [  N, 2, 4, 4, 4, 2,	 1 ],
 "B+"	       => [  N, N, 1, 0, 0, 4,	 1 ],
 "B4"	       => [  N, N, 3, 3, 4, 1,	 2 ],
 "B7"	       => [  0, 2, 1, 2, 0, 2,	 1 ],
 "B7+"	       => [  N, 2, 1, 2, 0, 3,	 1 ],
 "B7+5"	       => [  N, 2, 1, 2, 0, 3,	 1 ],
 "B7#9"	       => [  N, 2, 1, 2, 3, N,	 1 ],
 "B7(#9)"      => [  N, 2, 1, 2, 3, N,	 1 ],
 "B9"	       => [  1, 3, 1, 2, 1, 3,	 7 ],
 "B11"	       => [  1, 3, 3, 2, 0, 0,	 7 ],
 "B11/13"      => [  N, 1, 1, 1, 1, 3,	 2 ],
 "B13"	       => [  N, 2, 1, 2, 0, 4,	 1 ],
 "Bsus"	       => [  N, N, 3, 3, 4, 1,	 2 ],
 "Bsus4"       => [  N, N, 3, 3, 4, 1,	 2 ],
 "Bmaj"	       => [  N, 2, 4, 3, 4, N,	 1 ],
 "Bmaj7"       => [  N, 2, 4, 3, 4, N,	 1 ],
 "Bdim"	       => [  N, N, 0, 1, 0, 1,	 1 ],
 "Bm"	       => [  N, 2, 4, 4, 3, 2,	 1 ],
 "Bmin"	       => [  N, 2, 4, 4, 3, 2,	 1 ],
 "B/F#"	       => [  0, 2, 2, 2, 0, 0,	 2 ],
 "BaddE"       => [  N, 2, 4, 4, 0, 0,	 1 ],
 "B(addE)"     => [  N, 2, 4, 4, 0, 0,	 1 ],
 "BaddE/F#"    => [  2, N, 4, 4, 0, 0,	 1 ],
 "Bm6"	       => [  N, N, 4, 4, 3, 4,	 1 ],
 "Bm7"	       => [  N, 1, 3, 1, 2, 1,	 2 ],
 "Bmmaj7"      => [  N, 1, 4, 4, 3, N,	 1 ],
 "Bm(maj7)"    => [  N, 1, 4, 4, 3, N,	 1 ],
 "Bmsus9"      => [  N, N, 4, 4, 2, 2,	 1 ],
 "Bm(sus9)"    => [  N, N, 4, 4, 2, 2,	 1 ],
 "Bm7b5"       => [  1, 2, 4, 2, 3, 1,	 1 ],

);

# Chords info, as a hash by chord name.
my %chords;
# Chord names, in the order of the list above.
my @chordnames;
# Chord order ordinals, for sorting.
my %chordorderkey; {
    my $ord = 0;
    for ( split( ' ', "C C# Db D D# Eb E F F# Gb G G# Ab A A# Bb B" ) ) {
	$chordorderkey{$_} = $ord;
	$ord += 2;
    }
}

# Additional chords, defined by the configs.
my %config_chords;

# Additional chords, defined by the user.
my %song_chords;

# Current tuning.
my @tuning = @{ TUNING() };

# Transfer the info from the raw list into %chords and @chordnames.
my $chords_filled;
sub fill_tables {

    return if $chords_filled++;
    my @r = @builtin_chords;
    while ( @r ) {
	my ( $name, $info ) = splice( @r, 0, 2 );
	push( @chordnames, $name );
	my @i = @$info;
	$chords{$name} = [ CHORD_BUILTIN, pop(@i), @i ];
    }
}

# Returns a list of all chord names in a nice order.
sub chordcompare($$);
sub chordnames {
    fill_tables();
    [ sort chordcompare @chordnames ];
}

# Returns info about an individual chord.
sub chord_info {
    my ( $chord ) = @_;
    my $info;
    fill_tables();

    for ( \%song_chords, \%config_chords, \%chords ) {
	next unless exists($_->{$chord});
	$info = $_->{$chord};
	last;
    }

    my $s = strings();
    if ( ! $info && $::config->{diagrams}->{auto} ) {
	$info = [ CHORD_SONG, -1, (0) x $s ];
    }

    return unless $info;
    if ( $info->[1] <= 0 ) {
	return +{
		 name    => $chord,
		 strings => [ ],
		 base    => 0,
		 builtin => 1,
		 system  => "",
		 origin  => CHORD_SONG,
		 };
    }
    return +{
	     name    => $chord,
	     strings => [ @{$info}[2..$s+1] ],
	     @$info > $s+2 ? ( fingers => [ @{$info}[$s+2..2*$s+1] ] ) : (),
	     base    => $info->[1]-1,
	     builtin => $info->[0] == CHORD_BUILTIN,
	     system  => "",
	     origin  => $info->[0],
    };
}

sub chordcompare($$) {
    my ( $chorda, $chordb ) = @_;
    my ( $a0, $arest ) = $chorda =~ /^([A-G][b#]?)(.*)/;
    my ( $b0, $brest ) = $chordb =~ /^([A-G][b#]?)(.*)/;
    $a0 = $chordorderkey{$a0}//return 0;
    $b0 = $chordorderkey{$b0}//return 0;
    return $a0 <=> $b0 if $a0 != $b0;
    $a0++ if $arest =~ /^m(?:in)?(?!aj)/;
    $b0++ if $brest =~ /^m(?:in)?(?!aj)/;
    for ( $arest, $brest ) {
	s/11/:/;		# sort 11 after 9
	s/13/;/;		# sort 13 after 11
	s/\((.*?)\)/$1/g;	# ignore parens
	s/\+/aug/;		# sort + as aug
    }
    $a0 <=> $b0 || $arest cmp $brest;
}
# Dump a textual list of chord definitions.
# Should be handled by the ChordPro backend?

sub list_chords {
    my ( $chords, $origin, $hdr ) = @_;
    fill_tables();
    my @s;
    if ( $hdr ) {
	my $t = "-" x (((@tuning - 1) * 4) + 1);
	substr( $t, (length($t)-7)/2, 7, "strings" );
	push( @s,
	      "# CHORD CHART",
	      "# Generated by ChordPro " . $App::Music::ChordPro::VERSION,
	      "# http://www.chordpro.org",
	      "#",
	      "#            " . ( " " x 35 ) . $t,
	      "#       Chord" . ( " " x 35 ) .
	      join("",
		   map { sprintf("%-4s", $_) }
		   @tuning ),
	    );
    }

    foreach my $chord ( @$chords ) {
	my $info;
	if ( eval{ $chord->{name} } ) {
	    $info = $chord;
	}
	elsif ( $origin eq "chord" ) {
	    push( @s, sprintf( "{%s: %s}", "chord", $chord ) );
	    next;
	}
	else {
	    $info = chord_info($chord);
	}
	next unless $info;
	my $s = sprintf( "{%s: %-15.15s base-fret %2d    ".
			 "frets   %s",
			 $origin eq "chord" ? "chord" : "define",
			 $info->{name}, $info->{base} + 1,
			 @{ $info->{strings} }
			 ? join("",
				map { sprintf("%-4s", $_) }
				map { $_ < 0 ? "X" : $_ }
				@{ $info->{strings} } )
			 : ("    " x strings() ));
	$s .= join("", "    fingers ",
		   map { sprintf("%-4s", $_) }
		   map { $_ < 0 ? "X" : $_ }
		   @{ $info->{fingers} } )
	  if $info->{fingers} && @{ $info->{fingers} };
	$s .= "}";
	push( @s, $s );
    }
    \@s;
}

sub dump_chords {
    fill_tables();
    print( join( "\n", @{ list_chords(\@chordnames, "__CLI__", 1) } ), "\n" );
}

################ Section Tuning ################

# Return the number of strings supported.
sub strings { scalar(@tuning) }

sub set_tuning {
    my ( $t ) = @_;
    return "Invalid tuning (not array)" unless ref($t) eq "ARRAY";
    @tuning = @$t;		# need more checks
    fill_tables();
    @chordnames = ();
    %chords = ();
    %config_chords = ();
    return;

}

sub reset_tuning {
    $chords_filled = 0;
    fill_tables();
}

################ Section Config Chords ################

# Add a config defined chord.
sub add_config_chord {
    my ( $name, $base, $frets, $fingers ) = @_;
    unless ( @$frets == strings() ) {
	return scalar(@$frets) . " strings";
    }
    if ( $fingers && @$fingers && @$fingers != strings() ) {
	return scalar(@$frets) . " strings";
    }
    unless ( $base > 0 && $base < 12 ) {
	return "base-fret $base out of range";
    }
    $config_chords{$name} = [ CHORD_CONFIG, $base, @$frets,
			      $fingers && @$fingers ? @$fingers : () ];
    push( @chordnames, $name );
    return;
}

################ Section User (Song) Chords ################

# Reset user defined songs. Should be done for each new song.
sub reset_song_chords {
    %song_chords = ();
}

# Add a user defined chord.
sub add_song_chord {
    my ( $name, $base, $frets, $fingers ) = @_;
    if ( @$frets != strings() ) {
	return scalar(@$frets) . " strings";
    }
    if ( $fingers && @$fingers && @$fingers != strings() ) {
	return scalar(@$fingers) . " strings for fingers";
    }
    unless ( $base > 0 && $base < 12 ) {
	return "base-fret $base out of range";
    }
    $song_chords{$name} = [ CHORD_SONG, $base, @$frets,
			    $fingers && @$fingers ? @$fingers : () ];
    return;
}

# Add an unknown chord.
sub add_unknown_chord {
    my ( $name ) = @_;
    my $base = 0;
    my $frets = [ (0) x strings() ];
    $song_chords{$name} = [ CHORD_SONG, $base, @$frets ];
    return +{
	     name    => $name,
	     strings => [ ],
	     base    => 0,
	     builtin => 1,
	     origin  => CHORD_SONG,
	    };
}

################ Section Chords Parser ################

my $additions_maj =
  {
   map { $_ => $_ }
   "",
   "11",
   "13",
   "13#11",
   "13#9",
   "13b9",
   "13sus",
   "2",
   "5",
   "6",
   "69",
   "7",
   "7#11",
   "7#5",
   "7#9",
   "7#9#11",
   "7#9#5",
   "7#9b5",
   "7alt",
   "7b13",
   "7b13sus",
   "7b5",
   "7b9",
   "7b9#11",
   "7b9#5",
   "7b9#9",
   "7b9b13",
   "7b9b5",
   "7b9sus",
   "7sus",
   "7susadd3",
   "9",
   "9#11",
   "9#5",
   "9b5",
   "9sus",
   ( map { ( "maj$_", "^$_" ) }
     "",
     "13",
     "7",
     "7#11",
     "7#5",
     "9",
     "9#11",
   ),
   "add9",
   "alt",
   "h",
   "h7",
   "h9",
   ( map { "sus$_" } "", "2", "4", "9" ),
  };

my $additions_min =
  {
   map { $_ => $_ }
   "",
   "#5",
   "11",
   "6",
   "69",
   "7b5",
   ( map { ( "$_", "maj$_", "^$_" ) }
     "7",
     "9",
   ),
   "b6",
  };

my $additions_aug =
  {
   map { $_ => $_ }
   "",
  };

my $additions_dim =
  {
   map { $_ => $_ }
   "",
   "7",
  };

my %additions_map =
  ( ""  => $additions_maj,
    "-" => $additions_min,
    "+" => $additions_aug,
    "0" => $additions_dim,
  );

# Notes, sharp series ( C, C#, D, D#, ... )
my @notes_sharp = split( ' ', "C C# D D# E F F# G G# A A# B" );
# Notes, flat series ( C, Dd, D, Eb, ... )
my @notes_flat  = split( ' ', "C Db D Eb E F Gb G Ab A Bb B" );
# Notes -> canonical ( C = 0, D = 2, ... )
my %notes2canon; {
    my $ord = 0;
    for ( @notes_sharp ) {
	$notes2canon{$_} = $ord;
	$ord++;
    }
    $ord = 0;
    for ( @notes_flat ) {
	$notes2canon{$_} = $ord;
	$ord++;
    }
    $notes2canon{H} = $notes2canon{Bb};
}

my %tmap = ( C => 0, D => 2, E => 4, F => 5,
	     G => 7, A => 9, B => 11 );
my %nmap = ( 1 => 0, 2 => 2, 3 => 4, 4 => 5,
	     5 => 7, 6 => 9, 7 => 11 );
my @nmap = qw( I II III IV V VI VI );
my %rmap = ( I => 0, II => 2, III => 4, IV => 5,
	     V => 7, VI => 9, VII => 11 );
my $npat = qr{ ([b#]?) ([1-7]) }x;
my $rpat = qr{ ([b#]?) (IV|I{1,3}|VI{1,2}|V) }ix;
my $tpat = qr{ ( [CDEFGAB] )
	       ((?: [b#]
		    | (?<= [DGB]  ) es
		    | (?<= [EA]   ) s
		    | (?<= [CDFG] ) is
	       )?)
	 }x;

sub troot {
    $notes_sharp[$_[0]];
}

sub nroot {
    my $t = &troot;
    $t =~ s/(.)([#b])/$2$1/;
    $t =~ tr/CDEFGAB/1234567/;
    $t;
}

sub rroot {
    my $t = &nroot;
    $t =~ s/([1234567])/$nmap[$1-1]/e;
    $t;
}

my $ident_cache = {};

# Try to identify the argument as a valid chord.

sub identify {
    my ( $name ) = @_;
    return $ident_cache->{$name} if defined $ident_cache->{$name};

    my $rem = $name;
    my %info = ( name => $name, system => "" );

    # First some basic simplifications.
    $rem =~ tr/\x{266d}\x{266f}\x{0394}\x{f8}\x{b0}/b#^h0/;

    # Split off the duration, if present.
    if ( $rem =~ m;^(.*):(\d\.*)?(?:x(\d+))?$; ) {
	$rem = $1;
	$info{duration} = $2 // 1;
	$info{repeat} = $3;
    }

    # Split off the bass part, if present.
    my $bass = "";
    my $rootless;
    if ( $rem =~ m;^(.*)/(.*); ) {
	$bass = $2;
	$rem = $1;
	if ( $rem eq "" ) {
	    # Rootless. Fake a root by setting it to the bass.
	    # We'll remove the root info later.
	    $rootless++;
	    $rem = $bass;
	}
    }

    # Root processing.
    # Try: Traditional chord naming.
    if ( $rem =~ /^$tpat(.*)/ ) {

	$info{system} = "T";

	$info{dproot} = $1;
	my $root = $tmap{uc($1)};
	if ( $2 ) {
	    $root++ if $2 eq "#" || $2 eq "is";
	    $root-- if $2 eq "b" || $2 eq "es" || $1 eq "s";
	}
	$info{root} = $root % 12;
	$rem = $3;

	# Same for the bass.
	if ( $bass =~ m/^$tpat$/ ) {
	    $root = $tmap{uc($1)};
	    if ( $2 ) {
		$root++ if $2 eq "#" || $2 eq "is";
		$root-- if $2 eq "b" || $2 eq "es" || $1 eq "s";
	    }
	    $info{bass} = $root % 12;
	    $bass = "";
	}
    }

    # Try: Nashville Number System.
    elsif ( $rem =~ /^$npat(.*)/ ) {

	$info{system} = "N";

	$info{dproot} = $2;
	my $root = $nmap{$2};
	$root++ if $1 eq "#";
	$root-- if $1 eq "b";
	$info{root} = $root % 12;
	$rem = $3;

	# Same for the bass.
	if ( $bass =~ /^$npat$/ ) {
	    $root = $nmap{$2};
	    $root++ if $1 eq "#";
	    $root-- if $1 eq "b";
	    $info{bass} = $root % 12;
	    $bass = "";
	}
    }

    # Try: Roman Number System.
    elsif ( $rem =~ /^$rpat(.*)/ ) {

	$info{system} = "R";

	$info{dproot} = $2;
	my $root = $rmap{uc($2)};
	$root++ if $1 eq "#";
	$root-- if $1 eq "b";
	$info{root} = $root % 12;
	$info{qual} = $2 eq lc($2) ? "-" : ""; # implied by case
	$rem = $3;

	if ( $bass =~ m/^$rpat$/ ) {
	    $root = $rmap{uc($2)};
	    $root++ if $1 eq "#";
	    $root-- if $1 eq "b";
	    $info{bass} = $root % 12;
	    $bass = "";
	}
    }

    # Fallback to known chords. Maybe it is user defined.
    else {
	fill_tables();
	for ( \%song_chords, \%config_chords ) {
	    next unless exists($_->{$name});
	    $info{system} = "U";
	    return $ident_cache->{$name} = \%info;
	}

	# Final fallback to built-in chords.
	for ( \%chords ) {
	    next unless exists($_->{$name});
	    $info{system} = "B";
	    return $ident_cache->{$name} = \%info;
	}

	# Unknown/unparsable.
	$info{error} = $rem;
	$info{error} .= "/$bass" if $bass ne "";
	return $ident_cache->{$name} = \%info;
    }

    $info{nonroot} = $rem;

    # Chord quality, based on triads.
    $info{qual} //= "";
    if ( $rem =~ /^ ( aug | dim | min | m(?!aj) | [-+0] ) (.*) /x ) {
	$info{qual} = "+" if $1 eq "aug" || $1 eq "+";
	$info{qual} = "0" if $1 eq "dim" || $1 eq "0";
	$info{qual} = "-" if $1 eq "min" || $1 eq "-" || $1 eq "m";
	$rem = $2;
    }

    if ( $rem ne "") {
	$info{adds} = $rem;
	$rem = "";
	unless ( exists $additions_map{$info{qual}}{$rem} ) {
	    $info{warning} = "";
	    $info{warning} = $rem if $rem ne "";
	    $info{warning} .= "/$bass" if $bass ne "";
	}
    }

    # Did we process everything?
    if ( $rem ne "" || $bass ne "" ) {
	# Signal error.
	$info{error} = "";
	$info{error} = $rem if $rem ne "";
	$info{error} .= "/$bass" if $bass ne "";
    }
    # Remove fake root, if any.
    elsif ( $rootless ) {
	delete @info{ qw(root qual adds) };
    }

    return $ident_cache->{$name} = \%info;
}

################ Section Transposition ################

sub transpose {
    my ( $c, $xpose ) = @_;
    return $c unless $xpose;
    fill_tables();
    return $c unless $c =~ m/
				^ (
				    [CF](?:is|\#)? |
				    [DG](?:is|\#|es|b)? |
				    A(?:is|\#|s|b)? |
				    E(?:s|b)? |
				    B(?:es|b)? |
				    H
				  )
				  (.*)
			    /x;
    my ( $r, $rest ) = ( $1, $2 );
    my $mod = 0;
    $mod-- if $r =~ s/(e?s|b)$//;
    $mod++ if $r =~ s/(is|\#)$//;
    warn("WRONG NOTE: '$c' '$r' '$rest'") unless defined $notes2canon{$r};
    $r = ($notes2canon{$r} + $mod + $xpose) % 12;
    return ( $xpose > 0 ? \@notes_sharp : \@notes_flat )->[$r] . $rest;
}


unless ( caller ) {
    $App::Music::ChordPro::VERSION = "";
    #    dump_chords();
    require DDumper;
    DDumper(identify($_)) foreach @ARGV;
#    DDumper( $additions_maj );
}

1;
