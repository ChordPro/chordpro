#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Test::More;

use App::Packager ( ':name', 'App::Music::ChordPro' );
use App::Music::ChordPro::Config;
use App::Music::ChordPro::Chords;

my %tbl;

while ( <DATA> ) {
    chomp;
    my ( $chord, $info ) = split( /\t/, $_ );
    my $c = $chord;
    $c =~ s/[()]//g;
    $tbl{$c} = $info;
}

plan tests => 1 + keys(%tbl);

our $config =
  eval {
      App::Music::ChordPro::Config::configurator
	  ( { nosysconfig => 1, nolegacyconfig => 1, nouserconfig => 1,
	      config => getresource("config/notes_latin.json") } );
  };
ok( $config, "got config" );

use Data::Dumper qw();
local $Data::Dumper::Sortkeys  = 1;
local $Data::Dumper::Indent    = 1;
local $Data::Dumper::Quotekeys = 0;
local $Data::Dumper::Deparse   = 1;
local $Data::Dumper::Terse     = 1;
local $Data::Dumper::Trailingcomma = 1;
local $Data::Dumper::Useperl = 1;
local $Data::Dumper::Useqq     = 0; # I want unicode visible

=for generating

while ( <DATA> ) {
    chomp;
    my ( $chord, $info ) = split( /\t/, $_ );
    for ( $chord ) {
	s!^C#!Do#! or
	s!^C!Do! or
	s!^Db!Reb! or
	s!^D#!Re#! or
	s!^D!Re! or
	s!^Eb!Mib! or
	s!^E!Mi! or
	s!^F#!Fa#! or
	s!^F!Fa! or
	s!^Gb!Solb! or
	s!^G#!Sol#! or
	s!^G!Sol! or
	s!^Ab!Lab! or
	s!^A#!La#! or
	s!^A!La! or
	s!^Bb!Sib! or
	s!^B!Si!;

	s!/C#!/Do#! or
	s!/C!/Do! or
	s!/Db!/Reb! or
	s!/D#!/Re#! or
	s!/D!/Re! or
	s!/Eb!/Mib! or
	s!/E!/Mi! or
	s!/F#!/Fa#! or
	s!/F!/Fa! or
	s!/Gb!/Solb! or
	s!/G#!/Sol#! or
	s!/G!/Sol! or
	s!/Ab!/Lab! or
	s!/A#!/La#! or
	s!/A!/La! or
	s!/Bb!/Sib! or
	s!/B!/Si!;
    }

    my $c = $chord;
    $c =~ s/[()]//g;
    my $res = App::Music::ChordPro::Chords::parse_chord($c);
    unless ( $res ) {
	print( "$chord\tFAIL\n");
	next;
    }
    my $s = Data::Dumper::Dumper($res);
    $s =~ s/\s+/ /gs;
    $s =~ s/, \}/ }/gs;
    $s =~ s/\s+$//;
    print("$chord\t$s\n");
}

exit;

=cut

while ( my ( $c, $info ) = each %tbl ) {
    my $res = App::Music::ChordPro::Chords::parse_chord($c);
    $res //= "FAIL";
    if ( UNIVERSAL::isa( $res, 'HASH' ) ) {
        my $s = Data::Dumper::Dumper($res);
	$s =~ s/\s+/ /gs;
	$s =~ s/, \}/ }/gs;
	$s =~ s/\s+$//;
	$res = $s;
    }
    is( $res, $info, "parsing chord $c");
}

