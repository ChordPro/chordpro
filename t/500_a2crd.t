#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Test::More tests => 4;
use App::Music::ChordPro::Config;

our $options ;
our $config ;

package App::Music::ChordPro::Config;
$config = App::Music::ChordPro::Config::configurator() ;
$options->{trace}   = 1 if $options->{debug};
$options->{verbose} = 1 if $options->{trace};

package main;

use_ok 'App::Music::ChordPro::A2Crd';

{
    # test that title works
    my $data = <<EOD;
This is a title

A         C           D           E  F
The first line of the song is pretty normal,
EOD

    my @lines = split( /\r?\n/, $data );

    my $res = App::Music::ChordPro::A2Crd::a2cho(\@lines,$options);

    my $xp = [
      '{title:This is a title}',
      '',
      '[A]The first [C]line of the [D]song is pret[E]ty [F]normal,',
    ];

    is_deeply( $res, $xp, "title conversion" );
}

{
    # test that subtitle works
    my $data = <<EOD;
This is a song for testing chord detection with the --a2crd funtion:
This is a subtitle

A         C           D           E  F
The first line of the song is pretty normal,
EOD

    my @lines = split( /\r?\n/, $data );

    my $res = App::Music::ChordPro::A2Crd::a2cho(\@lines,$options);

    my $xp = [
      '{title:This is a song for testing chord detection with the --a2crd funtion:}',
      '{subtitle:This is a subtitle}',
      '',
      '[A]The first [C]line of the [D]song is pret[E]ty [F]normal,',
    ];

    is_deeply( $res, $xp, "subtitle conversion" );
}
{
    # test that chord line recognition works
    my $data = <<EOD;
This is a song for testing chord detection with the --a2crd funtion:
{a directive}
{another directive}

A         C           D           E  F
The first line of the song is pretty normal,
G
A line with only one chord
       Am
A line with a single chord not right at the beginning of the line
 Bm
A single space before the chord,
  Cm
Two spaces before the chord
	Cm
A tab   before the chord
  Dm	 Cm
A tab, then spaces before the chord

{soc}
Esus4  unknown
A line with one known, and one unknown chord
{eoc}

D        Bm7sus2  Bm7
  Sarah, please

Esus4  unk             unk
A line with one known, and two unknown chords, chordline still detected

 Esus4 unk             unk
A line with one known, and two unknown chords, one space chordline still detected
EOD

    my @lines = split( /\r?\n/, $data );

    my $res = App::Music::ChordPro::A2Crd::a2cho(\@lines,$options);

    my $xp = [
      '{title:This is a song for testing chord detection with the --a2crd funtion:}',
      '{a directive}',
      '{another directive}',
      '',
      '[A]The first [C]line of the [D]song is pret[E]ty [F]normal,',
      '[G]A line with only one chord',
      'A line [Am]with a single chord not right at the beginning of the line',
      'A[Bm] single space before the chord,',
      'Tw[Cm]o spaces before the chord',
      'A tab   [Cm]before the chord',
      'A [Dm]tab, th[Cm]en spaces before the chord',
      '',
      '{soc}',
      '[Esus4]A line [unknown]with one known, and one unknown chord',
      '{eoc}',
      '',
      '[D]  Sarah, [Bm7sus2]please[Bm7]',
      '',
      '[Esus4]A line [unk]with one known, [unk]and two unknown chords, chordline still detected',
      '',
      'A[Esus4] line [unk]with one known, [unk]and two unknown chords, one space chordline still detected',
    ];

    is_deeply( $res, $xp, "chord/line classification" );
}