__DATA__
Do	{ ext => '', name => 'Do', qual => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0 }
Do+	{ ext => '', name => 'Do+', qual => '+', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0 }
Do4	{ ext => 4, name => 'Do4', qual => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0 }
Do6	{ ext => 6, name => 'Do6', qual => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0 }
Do7	{ ext => 7, name => 'Do7', qual => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0 }
Do9	{ ext => 9, name => 'Do9', qual => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0 }
Do9(11)	{ ext => 911, name => 'Do911', qual => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0 }
Do11	{ ext => 11, name => 'Do11', qual => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0 }
Dosus	{ ext => 'sus4', name => 'Dosus', qual => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0 }
Dosus2	{ ext => 'sus2', name => 'Dosus2', qual => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0 }
Dosus4	{ ext => 'sus4', name => 'Dosus4', qual => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0 }
Dosus9	{ ext => 'sus9', name => 'Dosus9', qual => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0 }
Domaj	{ ext => 'maj', name => 'Domaj', qual => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0 }
Domaj7	{ ext => 'maj7', name => 'Domaj7', qual => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0 }
Dom	{ ext => '', name => 'Dom', qual => '-', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0 }
Domin	{ ext => '', name => 'Domin', qual => 'min', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0 }
Dodim	{ ext => '', name => 'Dodim', qual => 0, root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0 }
Do/Si	{ bass => 'Si', bass_canon => 'Si', bass_mod => 0, bass_ord => 11, ext => '', name => 'Do', qual => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0 }
Doadd9	{ ext => 'add9', name => 'Doadd9', qual => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0 }
Do3	{ ext => 3, name => 'Do3', qual => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0 }
Dom7	{ ext => 7, name => 'Dom7', qual => '-', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0 }
Dom11	{ ext => 11, name => 'Dom11', qual => '-', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0 }
Do#	{ ext => '', name => 'Do#', qual => '', root => 'Do#', root_canon => 'Do#', root_mod => 1, root_ord => 1 }
Do#+	{ ext => '', name => 'Do#+', qual => '+', root => 'Do#', root_canon => 'Do#', root_mod => 1, root_ord => 1 }
Do#4	{ ext => 4, name => 'Do#4', qual => '', root => 'Do#', root_canon => 'Do#', root_mod => 1, root_ord => 1 }
Do#7	{ ext => 7, name => 'Do#7', qual => '', root => 'Do#', root_canon => 'Do#', root_mod => 1, root_ord => 1 }
Do#7(b5)	{ ext => '7b5', name => 'Do#7b5', qual => '', root => 'Do#', root_canon => 'Do#', root_mod => 1, root_ord => 1 }
Do#sus	{ ext => 'sus4', name => 'Do#sus', qual => '', root => 'Do#', root_canon => 'Do#', root_mod => 1, root_ord => 1 }
Do#sus4	{ ext => 'sus4', name => 'Do#sus4', qual => '', root => 'Do#', root_canon => 'Do#', root_mod => 1, root_ord => 1 }
Do#maj	{ ext => 'maj', name => 'Do#maj', qual => '', root => 'Do#', root_canon => 'Do#', root_mod => 1, root_ord => 1 }
Do#maj7	{ ext => 'maj7', name => 'Do#maj7', qual => '', root => 'Do#', root_canon => 'Do#', root_mod => 1, root_ord => 1 }
Do#dim	{ ext => '', name => 'Do#dim', qual => 0, root => 'Do#', root_canon => 'Do#', root_mod => 1, root_ord => 1 }
Do#m	{ ext => '', name => 'Do#m', qual => '-', root => 'Do#', root_canon => 'Do#', root_mod => 1, root_ord => 1 }
Do#min	{ ext => '', name => 'Do#min', qual => 'min', root => 'Do#', root_canon => 'Do#', root_mod => 1, root_ord => 1 }
Do#add9	{ ext => 'add9', name => 'Do#add9', qual => '', root => 'Do#', root_canon => 'Do#', root_mod => 1, root_ord => 1 }
Do#(add9)	{ ext => 'add9', name => 'Do#add9', qual => '', root => 'Do#', root_canon => 'Do#', root_mod => 1, root_ord => 1 }
Do#m7	{ ext => 7, name => 'Do#m7', qual => '-', root => 'Do#', root_canon => 'Do#', root_mod => 1, root_ord => 1 }
Reb	{ ext => '', name => 'Reb', qual => '', root => 'Reb', root_canon => 'Reb', root_mod => -1, root_ord => 1 }
Reb+	{ ext => '', name => 'Reb+', qual => '+', root => 'Reb', root_canon => 'Reb', root_mod => -1, root_ord => 1 }
Reb7	{ ext => 7, name => 'Reb7', qual => '', root => 'Reb', root_canon => 'Reb', root_mod => -1, root_ord => 1 }
Rebsus	{ ext => 'sus4', name => 'Rebsus', qual => '', root => 'Reb', root_canon => 'Reb', root_mod => -1, root_ord => 1 }
Rebsus4	{ ext => 'sus4', name => 'Rebsus4', qual => '', root => 'Reb', root_canon => 'Reb', root_mod => -1, root_ord => 1 }
Rebmaj	{ ext => 'maj', name => 'Rebmaj', qual => '', root => 'Reb', root_canon => 'Reb', root_mod => -1, root_ord => 1 }
Rebmaj7	{ ext => 'maj7', name => 'Rebmaj7', qual => '', root => 'Reb', root_canon => 'Reb', root_mod => -1, root_ord => 1 }
Rebdim	{ ext => '', name => 'Rebdim', qual => 0, root => 'Reb', root_canon => 'Reb', root_mod => -1, root_ord => 1 }
Rebm	{ ext => '', name => 'Rebm', qual => '-', root => 'Reb', root_canon => 'Reb', root_mod => -1, root_ord => 1 }
Rebmin	{ ext => '', name => 'Rebmin', qual => 'min', root => 'Reb', root_canon => 'Reb', root_mod => -1, root_ord => 1 }
Rebm7	{ ext => 7, name => 'Rebm7', qual => '-', root => 'Reb', root_canon => 'Reb', root_mod => -1, root_ord => 1 }
Re	{ ext => '', name => 'Re', qual => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2 }
Re+	{ ext => '', name => 'Re+', qual => '+', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2 }
Re4	{ ext => 4, name => 'Re4', qual => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2 }
Re6	{ ext => 6, name => 'Re6', qual => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2 }
Re7	{ ext => 7, name => 'Re7', qual => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2 }
Re7#9	{ ext => '7#9', name => 'Re7#9', qual => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2 }
Re7(#9)	{ ext => '7#9', name => 'Re7#9', qual => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2 }
Re9	{ ext => 9, name => 'Re9', qual => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2 }
Re11	{ ext => 11, name => 'Re11', qual => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2 }
Resus	{ ext => 'sus4', name => 'Resus', qual => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2 }
Resus2	{ ext => 'sus2', name => 'Resus2', qual => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2 }
Resus4	{ ext => 'sus4', name => 'Resus4', qual => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2 }
Re7sus2	{ ext => '7sus2', name => 'Re7sus2', qual => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2 }
Re7sus4	{ ext => '7sus4', name => 'Re7sus4', qual => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2 }
Remaj	{ ext => 'maj', name => 'Remaj', qual => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2 }
Remaj7	{ ext => 'maj7', name => 'Remaj7', qual => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2 }
Redim	{ ext => '', name => 'Redim', qual => 0, root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2 }
Rem	{ ext => '', name => 'Rem', qual => '-', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2 }
Remin	{ ext => '', name => 'Remin', qual => 'min', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2 }
Re/La	{ bass => 'La', bass_canon => 'La', bass_mod => 0, bass_ord => 9, ext => '', name => 'Re', qual => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2 }
Re/Si	{ bass => 'Si', bass_canon => 'Si', bass_mod => 0, bass_ord => 11, ext => '', name => 'Re', qual => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2 }
Re/Do	{ bass => 'Do', bass_canon => 'Do', bass_mod => 0, bass_ord => 0, ext => '', name => 'Re', qual => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2 }
Re/Do#	{ bass => 'Do#', bass_canon => 'Do#', bass_mod => 1, bass_ord => 1, ext => '', name => 'Re', qual => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2 }
Re/Mi	{ bass => 'Mi', bass_canon => 'Mi', bass_mod => 0, bass_ord => 4, ext => '', name => 'Re', qual => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2 }
Re/Sol	{ bass => 'Sol', bass_canon => 'Sol', bass_mod => 0, bass_ord => 7, ext => '', name => 'Re', qual => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2 }
Re5/Mi	{ bass => 'Mi', bass_canon => 'Mi', bass_mod => 0, bass_ord => 4, ext => 5, name => 'Re5', qual => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2 }
Readd9	{ ext => 'add9', name => 'Readd9', qual => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2 }
Re9add6	{ ext => '9add6', name => 'Re9add6', qual => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2 }
Rem7	{ ext => 7, name => 'Rem7', qual => '-', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2 }
Rem#5	{ ext => '#5', name => 'Rem#5', qual => '-', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2 }
Rem#7	{ ext => '#7', name => 'Rem#7', qual => '-', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2 }
Rem/La	{ bass => 'La', bass_canon => 'La', bass_mod => 0, bass_ord => 9, ext => '', name => 'Rem', qual => '-', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2 }
Rem/Si	{ bass => 'Si', bass_canon => 'Si', bass_mod => 0, bass_ord => 11, ext => '', name => 'Rem', qual => '-', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2 }
Rem/Do	{ bass => 'Do', bass_canon => 'Do', bass_mod => 0, bass_ord => 0, ext => '', name => 'Rem', qual => '-', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2 }
Rem/Do#	{ bass => 'Do#', bass_canon => 'Do#', bass_mod => 1, bass_ord => 1, ext => '', name => 'Rem', qual => '-', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2 }
Rem9	{ ext => 9, name => 'Rem9', qual => '-', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2 }
Re#	{ ext => '', name => 'Re#', qual => '', root => 'Re#', root_canon => 'Re#', root_mod => 1, root_ord => 3 }
Re#+	{ ext => '', name => 'Re#+', qual => '+', root => 'Re#', root_canon => 'Re#', root_mod => 1, root_ord => 3 }
Re#4	{ ext => 4, name => 'Re#4', qual => '', root => 'Re#', root_canon => 'Re#', root_mod => 1, root_ord => 3 }
Re#7	{ ext => 7, name => 'Re#7', qual => '', root => 'Re#', root_canon => 'Re#', root_mod => 1, root_ord => 3 }
Re#sus	{ ext => 'sus4', name => 'Re#sus', qual => '', root => 'Re#', root_canon => 'Re#', root_mod => 1, root_ord => 3 }
Re#sus4	{ ext => 'sus4', name => 'Re#sus4', qual => '', root => 'Re#', root_canon => 'Re#', root_mod => 1, root_ord => 3 }
Re#maj	{ ext => 'maj', name => 'Re#maj', qual => '', root => 'Re#', root_canon => 'Re#', root_mod => 1, root_ord => 3 }
Re#maj7	{ ext => 'maj7', name => 'Re#maj7', qual => '', root => 'Re#', root_canon => 'Re#', root_mod => 1, root_ord => 3 }
Re#dim	{ ext => '', name => 'Re#dim', qual => 0, root => 'Re#', root_canon => 'Re#', root_mod => 1, root_ord => 3 }
Re#m	{ ext => '', name => 'Re#m', qual => '-', root => 'Re#', root_canon => 'Re#', root_mod => 1, root_ord => 3 }
Re#min	{ ext => '', name => 'Re#min', qual => 'min', root => 'Re#', root_canon => 'Re#', root_mod => 1, root_ord => 3 }
Re#m7	{ ext => 7, name => 'Re#m7', qual => '-', root => 'Re#', root_canon => 'Re#', root_mod => 1, root_ord => 3 }
Mib	{ ext => '', name => 'Mib', qual => '', root => 'Mib', root_canon => 'Mib', root_mod => -1, root_ord => 3 }
Mib+	{ ext => '', name => 'Mib+', qual => '+', root => 'Mib', root_canon => 'Mib', root_mod => -1, root_ord => 3 }
Mib4	{ ext => 4, name => 'Mib4', qual => '', root => 'Mib', root_canon => 'Mib', root_mod => -1, root_ord => 3 }
Mib7	{ ext => 7, name => 'Mib7', qual => '', root => 'Mib', root_canon => 'Mib', root_mod => -1, root_ord => 3 }
Mibsus	{ ext => 'sus4', name => 'Mibsus', qual => '', root => 'Mib', root_canon => 'Mib', root_mod => -1, root_ord => 3 }
Mibsus4	{ ext => 'sus4', name => 'Mibsus4', qual => '', root => 'Mib', root_canon => 'Mib', root_mod => -1, root_ord => 3 }
Mibmaj	{ ext => 'maj', name => 'Mibmaj', qual => '', root => 'Mib', root_canon => 'Mib', root_mod => -1, root_ord => 3 }
Mibmaj7	{ ext => 'maj7', name => 'Mibmaj7', qual => '', root => 'Mib', root_canon => 'Mib', root_mod => -1, root_ord => 3 }
Mibdim	{ ext => '', name => 'Mibdim', qual => 0, root => 'Mib', root_canon => 'Mib', root_mod => -1, root_ord => 3 }
Mibadd9	{ ext => 'add9', name => 'Mibadd9', qual => '', root => 'Mib', root_canon => 'Mib', root_mod => -1, root_ord => 3 }
Mib(add9)	{ ext => 'add9', name => 'Mibadd9', qual => '', root => 'Mib', root_canon => 'Mib', root_mod => -1, root_ord => 3 }
Mibm	{ ext => '', name => 'Mibm', qual => '-', root => 'Mib', root_canon => 'Mib', root_mod => -1, root_ord => 3 }
Mibmin	{ ext => '', name => 'Mibmin', qual => 'min', root => 'Mib', root_canon => 'Mib', root_mod => -1, root_ord => 3 }
Mibm7	{ ext => 7, name => 'Mibm7', qual => '-', root => 'Mib', root_canon => 'Mib', root_mod => -1, root_ord => 3 }
Mi	{ ext => '', name => 'Mi', qual => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4 }
Mi+	{ ext => '', name => 'Mi+', qual => '+', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4 }
Mi5	{ ext => 5, name => 'Mi5', qual => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4 }
Mi6	{ ext => 6, name => 'Mi6', qual => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4 }
Mi7	{ ext => 7, name => 'Mi7', qual => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4 }
Mi7#9	{ ext => '7#9', name => 'Mi7#9', qual => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4 }
Mi7(#9)	{ ext => '7#9', name => 'Mi7#9', qual => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4 }
Mi7(b5)	{ ext => '7b5', name => 'Mi7b5', qual => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4 }
Mi7b9	{ ext => '7b9', name => 'Mi7b9', qual => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4 }
Mi7(11)	{ ext => 711, name => 'Mi711', qual => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4 }
Mi9	{ ext => 9, name => 'Mi9', qual => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4 }
Mi11	{ ext => 11, name => 'Mi11', qual => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4 }
Misus	{ ext => 'sus4', name => 'Misus', qual => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4 }
Mimaj	{ ext => 'maj', name => 'Mimaj', qual => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4 }
Mimaj7	{ ext => 'maj7', name => 'Mimaj7', qual => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4 }
Midim	{ ext => '', name => 'Midim', qual => 0, root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4 }
Mim	{ ext => '', name => 'Mim', qual => '-', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4 }
Mimin	{ ext => '', name => 'Mimin', qual => 'min', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4 }
Mim6	{ ext => 6, name => 'Mim6', qual => '-', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4 }
Mim7	{ ext => 7, name => 'Mim7', qual => '-', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4 }
Mim/Si	{ bass => 'Si', bass_canon => 'Si', bass_mod => 0, bass_ord => 11, ext => '', name => 'Mim', qual => '-', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4 }
Mim/Re	{ bass => 'Re', bass_canon => 'Re', bass_mod => 0, bass_ord => 2, ext => '', name => 'Mim', qual => '-', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4 }
Mim7/Re	{ bass => 'Re', bass_canon => 'Re', bass_mod => 0, bass_ord => 2, ext => 7, name => 'Mim7', qual => '-', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4 }
Mimsus4	{ ext => 'sus4', name => 'Mimsus4', qual => '-', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4 }
Mimadd9	{ ext => 'add9', name => 'Mimadd9', qual => '-', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4 }
Fa	{ ext => '', name => 'Fa', qual => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5 }
Fa+	{ ext => '', name => 'Fa+', qual => '+', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5 }
Fa4	{ ext => 4, name => 'Fa4', qual => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5 }
Fa6	{ ext => 6, name => 'Fa6', qual => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5 }
Fa7	{ ext => 7, name => 'Fa7', qual => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5 }
Fa9	{ ext => 9, name => 'Fa9', qual => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5 }
Fa11	{ ext => 11, name => 'Fa11', qual => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5 }
Fasus	{ ext => 'sus4', name => 'Fasus', qual => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5 }
Fasus4	{ ext => 'sus4', name => 'Fasus4', qual => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5 }
Famaj	{ ext => 'maj', name => 'Famaj', qual => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5 }
Famaj7	{ ext => 'maj7', name => 'Famaj7', qual => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5 }
Fadim	{ ext => '', name => 'Fadim', qual => 0, root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5 }
Fam	{ ext => '', name => 'Fam', qual => '-', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5 }
Famin	{ ext => '', name => 'Famin', qual => 'min', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5 }
Fa/La	{ bass => 'La', bass_canon => 'La', bass_mod => 0, bass_ord => 9, ext => '', name => 'Fa', qual => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5 }
Fa/Do	{ bass => 'Do', bass_canon => 'Do', bass_mod => 0, bass_ord => 0, ext => '', name => 'Fa', qual => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5 }
Fa/Re	{ bass => 'Re', bass_canon => 'Re', bass_mod => 0, bass_ord => 2, ext => '', name => 'Fa', qual => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5 }
Fa/Sol	{ bass => 'Sol', bass_canon => 'Sol', bass_mod => 0, bass_ord => 7, ext => '', name => 'Fa', qual => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5 }
Fa7/La	{ bass => 'La', bass_canon => 'La', bass_mod => 0, bass_ord => 9, ext => 7, name => 'Fa7', qual => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5 }
Famaj7/La	{ bass => 'La', bass_canon => 'La', bass_mod => 0, bass_ord => 9, ext => 'maj7', name => 'Famaj7', qual => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5 }
Famaj7/Do	{ bass => 'Do', bass_canon => 'Do', bass_mod => 0, bass_ord => 0, ext => 'maj7', name => 'Famaj7', qual => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5 }
Faadd9	{ ext => 'add9', name => 'Faadd9', qual => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5 }
Fam6	{ ext => 6, name => 'Fam6', qual => '-', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5 }
Fam7	{ ext => 7, name => 'Fam7', qual => '-', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5 }
Fammaj7	{ ext => 'maj7', name => 'Fammaj7', qual => '-', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5 }
Fa#	{ ext => '', name => 'Fa#', qual => '', root => 'Fa#', root_canon => 'Fa#', root_mod => 1, root_ord => 6 }
Fa#+	{ ext => '', name => 'Fa#+', qual => '+', root => 'Fa#', root_canon => 'Fa#', root_mod => 1, root_ord => 6 }
Fa#7	{ ext => 7, name => 'Fa#7', qual => '', root => 'Fa#', root_canon => 'Fa#', root_mod => 1, root_ord => 6 }
Fa#9	{ ext => 9, name => 'Fa#9', qual => '', root => 'Fa#', root_canon => 'Fa#', root_mod => 1, root_ord => 6 }
Fa#11	{ ext => 11, name => 'Fa#11', qual => '', root => 'Fa#', root_canon => 'Fa#', root_mod => 1, root_ord => 6 }
Fa#sus	{ ext => 'sus4', name => 'Fa#sus', qual => '', root => 'Fa#', root_canon => 'Fa#', root_mod => 1, root_ord => 6 }
Fa#sus4	{ ext => 'sus4', name => 'Fa#sus4', qual => '', root => 'Fa#', root_canon => 'Fa#', root_mod => 1, root_ord => 6 }
Fa#maj7	{ ext => 'maj7', name => 'Fa#maj7', qual => '', root => 'Fa#', root_canon => 'Fa#', root_mod => 1, root_ord => 6 }
Fa#dim	{ ext => '', name => 'Fa#dim', qual => 0, root => 'Fa#', root_canon => 'Fa#', root_mod => 1, root_ord => 6 }
Fa#m	{ ext => '', name => 'Fa#m', qual => '-', root => 'Fa#', root_canon => 'Fa#', root_mod => 1, root_ord => 6 }
Fa#min	{ ext => '', name => 'Fa#min', qual => 'min', root => 'Fa#', root_canon => 'Fa#', root_mod => 1, root_ord => 6 }
Fa#/Mi	{ bass => 'Mi', bass_canon => 'Mi', bass_mod => 0, bass_ord => 4, ext => '', name => 'Fa#', qual => '', root => 'Fa#', root_canon => 'Fa#', root_mod => 1, root_ord => 6 }
Fa#4	{ ext => 4, name => 'Fa#4', qual => '', root => 'Fa#', root_canon => 'Fa#', root_mod => 1, root_ord => 6 }
Fa#m6	{ ext => 6, name => 'Fa#m6', qual => '-', root => 'Fa#', root_canon => 'Fa#', root_mod => 1, root_ord => 6 }
Fa#m7	{ ext => 7, name => 'Fa#m7', qual => '-', root => 'Fa#', root_canon => 'Fa#', root_mod => 1, root_ord => 6 }
Fa#m7b5	{ ext => '7b5', name => 'Fa#m7b5', qual => '-', root => 'Fa#', root_canon => 'Fa#', root_mod => 1, root_ord => 6 }
Fa#m/Do	{ bass => 'Do', bass_canon => 'Do', bass_mod => 0, bass_ord => 0, ext => '', name => 'Fa#m', qual => '-', root => 'Fa#', root_canon => 'Fa#', root_mod => 1, root_ord => 6 }
Solb	{ ext => '', name => 'Solb', qual => '', root => 'Solb', root_canon => 'Solb', root_mod => -1, root_ord => 6 }
Solb+	{ ext => '', name => 'Solb+', qual => '+', root => 'Solb', root_canon => 'Solb', root_mod => -1, root_ord => 6 }
Solb7	{ ext => 7, name => 'Solb7', qual => '', root => 'Solb', root_canon => 'Solb', root_mod => -1, root_ord => 6 }
Solb9	{ ext => 9, name => 'Solb9', qual => '', root => 'Solb', root_canon => 'Solb', root_mod => -1, root_ord => 6 }
Solbsus	{ ext => 'sus4', name => 'Solbsus', qual => '', root => 'Solb', root_canon => 'Solb', root_mod => -1, root_ord => 6 }
Solbsus4	{ ext => 'sus4', name => 'Solbsus4', qual => '', root => 'Solb', root_canon => 'Solb', root_mod => -1, root_ord => 6 }
Solbmaj	{ ext => 'maj', name => 'Solbmaj', qual => '', root => 'Solb', root_canon => 'Solb', root_mod => -1, root_ord => 6 }
Solbmaj7	{ ext => 'maj7', name => 'Solbmaj7', qual => '', root => 'Solb', root_canon => 'Solb', root_mod => -1, root_ord => 6 }
Solbdim	{ ext => '', name => 'Solbdim', qual => 0, root => 'Solb', root_canon => 'Solb', root_mod => -1, root_ord => 6 }
Solbm	{ ext => '', name => 'Solbm', qual => '-', root => 'Solb', root_canon => 'Solb', root_mod => -1, root_ord => 6 }
Solbmin	{ ext => '', name => 'Solbmin', qual => 'min', root => 'Solb', root_canon => 'Solb', root_mod => -1, root_ord => 6 }
Solbm7	{ ext => 7, name => 'Solbm7', qual => '-', root => 'Solb', root_canon => 'Solb', root_mod => -1, root_ord => 6 }
Sol	{ ext => '', name => 'Sol', qual => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7 }
Sol+	{ ext => '', name => 'Sol+', qual => '+', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7 }
Sol4	{ ext => 4, name => 'Sol4', qual => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7 }
Sol6	{ ext => 6, name => 'Sol6', qual => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7 }
Sol7	{ ext => 7, name => 'Sol7', qual => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7 }
Sol7b9	{ ext => '7b9', name => 'Sol7b9', qual => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7 }
Sol7#9	{ ext => '7#9', name => 'Sol7#9', qual => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7 }
Sol9	{ ext => 9, name => 'Sol9', qual => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7 }
Sol9(11)	{ ext => 911, name => 'Sol911', qual => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7 }
Sol11	{ ext => 11, name => 'Sol11', qual => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7 }
Solsus	{ ext => 'sus4', name => 'Solsus', qual => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7 }
Solsus4	{ ext => 'sus4', name => 'Solsus4', qual => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7 }
Sol6sus4	{ ext => '6sus4', name => 'Sol6sus4', qual => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7 }
Sol7sus4	{ ext => '7sus4', name => 'Sol7sus4', qual => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7 }
Solmaj	{ ext => 'maj', name => 'Solmaj', qual => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7 }
Solmaj7	{ ext => 'maj7', name => 'Solmaj7', qual => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7 }
Solmaj7sus4	{ ext => 'maj7sus4', name => 'Solmaj7sus4', qual => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7 }
Solmaj9	{ ext => 'maj9', name => 'Solmaj9', qual => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7 }
Solm	{ ext => '', name => 'Solm', qual => '-', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7 }
Solmin	{ ext => '', name => 'Solmin', qual => 'min', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7 }
Soldim	{ ext => '', name => 'Soldim', qual => 0, root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7 }
Soladd9	{ ext => 'add9', name => 'Soladd9', qual => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7 }
Sol(add9)	{ ext => 'add9', name => 'Soladd9', qual => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7 }
Sol/La	{ bass => 'La', bass_canon => 'La', bass_mod => 0, bass_ord => 9, ext => '', name => 'Sol', qual => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7 }
Sol/Si	{ bass => 'Si', bass_canon => 'Si', bass_mod => 0, bass_ord => 11, ext => '', name => 'Sol', qual => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7 }
Sol/Re	{ bass => 'Re', bass_canon => 'Re', bass_mod => 0, bass_ord => 2, ext => '', name => 'Sol', qual => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7 }
Sol/Fa#	{ bass => 'Fa#', bass_canon => 'Fa#', bass_mod => 1, bass_ord => 6, ext => '', name => 'Sol', qual => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7 }
Solm6	{ ext => 6, name => 'Solm6', qual => '-', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7 }
Solm7	{ ext => 7, name => 'Solm7', qual => '-', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7 }
Solm/Sib	{ bass => 'Sib', bass_canon => 'Sib', bass_mod => -1, bass_ord => 10, ext => '', name => 'Solm', qual => '-', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7 }
Sol#	{ ext => '', name => 'Sol#', qual => '', root => 'Sol#', root_canon => 'Sol#', root_mod => 1, root_ord => 8 }
Sol#+	{ ext => '', name => 'Sol#+', qual => '+', root => 'Sol#', root_canon => 'Sol#', root_mod => 1, root_ord => 8 }
Sol#4	{ ext => 4, name => 'Sol#4', qual => '', root => 'Sol#', root_canon => 'Sol#', root_mod => 1, root_ord => 8 }
Sol#7	{ ext => 7, name => 'Sol#7', qual => '', root => 'Sol#', root_canon => 'Sol#', root_mod => 1, root_ord => 8 }
Sol#sus	{ ext => 'sus4', name => 'Sol#sus', qual => '', root => 'Sol#', root_canon => 'Sol#', root_mod => 1, root_ord => 8 }
Sol#sus4	{ ext => 'sus4', name => 'Sol#sus4', qual => '', root => 'Sol#', root_canon => 'Sol#', root_mod => 1, root_ord => 8 }
Sol#maj	{ ext => 'maj', name => 'Sol#maj', qual => '', root => 'Sol#', root_canon => 'Sol#', root_mod => 1, root_ord => 8 }
Sol#maj7	{ ext => 'maj7', name => 'Sol#maj7', qual => '', root => 'Sol#', root_canon => 'Sol#', root_mod => 1, root_ord => 8 }
Sol#dim	{ ext => '', name => 'Sol#dim', qual => 0, root => 'Sol#', root_canon => 'Sol#', root_mod => 1, root_ord => 8 }
Sol#m	{ ext => '', name => 'Sol#m', qual => '-', root => 'Sol#', root_canon => 'Sol#', root_mod => 1, root_ord => 8 }
Sol#min	{ ext => '', name => 'Sol#min', qual => 'min', root => 'Sol#', root_canon => 'Sol#', root_mod => 1, root_ord => 8 }
Sol#m6	{ ext => 6, name => 'Sol#m6', qual => '-', root => 'Sol#', root_canon => 'Sol#', root_mod => 1, root_ord => 8 }
Sol#m7	{ ext => 7, name => 'Sol#m7', qual => '-', root => 'Sol#', root_canon => 'Sol#', root_mod => 1, root_ord => 8 }
Sol#m9maj7	{ ext => '9maj7', name => 'Sol#m9maj7', qual => '-', root => 'Sol#', root_canon => 'Sol#', root_mod => 1, root_ord => 8 }
Lab	{ ext => '', name => 'Lab', qual => '', root => 'Lab', root_canon => 'Lab', root_mod => -1, root_ord => 8 }
Lab+	{ ext => '', name => 'Lab+', qual => '+', root => 'Lab', root_canon => 'Lab', root_mod => -1, root_ord => 8 }
Lab4	{ ext => 4, name => 'Lab4', qual => '', root => 'Lab', root_canon => 'Lab', root_mod => -1, root_ord => 8 }
Lab7	{ ext => 7, name => 'Lab7', qual => '', root => 'Lab', root_canon => 'Lab', root_mod => -1, root_ord => 8 }
Lab11	{ ext => 11, name => 'Lab11', qual => '', root => 'Lab', root_canon => 'Lab', root_mod => -1, root_ord => 8 }
Labsus	{ ext => 'sus4', name => 'Labsus', qual => '', root => 'Lab', root_canon => 'Lab', root_mod => -1, root_ord => 8 }
Labsus4	{ ext => 'sus4', name => 'Labsus4', qual => '', root => 'Lab', root_canon => 'Lab', root_mod => -1, root_ord => 8 }
Labdim	{ ext => '', name => 'Labdim', qual => 0, root => 'Lab', root_canon => 'Lab', root_mod => -1, root_ord => 8 }
Labmaj	{ ext => 'maj', name => 'Labmaj', qual => '', root => 'Lab', root_canon => 'Lab', root_mod => -1, root_ord => 8 }
Labmaj7	{ ext => 'maj7', name => 'Labmaj7', qual => '', root => 'Lab', root_canon => 'Lab', root_mod => -1, root_ord => 8 }
Labm	{ ext => '', name => 'Labm', qual => '-', root => 'Lab', root_canon => 'Lab', root_mod => -1, root_ord => 8 }
Labmin	{ ext => '', name => 'Labmin', qual => 'min', root => 'Lab', root_canon => 'Lab', root_mod => -1, root_ord => 8 }
Labm7	{ ext => 7, name => 'Labm7', qual => '-', root => 'Lab', root_canon => 'Lab', root_mod => -1, root_ord => 8 }
La	{ ext => '', name => 'La', qual => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9 }
La+	{ ext => '', name => 'La+', qual => '+', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9 }
La4	{ ext => 4, name => 'La4', qual => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9 }
La6	{ ext => 6, name => 'La6', qual => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9 }
La7	{ ext => 7, name => 'La7', qual => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9 }
La9	{ ext => 9, name => 'La9', qual => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9 }
La11	{ ext => 11, name => 'La11', qual => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9 }
La13	{ ext => 13, name => 'La13', qual => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9 }
La7sus4	{ ext => '7sus4', name => 'La7sus4', qual => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9 }
La9sus	{ ext => '9sus', name => 'La9sus', qual => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9 }
Lasus	{ ext => 'sus4', name => 'Lasus', qual => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9 }
Lasus2	{ ext => 'sus2', name => 'Lasus2', qual => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9 }
Lasus4	{ ext => 'sus4', name => 'Lasus4', qual => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9 }
Ladim	{ ext => '', name => 'Ladim', qual => 0, root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9 }
Lamaj	{ ext => 'maj', name => 'Lamaj', qual => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9 }
Lamaj7	{ ext => 'maj7', name => 'Lamaj7', qual => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9 }
Lam	{ ext => '', name => 'Lam', qual => '-', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9 }
Lamin	{ ext => '', name => 'Lamin', qual => 'min', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9 }
La/Do#	{ bass => 'Do#', bass_canon => 'Do#', bass_mod => 1, bass_ord => 1, ext => '', name => 'La', qual => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9 }
La/Re	{ bass => 'Re', bass_canon => 'Re', bass_mod => 0, bass_ord => 2, ext => '', name => 'La', qual => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9 }
La/Mi	{ bass => 'Mi', bass_canon => 'Mi', bass_mod => 0, bass_ord => 4, ext => '', name => 'La', qual => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9 }
La/Fa#	{ bass => 'Fa#', bass_canon => 'Fa#', bass_mod => 1, bass_ord => 6, ext => '', name => 'La', qual => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9 }
La/Sol#	{ bass => 'Sol#', bass_canon => 'Sol#', bass_mod => 1, bass_ord => 8, ext => '', name => 'La', qual => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9 }
Lam#7	{ ext => '#7', name => 'Lam#7', qual => '-', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9 }
Lam6	{ ext => 6, name => 'Lam6', qual => '-', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9 }
Lam7	{ ext => 7, name => 'Lam7', qual => '-', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9 }
Lam7sus4	{ ext => '7sus4', name => 'Lam7sus4', qual => '-', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9 }
Lam9	{ ext => 9, name => 'Lam9', qual => '-', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9 }
Lam/Sol	{ bass => 'Sol', bass_canon => 'Sol', bass_mod => 0, bass_ord => 7, ext => '', name => 'Lam', qual => '-', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9 }
Lamadd9	{ ext => 'add9', name => 'Lamadd9', qual => '-', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9 }
La#	{ ext => '', name => 'La#', qual => '', root => 'La#', root_canon => 'La#', root_mod => 1, root_ord => 10 }
La#+	{ ext => '', name => 'La#+', qual => '+', root => 'La#', root_canon => 'La#', root_mod => 1, root_ord => 10 }
La#4	{ ext => 4, name => 'La#4', qual => '', root => 'La#', root_canon => 'La#', root_mod => 1, root_ord => 10 }
La#7	{ ext => 7, name => 'La#7', qual => '', root => 'La#', root_canon => 'La#', root_mod => 1, root_ord => 10 }
La#sus	{ ext => 'sus4', name => 'La#sus', qual => '', root => 'La#', root_canon => 'La#', root_mod => 1, root_ord => 10 }
La#sus4	{ ext => 'sus4', name => 'La#sus4', qual => '', root => 'La#', root_canon => 'La#', root_mod => 1, root_ord => 10 }
La#maj	{ ext => 'maj', name => 'La#maj', qual => '', root => 'La#', root_canon => 'La#', root_mod => 1, root_ord => 10 }
La#maj7	{ ext => 'maj7', name => 'La#maj7', qual => '', root => 'La#', root_canon => 'La#', root_mod => 1, root_ord => 10 }
La#dim	{ ext => '', name => 'La#dim', qual => 0, root => 'La#', root_canon => 'La#', root_mod => 1, root_ord => 10 }
La#m	{ ext => '', name => 'La#m', qual => '-', root => 'La#', root_canon => 'La#', root_mod => 1, root_ord => 10 }
La#min	{ ext => '', name => 'La#min', qual => 'min', root => 'La#', root_canon => 'La#', root_mod => 1, root_ord => 10 }
La#m7	{ ext => 7, name => 'La#m7', qual => '-', root => 'La#', root_canon => 'La#', root_mod => 1, root_ord => 10 }
Sib	{ ext => '', name => 'Sib', qual => '', root => 'Sib', root_canon => 'Sib', root_mod => -1, root_ord => 10 }
Sib+	{ ext => '', name => 'Sib+', qual => '+', root => 'Sib', root_canon => 'Sib', root_mod => -1, root_ord => 10 }
Sib4	{ ext => 4, name => 'Sib4', qual => '', root => 'Sib', root_canon => 'Sib', root_mod => -1, root_ord => 10 }
Sib6	{ ext => 6, name => 'Sib6', qual => '', root => 'Sib', root_canon => 'Sib', root_mod => -1, root_ord => 10 }
Sib7	{ ext => 7, name => 'Sib7', qual => '', root => 'Sib', root_canon => 'Sib', root_mod => -1, root_ord => 10 }
Sib9	{ ext => 9, name => 'Sib9', qual => '', root => 'Sib', root_canon => 'Sib', root_mod => -1, root_ord => 10 }
Sib11	{ ext => 11, name => 'Sib11', qual => '', root => 'Sib', root_canon => 'Sib', root_mod => -1, root_ord => 10 }
Sibsus	{ ext => 'sus4', name => 'Sibsus', qual => '', root => 'Sib', root_canon => 'Sib', root_mod => -1, root_ord => 10 }
Sibsus4	{ ext => 'sus4', name => 'Sibsus4', qual => '', root => 'Sib', root_canon => 'Sib', root_mod => -1, root_ord => 10 }
Sibmaj	{ ext => 'maj', name => 'Sibmaj', qual => '', root => 'Sib', root_canon => 'Sib', root_mod => -1, root_ord => 10 }
Sibmaj7	{ ext => 'maj7', name => 'Sibmaj7', qual => '', root => 'Sib', root_canon => 'Sib', root_mod => -1, root_ord => 10 }
Sibdim	{ ext => '', name => 'Sibdim', qual => 0, root => 'Sib', root_canon => 'Sib', root_mod => -1, root_ord => 10 }
Sibm	{ ext => '', name => 'Sibm', qual => '-', root => 'Sib', root_canon => 'Sib', root_mod => -1, root_ord => 10 }
Sibmin	{ ext => '', name => 'Sibmin', qual => 'min', root => 'Sib', root_canon => 'Sib', root_mod => -1, root_ord => 10 }
Sibm7	{ ext => 7, name => 'Sibm7', qual => '-', root => 'Sib', root_canon => 'Sib', root_mod => -1, root_ord => 10 }
Sibm9	{ ext => 9, name => 'Sibm9', qual => '-', root => 'Sib', root_canon => 'Sib', root_mod => -1, root_ord => 10 }
Si	{ ext => '', name => 'Si', qual => '', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11 }
Si+	{ ext => '', name => 'Si+', qual => '+', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11 }
Si4	{ ext => 4, name => 'Si4', qual => '', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11 }
Si7	{ ext => 7, name => 'Si7', qual => '', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11 }
Si7#9	{ ext => '7#9', name => 'Si7#9', qual => '', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11 }
Si9	{ ext => 9, name => 'Si9', qual => '', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11 }
Si11	{ ext => 11, name => 'Si11', qual => '', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11 }
Si13	{ ext => 13, name => 'Si13', qual => '', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11 }
Sisus	{ ext => 'sus4', name => 'Sisus', qual => '', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11 }
Sisus4	{ ext => 'sus4', name => 'Sisus4', qual => '', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11 }
Simaj	{ ext => 'maj', name => 'Simaj', qual => '', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11 }
Simaj7	{ ext => 'maj7', name => 'Simaj7', qual => '', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11 }
Sidim	{ ext => '', name => 'Sidim', qual => 0, root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11 }
Sim	{ ext => '', name => 'Sim', qual => '-', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11 }
Simin	{ ext => '', name => 'Simin', qual => 'min', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11 }
Si/Fa#	{ bass => 'Fa#', bass_canon => 'Fa#', bass_mod => 1, bass_ord => 6, ext => '', name => 'Si', qual => '', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11 }
Sim6	{ ext => 6, name => 'Sim6', qual => '-', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11 }
Sim7	{ ext => 7, name => 'Sim7', qual => '-', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11 }
Simmaj7	{ ext => 'maj7', name => 'Simmaj7', qual => '-', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11 }
Simsus9	{ ext => 'sus9', name => 'Simsus9', qual => '-', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11 }
Sim7b5	{ ext => '7b5', name => 'Sim7b5', qual => '-', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11 }
