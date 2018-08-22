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
	      config => getresource("config/notes_dutch.json") } );
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

=for generating

while ( <DATA> ) {
    chomp;
    my ( $chord, $info ) = split( /\t/, $_ );
    my $c = $chord;
    $c =~ s/[()]//g;
    my $res = App::Music::ChordPro::Chords::parse_chord($c);
    unless ( $res ) {
	print( "$_\tFAIL\n");
	next;
    }
    my $s = Data::Dumper::Dumper($res);
    $s =~ s/\s+/ /gs;
    $s =~ s/, \}/ }/gs;
    $s =~ /\s+$//;
    print("$_\t$s\n");
}

=cut

__DATA__
C	{ ext => '', name => 'C', qual => '', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0 }
C+	{ ext => '', name => 'C+', qual => '+', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0 }
C4	{ ext => 4, name => 'C4', qual => '', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0 }
C6	{ ext => 6, name => 'C6', qual => '', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0 }
C7	{ ext => 7, name => 'C7', qual => '', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0 }
C9	{ ext => 9, name => 'C9', qual => '', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0 }
C9(11)	{ ext => 911, name => 'C911', qual => '', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0 }
C11	{ ext => 11, name => 'C11', qual => '', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0 }
Csus	{ ext => 'sus4', name => 'Csus', qual => '', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0 }
Csus2	{ ext => 'sus2', name => 'Csus2', qual => '', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0 }
Csus4	{ ext => 'sus4', name => 'Csus4', qual => '', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0 }
Csus9	{ ext => 'sus9', name => 'Csus9', qual => '', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0 }
Cmaj	{ ext => 'maj', name => 'Cmaj', qual => '', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0 }
Cmaj7	{ ext => 'maj7', name => 'Cmaj7', qual => '', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0 }
Cm	{ ext => '', name => 'Cm', qual => '-', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0 }
Cmin	{ ext => '', name => 'Cmin', qual => 'min', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0 }
Cdim	{ ext => '', name => 'Cdim', qual => 0, root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0 }
C/B	{ bass => 'B', bass_canon => 'B', bass_mod => 0, bass_ord => 11, ext => '', name => 'C', qual => '', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0 }
Cadd9	{ ext => 'add9', name => 'Cadd9', qual => '', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0 }
C3	{ ext => 3, name => 'C3', qual => '', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0 }
Cm7	{ ext => 7, name => 'Cm7', qual => '-', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0 }
Cm11	{ ext => 11, name => 'Cm11', qual => '-', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0 }
C#	{ ext => '', name => 'C#', qual => '', root => 'C#', root_canon => 'C#', root_mod => 1, root_ord => 1 }
C#+	{ ext => '', name => 'C#+', qual => '+', root => 'C#', root_canon => 'C#', root_mod => 1, root_ord => 1 }
C#4	{ ext => 4, name => 'C#4', qual => '', root => 'C#', root_canon => 'C#', root_mod => 1, root_ord => 1 }
C#7	{ ext => 7, name => 'C#7', qual => '', root => 'C#', root_canon => 'C#', root_mod => 1, root_ord => 1 }
C#7(b5)	{ ext => '7b5', name => 'C#7b5', qual => '', root => 'C#', root_canon => 'C#', root_mod => 1, root_ord => 1 }
C#sus	{ ext => 'sus4', name => 'C#sus', qual => '', root => 'C#', root_canon => 'C#', root_mod => 1, root_ord => 1 }
C#sus4	{ ext => 'sus4', name => 'C#sus4', qual => '', root => 'C#', root_canon => 'C#', root_mod => 1, root_ord => 1 }
C#maj	{ ext => 'maj', name => 'C#maj', qual => '', root => 'C#', root_canon => 'C#', root_mod => 1, root_ord => 1 }
C#maj7	{ ext => 'maj7', name => 'C#maj7', qual => '', root => 'C#', root_canon => 'C#', root_mod => 1, root_ord => 1 }
C#dim	{ ext => '', name => 'C#dim', qual => 0, root => 'C#', root_canon => 'C#', root_mod => 1, root_ord => 1 }
C#m	{ ext => '', name => 'C#m', qual => '-', root => 'C#', root_canon => 'C#', root_mod => 1, root_ord => 1 }
C#min	{ ext => '', name => 'C#min', qual => 'min', root => 'C#', root_canon => 'C#', root_mod => 1, root_ord => 1 }
C#add9	{ ext => 'add9', name => 'C#add9', qual => '', root => 'C#', root_canon => 'C#', root_mod => 1, root_ord => 1 }
C#(add9)	{ ext => 'add9', name => 'C#add9', qual => '', root => 'C#', root_canon => 'C#', root_mod => 1, root_ord => 1 }
C#m7	{ ext => 7, name => 'C#m7', qual => '-', root => 'C#', root_canon => 'C#', root_mod => 1, root_ord => 1 }
Db	{ ext => '', name => 'Db', qual => '', root => 'Db', root_canon => 'Db', root_mod => -1, root_ord => 1 }
Db+	{ ext => '', name => 'Db+', qual => '+', root => 'Db', root_canon => 'Db', root_mod => -1, root_ord => 1 }
Db7	{ ext => 7, name => 'Db7', qual => '', root => 'Db', root_canon => 'Db', root_mod => -1, root_ord => 1 }
Dbsus	{ ext => 'sus4', name => 'Dbsus', qual => '', root => 'Db', root_canon => 'Db', root_mod => -1, root_ord => 1 }
Dbsus4	{ ext => 'sus4', name => 'Dbsus4', qual => '', root => 'Db', root_canon => 'Db', root_mod => -1, root_ord => 1 }
Dbmaj	{ ext => 'maj', name => 'Dbmaj', qual => '', root => 'Db', root_canon => 'Db', root_mod => -1, root_ord => 1 }
Dbmaj7	{ ext => 'maj7', name => 'Dbmaj7', qual => '', root => 'Db', root_canon => 'Db', root_mod => -1, root_ord => 1 }
Dbdim	{ ext => '', name => 'Dbdim', qual => 0, root => 'Db', root_canon => 'Db', root_mod => -1, root_ord => 1 }
Dbm	{ ext => '', name => 'Dbm', qual => '-', root => 'Db', root_canon => 'Db', root_mod => -1, root_ord => 1 }
Dbmin	{ ext => '', name => 'Dbmin', qual => 'min', root => 'Db', root_canon => 'Db', root_mod => -1, root_ord => 1 }
Dbm7	{ ext => 7, name => 'Dbm7', qual => '-', root => 'Db', root_canon => 'Db', root_mod => -1, root_ord => 1 }
D	{ ext => '', name => 'D', qual => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
D+	{ ext => '', name => 'D+', qual => '+', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
D4	{ ext => 4, name => 'D4', qual => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
D6	{ ext => 6, name => 'D6', qual => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
D7	{ ext => 7, name => 'D7', qual => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
D7#9	{ ext => '7#9', name => 'D7#9', qual => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
D7(#9)	{ ext => '7#9', name => 'D7#9', qual => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
D9	{ ext => 9, name => 'D9', qual => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
D11	{ ext => 11, name => 'D11', qual => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
Dsus	{ ext => 'sus4', name => 'Dsus', qual => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
Dsus2	{ ext => 'sus2', name => 'Dsus2', qual => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
Dsus4	{ ext => 'sus4', name => 'Dsus4', qual => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
D7sus2	{ ext => '7sus2', name => 'D7sus2', qual => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
D7sus4	{ ext => '7sus4', name => 'D7sus4', qual => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
Dmaj	{ ext => 'maj', name => 'Dmaj', qual => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
Dmaj7	{ ext => 'maj7', name => 'Dmaj7', qual => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
Ddim	{ ext => '', name => 'Ddim', qual => 0, root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
Dm	{ ext => '', name => 'Dm', qual => '-', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
Dmin	{ ext => '', name => 'Dmin', qual => 'min', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
D/A	{ bass => 'A', bass_canon => 'A', bass_mod => 0, bass_ord => 9, ext => '', name => 'D', qual => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
D/B	{ bass => 'B', bass_canon => 'B', bass_mod => 0, bass_ord => 11, ext => '', name => 'D', qual => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
D/C	{ bass => 'C', bass_canon => 'C', bass_mod => 0, bass_ord => 0, ext => '', name => 'D', qual => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
D/C#	{ bass => 'C#', bass_canon => 'C#', bass_mod => 1, bass_ord => 1, ext => '', name => 'D', qual => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
D/E	{ bass => 'E', bass_canon => 'E', bass_mod => 0, bass_ord => 4, ext => '', name => 'D', qual => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
D/G	{ bass => 'G', bass_canon => 'G', bass_mod => 0, bass_ord => 7, ext => '', name => 'D', qual => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
D5/E	{ bass => 'E', bass_canon => 'E', bass_mod => 0, bass_ord => 4, ext => 5, name => 'D5', qual => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
Dadd9	{ ext => 'add9', name => 'Dadd9', qual => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
D9add6	{ ext => '9add6', name => 'D9add6', qual => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
Dm7	{ ext => 7, name => 'Dm7', qual => '-', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
Dm#5	{ ext => '#5', name => 'Dm#5', qual => '-', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
Dm#7	{ ext => '#7', name => 'Dm#7', qual => '-', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
Dm/A	{ bass => 'A', bass_canon => 'A', bass_mod => 0, bass_ord => 9, ext => '', name => 'Dm', qual => '-', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
Dm/B	{ bass => 'B', bass_canon => 'B', bass_mod => 0, bass_ord => 11, ext => '', name => 'Dm', qual => '-', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
Dm/C	{ bass => 'C', bass_canon => 'C', bass_mod => 0, bass_ord => 0, ext => '', name => 'Dm', qual => '-', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
Dm/C#	{ bass => 'C#', bass_canon => 'C#', bass_mod => 1, bass_ord => 1, ext => '', name => 'Dm', qual => '-', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
Dm9	{ ext => 9, name => 'Dm9', qual => '-', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
D#	{ ext => '', name => 'D#', qual => '', root => 'D#', root_canon => 'D#', root_mod => 1, root_ord => 3 }
D#+	{ ext => '', name => 'D#+', qual => '+', root => 'D#', root_canon => 'D#', root_mod => 1, root_ord => 3 }
D#4	{ ext => 4, name => 'D#4', qual => '', root => 'D#', root_canon => 'D#', root_mod => 1, root_ord => 3 }
D#7	{ ext => 7, name => 'D#7', qual => '', root => 'D#', root_canon => 'D#', root_mod => 1, root_ord => 3 }
D#sus	{ ext => 'sus4', name => 'D#sus', qual => '', root => 'D#', root_canon => 'D#', root_mod => 1, root_ord => 3 }
D#sus4	{ ext => 'sus4', name => 'D#sus4', qual => '', root => 'D#', root_canon => 'D#', root_mod => 1, root_ord => 3 }
D#maj	{ ext => 'maj', name => 'D#maj', qual => '', root => 'D#', root_canon => 'D#', root_mod => 1, root_ord => 3 }
D#maj7	{ ext => 'maj7', name => 'D#maj7', qual => '', root => 'D#', root_canon => 'D#', root_mod => 1, root_ord => 3 }
D#dim	{ ext => '', name => 'D#dim', qual => 0, root => 'D#', root_canon => 'D#', root_mod => 1, root_ord => 3 }
D#m	{ ext => '', name => 'D#m', qual => '-', root => 'D#', root_canon => 'D#', root_mod => 1, root_ord => 3 }
D#min	{ ext => '', name => 'D#min', qual => 'min', root => 'D#', root_canon => 'D#', root_mod => 1, root_ord => 3 }
D#m7	{ ext => 7, name => 'D#m7', qual => '-', root => 'D#', root_canon => 'D#', root_mod => 1, root_ord => 3 }
Eb	{ ext => '', name => 'Eb', qual => '', root => 'Eb', root_canon => 'Eb', root_mod => -1, root_ord => 3 }
Eb+	{ ext => '', name => 'Eb+', qual => '+', root => 'Eb', root_canon => 'Eb', root_mod => -1, root_ord => 3 }
Eb4	{ ext => 4, name => 'Eb4', qual => '', root => 'Eb', root_canon => 'Eb', root_mod => -1, root_ord => 3 }
Eb7	{ ext => 7, name => 'Eb7', qual => '', root => 'Eb', root_canon => 'Eb', root_mod => -1, root_ord => 3 }
Ebsus	{ ext => 'sus4', name => 'Ebsus', qual => '', root => 'Eb', root_canon => 'Eb', root_mod => -1, root_ord => 3 }
Ebsus4	{ ext => 'sus4', name => 'Ebsus4', qual => '', root => 'Eb', root_canon => 'Eb', root_mod => -1, root_ord => 3 }
Ebmaj	{ ext => 'maj', name => 'Ebmaj', qual => '', root => 'Eb', root_canon => 'Eb', root_mod => -1, root_ord => 3 }
Ebmaj7	{ ext => 'maj7', name => 'Ebmaj7', qual => '', root => 'Eb', root_canon => 'Eb', root_mod => -1, root_ord => 3 }
Ebdim	{ ext => '', name => 'Ebdim', qual => 0, root => 'Eb', root_canon => 'Eb', root_mod => -1, root_ord => 3 }
Ebadd9	{ ext => 'add9', name => 'Ebadd9', qual => '', root => 'Eb', root_canon => 'Eb', root_mod => -1, root_ord => 3 }
Eb(add9)	{ ext => 'add9', name => 'Ebadd9', qual => '', root => 'Eb', root_canon => 'Eb', root_mod => -1, root_ord => 3 }
Ebm	{ ext => '', name => 'Ebm', qual => '-', root => 'Eb', root_canon => 'Eb', root_mod => -1, root_ord => 3 }
Ebmin	{ ext => '', name => 'Ebmin', qual => 'min', root => 'Eb', root_canon => 'Eb', root_mod => -1, root_ord => 3 }
Ebm7	{ ext => 7, name => 'Ebm7', qual => '-', root => 'Eb', root_canon => 'Eb', root_mod => -1, root_ord => 3 }
E	{ ext => '', name => 'E', qual => '', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4 }
E+	{ ext => '', name => 'E+', qual => '+', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4 }
E5	{ ext => 5, name => 'E5', qual => '', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4 }
E6	{ ext => 6, name => 'E6', qual => '', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4 }
E7	{ ext => 7, name => 'E7', qual => '', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4 }
E7#9	{ ext => '7#9', name => 'E7#9', qual => '', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4 }
E7(#9)	{ ext => '7#9', name => 'E7#9', qual => '', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4 }
E7(b5)	{ ext => '7b5', name => 'E7b5', qual => '', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4 }
E7b9	{ ext => '7b9', name => 'E7b9', qual => '', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4 }
E7(11)	{ ext => 711, name => 'E711', qual => '', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4 }
E9	{ ext => 9, name => 'E9', qual => '', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4 }
E11	{ ext => 11, name => 'E11', qual => '', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4 }
Esus	{ ext => 'sus4', name => 'Esus', qual => '', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4 }
Emaj	{ ext => 'maj', name => 'Emaj', qual => '', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4 }
Emaj7	{ ext => 'maj7', name => 'Emaj7', qual => '', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4 }
Edim	{ ext => '', name => 'Edim', qual => 0, root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4 }
Em	{ ext => '', name => 'Em', qual => '-', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4 }
Emin	{ ext => '', name => 'Emin', qual => 'min', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4 }
Em6	{ ext => 6, name => 'Em6', qual => '-', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4 }
Em7	{ ext => 7, name => 'Em7', qual => '-', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4 }
Em/B	{ bass => 'B', bass_canon => 'B', bass_mod => 0, bass_ord => 11, ext => '', name => 'Em', qual => '-', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4 }
Em/D	{ bass => 'D', bass_canon => 'D', bass_mod => 0, bass_ord => 2, ext => '', name => 'Em', qual => '-', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4 }
Em7/D	{ bass => 'D', bass_canon => 'D', bass_mod => 0, bass_ord => 2, ext => 7, name => 'Em7', qual => '-', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4 }
Emsus4	{ ext => 'sus4', name => 'Emsus4', qual => '-', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4 }
Emadd9	{ ext => 'add9', name => 'Emadd9', qual => '-', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4 }
F	{ ext => '', name => 'F', qual => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5 }
F+	{ ext => '', name => 'F+', qual => '+', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5 }
F4	{ ext => 4, name => 'F4', qual => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5 }
F6	{ ext => 6, name => 'F6', qual => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5 }
F7	{ ext => 7, name => 'F7', qual => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5 }
F9	{ ext => 9, name => 'F9', qual => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5 }
F11	{ ext => 11, name => 'F11', qual => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5 }
Fsus	{ ext => 'sus4', name => 'Fsus', qual => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5 }
Fsus4	{ ext => 'sus4', name => 'Fsus4', qual => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5 }
Fmaj	{ ext => 'maj', name => 'Fmaj', qual => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5 }
Fmaj7	{ ext => 'maj7', name => 'Fmaj7', qual => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5 }
Fdim	{ ext => '', name => 'Fdim', qual => 0, root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5 }
Fm	{ ext => '', name => 'Fm', qual => '-', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5 }
Fmin	{ ext => '', name => 'Fmin', qual => 'min', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5 }
F/A	{ bass => 'A', bass_canon => 'A', bass_mod => 0, bass_ord => 9, ext => '', name => 'F', qual => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5 }
F/C	{ bass => 'C', bass_canon => 'C', bass_mod => 0, bass_ord => 0, ext => '', name => 'F', qual => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5 }
F/D	{ bass => 'D', bass_canon => 'D', bass_mod => 0, bass_ord => 2, ext => '', name => 'F', qual => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5 }
F/G	{ bass => 'G', bass_canon => 'G', bass_mod => 0, bass_ord => 7, ext => '', name => 'F', qual => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5 }
F7/A	{ bass => 'A', bass_canon => 'A', bass_mod => 0, bass_ord => 9, ext => 7, name => 'F7', qual => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5 }
Fmaj7/A	{ bass => 'A', bass_canon => 'A', bass_mod => 0, bass_ord => 9, ext => 'maj7', name => 'Fmaj7', qual => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5 }
Fmaj7/C	{ bass => 'C', bass_canon => 'C', bass_mod => 0, bass_ord => 0, ext => 'maj7', name => 'Fmaj7', qual => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5 }
Fadd9	{ ext => 'add9', name => 'Fadd9', qual => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5 }
Fm6	{ ext => 6, name => 'Fm6', qual => '-', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5 }
Fm7	{ ext => 7, name => 'Fm7', qual => '-', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5 }
Fmmaj7	{ ext => 'maj7', name => 'Fmmaj7', qual => '-', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5 }
F#	{ ext => '', name => 'F#', qual => '', root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6 }
F#+	{ ext => '', name => 'F#+', qual => '+', root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6 }
F#7	{ ext => 7, name => 'F#7', qual => '', root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6 }
F#9	{ ext => 9, name => 'F#9', qual => '', root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6 }
F#11	{ ext => 11, name => 'F#11', qual => '', root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6 }
F#sus	{ ext => 'sus4', name => 'F#sus', qual => '', root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6 }
F#sus4	{ ext => 'sus4', name => 'F#sus4', qual => '', root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6 }
F#maj7	{ ext => 'maj7', name => 'F#maj7', qual => '', root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6 }
F#dim	{ ext => '', name => 'F#dim', qual => 0, root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6 }
F#m	{ ext => '', name => 'F#m', qual => '-', root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6 }
F#min	{ ext => '', name => 'F#min', qual => 'min', root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6 }
F#/E	{ bass => 'E', bass_canon => 'E', bass_mod => 0, bass_ord => 4, ext => '', name => 'F#', qual => '', root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6 }
F#4	{ ext => 4, name => 'F#4', qual => '', root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6 }
F#m6	{ ext => 6, name => 'F#m6', qual => '-', root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6 }
F#m7	{ ext => 7, name => 'F#m7', qual => '-', root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6 }
F#m7b5	{ ext => '7b5', name => 'F#m7b5', qual => '-', root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6 }
F#m/C	{ bass => 'C', bass_canon => 'C', bass_mod => 0, bass_ord => 0, ext => '', name => 'F#m', qual => '-', root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6 }
Gb	{ ext => '', name => 'Gb', qual => '', root => 'Gb', root_canon => 'Gb', root_mod => -1, root_ord => 6 }
Gb+	{ ext => '', name => 'Gb+', qual => '+', root => 'Gb', root_canon => 'Gb', root_mod => -1, root_ord => 6 }
Gb7	{ ext => 7, name => 'Gb7', qual => '', root => 'Gb', root_canon => 'Gb', root_mod => -1, root_ord => 6 }
Gb9	{ ext => 9, name => 'Gb9', qual => '', root => 'Gb', root_canon => 'Gb', root_mod => -1, root_ord => 6 }
Gbsus	{ ext => 'sus4', name => 'Gbsus', qual => '', root => 'Gb', root_canon => 'Gb', root_mod => -1, root_ord => 6 }
Gbsus4	{ ext => 'sus4', name => 'Gbsus4', qual => '', root => 'Gb', root_canon => 'Gb', root_mod => -1, root_ord => 6 }
Gbmaj	{ ext => 'maj', name => 'Gbmaj', qual => '', root => 'Gb', root_canon => 'Gb', root_mod => -1, root_ord => 6 }
Gbmaj7	{ ext => 'maj7', name => 'Gbmaj7', qual => '', root => 'Gb', root_canon => 'Gb', root_mod => -1, root_ord => 6 }
Gbdim	{ ext => '', name => 'Gbdim', qual => 0, root => 'Gb', root_canon => 'Gb', root_mod => -1, root_ord => 6 }
Gbm	{ ext => '', name => 'Gbm', qual => '-', root => 'Gb', root_canon => 'Gb', root_mod => -1, root_ord => 6 }
Gbmin	{ ext => '', name => 'Gbmin', qual => 'min', root => 'Gb', root_canon => 'Gb', root_mod => -1, root_ord => 6 }
Gbm7	{ ext => 7, name => 'Gbm7', qual => '-', root => 'Gb', root_canon => 'Gb', root_mod => -1, root_ord => 6 }
G	{ ext => '', name => 'G', qual => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7 }
G+	{ ext => '', name => 'G+', qual => '+', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7 }
G4	{ ext => 4, name => 'G4', qual => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7 }
G6	{ ext => 6, name => 'G6', qual => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7 }
G7	{ ext => 7, name => 'G7', qual => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7 }
G7b9	{ ext => '7b9', name => 'G7b9', qual => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7 }
G7#9	{ ext => '7#9', name => 'G7#9', qual => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7 }
G9	{ ext => 9, name => 'G9', qual => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7 }
G9(11)	{ ext => 911, name => 'G911', qual => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7 }
G11	{ ext => 11, name => 'G11', qual => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7 }
Gsus	{ ext => 'sus4', name => 'Gsus', qual => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7 }
Gsus4	{ ext => 'sus4', name => 'Gsus4', qual => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7 }
G6sus4	{ ext => '6sus4', name => 'G6sus4', qual => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7 }
G7sus4	{ ext => '7sus4', name => 'G7sus4', qual => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7 }
Gmaj	{ ext => 'maj', name => 'Gmaj', qual => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7 }
Gmaj7	{ ext => 'maj7', name => 'Gmaj7', qual => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7 }
Gmaj7sus4	{ ext => 'maj7sus4', name => 'Gmaj7sus4', qual => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7 }
Gmaj9	{ ext => 'maj9', name => 'Gmaj9', qual => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7 }
Gm	{ ext => '', name => 'Gm', qual => '-', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7 }
Gmin	{ ext => '', name => 'Gmin', qual => 'min', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7 }
Gdim	{ ext => '', name => 'Gdim', qual => 0, root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7 }
Gadd9	{ ext => 'add9', name => 'Gadd9', qual => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7 }
G(add9)	{ ext => 'add9', name => 'Gadd9', qual => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7 }
G/A	{ bass => 'A', bass_canon => 'A', bass_mod => 0, bass_ord => 9, ext => '', name => 'G', qual => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7 }
G/B	{ bass => 'B', bass_canon => 'B', bass_mod => 0, bass_ord => 11, ext => '', name => 'G', qual => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7 }
G/D	{ bass => 'D', bass_canon => 'D', bass_mod => 0, bass_ord => 2, ext => '', name => 'G', qual => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7 }
G/F#	{ bass => 'F#', bass_canon => 'F#', bass_mod => 1, bass_ord => 6, ext => '', name => 'G', qual => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7 }
Gm6	{ ext => 6, name => 'Gm6', qual => '-', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7 }
Gm7	{ ext => 7, name => 'Gm7', qual => '-', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7 }
Gm/Bb	{ bass => 'Bb', bass_canon => 'Bb', bass_mod => -1, bass_ord => 10, ext => '', name => 'Gm', qual => '-', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7 }
G#	{ ext => '', name => 'G#', qual => '', root => 'G#', root_canon => 'G#', root_mod => 1, root_ord => 8 }
G#+	{ ext => '', name => 'G#+', qual => '+', root => 'G#', root_canon => 'G#', root_mod => 1, root_ord => 8 }
G#4	{ ext => 4, name => 'G#4', qual => '', root => 'G#', root_canon => 'G#', root_mod => 1, root_ord => 8 }
G#7	{ ext => 7, name => 'G#7', qual => '', root => 'G#', root_canon => 'G#', root_mod => 1, root_ord => 8 }
G#sus	{ ext => 'sus4', name => 'G#sus', qual => '', root => 'G#', root_canon => 'G#', root_mod => 1, root_ord => 8 }
G#sus4	{ ext => 'sus4', name => 'G#sus4', qual => '', root => 'G#', root_canon => 'G#', root_mod => 1, root_ord => 8 }
G#maj	{ ext => 'maj', name => 'G#maj', qual => '', root => 'G#', root_canon => 'G#', root_mod => 1, root_ord => 8 }
G#maj7	{ ext => 'maj7', name => 'G#maj7', qual => '', root => 'G#', root_canon => 'G#', root_mod => 1, root_ord => 8 }
G#dim	{ ext => '', name => 'G#dim', qual => 0, root => 'G#', root_canon => 'G#', root_mod => 1, root_ord => 8 }
G#m	{ ext => '', name => 'G#m', qual => '-', root => 'G#', root_canon => 'G#', root_mod => 1, root_ord => 8 }
G#min	{ ext => '', name => 'G#min', qual => 'min', root => 'G#', root_canon => 'G#', root_mod => 1, root_ord => 8 }
G#m6	{ ext => 6, name => 'G#m6', qual => '-', root => 'G#', root_canon => 'G#', root_mod => 1, root_ord => 8 }
G#m7	{ ext => 7, name => 'G#m7', qual => '-', root => 'G#', root_canon => 'G#', root_mod => 1, root_ord => 8 }
G#m9maj7	{ ext => '9maj7', name => 'G#m9maj7', qual => '-', root => 'G#', root_canon => 'G#', root_mod => 1, root_ord => 8 }
Ab	{ ext => '', name => 'Ab', qual => '', root => 'Ab', root_canon => 'Ab', root_mod => -1, root_ord => 8 }
Ab+	{ ext => '', name => 'Ab+', qual => '+', root => 'Ab', root_canon => 'Ab', root_mod => -1, root_ord => 8 }
Ab4	{ ext => 4, name => 'Ab4', qual => '', root => 'Ab', root_canon => 'Ab', root_mod => -1, root_ord => 8 }
Ab7	{ ext => 7, name => 'Ab7', qual => '', root => 'Ab', root_canon => 'Ab', root_mod => -1, root_ord => 8 }
Ab11	{ ext => 11, name => 'Ab11', qual => '', root => 'Ab', root_canon => 'Ab', root_mod => -1, root_ord => 8 }
Absus	{ ext => 'sus4', name => 'Absus', qual => '', root => 'Ab', root_canon => 'Ab', root_mod => -1, root_ord => 8 }
Absus4	{ ext => 'sus4', name => 'Absus4', qual => '', root => 'Ab', root_canon => 'Ab', root_mod => -1, root_ord => 8 }
Abdim	{ ext => '', name => 'Abdim', qual => 0, root => 'Ab', root_canon => 'Ab', root_mod => -1, root_ord => 8 }
Abmaj	{ ext => 'maj', name => 'Abmaj', qual => '', root => 'Ab', root_canon => 'Ab', root_mod => -1, root_ord => 8 }
Abmaj7	{ ext => 'maj7', name => 'Abmaj7', qual => '', root => 'Ab', root_canon => 'Ab', root_mod => -1, root_ord => 8 }
Abm	{ ext => '', name => 'Abm', qual => '-', root => 'Ab', root_canon => 'Ab', root_mod => -1, root_ord => 8 }
Abmin	{ ext => '', name => 'Abmin', qual => 'min', root => 'Ab', root_canon => 'Ab', root_mod => -1, root_ord => 8 }
Abm7	{ ext => 7, name => 'Abm7', qual => '-', root => 'Ab', root_canon => 'Ab', root_mod => -1, root_ord => 8 }
A	{ ext => '', name => 'A', qual => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
A+	{ ext => '', name => 'A+', qual => '+', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
A4	{ ext => 4, name => 'A4', qual => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
A6	{ ext => 6, name => 'A6', qual => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
A7	{ ext => 7, name => 'A7', qual => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
A9	{ ext => 9, name => 'A9', qual => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
A11	{ ext => 11, name => 'A11', qual => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
A13	{ ext => 13, name => 'A13', qual => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
A7sus4	{ ext => '7sus4', name => 'A7sus4', qual => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
A9sus	{ ext => '9sus', name => 'A9sus', qual => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
Asus	{ ext => 'sus4', name => 'Asus', qual => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
Asus2	{ ext => 'sus2', name => 'Asus2', qual => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
Asus4	{ ext => 'sus4', name => 'Asus4', qual => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
Adim	{ ext => '', name => 'Adim', qual => 0, root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
Amaj	{ ext => 'maj', name => 'Amaj', qual => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
Amaj7	{ ext => 'maj7', name => 'Amaj7', qual => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
Am	{ ext => '', name => 'Am', qual => '-', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
Amin	{ ext => '', name => 'Amin', qual => 'min', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
A/C#	{ bass => 'C#', bass_canon => 'C#', bass_mod => 1, bass_ord => 1, ext => '', name => 'A', qual => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
A/D	{ bass => 'D', bass_canon => 'D', bass_mod => 0, bass_ord => 2, ext => '', name => 'A', qual => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
A/E	{ bass => 'E', bass_canon => 'E', bass_mod => 0, bass_ord => 4, ext => '', name => 'A', qual => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
A/F#	{ bass => 'F#', bass_canon => 'F#', bass_mod => 1, bass_ord => 6, ext => '', name => 'A', qual => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
A/G#	{ bass => 'G#', bass_canon => 'G#', bass_mod => 1, bass_ord => 8, ext => '', name => 'A', qual => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
Am#7	{ ext => '#7', name => 'Am#7', qual => '-', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
Am6	{ ext => 6, name => 'Am6', qual => '-', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
Am7	{ ext => 7, name => 'Am7', qual => '-', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
Am7sus4	{ ext => '7sus4', name => 'Am7sus4', qual => '-', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
Am9	{ ext => 9, name => 'Am9', qual => '-', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
Am/G	{ bass => 'G', bass_canon => 'G', bass_mod => 0, bass_ord => 7, ext => '', name => 'Am', qual => '-', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
Amadd9	{ ext => 'add9', name => 'Amadd9', qual => '-', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
A#	{ ext => '', name => 'A#', qual => '', root => 'A#', root_canon => 'A#', root_mod => 1, root_ord => 10 }
A#+	{ ext => '', name => 'A#+', qual => '+', root => 'A#', root_canon => 'A#', root_mod => 1, root_ord => 10 }
A#4	{ ext => 4, name => 'A#4', qual => '', root => 'A#', root_canon => 'A#', root_mod => 1, root_ord => 10 }
A#7	{ ext => 7, name => 'A#7', qual => '', root => 'A#', root_canon => 'A#', root_mod => 1, root_ord => 10 }
A#sus	{ ext => 'sus4', name => 'A#sus', qual => '', root => 'A#', root_canon => 'A#', root_mod => 1, root_ord => 10 }
A#sus4	{ ext => 'sus4', name => 'A#sus4', qual => '', root => 'A#', root_canon => 'A#', root_mod => 1, root_ord => 10 }
A#maj	{ ext => 'maj', name => 'A#maj', qual => '', root => 'A#', root_canon => 'A#', root_mod => 1, root_ord => 10 }
A#maj7	{ ext => 'maj7', name => 'A#maj7', qual => '', root => 'A#', root_canon => 'A#', root_mod => 1, root_ord => 10 }
A#dim	{ ext => '', name => 'A#dim', qual => 0, root => 'A#', root_canon => 'A#', root_mod => 1, root_ord => 10 }
A#m	{ ext => '', name => 'A#m', qual => '-', root => 'A#', root_canon => 'A#', root_mod => 1, root_ord => 10 }
A#min	{ ext => '', name => 'A#min', qual => 'min', root => 'A#', root_canon => 'A#', root_mod => 1, root_ord => 10 }
A#m7	{ ext => 7, name => 'A#m7', qual => '-', root => 'A#', root_canon => 'A#', root_mod => 1, root_ord => 10 }
Bb	{ ext => '', name => 'Bb', qual => '', root => 'Bb', root_canon => 'Bb', root_mod => -1, root_ord => 10 }
Bb+	{ ext => '', name => 'Bb+', qual => '+', root => 'Bb', root_canon => 'Bb', root_mod => -1, root_ord => 10 }
Bb4	{ ext => 4, name => 'Bb4', qual => '', root => 'Bb', root_canon => 'Bb', root_mod => -1, root_ord => 10 }
Bb6	{ ext => 6, name => 'Bb6', qual => '', root => 'Bb', root_canon => 'Bb', root_mod => -1, root_ord => 10 }
Bb7	{ ext => 7, name => 'Bb7', qual => '', root => 'Bb', root_canon => 'Bb', root_mod => -1, root_ord => 10 }
Bb9	{ ext => 9, name => 'Bb9', qual => '', root => 'Bb', root_canon => 'Bb', root_mod => -1, root_ord => 10 }
Bb11	{ ext => 11, name => 'Bb11', qual => '', root => 'Bb', root_canon => 'Bb', root_mod => -1, root_ord => 10 }
Bbsus	{ ext => 'sus4', name => 'Bbsus', qual => '', root => 'Bb', root_canon => 'Bb', root_mod => -1, root_ord => 10 }
Bbsus4	{ ext => 'sus4', name => 'Bbsus4', qual => '', root => 'Bb', root_canon => 'Bb', root_mod => -1, root_ord => 10 }
Bbmaj	{ ext => 'maj', name => 'Bbmaj', qual => '', root => 'Bb', root_canon => 'Bb', root_mod => -1, root_ord => 10 }
Bbmaj7	{ ext => 'maj7', name => 'Bbmaj7', qual => '', root => 'Bb', root_canon => 'Bb', root_mod => -1, root_ord => 10 }
Bbdim	{ ext => '', name => 'Bbdim', qual => 0, root => 'Bb', root_canon => 'Bb', root_mod => -1, root_ord => 10 }
Bbm	{ ext => '', name => 'Bbm', qual => '-', root => 'Bb', root_canon => 'Bb', root_mod => -1, root_ord => 10 }
Bbmin	{ ext => '', name => 'Bbmin', qual => 'min', root => 'Bb', root_canon => 'Bb', root_mod => -1, root_ord => 10 }
Bbm7	{ ext => 7, name => 'Bbm7', qual => '-', root => 'Bb', root_canon => 'Bb', root_mod => -1, root_ord => 10 }
Bbm9	{ ext => 9, name => 'Bbm9', qual => '-', root => 'Bb', root_canon => 'Bb', root_mod => -1, root_ord => 10 }
B	{ ext => '', name => 'B', qual => '', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11 }
B+	{ ext => '', name => 'B+', qual => '+', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11 }
B4	{ ext => 4, name => 'B4', qual => '', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11 }
B7	{ ext => 7, name => 'B7', qual => '', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11 }
B7#9	{ ext => '7#9', name => 'B7#9', qual => '', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11 }
B9	{ ext => 9, name => 'B9', qual => '', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11 }
B11	{ ext => 11, name => 'B11', qual => '', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11 }
B13	{ ext => 13, name => 'B13', qual => '', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11 }
Bsus	{ ext => 'sus4', name => 'Bsus', qual => '', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11 }
Bsus4	{ ext => 'sus4', name => 'Bsus4', qual => '', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11 }
Bmaj	{ ext => 'maj', name => 'Bmaj', qual => '', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11 }
Bmaj7	{ ext => 'maj7', name => 'Bmaj7', qual => '', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11 }
Bdim	{ ext => '', name => 'Bdim', qual => 0, root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11 }
Bm	{ ext => '', name => 'Bm', qual => '-', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11 }
Bmin	{ ext => '', name => 'Bmin', qual => 'min', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11 }
B/F#	{ bass => 'F#', bass_canon => 'F#', bass_mod => 1, bass_ord => 6, ext => '', name => 'B', qual => '', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11 }
Bm6	{ ext => 6, name => 'Bm6', qual => '-', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11 }
Bm7	{ ext => 7, name => 'Bm7', qual => '-', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11 }
Bmmaj7	{ ext => 'maj7', name => 'Bmmaj7', qual => '-', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11 }
Bmsus9	{ ext => 'sus9', name => 'Bmsus9', qual => '-', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11 }
Bm7b5	{ ext => '7b5', name => 'Bm7b5', qual => '-', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11 }
1	{ ext => '', name => 1, qual => '', root => 1, root_canon => 1, root_ord => 0, system => 'nashville' }
17	{ ext => 7, name => 17, qual => '', root => 1, root_canon => 1, root_ord => 0, system => 'nashville' }
1^	{ ext => '^', name => '1^', qual => '', root => 1, root_canon => 1, root_ord => 0, system => 'nashville' }
1h	{ ext => 'h', name => '1h', qual => '', root => 1, root_canon => 1, root_ord => 0, system => 'nashville' }
1h7	{ ext => 'h7', name => '1h7', qual => '', root => 1, root_canon => 1, root_ord => 0, system => 'nashville' }
1^7	{ ext => '^7', name => '1^7', qual => '', root => 1, root_canon => 1, root_ord => 0, system => 'nashville' }
1-	{ ext => '', name => '1-', qual => '-', root => 1, root_canon => 1, root_ord => 0, system => 'nashville' }
1-7	{ ext => 7, name => '1-7', qual => '-', root => 1, root_canon => 1, root_ord => 0, system => 'nashville' }
1-^	{ ext => '^', name => '1-^', qual => '-', root => 1, root_canon => 1, root_ord => 0, system => 'nashville' }
1-h	{ ext => 'h', name => '1-h', qual => '-', root => 1, root_canon => 1, root_ord => 0, system => 'nashville' }
1-h7	{ ext => 'h7', name => '1-h7', qual => '-', root => 1, root_canon => 1, root_ord => 0, system => 'nashville' }
1-^7	{ ext => '^7', name => '1-^7', qual => '-', root => 1, root_canon => 1, root_ord => 0, system => 'nashville' }
10	{ ext => '', name => 10, qual => 0, root => 1, root_canon => 1, root_ord => 0, system => 'nashville' }
107	{ ext => 7, name => 107, qual => 0, root => 1, root_canon => 1, root_ord => 0, system => 'nashville' }
10^	{ ext => '^', name => '10^', qual => 0, root => 1, root_canon => 1, root_ord => 0, system => 'nashville' }
10h	{ ext => 'h', name => '10h', qual => 0, root => 1, root_canon => 1, root_ord => 0, system => 'nashville' }
10h7	{ ext => 'h7', name => '10h7', qual => 0, root => 1, root_canon => 1, root_ord => 0, system => 'nashville' }
10^7	{ ext => '^7', name => '10^7', qual => 0, root => 1, root_canon => 1, root_ord => 0, system => 'nashville' }
1+	{ ext => '', name => '1+', qual => '+', root => 1, root_canon => 1, root_ord => 0, system => 'nashville' }
1+7	{ ext => 7, name => '1+7', qual => '+', root => 1, root_canon => 1, root_ord => 0, system => 'nashville' }
1+^	{ ext => '^', name => '1+^', qual => '+', root => 1, root_canon => 1, root_ord => 0, system => 'nashville' }
1+h	{ ext => 'h', name => '1+h', qual => '+', root => 1, root_canon => 1, root_ord => 0, system => 'nashville' }
1+h7	{ ext => 'h7', name => '1+h7', qual => '+', root => 1, root_canon => 1, root_ord => 0, system => 'nashville' }
1+^7	{ ext => '^7', name => '1+^7', qual => '+', root => 1, root_canon => 1, root_ord => 0, system => 'nashville' }
#1	{ ext => '', name => '#1', qual => '', root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#17	{ ext => 7, name => '#17', qual => '', root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#1^	{ ext => '^', name => '#1^', qual => '', root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#1h	{ ext => 'h', name => '#1h', qual => '', root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#1h7	{ ext => 'h7', name => '#1h7', qual => '', root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#1^7	{ ext => '^7', name => '#1^7', qual => '', root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#1-	{ ext => '', name => '#1-', qual => '-', root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#1-7	{ ext => 7, name => '#1-7', qual => '-', root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#1-^	{ ext => '^', name => '#1-^', qual => '-', root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#1-h	{ ext => 'h', name => '#1-h', qual => '-', root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#1-h7	{ ext => 'h7', name => '#1-h7', qual => '-', root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#1-^7	{ ext => '^7', name => '#1-^7', qual => '-', root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#10	{ ext => '', name => '#10', qual => 0, root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#107	{ ext => 7, name => '#107', qual => 0, root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#10^	{ ext => '^', name => '#10^', qual => 0, root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#10h	{ ext => 'h', name => '#10h', qual => 0, root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#10h7	{ ext => 'h7', name => '#10h7', qual => 0, root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#10^7	{ ext => '^7', name => '#10^7', qual => 0, root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#1+	{ ext => '', name => '#1+', qual => '+', root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#1+7	{ ext => 7, name => '#1+7', qual => '+', root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#1+^	{ ext => '^', name => '#1+^', qual => '+', root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#1+h	{ ext => 'h', name => '#1+h', qual => '+', root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#1+h7	{ ext => 'h7', name => '#1+h7', qual => '+', root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#1+^7	{ ext => '^7', name => '#1+^7', qual => '+', root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
b2	{ ext => '', name => 'b2', qual => '', root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b27	{ ext => 7, name => 'b27', qual => '', root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b2^	{ ext => '^', name => 'b2^', qual => '', root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b2h	{ ext => 'h', name => 'b2h', qual => '', root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b2h7	{ ext => 'h7', name => 'b2h7', qual => '', root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b2^7	{ ext => '^7', name => 'b2^7', qual => '', root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b2-	{ ext => '', name => 'b2-', qual => '-', root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b2-7	{ ext => 7, name => 'b2-7', qual => '-', root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b2-^	{ ext => '^', name => 'b2-^', qual => '-', root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b2-h	{ ext => 'h', name => 'b2-h', qual => '-', root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b2-h7	{ ext => 'h7', name => 'b2-h7', qual => '-', root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b2-^7	{ ext => '^7', name => 'b2-^7', qual => '-', root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b20	{ ext => '', name => 'b20', qual => 0, root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b207	{ ext => 7, name => 'b207', qual => 0, root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b20^	{ ext => '^', name => 'b20^', qual => 0, root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b20h	{ ext => 'h', name => 'b20h', qual => 0, root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b20h7	{ ext => 'h7', name => 'b20h7', qual => 0, root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b20^7	{ ext => '^7', name => 'b20^7', qual => 0, root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b2+	{ ext => '', name => 'b2+', qual => '+', root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b2+7	{ ext => 7, name => 'b2+7', qual => '+', root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b2+^	{ ext => '^', name => 'b2+^', qual => '+', root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b2+h	{ ext => 'h', name => 'b2+h', qual => '+', root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b2+h7	{ ext => 'h7', name => 'b2+h7', qual => '+', root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b2+^7	{ ext => '^7', name => 'b2+^7', qual => '+', root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
2	{ ext => '', name => 2, qual => '', root => 2, root_canon => 2, root_ord => 2, system => 'nashville' }
27	{ ext => 7, name => 27, qual => '', root => 2, root_canon => 2, root_ord => 2, system => 'nashville' }
2^	{ ext => '^', name => '2^', qual => '', root => 2, root_canon => 2, root_ord => 2, system => 'nashville' }
2h	{ ext => 'h', name => '2h', qual => '', root => 2, root_canon => 2, root_ord => 2, system => 'nashville' }
2h7	{ ext => 'h7', name => '2h7', qual => '', root => 2, root_canon => 2, root_ord => 2, system => 'nashville' }
2^7	{ ext => '^7', name => '2^7', qual => '', root => 2, root_canon => 2, root_ord => 2, system => 'nashville' }
2-	{ ext => '', name => '2-', qual => '-', root => 2, root_canon => 2, root_ord => 2, system => 'nashville' }
2-7	{ ext => 7, name => '2-7', qual => '-', root => 2, root_canon => 2, root_ord => 2, system => 'nashville' }
2-^	{ ext => '^', name => '2-^', qual => '-', root => 2, root_canon => 2, root_ord => 2, system => 'nashville' }
2-h	{ ext => 'h', name => '2-h', qual => '-', root => 2, root_canon => 2, root_ord => 2, system => 'nashville' }
2-h7	{ ext => 'h7', name => '2-h7', qual => '-', root => 2, root_canon => 2, root_ord => 2, system => 'nashville' }
2-^7	{ ext => '^7', name => '2-^7', qual => '-', root => 2, root_canon => 2, root_ord => 2, system => 'nashville' }
20	{ ext => '', name => 20, qual => 0, root => 2, root_canon => 2, root_ord => 2, system => 'nashville' }
207	{ ext => 7, name => 207, qual => 0, root => 2, root_canon => 2, root_ord => 2, system => 'nashville' }
20^	{ ext => '^', name => '20^', qual => 0, root => 2, root_canon => 2, root_ord => 2, system => 'nashville' }
20h	{ ext => 'h', name => '20h', qual => 0, root => 2, root_canon => 2, root_ord => 2, system => 'nashville' }
20h7	{ ext => 'h7', name => '20h7', qual => 0, root => 2, root_canon => 2, root_ord => 2, system => 'nashville' }
20^7	{ ext => '^7', name => '20^7', qual => 0, root => 2, root_canon => 2, root_ord => 2, system => 'nashville' }
2+	{ ext => '', name => '2+', qual => '+', root => 2, root_canon => 2, root_ord => 2, system => 'nashville' }
2+7	{ ext => 7, name => '2+7', qual => '+', root => 2, root_canon => 2, root_ord => 2, system => 'nashville' }
2+^	{ ext => '^', name => '2+^', qual => '+', root => 2, root_canon => 2, root_ord => 2, system => 'nashville' }
2+h	{ ext => 'h', name => '2+h', qual => '+', root => 2, root_canon => 2, root_ord => 2, system => 'nashville' }
2+h7	{ ext => 'h7', name => '2+h7', qual => '+', root => 2, root_canon => 2, root_ord => 2, system => 'nashville' }
2+^7	{ ext => '^7', name => '2+^7', qual => '+', root => 2, root_canon => 2, root_ord => 2, system => 'nashville' }
#2	{ ext => '', name => '#2', qual => '', root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#27	{ ext => 7, name => '#27', qual => '', root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#2^	{ ext => '^', name => '#2^', qual => '', root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#2h	{ ext => 'h', name => '#2h', qual => '', root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#2h7	{ ext => 'h7', name => '#2h7', qual => '', root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#2^7	{ ext => '^7', name => '#2^7', qual => '', root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#2-	{ ext => '', name => '#2-', qual => '-', root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#2-7	{ ext => 7, name => '#2-7', qual => '-', root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#2-^	{ ext => '^', name => '#2-^', qual => '-', root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#2-h	{ ext => 'h', name => '#2-h', qual => '-', root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#2-h7	{ ext => 'h7', name => '#2-h7', qual => '-', root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#2-^7	{ ext => '^7', name => '#2-^7', qual => '-', root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#20	{ ext => '', name => '#20', qual => 0, root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#207	{ ext => 7, name => '#207', qual => 0, root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#20^	{ ext => '^', name => '#20^', qual => 0, root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#20h	{ ext => 'h', name => '#20h', qual => 0, root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#20h7	{ ext => 'h7', name => '#20h7', qual => 0, root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#20^7	{ ext => '^7', name => '#20^7', qual => 0, root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#2+	{ ext => '', name => '#2+', qual => '+', root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#2+7	{ ext => 7, name => '#2+7', qual => '+', root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#2+^	{ ext => '^', name => '#2+^', qual => '+', root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#2+h	{ ext => 'h', name => '#2+h', qual => '+', root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#2+h7	{ ext => 'h7', name => '#2+h7', qual => '+', root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#2+^7	{ ext => '^7', name => '#2+^7', qual => '+', root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
b3	{ ext => '', name => 'b3', qual => '', root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b37	{ ext => 7, name => 'b37', qual => '', root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b3^	{ ext => '^', name => 'b3^', qual => '', root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b3h	{ ext => 'h', name => 'b3h', qual => '', root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b3h7	{ ext => 'h7', name => 'b3h7', qual => '', root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b3^7	{ ext => '^7', name => 'b3^7', qual => '', root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b3-	{ ext => '', name => 'b3-', qual => '-', root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b3-7	{ ext => 7, name => 'b3-7', qual => '-', root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b3-^	{ ext => '^', name => 'b3-^', qual => '-', root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b3-h	{ ext => 'h', name => 'b3-h', qual => '-', root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b3-h7	{ ext => 'h7', name => 'b3-h7', qual => '-', root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b3-^7	{ ext => '^7', name => 'b3-^7', qual => '-', root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b30	{ ext => '', name => 'b30', qual => 0, root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b307	{ ext => 7, name => 'b307', qual => 0, root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b30^	{ ext => '^', name => 'b30^', qual => 0, root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b30h	{ ext => 'h', name => 'b30h', qual => 0, root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b30h7	{ ext => 'h7', name => 'b30h7', qual => 0, root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b30^7	{ ext => '^7', name => 'b30^7', qual => 0, root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b3+	{ ext => '', name => 'b3+', qual => '+', root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b3+7	{ ext => 7, name => 'b3+7', qual => '+', root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b3+^	{ ext => '^', name => 'b3+^', qual => '+', root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b3+h	{ ext => 'h', name => 'b3+h', qual => '+', root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b3+h7	{ ext => 'h7', name => 'b3+h7', qual => '+', root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b3+^7	{ ext => '^7', name => 'b3+^7', qual => '+', root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
3	{ ext => '', name => 3, qual => '', root => 3, root_canon => 3, root_ord => 4, system => 'nashville' }
37	{ ext => 7, name => 37, qual => '', root => 3, root_canon => 3, root_ord => 4, system => 'nashville' }
3^	{ ext => '^', name => '3^', qual => '', root => 3, root_canon => 3, root_ord => 4, system => 'nashville' }
3h	{ ext => 'h', name => '3h', qual => '', root => 3, root_canon => 3, root_ord => 4, system => 'nashville' }
3h7	{ ext => 'h7', name => '3h7', qual => '', root => 3, root_canon => 3, root_ord => 4, system => 'nashville' }
3^7	{ ext => '^7', name => '3^7', qual => '', root => 3, root_canon => 3, root_ord => 4, system => 'nashville' }
3-	{ ext => '', name => '3-', qual => '-', root => 3, root_canon => 3, root_ord => 4, system => 'nashville' }
3-7	{ ext => 7, name => '3-7', qual => '-', root => 3, root_canon => 3, root_ord => 4, system => 'nashville' }
3-^	{ ext => '^', name => '3-^', qual => '-', root => 3, root_canon => 3, root_ord => 4, system => 'nashville' }
3-h	{ ext => 'h', name => '3-h', qual => '-', root => 3, root_canon => 3, root_ord => 4, system => 'nashville' }
3-h7	{ ext => 'h7', name => '3-h7', qual => '-', root => 3, root_canon => 3, root_ord => 4, system => 'nashville' }
3-^7	{ ext => '^7', name => '3-^7', qual => '-', root => 3, root_canon => 3, root_ord => 4, system => 'nashville' }
30	{ ext => '', name => 30, qual => 0, root => 3, root_canon => 3, root_ord => 4, system => 'nashville' }
307	{ ext => 7, name => 307, qual => 0, root => 3, root_canon => 3, root_ord => 4, system => 'nashville' }
30^	{ ext => '^', name => '30^', qual => 0, root => 3, root_canon => 3, root_ord => 4, system => 'nashville' }
30h	{ ext => 'h', name => '30h', qual => 0, root => 3, root_canon => 3, root_ord => 4, system => 'nashville' }
30h7	{ ext => 'h7', name => '30h7', qual => 0, root => 3, root_canon => 3, root_ord => 4, system => 'nashville' }
30^7	{ ext => '^7', name => '30^7', qual => 0, root => 3, root_canon => 3, root_ord => 4, system => 'nashville' }
3+	{ ext => '', name => '3+', qual => '+', root => 3, root_canon => 3, root_ord => 4, system => 'nashville' }
3+7	{ ext => 7, name => '3+7', qual => '+', root => 3, root_canon => 3, root_ord => 4, system => 'nashville' }
3+^	{ ext => '^', name => '3+^', qual => '+', root => 3, root_canon => 3, root_ord => 4, system => 'nashville' }
3+h	{ ext => 'h', name => '3+h', qual => '+', root => 3, root_canon => 3, root_ord => 4, system => 'nashville' }
3+h7	{ ext => 'h7', name => '3+h7', qual => '+', root => 3, root_canon => 3, root_ord => 4, system => 'nashville' }
3+^7	{ ext => '^7', name => '3+^7', qual => '+', root => 3, root_canon => 3, root_ord => 4, system => 'nashville' }
4	{ ext => '', name => 4, qual => '', root => 4, root_canon => 4, root_ord => 5, system => 'nashville' }
47	{ ext => 7, name => 47, qual => '', root => 4, root_canon => 4, root_ord => 5, system => 'nashville' }
4^	{ ext => '^', name => '4^', qual => '', root => 4, root_canon => 4, root_ord => 5, system => 'nashville' }
4h	{ ext => 'h', name => '4h', qual => '', root => 4, root_canon => 4, root_ord => 5, system => 'nashville' }
4h7	{ ext => 'h7', name => '4h7', qual => '', root => 4, root_canon => 4, root_ord => 5, system => 'nashville' }
4^7	{ ext => '^7', name => '4^7', qual => '', root => 4, root_canon => 4, root_ord => 5, system => 'nashville' }
4-	{ ext => '', name => '4-', qual => '-', root => 4, root_canon => 4, root_ord => 5, system => 'nashville' }
4-7	{ ext => 7, name => '4-7', qual => '-', root => 4, root_canon => 4, root_ord => 5, system => 'nashville' }
4-^	{ ext => '^', name => '4-^', qual => '-', root => 4, root_canon => 4, root_ord => 5, system => 'nashville' }
4-h	{ ext => 'h', name => '4-h', qual => '-', root => 4, root_canon => 4, root_ord => 5, system => 'nashville' }
4-h7	{ ext => 'h7', name => '4-h7', qual => '-', root => 4, root_canon => 4, root_ord => 5, system => 'nashville' }
4-^7	{ ext => '^7', name => '4-^7', qual => '-', root => 4, root_canon => 4, root_ord => 5, system => 'nashville' }
40	{ ext => '', name => 40, qual => 0, root => 4, root_canon => 4, root_ord => 5, system => 'nashville' }
407	{ ext => 7, name => 407, qual => 0, root => 4, root_canon => 4, root_ord => 5, system => 'nashville' }
40^	{ ext => '^', name => '40^', qual => 0, root => 4, root_canon => 4, root_ord => 5, system => 'nashville' }
40h	{ ext => 'h', name => '40h', qual => 0, root => 4, root_canon => 4, root_ord => 5, system => 'nashville' }
40h7	{ ext => 'h7', name => '40h7', qual => 0, root => 4, root_canon => 4, root_ord => 5, system => 'nashville' }
40^7	{ ext => '^7', name => '40^7', qual => 0, root => 4, root_canon => 4, root_ord => 5, system => 'nashville' }
4+	{ ext => '', name => '4+', qual => '+', root => 4, root_canon => 4, root_ord => 5, system => 'nashville' }
4+7	{ ext => 7, name => '4+7', qual => '+', root => 4, root_canon => 4, root_ord => 5, system => 'nashville' }
4+^	{ ext => '^', name => '4+^', qual => '+', root => 4, root_canon => 4, root_ord => 5, system => 'nashville' }
4+h	{ ext => 'h', name => '4+h', qual => '+', root => 4, root_canon => 4, root_ord => 5, system => 'nashville' }
4+h7	{ ext => 'h7', name => '4+h7', qual => '+', root => 4, root_canon => 4, root_ord => 5, system => 'nashville' }
4+^7	{ ext => '^7', name => '4+^7', qual => '+', root => 4, root_canon => 4, root_ord => 5, system => 'nashville' }
#4	{ ext => '', name => '#4', qual => '', root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#47	{ ext => 7, name => '#47', qual => '', root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#4^	{ ext => '^', name => '#4^', qual => '', root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#4h	{ ext => 'h', name => '#4h', qual => '', root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#4h7	{ ext => 'h7', name => '#4h7', qual => '', root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#4^7	{ ext => '^7', name => '#4^7', qual => '', root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#4-	{ ext => '', name => '#4-', qual => '-', root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#4-7	{ ext => 7, name => '#4-7', qual => '-', root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#4-^	{ ext => '^', name => '#4-^', qual => '-', root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#4-h	{ ext => 'h', name => '#4-h', qual => '-', root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#4-h7	{ ext => 'h7', name => '#4-h7', qual => '-', root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#4-^7	{ ext => '^7', name => '#4-^7', qual => '-', root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#40	{ ext => '', name => '#40', qual => 0, root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#407	{ ext => 7, name => '#407', qual => 0, root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#40^	{ ext => '^', name => '#40^', qual => 0, root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#40h	{ ext => 'h', name => '#40h', qual => 0, root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#40h7	{ ext => 'h7', name => '#40h7', qual => 0, root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#40^7	{ ext => '^7', name => '#40^7', qual => 0, root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#4+	{ ext => '', name => '#4+', qual => '+', root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#4+7	{ ext => 7, name => '#4+7', qual => '+', root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#4+^	{ ext => '^', name => '#4+^', qual => '+', root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#4+h	{ ext => 'h', name => '#4+h', qual => '+', root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#4+h7	{ ext => 'h7', name => '#4+h7', qual => '+', root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#4+^7	{ ext => '^7', name => '#4+^7', qual => '+', root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
b5	{ ext => '', name => 'b5', qual => '', root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b57	{ ext => 7, name => 'b57', qual => '', root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b5^	{ ext => '^', name => 'b5^', qual => '', root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b5h	{ ext => 'h', name => 'b5h', qual => '', root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b5h7	{ ext => 'h7', name => 'b5h7', qual => '', root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b5^7	{ ext => '^7', name => 'b5^7', qual => '', root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b5-	{ ext => '', name => 'b5-', qual => '-', root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b5-7	{ ext => 7, name => 'b5-7', qual => '-', root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b5-^	{ ext => '^', name => 'b5-^', qual => '-', root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b5-h	{ ext => 'h', name => 'b5-h', qual => '-', root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b5-h7	{ ext => 'h7', name => 'b5-h7', qual => '-', root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b5-^7	{ ext => '^7', name => 'b5-^7', qual => '-', root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b50	{ ext => '', name => 'b50', qual => 0, root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b507	{ ext => 7, name => 'b507', qual => 0, root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b50^	{ ext => '^', name => 'b50^', qual => 0, root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b50h	{ ext => 'h', name => 'b50h', qual => 0, root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b50h7	{ ext => 'h7', name => 'b50h7', qual => 0, root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b50^7	{ ext => '^7', name => 'b50^7', qual => 0, root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b5+	{ ext => '', name => 'b5+', qual => '+', root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b5+7	{ ext => 7, name => 'b5+7', qual => '+', root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b5+^	{ ext => '^', name => 'b5+^', qual => '+', root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b5+h	{ ext => 'h', name => 'b5+h', qual => '+', root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b5+h7	{ ext => 'h7', name => 'b5+h7', qual => '+', root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b5+^7	{ ext => '^7', name => 'b5+^7', qual => '+', root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
5	{ ext => '', name => 5, qual => '', root => 5, root_canon => 5, root_ord => 7, system => 'nashville' }
57	{ ext => 7, name => 57, qual => '', root => 5, root_canon => 5, root_ord => 7, system => 'nashville' }
5^	{ ext => '^', name => '5^', qual => '', root => 5, root_canon => 5, root_ord => 7, system => 'nashville' }
5h	{ ext => 'h', name => '5h', qual => '', root => 5, root_canon => 5, root_ord => 7, system => 'nashville' }
5h7	{ ext => 'h7', name => '5h7', qual => '', root => 5, root_canon => 5, root_ord => 7, system => 'nashville' }
5^7	{ ext => '^7', name => '5^7', qual => '', root => 5, root_canon => 5, root_ord => 7, system => 'nashville' }
5-	{ ext => '', name => '5-', qual => '-', root => 5, root_canon => 5, root_ord => 7, system => 'nashville' }
5-7	{ ext => 7, name => '5-7', qual => '-', root => 5, root_canon => 5, root_ord => 7, system => 'nashville' }
5-^	{ ext => '^', name => '5-^', qual => '-', root => 5, root_canon => 5, root_ord => 7, system => 'nashville' }
5-h	{ ext => 'h', name => '5-h', qual => '-', root => 5, root_canon => 5, root_ord => 7, system => 'nashville' }
5-h7	{ ext => 'h7', name => '5-h7', qual => '-', root => 5, root_canon => 5, root_ord => 7, system => 'nashville' }
5-^7	{ ext => '^7', name => '5-^7', qual => '-', root => 5, root_canon => 5, root_ord => 7, system => 'nashville' }
50	{ ext => '', name => 50, qual => 0, root => 5, root_canon => 5, root_ord => 7, system => 'nashville' }
507	{ ext => 7, name => 507, qual => 0, root => 5, root_canon => 5, root_ord => 7, system => 'nashville' }
50^	{ ext => '^', name => '50^', qual => 0, root => 5, root_canon => 5, root_ord => 7, system => 'nashville' }
50h	{ ext => 'h', name => '50h', qual => 0, root => 5, root_canon => 5, root_ord => 7, system => 'nashville' }
50h7	{ ext => 'h7', name => '50h7', qual => 0, root => 5, root_canon => 5, root_ord => 7, system => 'nashville' }
50^7	{ ext => '^7', name => '50^7', qual => 0, root => 5, root_canon => 5, root_ord => 7, system => 'nashville' }
5+	{ ext => '', name => '5+', qual => '+', root => 5, root_canon => 5, root_ord => 7, system => 'nashville' }
5+7	{ ext => 7, name => '5+7', qual => '+', root => 5, root_canon => 5, root_ord => 7, system => 'nashville' }
5+^	{ ext => '^', name => '5+^', qual => '+', root => 5, root_canon => 5, root_ord => 7, system => 'nashville' }
5+h	{ ext => 'h', name => '5+h', qual => '+', root => 5, root_canon => 5, root_ord => 7, system => 'nashville' }
5+h7	{ ext => 'h7', name => '5+h7', qual => '+', root => 5, root_canon => 5, root_ord => 7, system => 'nashville' }
5+^7	{ ext => '^7', name => '5+^7', qual => '+', root => 5, root_canon => 5, root_ord => 7, system => 'nashville' }
#5	{ ext => '', name => '#5', qual => '', root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#57	{ ext => 7, name => '#57', qual => '', root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#5^	{ ext => '^', name => '#5^', qual => '', root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#5h	{ ext => 'h', name => '#5h', qual => '', root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#5h7	{ ext => 'h7', name => '#5h7', qual => '', root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#5^7	{ ext => '^7', name => '#5^7', qual => '', root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#5-	{ ext => '', name => '#5-', qual => '-', root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#5-7	{ ext => 7, name => '#5-7', qual => '-', root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#5-^	{ ext => '^', name => '#5-^', qual => '-', root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#5-h	{ ext => 'h', name => '#5-h', qual => '-', root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#5-h7	{ ext => 'h7', name => '#5-h7', qual => '-', root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#5-^7	{ ext => '^7', name => '#5-^7', qual => '-', root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#50	{ ext => '', name => '#50', qual => 0, root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#507	{ ext => 7, name => '#507', qual => 0, root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#50^	{ ext => '^', name => '#50^', qual => 0, root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#50h	{ ext => 'h', name => '#50h', qual => 0, root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#50h7	{ ext => 'h7', name => '#50h7', qual => 0, root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#50^7	{ ext => '^7', name => '#50^7', qual => 0, root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#5+	{ ext => '', name => '#5+', qual => '+', root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#5+7	{ ext => 7, name => '#5+7', qual => '+', root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#5+^	{ ext => '^', name => '#5+^', qual => '+', root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#5+h	{ ext => 'h', name => '#5+h', qual => '+', root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#5+h7	{ ext => 'h7', name => '#5+h7', qual => '+', root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#5+^7	{ ext => '^7', name => '#5+^7', qual => '+', root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
b6	{ ext => '', name => 'b6', qual => '', root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b67	{ ext => 7, name => 'b67', qual => '', root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b6^	{ ext => '^', name => 'b6^', qual => '', root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b6h	{ ext => 'h', name => 'b6h', qual => '', root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b6h7	{ ext => 'h7', name => 'b6h7', qual => '', root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b6^7	{ ext => '^7', name => 'b6^7', qual => '', root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b6-	{ ext => '', name => 'b6-', qual => '-', root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b6-7	{ ext => 7, name => 'b6-7', qual => '-', root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b6-^	{ ext => '^', name => 'b6-^', qual => '-', root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b6-h	{ ext => 'h', name => 'b6-h', qual => '-', root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b6-h7	{ ext => 'h7', name => 'b6-h7', qual => '-', root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b6-^7	{ ext => '^7', name => 'b6-^7', qual => '-', root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b60	{ ext => '', name => 'b60', qual => 0, root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b607	{ ext => 7, name => 'b607', qual => 0, root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b60^	{ ext => '^', name => 'b60^', qual => 0, root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b60h	{ ext => 'h', name => 'b60h', qual => 0, root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b60h7	{ ext => 'h7', name => 'b60h7', qual => 0, root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b60^7	{ ext => '^7', name => 'b60^7', qual => 0, root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b6+	{ ext => '', name => 'b6+', qual => '+', root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b6+7	{ ext => 7, name => 'b6+7', qual => '+', root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b6+^	{ ext => '^', name => 'b6+^', qual => '+', root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b6+h	{ ext => 'h', name => 'b6+h', qual => '+', root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b6+h7	{ ext => 'h7', name => 'b6+h7', qual => '+', root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b6+^7	{ ext => '^7', name => 'b6+^7', qual => '+', root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
6	{ ext => '', name => 6, qual => '', root => 6, root_canon => 6, root_ord => 9, system => 'nashville' }
67	{ ext => 7, name => 67, qual => '', root => 6, root_canon => 6, root_ord => 9, system => 'nashville' }
6^	{ ext => '^', name => '6^', qual => '', root => 6, root_canon => 6, root_ord => 9, system => 'nashville' }
6h	{ ext => 'h', name => '6h', qual => '', root => 6, root_canon => 6, root_ord => 9, system => 'nashville' }
6h7	{ ext => 'h7', name => '6h7', qual => '', root => 6, root_canon => 6, root_ord => 9, system => 'nashville' }
6^7	{ ext => '^7', name => '6^7', qual => '', root => 6, root_canon => 6, root_ord => 9, system => 'nashville' }
6-	{ ext => '', name => '6-', qual => '-', root => 6, root_canon => 6, root_ord => 9, system => 'nashville' }
6-7	{ ext => 7, name => '6-7', qual => '-', root => 6, root_canon => 6, root_ord => 9, system => 'nashville' }
6-^	{ ext => '^', name => '6-^', qual => '-', root => 6, root_canon => 6, root_ord => 9, system => 'nashville' }
6-h	{ ext => 'h', name => '6-h', qual => '-', root => 6, root_canon => 6, root_ord => 9, system => 'nashville' }
6-h7	{ ext => 'h7', name => '6-h7', qual => '-', root => 6, root_canon => 6, root_ord => 9, system => 'nashville' }
6-^7	{ ext => '^7', name => '6-^7', qual => '-', root => 6, root_canon => 6, root_ord => 9, system => 'nashville' }
60	{ ext => '', name => 60, qual => 0, root => 6, root_canon => 6, root_ord => 9, system => 'nashville' }
607	{ ext => 7, name => 607, qual => 0, root => 6, root_canon => 6, root_ord => 9, system => 'nashville' }
60^	{ ext => '^', name => '60^', qual => 0, root => 6, root_canon => 6, root_ord => 9, system => 'nashville' }
60h	{ ext => 'h', name => '60h', qual => 0, root => 6, root_canon => 6, root_ord => 9, system => 'nashville' }
60h7	{ ext => 'h7', name => '60h7', qual => 0, root => 6, root_canon => 6, root_ord => 9, system => 'nashville' }
60^7	{ ext => '^7', name => '60^7', qual => 0, root => 6, root_canon => 6, root_ord => 9, system => 'nashville' }
6+	{ ext => '', name => '6+', qual => '+', root => 6, root_canon => 6, root_ord => 9, system => 'nashville' }
6+7	{ ext => 7, name => '6+7', qual => '+', root => 6, root_canon => 6, root_ord => 9, system => 'nashville' }
6+^	{ ext => '^', name => '6+^', qual => '+', root => 6, root_canon => 6, root_ord => 9, system => 'nashville' }
6+h	{ ext => 'h', name => '6+h', qual => '+', root => 6, root_canon => 6, root_ord => 9, system => 'nashville' }
6+h7	{ ext => 'h7', name => '6+h7', qual => '+', root => 6, root_canon => 6, root_ord => 9, system => 'nashville' }
6+^7	{ ext => '^7', name => '6+^7', qual => '+', root => 6, root_canon => 6, root_ord => 9, system => 'nashville' }
#6	{ ext => '', name => '#6', qual => '', root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#67	{ ext => 7, name => '#67', qual => '', root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#6^	{ ext => '^', name => '#6^', qual => '', root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#6h	{ ext => 'h', name => '#6h', qual => '', root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#6h7	{ ext => 'h7', name => '#6h7', qual => '', root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#6^7	{ ext => '^7', name => '#6^7', qual => '', root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#6-	{ ext => '', name => '#6-', qual => '-', root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#6-7	{ ext => 7, name => '#6-7', qual => '-', root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#6-^	{ ext => '^', name => '#6-^', qual => '-', root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#6-h	{ ext => 'h', name => '#6-h', qual => '-', root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#6-h7	{ ext => 'h7', name => '#6-h7', qual => '-', root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#6-^7	{ ext => '^7', name => '#6-^7', qual => '-', root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#60	{ ext => '', name => '#60', qual => 0, root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#607	{ ext => 7, name => '#607', qual => 0, root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#60^	{ ext => '^', name => '#60^', qual => 0, root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#60h	{ ext => 'h', name => '#60h', qual => 0, root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#60h7	{ ext => 'h7', name => '#60h7', qual => 0, root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#60^7	{ ext => '^7', name => '#60^7', qual => 0, root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#6+	{ ext => '', name => '#6+', qual => '+', root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#6+7	{ ext => 7, name => '#6+7', qual => '+', root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#6+^	{ ext => '^', name => '#6+^', qual => '+', root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#6+h	{ ext => 'h', name => '#6+h', qual => '+', root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#6+h7	{ ext => 'h7', name => '#6+h7', qual => '+', root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#6+^7	{ ext => '^7', name => '#6+^7', qual => '+', root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
b7	{ ext => '', name => 'b7', qual => '', root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b77	{ ext => 7, name => 'b77', qual => '', root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b7^	{ ext => '^', name => 'b7^', qual => '', root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b7h	{ ext => 'h', name => 'b7h', qual => '', root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b7h7	{ ext => 'h7', name => 'b7h7', qual => '', root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b7^7	{ ext => '^7', name => 'b7^7', qual => '', root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b7-	{ ext => '', name => 'b7-', qual => '-', root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b7-7	{ ext => 7, name => 'b7-7', qual => '-', root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b7-^	{ ext => '^', name => 'b7-^', qual => '-', root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b7-h	{ ext => 'h', name => 'b7-h', qual => '-', root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b7-h7	{ ext => 'h7', name => 'b7-h7', qual => '-', root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b7-^7	{ ext => '^7', name => 'b7-^7', qual => '-', root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b70	{ ext => '', name => 'b70', qual => 0, root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b707	{ ext => 7, name => 'b707', qual => 0, root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b70^	{ ext => '^', name => 'b70^', qual => 0, root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b70h	{ ext => 'h', name => 'b70h', qual => 0, root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b70h7	{ ext => 'h7', name => 'b70h7', qual => 0, root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b70^7	{ ext => '^7', name => 'b70^7', qual => 0, root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b7+	{ ext => '', name => 'b7+', qual => '+', root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b7+7	{ ext => 7, name => 'b7+7', qual => '+', root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b7+^	{ ext => '^', name => 'b7+^', qual => '+', root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b7+h	{ ext => 'h', name => 'b7+h', qual => '+', root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b7+h7	{ ext => 'h7', name => 'b7+h7', qual => '+', root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b7+^7	{ ext => '^7', name => 'b7+^7', qual => '+', root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
7	{ ext => '', name => 7, qual => '', root => 7, root_canon => 7, root_ord => 11, system => 'nashville' }
77	{ ext => 7, name => 77, qual => '', root => 7, root_canon => 7, root_ord => 11, system => 'nashville' }
7^	{ ext => '^', name => '7^', qual => '', root => 7, root_canon => 7, root_ord => 11, system => 'nashville' }
7h	{ ext => 'h', name => '7h', qual => '', root => 7, root_canon => 7, root_ord => 11, system => 'nashville' }
7h7	{ ext => 'h7', name => '7h7', qual => '', root => 7, root_canon => 7, root_ord => 11, system => 'nashville' }
7^7	{ ext => '^7', name => '7^7', qual => '', root => 7, root_canon => 7, root_ord => 11, system => 'nashville' }
7-	{ ext => '', name => '7-', qual => '-', root => 7, root_canon => 7, root_ord => 11, system => 'nashville' }
7-7	{ ext => 7, name => '7-7', qual => '-', root => 7, root_canon => 7, root_ord => 11, system => 'nashville' }
7-^	{ ext => '^', name => '7-^', qual => '-', root => 7, root_canon => 7, root_ord => 11, system => 'nashville' }
7-h	{ ext => 'h', name => '7-h', qual => '-', root => 7, root_canon => 7, root_ord => 11, system => 'nashville' }
7-h7	{ ext => 'h7', name => '7-h7', qual => '-', root => 7, root_canon => 7, root_ord => 11, system => 'nashville' }
7-^7	{ ext => '^7', name => '7-^7', qual => '-', root => 7, root_canon => 7, root_ord => 11, system => 'nashville' }
70	{ ext => '', name => 70, qual => 0, root => 7, root_canon => 7, root_ord => 11, system => 'nashville' }
707	{ ext => 7, name => 707, qual => 0, root => 7, root_canon => 7, root_ord => 11, system => 'nashville' }
70^	{ ext => '^', name => '70^', qual => 0, root => 7, root_canon => 7, root_ord => 11, system => 'nashville' }
70h	{ ext => 'h', name => '70h', qual => 0, root => 7, root_canon => 7, root_ord => 11, system => 'nashville' }
70h7	{ ext => 'h7', name => '70h7', qual => 0, root => 7, root_canon => 7, root_ord => 11, system => 'nashville' }
70^7	{ ext => '^7', name => '70^7', qual => 0, root => 7, root_canon => 7, root_ord => 11, system => 'nashville' }
7+	{ ext => '', name => '7+', qual => '+', root => 7, root_canon => 7, root_ord => 11, system => 'nashville' }
7+7	{ ext => 7, name => '7+7', qual => '+', root => 7, root_canon => 7, root_ord => 11, system => 'nashville' }
7+^	{ ext => '^', name => '7+^', qual => '+', root => 7, root_canon => 7, root_ord => 11, system => 'nashville' }
7+h	{ ext => 'h', name => '7+h', qual => '+', root => 7, root_canon => 7, root_ord => 11, system => 'nashville' }
7+h7	{ ext => 'h7', name => '7+h7', qual => '+', root => 7, root_canon => 7, root_ord => 11, system => 'nashville' }
7+^7	{ ext => '^7', name => '7+^7', qual => '+', root => 7, root_canon => 7, root_ord => 11, system => 'nashville' }
I	{ ext => '', name => 'I', qual => '', root => 'I', root_canon => 'I', root_ord => 0, system => 'roman' }
i	{ ext => '', name => 'i', qual => '-', root => 'i', root_canon => 'i', root_ord => 0, system => 'roman' }
I7	{ ext => 7, name => 'I7', qual => '', root => 'I', root_canon => 'I', root_ord => 0, system => 'roman' }
i7	{ ext => 7, name => 'i7', qual => '-', root => 'i', root_canon => 'i', root_ord => 0, system => 'roman' }
I^	{ ext => '^', name => 'I^', qual => '', root => 'I', root_canon => 'I', root_ord => 0, system => 'roman' }
i^	{ ext => '^', name => 'i^', qual => '-', root => 'i', root_canon => 'i', root_ord => 0, system => 'roman' }
Ih	{ ext => 'h', name => 'Ih', qual => '', root => 'I', root_canon => 'I', root_ord => 0, system => 'roman' }
ih	{ ext => 'h', name => 'ih', qual => '-', root => 'i', root_canon => 'i', root_ord => 0, system => 'roman' }
Ih7	{ ext => 'h7', name => 'Ih7', qual => '', root => 'I', root_canon => 'I', root_ord => 0, system => 'roman' }
ih7	{ ext => 'h7', name => 'ih7', qual => '-', root => 'i', root_canon => 'i', root_ord => 0, system => 'roman' }
I^7	{ ext => '^7', name => 'I^7', qual => '', root => 'I', root_canon => 'I', root_ord => 0, system => 'roman' }
i^7	{ ext => '^7', name => 'i^7', qual => '-', root => 'i', root_canon => 'i', root_ord => 0, system => 'roman' }
I0	{ ext => '', name => 'I0', qual => 0, root => 'I', root_canon => 'I', root_ord => 0, system => 'roman' }
i0	{ ext => '', name => 'i0', qual => '-', root => 'i', root_canon => 'i', root_ord => 0, system => 'roman' }
I07	{ ext => 7, name => 'I07', qual => 0, root => 'I', root_canon => 'I', root_ord => 0, system => 'roman' }
i07	{ ext => 7, name => 'i07', qual => '-', root => 'i', root_canon => 'i', root_ord => 0, system => 'roman' }
I0^	{ ext => '^', name => 'I0^', qual => 0, root => 'I', root_canon => 'I', root_ord => 0, system => 'roman' }
i0^	{ ext => '^', name => 'i0^', qual => '-', root => 'i', root_canon => 'i', root_ord => 0, system => 'roman' }
I0h	{ ext => 'h', name => 'I0h', qual => 0, root => 'I', root_canon => 'I', root_ord => 0, system => 'roman' }
i0h	{ ext => 'h', name => 'i0h', qual => '-', root => 'i', root_canon => 'i', root_ord => 0, system => 'roman' }
I0h7	{ ext => 'h7', name => 'I0h7', qual => 0, root => 'I', root_canon => 'I', root_ord => 0, system => 'roman' }
i0h7	{ ext => 'h7', name => 'i0h7', qual => '-', root => 'i', root_canon => 'i', root_ord => 0, system => 'roman' }
I0^7	{ ext => '^7', name => 'I0^7', qual => 0, root => 'I', root_canon => 'I', root_ord => 0, system => 'roman' }
i0^7	{ ext => '^7', name => 'i0^7', qual => '-', root => 'i', root_canon => 'i', root_ord => 0, system => 'roman' }
I+	{ ext => '', name => 'I+', qual => '+', root => 'I', root_canon => 'I', root_ord => 0, system => 'roman' }
i+	{ ext => '', name => 'i+', qual => '-', root => 'i', root_canon => 'i', root_ord => 0, system => 'roman' }
I+7	{ ext => 7, name => 'I+7', qual => '+', root => 'I', root_canon => 'I', root_ord => 0, system => 'roman' }
i+7	{ ext => 7, name => 'i+7', qual => '-', root => 'i', root_canon => 'i', root_ord => 0, system => 'roman' }
I+^	{ ext => '^', name => 'I+^', qual => '+', root => 'I', root_canon => 'I', root_ord => 0, system => 'roman' }
i+^	{ ext => '^', name => 'i+^', qual => '-', root => 'i', root_canon => 'i', root_ord => 0, system => 'roman' }
I+h	{ ext => 'h', name => 'I+h', qual => '+', root => 'I', root_canon => 'I', root_ord => 0, system => 'roman' }
i+h	{ ext => 'h', name => 'i+h', qual => '-', root => 'i', root_canon => 'i', root_ord => 0, system => 'roman' }
I+h7	{ ext => 'h7', name => 'I+h7', qual => '+', root => 'I', root_canon => 'I', root_ord => 0, system => 'roman' }
i+h7	{ ext => 'h7', name => 'i+h7', qual => '-', root => 'i', root_canon => 'i', root_ord => 0, system => 'roman' }
I+^7	{ ext => '^7', name => 'I+^7', qual => '+', root => 'I', root_canon => 'I', root_ord => 0, system => 'roman' }
i+^7	{ ext => '^7', name => 'i+^7', qual => '-', root => 'i', root_canon => 'i', root_ord => 0, system => 'roman' }
#I	{ ext => '', name => '#I', qual => '', root => 'I', root_canon => 'I', root_mod => 1, root_ord => 1, system => 'roman' }
#i	{ ext => '', name => '#i', qual => '-', root => 'i', root_canon => 'i', root_mod => 1, root_ord => 1, system => 'roman' }
#I7	{ ext => 7, name => '#I7', qual => '', root => 'I', root_canon => 'I', root_mod => 1, root_ord => 1, system => 'roman' }
#i7	{ ext => 7, name => '#i7', qual => '-', root => 'i', root_canon => 'i', root_mod => 1, root_ord => 1, system => 'roman' }
#I^	{ ext => '^', name => '#I^', qual => '', root => 'I', root_canon => 'I', root_mod => 1, root_ord => 1, system => 'roman' }
#i^	{ ext => '^', name => '#i^', qual => '-', root => 'i', root_canon => 'i', root_mod => 1, root_ord => 1, system => 'roman' }
#Ih	{ ext => 'h', name => '#Ih', qual => '', root => 'I', root_canon => 'I', root_mod => 1, root_ord => 1, system => 'roman' }
#ih	{ ext => 'h', name => '#ih', qual => '-', root => 'i', root_canon => 'i', root_mod => 1, root_ord => 1, system => 'roman' }
#Ih7	{ ext => 'h7', name => '#Ih7', qual => '', root => 'I', root_canon => 'I', root_mod => 1, root_ord => 1, system => 'roman' }
#ih7	{ ext => 'h7', name => '#ih7', qual => '-', root => 'i', root_canon => 'i', root_mod => 1, root_ord => 1, system => 'roman' }
#I^7	{ ext => '^7', name => '#I^7', qual => '', root => 'I', root_canon => 'I', root_mod => 1, root_ord => 1, system => 'roman' }
#i^7	{ ext => '^7', name => '#i^7', qual => '-', root => 'i', root_canon => 'i', root_mod => 1, root_ord => 1, system => 'roman' }
#I0	{ ext => '', name => '#I0', qual => 0, root => 'I', root_canon => 'I', root_mod => 1, root_ord => 1, system => 'roman' }
#i0	{ ext => '', name => '#i0', qual => '-', root => 'i', root_canon => 'i', root_mod => 1, root_ord => 1, system => 'roman' }
#I07	{ ext => 7, name => '#I07', qual => 0, root => 'I', root_canon => 'I', root_mod => 1, root_ord => 1, system => 'roman' }
#i07	{ ext => 7, name => '#i07', qual => '-', root => 'i', root_canon => 'i', root_mod => 1, root_ord => 1, system => 'roman' }
#I0^	{ ext => '^', name => '#I0^', qual => 0, root => 'I', root_canon => 'I', root_mod => 1, root_ord => 1, system => 'roman' }
#i0^	{ ext => '^', name => '#i0^', qual => '-', root => 'i', root_canon => 'i', root_mod => 1, root_ord => 1, system => 'roman' }
#I0h	{ ext => 'h', name => '#I0h', qual => 0, root => 'I', root_canon => 'I', root_mod => 1, root_ord => 1, system => 'roman' }
#i0h	{ ext => 'h', name => '#i0h', qual => '-', root => 'i', root_canon => 'i', root_mod => 1, root_ord => 1, system => 'roman' }
#I0h7	{ ext => 'h7', name => '#I0h7', qual => 0, root => 'I', root_canon => 'I', root_mod => 1, root_ord => 1, system => 'roman' }
#i0h7	{ ext => 'h7', name => '#i0h7', qual => '-', root => 'i', root_canon => 'i', root_mod => 1, root_ord => 1, system => 'roman' }
#I0^7	{ ext => '^7', name => '#I0^7', qual => 0, root => 'I', root_canon => 'I', root_mod => 1, root_ord => 1, system => 'roman' }
#i0^7	{ ext => '^7', name => '#i0^7', qual => '-', root => 'i', root_canon => 'i', root_mod => 1, root_ord => 1, system => 'roman' }
#I+	{ ext => '', name => '#I+', qual => '+', root => 'I', root_canon => 'I', root_mod => 1, root_ord => 1, system => 'roman' }
#i+	{ ext => '', name => '#i+', qual => '-', root => 'i', root_canon => 'i', root_mod => 1, root_ord => 1, system => 'roman' }
#I+7	{ ext => 7, name => '#I+7', qual => '+', root => 'I', root_canon => 'I', root_mod => 1, root_ord => 1, system => 'roman' }
#i+7	{ ext => 7, name => '#i+7', qual => '-', root => 'i', root_canon => 'i', root_mod => 1, root_ord => 1, system => 'roman' }
#I+^	{ ext => '^', name => '#I+^', qual => '+', root => 'I', root_canon => 'I', root_mod => 1, root_ord => 1, system => 'roman' }
#i+^	{ ext => '^', name => '#i+^', qual => '-', root => 'i', root_canon => 'i', root_mod => 1, root_ord => 1, system => 'roman' }
#I+h	{ ext => 'h', name => '#I+h', qual => '+', root => 'I', root_canon => 'I', root_mod => 1, root_ord => 1, system => 'roman' }
#i+h	{ ext => 'h', name => '#i+h', qual => '-', root => 'i', root_canon => 'i', root_mod => 1, root_ord => 1, system => 'roman' }
#I+h7	{ ext => 'h7', name => '#I+h7', qual => '+', root => 'I', root_canon => 'I', root_mod => 1, root_ord => 1, system => 'roman' }
#i+h7	{ ext => 'h7', name => '#i+h7', qual => '-', root => 'i', root_canon => 'i', root_mod => 1, root_ord => 1, system => 'roman' }
#I+^7	{ ext => '^7', name => '#I+^7', qual => '+', root => 'I', root_canon => 'I', root_mod => 1, root_ord => 1, system => 'roman' }
#i+^7	{ ext => '^7', name => '#i+^7', qual => '-', root => 'i', root_canon => 'i', root_mod => 1, root_ord => 1, system => 'roman' }
bII	{ ext => '', name => 'bII', qual => '', root => 'II', root_canon => 'II', root_mod => -1, root_ord => 1, system => 'roman' }
bii	{ ext => '', name => 'bii', qual => '-', root => 'ii', root_canon => 'ii', root_mod => -1, root_ord => 1, system => 'roman' }
bII7	{ ext => 7, name => 'bII7', qual => '', root => 'II', root_canon => 'II', root_mod => -1, root_ord => 1, system => 'roman' }
bii7	{ ext => 7, name => 'bii7', qual => '-', root => 'ii', root_canon => 'ii', root_mod => -1, root_ord => 1, system => 'roman' }
bII^	{ ext => '^', name => 'bII^', qual => '', root => 'II', root_canon => 'II', root_mod => -1, root_ord => 1, system => 'roman' }
bii^	{ ext => '^', name => 'bii^', qual => '-', root => 'ii', root_canon => 'ii', root_mod => -1, root_ord => 1, system => 'roman' }
bIIh	{ ext => 'h', name => 'bIIh', qual => '', root => 'II', root_canon => 'II', root_mod => -1, root_ord => 1, system => 'roman' }
biih	{ ext => 'h', name => 'biih', qual => '-', root => 'ii', root_canon => 'ii', root_mod => -1, root_ord => 1, system => 'roman' }
bIIh7	{ ext => 'h7', name => 'bIIh7', qual => '', root => 'II', root_canon => 'II', root_mod => -1, root_ord => 1, system => 'roman' }
biih7	{ ext => 'h7', name => 'biih7', qual => '-', root => 'ii', root_canon => 'ii', root_mod => -1, root_ord => 1, system => 'roman' }
bII^7	{ ext => '^7', name => 'bII^7', qual => '', root => 'II', root_canon => 'II', root_mod => -1, root_ord => 1, system => 'roman' }
bii^7	{ ext => '^7', name => 'bii^7', qual => '-', root => 'ii', root_canon => 'ii', root_mod => -1, root_ord => 1, system => 'roman' }
bII0	{ ext => '', name => 'bII0', qual => 0, root => 'II', root_canon => 'II', root_mod => -1, root_ord => 1, system => 'roman' }
bii0	{ ext => '', name => 'bii0', qual => '-', root => 'ii', root_canon => 'ii', root_mod => -1, root_ord => 1, system => 'roman' }
bII07	{ ext => 7, name => 'bII07', qual => 0, root => 'II', root_canon => 'II', root_mod => -1, root_ord => 1, system => 'roman' }
bii07	{ ext => 7, name => 'bii07', qual => '-', root => 'ii', root_canon => 'ii', root_mod => -1, root_ord => 1, system => 'roman' }
bII0^	{ ext => '^', name => 'bII0^', qual => 0, root => 'II', root_canon => 'II', root_mod => -1, root_ord => 1, system => 'roman' }
bii0^	{ ext => '^', name => 'bii0^', qual => '-', root => 'ii', root_canon => 'ii', root_mod => -1, root_ord => 1, system => 'roman' }
bII0h	{ ext => 'h', name => 'bII0h', qual => 0, root => 'II', root_canon => 'II', root_mod => -1, root_ord => 1, system => 'roman' }
bii0h	{ ext => 'h', name => 'bii0h', qual => '-', root => 'ii', root_canon => 'ii', root_mod => -1, root_ord => 1, system => 'roman' }
bII0h7	{ ext => 'h7', name => 'bII0h7', qual => 0, root => 'II', root_canon => 'II', root_mod => -1, root_ord => 1, system => 'roman' }
bii0h7	{ ext => 'h7', name => 'bii0h7', qual => '-', root => 'ii', root_canon => 'ii', root_mod => -1, root_ord => 1, system => 'roman' }
bII0^7	{ ext => '^7', name => 'bII0^7', qual => 0, root => 'II', root_canon => 'II', root_mod => -1, root_ord => 1, system => 'roman' }
bii0^7	{ ext => '^7', name => 'bii0^7', qual => '-', root => 'ii', root_canon => 'ii', root_mod => -1, root_ord => 1, system => 'roman' }
bII+	{ ext => '', name => 'bII+', qual => '+', root => 'II', root_canon => 'II', root_mod => -1, root_ord => 1, system => 'roman' }
bii+	{ ext => '', name => 'bii+', qual => '-', root => 'ii', root_canon => 'ii', root_mod => -1, root_ord => 1, system => 'roman' }
bII+7	{ ext => 7, name => 'bII+7', qual => '+', root => 'II', root_canon => 'II', root_mod => -1, root_ord => 1, system => 'roman' }
bii+7	{ ext => 7, name => 'bii+7', qual => '-', root => 'ii', root_canon => 'ii', root_mod => -1, root_ord => 1, system => 'roman' }
bII+^	{ ext => '^', name => 'bII+^', qual => '+', root => 'II', root_canon => 'II', root_mod => -1, root_ord => 1, system => 'roman' }
bii+^	{ ext => '^', name => 'bii+^', qual => '-', root => 'ii', root_canon => 'ii', root_mod => -1, root_ord => 1, system => 'roman' }
bII+h	{ ext => 'h', name => 'bII+h', qual => '+', root => 'II', root_canon => 'II', root_mod => -1, root_ord => 1, system => 'roman' }
bii+h	{ ext => 'h', name => 'bii+h', qual => '-', root => 'ii', root_canon => 'ii', root_mod => -1, root_ord => 1, system => 'roman' }
bII+h7	{ ext => 'h7', name => 'bII+h7', qual => '+', root => 'II', root_canon => 'II', root_mod => -1, root_ord => 1, system => 'roman' }
bii+h7	{ ext => 'h7', name => 'bii+h7', qual => '-', root => 'ii', root_canon => 'ii', root_mod => -1, root_ord => 1, system => 'roman' }
bII+^7	{ ext => '^7', name => 'bII+^7', qual => '+', root => 'II', root_canon => 'II', root_mod => -1, root_ord => 1, system => 'roman' }
bii+^7	{ ext => '^7', name => 'bii+^7', qual => '-', root => 'ii', root_canon => 'ii', root_mod => -1, root_ord => 1, system => 'roman' }
II	{ ext => '', name => 'II', qual => '', root => 'II', root_canon => 'II', root_ord => 2, system => 'roman' }
ii	{ ext => '', name => 'ii', qual => '-', root => 'ii', root_canon => 'ii', root_ord => 2, system => 'roman' }
II7	{ ext => 7, name => 'II7', qual => '', root => 'II', root_canon => 'II', root_ord => 2, system => 'roman' }
ii7	{ ext => 7, name => 'ii7', qual => '-', root => 'ii', root_canon => 'ii', root_ord => 2, system => 'roman' }
II^	{ ext => '^', name => 'II^', qual => '', root => 'II', root_canon => 'II', root_ord => 2, system => 'roman' }
ii^	{ ext => '^', name => 'ii^', qual => '-', root => 'ii', root_canon => 'ii', root_ord => 2, system => 'roman' }
IIh	{ ext => 'h', name => 'IIh', qual => '', root => 'II', root_canon => 'II', root_ord => 2, system => 'roman' }
iih	{ ext => 'h', name => 'iih', qual => '-', root => 'ii', root_canon => 'ii', root_ord => 2, system => 'roman' }
IIh7	{ ext => 'h7', name => 'IIh7', qual => '', root => 'II', root_canon => 'II', root_ord => 2, system => 'roman' }
iih7	{ ext => 'h7', name => 'iih7', qual => '-', root => 'ii', root_canon => 'ii', root_ord => 2, system => 'roman' }
II^7	{ ext => '^7', name => 'II^7', qual => '', root => 'II', root_canon => 'II', root_ord => 2, system => 'roman' }
ii^7	{ ext => '^7', name => 'ii^7', qual => '-', root => 'ii', root_canon => 'ii', root_ord => 2, system => 'roman' }
II0	{ ext => '', name => 'II0', qual => 0, root => 'II', root_canon => 'II', root_ord => 2, system => 'roman' }
ii0	{ ext => '', name => 'ii0', qual => '-', root => 'ii', root_canon => 'ii', root_ord => 2, system => 'roman' }
II07	{ ext => 7, name => 'II07', qual => 0, root => 'II', root_canon => 'II', root_ord => 2, system => 'roman' }
ii07	{ ext => 7, name => 'ii07', qual => '-', root => 'ii', root_canon => 'ii', root_ord => 2, system => 'roman' }
II0^	{ ext => '^', name => 'II0^', qual => 0, root => 'II', root_canon => 'II', root_ord => 2, system => 'roman' }
ii0^	{ ext => '^', name => 'ii0^', qual => '-', root => 'ii', root_canon => 'ii', root_ord => 2, system => 'roman' }
II0h	{ ext => 'h', name => 'II0h', qual => 0, root => 'II', root_canon => 'II', root_ord => 2, system => 'roman' }
ii0h	{ ext => 'h', name => 'ii0h', qual => '-', root => 'ii', root_canon => 'ii', root_ord => 2, system => 'roman' }
II0h7	{ ext => 'h7', name => 'II0h7', qual => 0, root => 'II', root_canon => 'II', root_ord => 2, system => 'roman' }
ii0h7	{ ext => 'h7', name => 'ii0h7', qual => '-', root => 'ii', root_canon => 'ii', root_ord => 2, system => 'roman' }
II0^7	{ ext => '^7', name => 'II0^7', qual => 0, root => 'II', root_canon => 'II', root_ord => 2, system => 'roman' }
ii0^7	{ ext => '^7', name => 'ii0^7', qual => '-', root => 'ii', root_canon => 'ii', root_ord => 2, system => 'roman' }
II+	{ ext => '', name => 'II+', qual => '+', root => 'II', root_canon => 'II', root_ord => 2, system => 'roman' }
ii+	{ ext => '', name => 'ii+', qual => '-', root => 'ii', root_canon => 'ii', root_ord => 2, system => 'roman' }
II+7	{ ext => 7, name => 'II+7', qual => '+', root => 'II', root_canon => 'II', root_ord => 2, system => 'roman' }
ii+7	{ ext => 7, name => 'ii+7', qual => '-', root => 'ii', root_canon => 'ii', root_ord => 2, system => 'roman' }
II+^	{ ext => '^', name => 'II+^', qual => '+', root => 'II', root_canon => 'II', root_ord => 2, system => 'roman' }
ii+^	{ ext => '^', name => 'ii+^', qual => '-', root => 'ii', root_canon => 'ii', root_ord => 2, system => 'roman' }
II+h	{ ext => 'h', name => 'II+h', qual => '+', root => 'II', root_canon => 'II', root_ord => 2, system => 'roman' }
ii+h	{ ext => 'h', name => 'ii+h', qual => '-', root => 'ii', root_canon => 'ii', root_ord => 2, system => 'roman' }
II+h7	{ ext => 'h7', name => 'II+h7', qual => '+', root => 'II', root_canon => 'II', root_ord => 2, system => 'roman' }
ii+h7	{ ext => 'h7', name => 'ii+h7', qual => '-', root => 'ii', root_canon => 'ii', root_ord => 2, system => 'roman' }
II+^7	{ ext => '^7', name => 'II+^7', qual => '+', root => 'II', root_canon => 'II', root_ord => 2, system => 'roman' }
ii+^7	{ ext => '^7', name => 'ii+^7', qual => '-', root => 'ii', root_canon => 'ii', root_ord => 2, system => 'roman' }
#II	{ ext => '', name => '#II', qual => '', root => 'II', root_canon => 'II', root_mod => 1, root_ord => 3, system => 'roman' }
#ii	{ ext => '', name => '#ii', qual => '-', root => 'ii', root_canon => 'ii', root_mod => 1, root_ord => 3, system => 'roman' }
#II7	{ ext => 7, name => '#II7', qual => '', root => 'II', root_canon => 'II', root_mod => 1, root_ord => 3, system => 'roman' }
#ii7	{ ext => 7, name => '#ii7', qual => '-', root => 'ii', root_canon => 'ii', root_mod => 1, root_ord => 3, system => 'roman' }
#II^	{ ext => '^', name => '#II^', qual => '', root => 'II', root_canon => 'II', root_mod => 1, root_ord => 3, system => 'roman' }
#ii^	{ ext => '^', name => '#ii^', qual => '-', root => 'ii', root_canon => 'ii', root_mod => 1, root_ord => 3, system => 'roman' }
#IIh	{ ext => 'h', name => '#IIh', qual => '', root => 'II', root_canon => 'II', root_mod => 1, root_ord => 3, system => 'roman' }
#iih	{ ext => 'h', name => '#iih', qual => '-', root => 'ii', root_canon => 'ii', root_mod => 1, root_ord => 3, system => 'roman' }
#IIh7	{ ext => 'h7', name => '#IIh7', qual => '', root => 'II', root_canon => 'II', root_mod => 1, root_ord => 3, system => 'roman' }
#iih7	{ ext => 'h7', name => '#iih7', qual => '-', root => 'ii', root_canon => 'ii', root_mod => 1, root_ord => 3, system => 'roman' }
#II^7	{ ext => '^7', name => '#II^7', qual => '', root => 'II', root_canon => 'II', root_mod => 1, root_ord => 3, system => 'roman' }
#ii^7	{ ext => '^7', name => '#ii^7', qual => '-', root => 'ii', root_canon => 'ii', root_mod => 1, root_ord => 3, system => 'roman' }
#II0	{ ext => '', name => '#II0', qual => 0, root => 'II', root_canon => 'II', root_mod => 1, root_ord => 3, system => 'roman' }
#ii0	{ ext => '', name => '#ii0', qual => '-', root => 'ii', root_canon => 'ii', root_mod => 1, root_ord => 3, system => 'roman' }
#II07	{ ext => 7, name => '#II07', qual => 0, root => 'II', root_canon => 'II', root_mod => 1, root_ord => 3, system => 'roman' }
#ii07	{ ext => 7, name => '#ii07', qual => '-', root => 'ii', root_canon => 'ii', root_mod => 1, root_ord => 3, system => 'roman' }
#II0^	{ ext => '^', name => '#II0^', qual => 0, root => 'II', root_canon => 'II', root_mod => 1, root_ord => 3, system => 'roman' }
#ii0^	{ ext => '^', name => '#ii0^', qual => '-', root => 'ii', root_canon => 'ii', root_mod => 1, root_ord => 3, system => 'roman' }
#II0h	{ ext => 'h', name => '#II0h', qual => 0, root => 'II', root_canon => 'II', root_mod => 1, root_ord => 3, system => 'roman' }
#ii0h	{ ext => 'h', name => '#ii0h', qual => '-', root => 'ii', root_canon => 'ii', root_mod => 1, root_ord => 3, system => 'roman' }
#II0h7	{ ext => 'h7', name => '#II0h7', qual => 0, root => 'II', root_canon => 'II', root_mod => 1, root_ord => 3, system => 'roman' }
#ii0h7	{ ext => 'h7', name => '#ii0h7', qual => '-', root => 'ii', root_canon => 'ii', root_mod => 1, root_ord => 3, system => 'roman' }
#II0^7	{ ext => '^7', name => '#II0^7', qual => 0, root => 'II', root_canon => 'II', root_mod => 1, root_ord => 3, system => 'roman' }
#ii0^7	{ ext => '^7', name => '#ii0^7', qual => '-', root => 'ii', root_canon => 'ii', root_mod => 1, root_ord => 3, system => 'roman' }
#II+	{ ext => '', name => '#II+', qual => '+', root => 'II', root_canon => 'II', root_mod => 1, root_ord => 3, system => 'roman' }
#ii+	{ ext => '', name => '#ii+', qual => '-', root => 'ii', root_canon => 'ii', root_mod => 1, root_ord => 3, system => 'roman' }
#II+7	{ ext => 7, name => '#II+7', qual => '+', root => 'II', root_canon => 'II', root_mod => 1, root_ord => 3, system => 'roman' }
#ii+7	{ ext => 7, name => '#ii+7', qual => '-', root => 'ii', root_canon => 'ii', root_mod => 1, root_ord => 3, system => 'roman' }
#II+^	{ ext => '^', name => '#II+^', qual => '+', root => 'II', root_canon => 'II', root_mod => 1, root_ord => 3, system => 'roman' }
#ii+^	{ ext => '^', name => '#ii+^', qual => '-', root => 'ii', root_canon => 'ii', root_mod => 1, root_ord => 3, system => 'roman' }
#II+h	{ ext => 'h', name => '#II+h', qual => '+', root => 'II', root_canon => 'II', root_mod => 1, root_ord => 3, system => 'roman' }
#ii+h	{ ext => 'h', name => '#ii+h', qual => '-', root => 'ii', root_canon => 'ii', root_mod => 1, root_ord => 3, system => 'roman' }
#II+h7	{ ext => 'h7', name => '#II+h7', qual => '+', root => 'II', root_canon => 'II', root_mod => 1, root_ord => 3, system => 'roman' }
#ii+h7	{ ext => 'h7', name => '#ii+h7', qual => '-', root => 'ii', root_canon => 'ii', root_mod => 1, root_ord => 3, system => 'roman' }
#II+^7	{ ext => '^7', name => '#II+^7', qual => '+', root => 'II', root_canon => 'II', root_mod => 1, root_ord => 3, system => 'roman' }
#ii+^7	{ ext => '^7', name => '#ii+^7', qual => '-', root => 'ii', root_canon => 'ii', root_mod => 1, root_ord => 3, system => 'roman' }
bIII	{ ext => '', name => 'bIII', qual => '', root => 'III', root_canon => 'III', root_mod => -1, root_ord => 3, system => 'roman' }
biii	{ ext => '', name => 'biii', qual => '-', root => 'iii', root_canon => 'iii', root_mod => -1, root_ord => 3, system => 'roman' }
bIII7	{ ext => 7, name => 'bIII7', qual => '', root => 'III', root_canon => 'III', root_mod => -1, root_ord => 3, system => 'roman' }
biii7	{ ext => 7, name => 'biii7', qual => '-', root => 'iii', root_canon => 'iii', root_mod => -1, root_ord => 3, system => 'roman' }
bIII^	{ ext => '^', name => 'bIII^', qual => '', root => 'III', root_canon => 'III', root_mod => -1, root_ord => 3, system => 'roman' }
biii^	{ ext => '^', name => 'biii^', qual => '-', root => 'iii', root_canon => 'iii', root_mod => -1, root_ord => 3, system => 'roman' }
bIIIh	{ ext => 'h', name => 'bIIIh', qual => '', root => 'III', root_canon => 'III', root_mod => -1, root_ord => 3, system => 'roman' }
biiih	{ ext => 'h', name => 'biiih', qual => '-', root => 'iii', root_canon => 'iii', root_mod => -1, root_ord => 3, system => 'roman' }
bIIIh7	{ ext => 'h7', name => 'bIIIh7', qual => '', root => 'III', root_canon => 'III', root_mod => -1, root_ord => 3, system => 'roman' }
biiih7	{ ext => 'h7', name => 'biiih7', qual => '-', root => 'iii', root_canon => 'iii', root_mod => -1, root_ord => 3, system => 'roman' }
bIII^7	{ ext => '^7', name => 'bIII^7', qual => '', root => 'III', root_canon => 'III', root_mod => -1, root_ord => 3, system => 'roman' }
biii^7	{ ext => '^7', name => 'biii^7', qual => '-', root => 'iii', root_canon => 'iii', root_mod => -1, root_ord => 3, system => 'roman' }
bIII0	{ ext => '', name => 'bIII0', qual => 0, root => 'III', root_canon => 'III', root_mod => -1, root_ord => 3, system => 'roman' }
biii0	{ ext => '', name => 'biii0', qual => '-', root => 'iii', root_canon => 'iii', root_mod => -1, root_ord => 3, system => 'roman' }
bIII07	{ ext => 7, name => 'bIII07', qual => 0, root => 'III', root_canon => 'III', root_mod => -1, root_ord => 3, system => 'roman' }
biii07	{ ext => 7, name => 'biii07', qual => '-', root => 'iii', root_canon => 'iii', root_mod => -1, root_ord => 3, system => 'roman' }
bIII0^	{ ext => '^', name => 'bIII0^', qual => 0, root => 'III', root_canon => 'III', root_mod => -1, root_ord => 3, system => 'roman' }
biii0^	{ ext => '^', name => 'biii0^', qual => '-', root => 'iii', root_canon => 'iii', root_mod => -1, root_ord => 3, system => 'roman' }
bIII0h	{ ext => 'h', name => 'bIII0h', qual => 0, root => 'III', root_canon => 'III', root_mod => -1, root_ord => 3, system => 'roman' }
biii0h	{ ext => 'h', name => 'biii0h', qual => '-', root => 'iii', root_canon => 'iii', root_mod => -1, root_ord => 3, system => 'roman' }
bIII0h7	{ ext => 'h7', name => 'bIII0h7', qual => 0, root => 'III', root_canon => 'III', root_mod => -1, root_ord => 3, system => 'roman' }
biii0h7	{ ext => 'h7', name => 'biii0h7', qual => '-', root => 'iii', root_canon => 'iii', root_mod => -1, root_ord => 3, system => 'roman' }
bIII0^7	{ ext => '^7', name => 'bIII0^7', qual => 0, root => 'III', root_canon => 'III', root_mod => -1, root_ord => 3, system => 'roman' }
biii0^7	{ ext => '^7', name => 'biii0^7', qual => '-', root => 'iii', root_canon => 'iii', root_mod => -1, root_ord => 3, system => 'roman' }
bIII+	{ ext => '', name => 'bIII+', qual => '+', root => 'III', root_canon => 'III', root_mod => -1, root_ord => 3, system => 'roman' }
biii+	{ ext => '', name => 'biii+', qual => '-', root => 'iii', root_canon => 'iii', root_mod => -1, root_ord => 3, system => 'roman' }
bIII+7	{ ext => 7, name => 'bIII+7', qual => '+', root => 'III', root_canon => 'III', root_mod => -1, root_ord => 3, system => 'roman' }
biii+7	{ ext => 7, name => 'biii+7', qual => '-', root => 'iii', root_canon => 'iii', root_mod => -1, root_ord => 3, system => 'roman' }
bIII+^	{ ext => '^', name => 'bIII+^', qual => '+', root => 'III', root_canon => 'III', root_mod => -1, root_ord => 3, system => 'roman' }
biii+^	{ ext => '^', name => 'biii+^', qual => '-', root => 'iii', root_canon => 'iii', root_mod => -1, root_ord => 3, system => 'roman' }
bIII+h	{ ext => 'h', name => 'bIII+h', qual => '+', root => 'III', root_canon => 'III', root_mod => -1, root_ord => 3, system => 'roman' }
biii+h	{ ext => 'h', name => 'biii+h', qual => '-', root => 'iii', root_canon => 'iii', root_mod => -1, root_ord => 3, system => 'roman' }
bIII+h7	{ ext => 'h7', name => 'bIII+h7', qual => '+', root => 'III', root_canon => 'III', root_mod => -1, root_ord => 3, system => 'roman' }
biii+h7	{ ext => 'h7', name => 'biii+h7', qual => '-', root => 'iii', root_canon => 'iii', root_mod => -1, root_ord => 3, system => 'roman' }
bIII+^7	{ ext => '^7', name => 'bIII+^7', qual => '+', root => 'III', root_canon => 'III', root_mod => -1, root_ord => 3, system => 'roman' }
biii+^7	{ ext => '^7', name => 'biii+^7', qual => '-', root => 'iii', root_canon => 'iii', root_mod => -1, root_ord => 3, system => 'roman' }
III	{ ext => '', name => 'III', qual => '', root => 'III', root_canon => 'III', root_ord => 4, system => 'roman' }
iii	{ ext => '', name => 'iii', qual => '-', root => 'iii', root_canon => 'iii', root_ord => 4, system => 'roman' }
III7	{ ext => 7, name => 'III7', qual => '', root => 'III', root_canon => 'III', root_ord => 4, system => 'roman' }
iii7	{ ext => 7, name => 'iii7', qual => '-', root => 'iii', root_canon => 'iii', root_ord => 4, system => 'roman' }
III^	{ ext => '^', name => 'III^', qual => '', root => 'III', root_canon => 'III', root_ord => 4, system => 'roman' }
iii^	{ ext => '^', name => 'iii^', qual => '-', root => 'iii', root_canon => 'iii', root_ord => 4, system => 'roman' }
IIIh	{ ext => 'h', name => 'IIIh', qual => '', root => 'III', root_canon => 'III', root_ord => 4, system => 'roman' }
iiih	{ ext => 'h', name => 'iiih', qual => '-', root => 'iii', root_canon => 'iii', root_ord => 4, system => 'roman' }
IIIh7	{ ext => 'h7', name => 'IIIh7', qual => '', root => 'III', root_canon => 'III', root_ord => 4, system => 'roman' }
iiih7	{ ext => 'h7', name => 'iiih7', qual => '-', root => 'iii', root_canon => 'iii', root_ord => 4, system => 'roman' }
III^7	{ ext => '^7', name => 'III^7', qual => '', root => 'III', root_canon => 'III', root_ord => 4, system => 'roman' }
iii^7	{ ext => '^7', name => 'iii^7', qual => '-', root => 'iii', root_canon => 'iii', root_ord => 4, system => 'roman' }
III0	{ ext => '', name => 'III0', qual => 0, root => 'III', root_canon => 'III', root_ord => 4, system => 'roman' }
iii0	{ ext => '', name => 'iii0', qual => '-', root => 'iii', root_canon => 'iii', root_ord => 4, system => 'roman' }
III07	{ ext => 7, name => 'III07', qual => 0, root => 'III', root_canon => 'III', root_ord => 4, system => 'roman' }
iii07	{ ext => 7, name => 'iii07', qual => '-', root => 'iii', root_canon => 'iii', root_ord => 4, system => 'roman' }
III0^	{ ext => '^', name => 'III0^', qual => 0, root => 'III', root_canon => 'III', root_ord => 4, system => 'roman' }
iii0^	{ ext => '^', name => 'iii0^', qual => '-', root => 'iii', root_canon => 'iii', root_ord => 4, system => 'roman' }
III0h	{ ext => 'h', name => 'III0h', qual => 0, root => 'III', root_canon => 'III', root_ord => 4, system => 'roman' }
iii0h	{ ext => 'h', name => 'iii0h', qual => '-', root => 'iii', root_canon => 'iii', root_ord => 4, system => 'roman' }
III0h7	{ ext => 'h7', name => 'III0h7', qual => 0, root => 'III', root_canon => 'III', root_ord => 4, system => 'roman' }
iii0h7	{ ext => 'h7', name => 'iii0h7', qual => '-', root => 'iii', root_canon => 'iii', root_ord => 4, system => 'roman' }
III0^7	{ ext => '^7', name => 'III0^7', qual => 0, root => 'III', root_canon => 'III', root_ord => 4, system => 'roman' }
iii0^7	{ ext => '^7', name => 'iii0^7', qual => '-', root => 'iii', root_canon => 'iii', root_ord => 4, system => 'roman' }
III+	{ ext => '', name => 'III+', qual => '+', root => 'III', root_canon => 'III', root_ord => 4, system => 'roman' }
iii+	{ ext => '', name => 'iii+', qual => '-', root => 'iii', root_canon => 'iii', root_ord => 4, system => 'roman' }
III+7	{ ext => 7, name => 'III+7', qual => '+', root => 'III', root_canon => 'III', root_ord => 4, system => 'roman' }
iii+7	{ ext => 7, name => 'iii+7', qual => '-', root => 'iii', root_canon => 'iii', root_ord => 4, system => 'roman' }
III+^	{ ext => '^', name => 'III+^', qual => '+', root => 'III', root_canon => 'III', root_ord => 4, system => 'roman' }
iii+^	{ ext => '^', name => 'iii+^', qual => '-', root => 'iii', root_canon => 'iii', root_ord => 4, system => 'roman' }
III+h	{ ext => 'h', name => 'III+h', qual => '+', root => 'III', root_canon => 'III', root_ord => 4, system => 'roman' }
iii+h	{ ext => 'h', name => 'iii+h', qual => '-', root => 'iii', root_canon => 'iii', root_ord => 4, system => 'roman' }
III+h7	{ ext => 'h7', name => 'III+h7', qual => '+', root => 'III', root_canon => 'III', root_ord => 4, system => 'roman' }
iii+h7	{ ext => 'h7', name => 'iii+h7', qual => '-', root => 'iii', root_canon => 'iii', root_ord => 4, system => 'roman' }
III+^7	{ ext => '^7', name => 'III+^7', qual => '+', root => 'III', root_canon => 'III', root_ord => 4, system => 'roman' }
iii+^7	{ ext => '^7', name => 'iii+^7', qual => '-', root => 'iii', root_canon => 'iii', root_ord => 4, system => 'roman' }
IV	{ ext => '', name => 'IV', qual => '', root => 'IV', root_canon => 'IV', root_ord => 5, system => 'roman' }
iv	{ ext => '', name => 'iv', qual => '-', root => 'iv', root_canon => 'iv', root_ord => 5, system => 'roman' }
IV7	{ ext => 7, name => 'IV7', qual => '', root => 'IV', root_canon => 'IV', root_ord => 5, system => 'roman' }
iv7	{ ext => 7, name => 'iv7', qual => '-', root => 'iv', root_canon => 'iv', root_ord => 5, system => 'roman' }
IV^	{ ext => '^', name => 'IV^', qual => '', root => 'IV', root_canon => 'IV', root_ord => 5, system => 'roman' }
iv^	{ ext => '^', name => 'iv^', qual => '-', root => 'iv', root_canon => 'iv', root_ord => 5, system => 'roman' }
IVh	{ ext => 'h', name => 'IVh', qual => '', root => 'IV', root_canon => 'IV', root_ord => 5, system => 'roman' }
ivh	{ ext => 'h', name => 'ivh', qual => '-', root => 'iv', root_canon => 'iv', root_ord => 5, system => 'roman' }
IVh7	{ ext => 'h7', name => 'IVh7', qual => '', root => 'IV', root_canon => 'IV', root_ord => 5, system => 'roman' }
ivh7	{ ext => 'h7', name => 'ivh7', qual => '-', root => 'iv', root_canon => 'iv', root_ord => 5, system => 'roman' }
IV^7	{ ext => '^7', name => 'IV^7', qual => '', root => 'IV', root_canon => 'IV', root_ord => 5, system => 'roman' }
iv^7	{ ext => '^7', name => 'iv^7', qual => '-', root => 'iv', root_canon => 'iv', root_ord => 5, system => 'roman' }
IV0	{ ext => '', name => 'IV0', qual => 0, root => 'IV', root_canon => 'IV', root_ord => 5, system => 'roman' }
iv0	{ ext => '', name => 'iv0', qual => '-', root => 'iv', root_canon => 'iv', root_ord => 5, system => 'roman' }
IV07	{ ext => 7, name => 'IV07', qual => 0, root => 'IV', root_canon => 'IV', root_ord => 5, system => 'roman' }
iv07	{ ext => 7, name => 'iv07', qual => '-', root => 'iv', root_canon => 'iv', root_ord => 5, system => 'roman' }
IV0^	{ ext => '^', name => 'IV0^', qual => 0, root => 'IV', root_canon => 'IV', root_ord => 5, system => 'roman' }
iv0^	{ ext => '^', name => 'iv0^', qual => '-', root => 'iv', root_canon => 'iv', root_ord => 5, system => 'roman' }
IV0h	{ ext => 'h', name => 'IV0h', qual => 0, root => 'IV', root_canon => 'IV', root_ord => 5, system => 'roman' }
iv0h	{ ext => 'h', name => 'iv0h', qual => '-', root => 'iv', root_canon => 'iv', root_ord => 5, system => 'roman' }
IV0h7	{ ext => 'h7', name => 'IV0h7', qual => 0, root => 'IV', root_canon => 'IV', root_ord => 5, system => 'roman' }
iv0h7	{ ext => 'h7', name => 'iv0h7', qual => '-', root => 'iv', root_canon => 'iv', root_ord => 5, system => 'roman' }
IV0^7	{ ext => '^7', name => 'IV0^7', qual => 0, root => 'IV', root_canon => 'IV', root_ord => 5, system => 'roman' }
iv0^7	{ ext => '^7', name => 'iv0^7', qual => '-', root => 'iv', root_canon => 'iv', root_ord => 5, system => 'roman' }
IV+	{ ext => '', name => 'IV+', qual => '+', root => 'IV', root_canon => 'IV', root_ord => 5, system => 'roman' }
iv+	{ ext => '', name => 'iv+', qual => '-', root => 'iv', root_canon => 'iv', root_ord => 5, system => 'roman' }
IV+7	{ ext => 7, name => 'IV+7', qual => '+', root => 'IV', root_canon => 'IV', root_ord => 5, system => 'roman' }
iv+7	{ ext => 7, name => 'iv+7', qual => '-', root => 'iv', root_canon => 'iv', root_ord => 5, system => 'roman' }
IV+^	{ ext => '^', name => 'IV+^', qual => '+', root => 'IV', root_canon => 'IV', root_ord => 5, system => 'roman' }
iv+^	{ ext => '^', name => 'iv+^', qual => '-', root => 'iv', root_canon => 'iv', root_ord => 5, system => 'roman' }
IV+h	{ ext => 'h', name => 'IV+h', qual => '+', root => 'IV', root_canon => 'IV', root_ord => 5, system => 'roman' }
iv+h	{ ext => 'h', name => 'iv+h', qual => '-', root => 'iv', root_canon => 'iv', root_ord => 5, system => 'roman' }
IV+h7	{ ext => 'h7', name => 'IV+h7', qual => '+', root => 'IV', root_canon => 'IV', root_ord => 5, system => 'roman' }
iv+h7	{ ext => 'h7', name => 'iv+h7', qual => '-', root => 'iv', root_canon => 'iv', root_ord => 5, system => 'roman' }
IV+^7	{ ext => '^7', name => 'IV+^7', qual => '+', root => 'IV', root_canon => 'IV', root_ord => 5, system => 'roman' }
iv+^7	{ ext => '^7', name => 'iv+^7', qual => '-', root => 'iv', root_canon => 'iv', root_ord => 5, system => 'roman' }
#IV	{ ext => '', name => '#IV', qual => '', root => 'IV', root_canon => 'IV', root_mod => 1, root_ord => 6, system => 'roman' }
#iv	{ ext => '', name => '#iv', qual => '-', root => 'iv', root_canon => 'iv', root_mod => 1, root_ord => 6, system => 'roman' }
#IV7	{ ext => 7, name => '#IV7', qual => '', root => 'IV', root_canon => 'IV', root_mod => 1, root_ord => 6, system => 'roman' }
#iv7	{ ext => 7, name => '#iv7', qual => '-', root => 'iv', root_canon => 'iv', root_mod => 1, root_ord => 6, system => 'roman' }
#IV^	{ ext => '^', name => '#IV^', qual => '', root => 'IV', root_canon => 'IV', root_mod => 1, root_ord => 6, system => 'roman' }
#iv^	{ ext => '^', name => '#iv^', qual => '-', root => 'iv', root_canon => 'iv', root_mod => 1, root_ord => 6, system => 'roman' }
#IVh	{ ext => 'h', name => '#IVh', qual => '', root => 'IV', root_canon => 'IV', root_mod => 1, root_ord => 6, system => 'roman' }
#ivh	{ ext => 'h', name => '#ivh', qual => '-', root => 'iv', root_canon => 'iv', root_mod => 1, root_ord => 6, system => 'roman' }
#IVh7	{ ext => 'h7', name => '#IVh7', qual => '', root => 'IV', root_canon => 'IV', root_mod => 1, root_ord => 6, system => 'roman' }
#ivh7	{ ext => 'h7', name => '#ivh7', qual => '-', root => 'iv', root_canon => 'iv', root_mod => 1, root_ord => 6, system => 'roman' }
#IV^7	{ ext => '^7', name => '#IV^7', qual => '', root => 'IV', root_canon => 'IV', root_mod => 1, root_ord => 6, system => 'roman' }
#iv^7	{ ext => '^7', name => '#iv^7', qual => '-', root => 'iv', root_canon => 'iv', root_mod => 1, root_ord => 6, system => 'roman' }
#IV0	{ ext => '', name => '#IV0', qual => 0, root => 'IV', root_canon => 'IV', root_mod => 1, root_ord => 6, system => 'roman' }
#iv0	{ ext => '', name => '#iv0', qual => '-', root => 'iv', root_canon => 'iv', root_mod => 1, root_ord => 6, system => 'roman' }
#IV07	{ ext => 7, name => '#IV07', qual => 0, root => 'IV', root_canon => 'IV', root_mod => 1, root_ord => 6, system => 'roman' }
#iv07	{ ext => 7, name => '#iv07', qual => '-', root => 'iv', root_canon => 'iv', root_mod => 1, root_ord => 6, system => 'roman' }
#IV0^	{ ext => '^', name => '#IV0^', qual => 0, root => 'IV', root_canon => 'IV', root_mod => 1, root_ord => 6, system => 'roman' }
#iv0^	{ ext => '^', name => '#iv0^', qual => '-', root => 'iv', root_canon => 'iv', root_mod => 1, root_ord => 6, system => 'roman' }
#IV0h	{ ext => 'h', name => '#IV0h', qual => 0, root => 'IV', root_canon => 'IV', root_mod => 1, root_ord => 6, system => 'roman' }
#iv0h	{ ext => 'h', name => '#iv0h', qual => '-', root => 'iv', root_canon => 'iv', root_mod => 1, root_ord => 6, system => 'roman' }
#IV0h7	{ ext => 'h7', name => '#IV0h7', qual => 0, root => 'IV', root_canon => 'IV', root_mod => 1, root_ord => 6, system => 'roman' }
#iv0h7	{ ext => 'h7', name => '#iv0h7', qual => '-', root => 'iv', root_canon => 'iv', root_mod => 1, root_ord => 6, system => 'roman' }
#IV0^7	{ ext => '^7', name => '#IV0^7', qual => 0, root => 'IV', root_canon => 'IV', root_mod => 1, root_ord => 6, system => 'roman' }
#iv0^7	{ ext => '^7', name => '#iv0^7', qual => '-', root => 'iv', root_canon => 'iv', root_mod => 1, root_ord => 6, system => 'roman' }
#IV+	{ ext => '', name => '#IV+', qual => '+', root => 'IV', root_canon => 'IV', root_mod => 1, root_ord => 6, system => 'roman' }
#iv+	{ ext => '', name => '#iv+', qual => '-', root => 'iv', root_canon => 'iv', root_mod => 1, root_ord => 6, system => 'roman' }
#IV+7	{ ext => 7, name => '#IV+7', qual => '+', root => 'IV', root_canon => 'IV', root_mod => 1, root_ord => 6, system => 'roman' }
#iv+7	{ ext => 7, name => '#iv+7', qual => '-', root => 'iv', root_canon => 'iv', root_mod => 1, root_ord => 6, system => 'roman' }
#IV+^	{ ext => '^', name => '#IV+^', qual => '+', root => 'IV', root_canon => 'IV', root_mod => 1, root_ord => 6, system => 'roman' }
#iv+^	{ ext => '^', name => '#iv+^', qual => '-', root => 'iv', root_canon => 'iv', root_mod => 1, root_ord => 6, system => 'roman' }
#IV+h	{ ext => 'h', name => '#IV+h', qual => '+', root => 'IV', root_canon => 'IV', root_mod => 1, root_ord => 6, system => 'roman' }
#iv+h	{ ext => 'h', name => '#iv+h', qual => '-', root => 'iv', root_canon => 'iv', root_mod => 1, root_ord => 6, system => 'roman' }
#IV+h7	{ ext => 'h7', name => '#IV+h7', qual => '+', root => 'IV', root_canon => 'IV', root_mod => 1, root_ord => 6, system => 'roman' }
#iv+h7	{ ext => 'h7', name => '#iv+h7', qual => '-', root => 'iv', root_canon => 'iv', root_mod => 1, root_ord => 6, system => 'roman' }
#IV+^7	{ ext => '^7', name => '#IV+^7', qual => '+', root => 'IV', root_canon => 'IV', root_mod => 1, root_ord => 6, system => 'roman' }
#iv+^7	{ ext => '^7', name => '#iv+^7', qual => '-', root => 'iv', root_canon => 'iv', root_mod => 1, root_ord => 6, system => 'roman' }
bV	{ ext => '', name => 'bV', qual => '', root => 'V', root_canon => 'V', root_mod => -1, root_ord => 6, system => 'roman' }
bv	{ ext => '', name => 'bv', qual => '-', root => 'v', root_canon => 'v', root_mod => -1, root_ord => 6, system => 'roman' }
bV7	{ ext => 7, name => 'bV7', qual => '', root => 'V', root_canon => 'V', root_mod => -1, root_ord => 6, system => 'roman' }
bv7	{ ext => 7, name => 'bv7', qual => '-', root => 'v', root_canon => 'v', root_mod => -1, root_ord => 6, system => 'roman' }
bV^	{ ext => '^', name => 'bV^', qual => '', root => 'V', root_canon => 'V', root_mod => -1, root_ord => 6, system => 'roman' }
bv^	{ ext => '^', name => 'bv^', qual => '-', root => 'v', root_canon => 'v', root_mod => -1, root_ord => 6, system => 'roman' }
bVh	{ ext => 'h', name => 'bVh', qual => '', root => 'V', root_canon => 'V', root_mod => -1, root_ord => 6, system => 'roman' }
bvh	{ ext => 'h', name => 'bvh', qual => '-', root => 'v', root_canon => 'v', root_mod => -1, root_ord => 6, system => 'roman' }
bVh7	{ ext => 'h7', name => 'bVh7', qual => '', root => 'V', root_canon => 'V', root_mod => -1, root_ord => 6, system => 'roman' }
bvh7	{ ext => 'h7', name => 'bvh7', qual => '-', root => 'v', root_canon => 'v', root_mod => -1, root_ord => 6, system => 'roman' }
bV^7	{ ext => '^7', name => 'bV^7', qual => '', root => 'V', root_canon => 'V', root_mod => -1, root_ord => 6, system => 'roman' }
bv^7	{ ext => '^7', name => 'bv^7', qual => '-', root => 'v', root_canon => 'v', root_mod => -1, root_ord => 6, system => 'roman' }
bV0	{ ext => '', name => 'bV0', qual => 0, root => 'V', root_canon => 'V', root_mod => -1, root_ord => 6, system => 'roman' }
bv0	{ ext => '', name => 'bv0', qual => '-', root => 'v', root_canon => 'v', root_mod => -1, root_ord => 6, system => 'roman' }
bV07	{ ext => 7, name => 'bV07', qual => 0, root => 'V', root_canon => 'V', root_mod => -1, root_ord => 6, system => 'roman' }
bv07	{ ext => 7, name => 'bv07', qual => '-', root => 'v', root_canon => 'v', root_mod => -1, root_ord => 6, system => 'roman' }
bV0^	{ ext => '^', name => 'bV0^', qual => 0, root => 'V', root_canon => 'V', root_mod => -1, root_ord => 6, system => 'roman' }
bv0^	{ ext => '^', name => 'bv0^', qual => '-', root => 'v', root_canon => 'v', root_mod => -1, root_ord => 6, system => 'roman' }
bV0h	{ ext => 'h', name => 'bV0h', qual => 0, root => 'V', root_canon => 'V', root_mod => -1, root_ord => 6, system => 'roman' }
bv0h	{ ext => 'h', name => 'bv0h', qual => '-', root => 'v', root_canon => 'v', root_mod => -1, root_ord => 6, system => 'roman' }
bV0h7	{ ext => 'h7', name => 'bV0h7', qual => 0, root => 'V', root_canon => 'V', root_mod => -1, root_ord => 6, system => 'roman' }
bv0h7	{ ext => 'h7', name => 'bv0h7', qual => '-', root => 'v', root_canon => 'v', root_mod => -1, root_ord => 6, system => 'roman' }
bV0^7	{ ext => '^7', name => 'bV0^7', qual => 0, root => 'V', root_canon => 'V', root_mod => -1, root_ord => 6, system => 'roman' }
bv0^7	{ ext => '^7', name => 'bv0^7', qual => '-', root => 'v', root_canon => 'v', root_mod => -1, root_ord => 6, system => 'roman' }
bV+	{ ext => '', name => 'bV+', qual => '+', root => 'V', root_canon => 'V', root_mod => -1, root_ord => 6, system => 'roman' }
bv+	{ ext => '', name => 'bv+', qual => '-', root => 'v', root_canon => 'v', root_mod => -1, root_ord => 6, system => 'roman' }
bV+7	{ ext => 7, name => 'bV+7', qual => '+', root => 'V', root_canon => 'V', root_mod => -1, root_ord => 6, system => 'roman' }
bv+7	{ ext => 7, name => 'bv+7', qual => '-', root => 'v', root_canon => 'v', root_mod => -1, root_ord => 6, system => 'roman' }
bV+^	{ ext => '^', name => 'bV+^', qual => '+', root => 'V', root_canon => 'V', root_mod => -1, root_ord => 6, system => 'roman' }
bv+^	{ ext => '^', name => 'bv+^', qual => '-', root => 'v', root_canon => 'v', root_mod => -1, root_ord => 6, system => 'roman' }
bV+h	{ ext => 'h', name => 'bV+h', qual => '+', root => 'V', root_canon => 'V', root_mod => -1, root_ord => 6, system => 'roman' }
bv+h	{ ext => 'h', name => 'bv+h', qual => '-', root => 'v', root_canon => 'v', root_mod => -1, root_ord => 6, system => 'roman' }
bV+h7	{ ext => 'h7', name => 'bV+h7', qual => '+', root => 'V', root_canon => 'V', root_mod => -1, root_ord => 6, system => 'roman' }
bv+h7	{ ext => 'h7', name => 'bv+h7', qual => '-', root => 'v', root_canon => 'v', root_mod => -1, root_ord => 6, system => 'roman' }
bV+^7	{ ext => '^7', name => 'bV+^7', qual => '+', root => 'V', root_canon => 'V', root_mod => -1, root_ord => 6, system => 'roman' }
bv+^7	{ ext => '^7', name => 'bv+^7', qual => '-', root => 'v', root_canon => 'v', root_mod => -1, root_ord => 6, system => 'roman' }
V	{ ext => '', name => 'V', qual => '', root => 'V', root_canon => 'V', root_ord => 7, system => 'roman' }
v	{ ext => '', name => 'v', qual => '-', root => 'v', root_canon => 'v', root_ord => 7, system => 'roman' }
V7	{ ext => 7, name => 'V7', qual => '', root => 'V', root_canon => 'V', root_ord => 7, system => 'roman' }
v7	{ ext => 7, name => 'v7', qual => '-', root => 'v', root_canon => 'v', root_ord => 7, system => 'roman' }
V^	{ ext => '^', name => 'V^', qual => '', root => 'V', root_canon => 'V', root_ord => 7, system => 'roman' }
v^	{ ext => '^', name => 'v^', qual => '-', root => 'v', root_canon => 'v', root_ord => 7, system => 'roman' }
Vh	{ ext => 'h', name => 'Vh', qual => '', root => 'V', root_canon => 'V', root_ord => 7, system => 'roman' }
vh	{ ext => 'h', name => 'vh', qual => '-', root => 'v', root_canon => 'v', root_ord => 7, system => 'roman' }
Vh7	{ ext => 'h7', name => 'Vh7', qual => '', root => 'V', root_canon => 'V', root_ord => 7, system => 'roman' }
vh7	{ ext => 'h7', name => 'vh7', qual => '-', root => 'v', root_canon => 'v', root_ord => 7, system => 'roman' }
V^7	{ ext => '^7', name => 'V^7', qual => '', root => 'V', root_canon => 'V', root_ord => 7, system => 'roman' }
v^7	{ ext => '^7', name => 'v^7', qual => '-', root => 'v', root_canon => 'v', root_ord => 7, system => 'roman' }
V0	{ ext => '', name => 'V0', qual => 0, root => 'V', root_canon => 'V', root_ord => 7, system => 'roman' }
v0	{ ext => '', name => 'v0', qual => '-', root => 'v', root_canon => 'v', root_ord => 7, system => 'roman' }
V07	{ ext => 7, name => 'V07', qual => 0, root => 'V', root_canon => 'V', root_ord => 7, system => 'roman' }
v07	{ ext => 7, name => 'v07', qual => '-', root => 'v', root_canon => 'v', root_ord => 7, system => 'roman' }
V0^	{ ext => '^', name => 'V0^', qual => 0, root => 'V', root_canon => 'V', root_ord => 7, system => 'roman' }
v0^	{ ext => '^', name => 'v0^', qual => '-', root => 'v', root_canon => 'v', root_ord => 7, system => 'roman' }
V0h	{ ext => 'h', name => 'V0h', qual => 0, root => 'V', root_canon => 'V', root_ord => 7, system => 'roman' }
v0h	{ ext => 'h', name => 'v0h', qual => '-', root => 'v', root_canon => 'v', root_ord => 7, system => 'roman' }
V0h7	{ ext => 'h7', name => 'V0h7', qual => 0, root => 'V', root_canon => 'V', root_ord => 7, system => 'roman' }
v0h7	{ ext => 'h7', name => 'v0h7', qual => '-', root => 'v', root_canon => 'v', root_ord => 7, system => 'roman' }
V0^7	{ ext => '^7', name => 'V0^7', qual => 0, root => 'V', root_canon => 'V', root_ord => 7, system => 'roman' }
v0^7	{ ext => '^7', name => 'v0^7', qual => '-', root => 'v', root_canon => 'v', root_ord => 7, system => 'roman' }
V+	{ ext => '', name => 'V+', qual => '+', root => 'V', root_canon => 'V', root_ord => 7, system => 'roman' }
v+	{ ext => '', name => 'v+', qual => '-', root => 'v', root_canon => 'v', root_ord => 7, system => 'roman' }
V+7	{ ext => 7, name => 'V+7', qual => '+', root => 'V', root_canon => 'V', root_ord => 7, system => 'roman' }
v+7	{ ext => 7, name => 'v+7', qual => '-', root => 'v', root_canon => 'v', root_ord => 7, system => 'roman' }
V+^	{ ext => '^', name => 'V+^', qual => '+', root => 'V', root_canon => 'V', root_ord => 7, system => 'roman' }
v+^	{ ext => '^', name => 'v+^', qual => '-', root => 'v', root_canon => 'v', root_ord => 7, system => 'roman' }
V+h	{ ext => 'h', name => 'V+h', qual => '+', root => 'V', root_canon => 'V', root_ord => 7, system => 'roman' }
v+h	{ ext => 'h', name => 'v+h', qual => '-', root => 'v', root_canon => 'v', root_ord => 7, system => 'roman' }
V+h7	{ ext => 'h7', name => 'V+h7', qual => '+', root => 'V', root_canon => 'V', root_ord => 7, system => 'roman' }
v+h7	{ ext => 'h7', name => 'v+h7', qual => '-', root => 'v', root_canon => 'v', root_ord => 7, system => 'roman' }
V+^7	{ ext => '^7', name => 'V+^7', qual => '+', root => 'V', root_canon => 'V', root_ord => 7, system => 'roman' }
v+^7	{ ext => '^7', name => 'v+^7', qual => '-', root => 'v', root_canon => 'v', root_ord => 7, system => 'roman' }
#V	{ ext => '', name => '#V', qual => '', root => 'V', root_canon => 'V', root_mod => 1, root_ord => 8, system => 'roman' }
#v	{ ext => '', name => '#v', qual => '-', root => 'v', root_canon => 'v', root_mod => 1, root_ord => 8, system => 'roman' }
#V7	{ ext => 7, name => '#V7', qual => '', root => 'V', root_canon => 'V', root_mod => 1, root_ord => 8, system => 'roman' }
#v7	{ ext => 7, name => '#v7', qual => '-', root => 'v', root_canon => 'v', root_mod => 1, root_ord => 8, system => 'roman' }
#V^	{ ext => '^', name => '#V^', qual => '', root => 'V', root_canon => 'V', root_mod => 1, root_ord => 8, system => 'roman' }
#v^	{ ext => '^', name => '#v^', qual => '-', root => 'v', root_canon => 'v', root_mod => 1, root_ord => 8, system => 'roman' }
#Vh	{ ext => 'h', name => '#Vh', qual => '', root => 'V', root_canon => 'V', root_mod => 1, root_ord => 8, system => 'roman' }
#vh	{ ext => 'h', name => '#vh', qual => '-', root => 'v', root_canon => 'v', root_mod => 1, root_ord => 8, system => 'roman' }
#Vh7	{ ext => 'h7', name => '#Vh7', qual => '', root => 'V', root_canon => 'V', root_mod => 1, root_ord => 8, system => 'roman' }
#vh7	{ ext => 'h7', name => '#vh7', qual => '-', root => 'v', root_canon => 'v', root_mod => 1, root_ord => 8, system => 'roman' }
#V^7	{ ext => '^7', name => '#V^7', qual => '', root => 'V', root_canon => 'V', root_mod => 1, root_ord => 8, system => 'roman' }
#v^7	{ ext => '^7', name => '#v^7', qual => '-', root => 'v', root_canon => 'v', root_mod => 1, root_ord => 8, system => 'roman' }
#V0	{ ext => '', name => '#V0', qual => 0, root => 'V', root_canon => 'V', root_mod => 1, root_ord => 8, system => 'roman' }
#v0	{ ext => '', name => '#v0', qual => '-', root => 'v', root_canon => 'v', root_mod => 1, root_ord => 8, system => 'roman' }
#V07	{ ext => 7, name => '#V07', qual => 0, root => 'V', root_canon => 'V', root_mod => 1, root_ord => 8, system => 'roman' }
#v07	{ ext => 7, name => '#v07', qual => '-', root => 'v', root_canon => 'v', root_mod => 1, root_ord => 8, system => 'roman' }
#V0^	{ ext => '^', name => '#V0^', qual => 0, root => 'V', root_canon => 'V', root_mod => 1, root_ord => 8, system => 'roman' }
#v0^	{ ext => '^', name => '#v0^', qual => '-', root => 'v', root_canon => 'v', root_mod => 1, root_ord => 8, system => 'roman' }
#V0h	{ ext => 'h', name => '#V0h', qual => 0, root => 'V', root_canon => 'V', root_mod => 1, root_ord => 8, system => 'roman' }
#v0h	{ ext => 'h', name => '#v0h', qual => '-', root => 'v', root_canon => 'v', root_mod => 1, root_ord => 8, system => 'roman' }
#V0h7	{ ext => 'h7', name => '#V0h7', qual => 0, root => 'V', root_canon => 'V', root_mod => 1, root_ord => 8, system => 'roman' }
#v0h7	{ ext => 'h7', name => '#v0h7', qual => '-', root => 'v', root_canon => 'v', root_mod => 1, root_ord => 8, system => 'roman' }
#V0^7	{ ext => '^7', name => '#V0^7', qual => 0, root => 'V', root_canon => 'V', root_mod => 1, root_ord => 8, system => 'roman' }
#v0^7	{ ext => '^7', name => '#v0^7', qual => '-', root => 'v', root_canon => 'v', root_mod => 1, root_ord => 8, system => 'roman' }
#V+	{ ext => '', name => '#V+', qual => '+', root => 'V', root_canon => 'V', root_mod => 1, root_ord => 8, system => 'roman' }
#v+	{ ext => '', name => '#v+', qual => '-', root => 'v', root_canon => 'v', root_mod => 1, root_ord => 8, system => 'roman' }
#V+7	{ ext => 7, name => '#V+7', qual => '+', root => 'V', root_canon => 'V', root_mod => 1, root_ord => 8, system => 'roman' }
#v+7	{ ext => 7, name => '#v+7', qual => '-', root => 'v', root_canon => 'v', root_mod => 1, root_ord => 8, system => 'roman' }
#V+^	{ ext => '^', name => '#V+^', qual => '+', root => 'V', root_canon => 'V', root_mod => 1, root_ord => 8, system => 'roman' }
#v+^	{ ext => '^', name => '#v+^', qual => '-', root => 'v', root_canon => 'v', root_mod => 1, root_ord => 8, system => 'roman' }
#V+h	{ ext => 'h', name => '#V+h', qual => '+', root => 'V', root_canon => 'V', root_mod => 1, root_ord => 8, system => 'roman' }
#v+h	{ ext => 'h', name => '#v+h', qual => '-', root => 'v', root_canon => 'v', root_mod => 1, root_ord => 8, system => 'roman' }
#V+h7	{ ext => 'h7', name => '#V+h7', qual => '+', root => 'V', root_canon => 'V', root_mod => 1, root_ord => 8, system => 'roman' }
#v+h7	{ ext => 'h7', name => '#v+h7', qual => '-', root => 'v', root_canon => 'v', root_mod => 1, root_ord => 8, system => 'roman' }
#V+^7	{ ext => '^7', name => '#V+^7', qual => '+', root => 'V', root_canon => 'V', root_mod => 1, root_ord => 8, system => 'roman' }
#v+^7	{ ext => '^7', name => '#v+^7', qual => '-', root => 'v', root_canon => 'v', root_mod => 1, root_ord => 8, system => 'roman' }
bVI	{ ext => '', name => 'bVI', qual => '', root => 'VI', root_canon => 'VI', root_mod => -1, root_ord => 8, system => 'roman' }
bvi	{ ext => '', name => 'bvi', qual => '-', root => 'vi', root_canon => 'vi', root_mod => -1, root_ord => 8, system => 'roman' }
bVI7	{ ext => 7, name => 'bVI7', qual => '', root => 'VI', root_canon => 'VI', root_mod => -1, root_ord => 8, system => 'roman' }
bvi7	{ ext => 7, name => 'bvi7', qual => '-', root => 'vi', root_canon => 'vi', root_mod => -1, root_ord => 8, system => 'roman' }
bVI^	{ ext => '^', name => 'bVI^', qual => '', root => 'VI', root_canon => 'VI', root_mod => -1, root_ord => 8, system => 'roman' }
bvi^	{ ext => '^', name => 'bvi^', qual => '-', root => 'vi', root_canon => 'vi', root_mod => -1, root_ord => 8, system => 'roman' }
bVIh	{ ext => 'h', name => 'bVIh', qual => '', root => 'VI', root_canon => 'VI', root_mod => -1, root_ord => 8, system => 'roman' }
bvih	{ ext => 'h', name => 'bvih', qual => '-', root => 'vi', root_canon => 'vi', root_mod => -1, root_ord => 8, system => 'roman' }
bVIh7	{ ext => 'h7', name => 'bVIh7', qual => '', root => 'VI', root_canon => 'VI', root_mod => -1, root_ord => 8, system => 'roman' }
bvih7	{ ext => 'h7', name => 'bvih7', qual => '-', root => 'vi', root_canon => 'vi', root_mod => -1, root_ord => 8, system => 'roman' }
bVI^7	{ ext => '^7', name => 'bVI^7', qual => '', root => 'VI', root_canon => 'VI', root_mod => -1, root_ord => 8, system => 'roman' }
bvi^7	{ ext => '^7', name => 'bvi^7', qual => '-', root => 'vi', root_canon => 'vi', root_mod => -1, root_ord => 8, system => 'roman' }
bVI0	{ ext => '', name => 'bVI0', qual => 0, root => 'VI', root_canon => 'VI', root_mod => -1, root_ord => 8, system => 'roman' }
bvi0	{ ext => '', name => 'bvi0', qual => '-', root => 'vi', root_canon => 'vi', root_mod => -1, root_ord => 8, system => 'roman' }
bVI07	{ ext => 7, name => 'bVI07', qual => 0, root => 'VI', root_canon => 'VI', root_mod => -1, root_ord => 8, system => 'roman' }
bvi07	{ ext => 7, name => 'bvi07', qual => '-', root => 'vi', root_canon => 'vi', root_mod => -1, root_ord => 8, system => 'roman' }
bVI0^	{ ext => '^', name => 'bVI0^', qual => 0, root => 'VI', root_canon => 'VI', root_mod => -1, root_ord => 8, system => 'roman' }
bvi0^	{ ext => '^', name => 'bvi0^', qual => '-', root => 'vi', root_canon => 'vi', root_mod => -1, root_ord => 8, system => 'roman' }
bVI0h	{ ext => 'h', name => 'bVI0h', qual => 0, root => 'VI', root_canon => 'VI', root_mod => -1, root_ord => 8, system => 'roman' }
bvi0h	{ ext => 'h', name => 'bvi0h', qual => '-', root => 'vi', root_canon => 'vi', root_mod => -1, root_ord => 8, system => 'roman' }
bVI0h7	{ ext => 'h7', name => 'bVI0h7', qual => 0, root => 'VI', root_canon => 'VI', root_mod => -1, root_ord => 8, system => 'roman' }
bvi0h7	{ ext => 'h7', name => 'bvi0h7', qual => '-', root => 'vi', root_canon => 'vi', root_mod => -1, root_ord => 8, system => 'roman' }
bVI0^7	{ ext => '^7', name => 'bVI0^7', qual => 0, root => 'VI', root_canon => 'VI', root_mod => -1, root_ord => 8, system => 'roman' }
bvi0^7	{ ext => '^7', name => 'bvi0^7', qual => '-', root => 'vi', root_canon => 'vi', root_mod => -1, root_ord => 8, system => 'roman' }
bVI+	{ ext => '', name => 'bVI+', qual => '+', root => 'VI', root_canon => 'VI', root_mod => -1, root_ord => 8, system => 'roman' }
bvi+	{ ext => '', name => 'bvi+', qual => '-', root => 'vi', root_canon => 'vi', root_mod => -1, root_ord => 8, system => 'roman' }
bVI+7	{ ext => 7, name => 'bVI+7', qual => '+', root => 'VI', root_canon => 'VI', root_mod => -1, root_ord => 8, system => 'roman' }
bvi+7	{ ext => 7, name => 'bvi+7', qual => '-', root => 'vi', root_canon => 'vi', root_mod => -1, root_ord => 8, system => 'roman' }
bVI+^	{ ext => '^', name => 'bVI+^', qual => '+', root => 'VI', root_canon => 'VI', root_mod => -1, root_ord => 8, system => 'roman' }
bvi+^	{ ext => '^', name => 'bvi+^', qual => '-', root => 'vi', root_canon => 'vi', root_mod => -1, root_ord => 8, system => 'roman' }
bVI+h	{ ext => 'h', name => 'bVI+h', qual => '+', root => 'VI', root_canon => 'VI', root_mod => -1, root_ord => 8, system => 'roman' }
bvi+h	{ ext => 'h', name => 'bvi+h', qual => '-', root => 'vi', root_canon => 'vi', root_mod => -1, root_ord => 8, system => 'roman' }
bVI+h7	{ ext => 'h7', name => 'bVI+h7', qual => '+', root => 'VI', root_canon => 'VI', root_mod => -1, root_ord => 8, system => 'roman' }
bvi+h7	{ ext => 'h7', name => 'bvi+h7', qual => '-', root => 'vi', root_canon => 'vi', root_mod => -1, root_ord => 8, system => 'roman' }
bVI+^7	{ ext => '^7', name => 'bVI+^7', qual => '+', root => 'VI', root_canon => 'VI', root_mod => -1, root_ord => 8, system => 'roman' }
bvi+^7	{ ext => '^7', name => 'bvi+^7', qual => '-', root => 'vi', root_canon => 'vi', root_mod => -1, root_ord => 8, system => 'roman' }
VI	{ ext => '', name => 'VI', qual => '', root => 'VI', root_canon => 'VI', root_ord => 9, system => 'roman' }
vi	{ ext => '', name => 'vi', qual => '-', root => 'vi', root_canon => 'vi', root_ord => 9, system => 'roman' }
VI7	{ ext => 7, name => 'VI7', qual => '', root => 'VI', root_canon => 'VI', root_ord => 9, system => 'roman' }
vi7	{ ext => 7, name => 'vi7', qual => '-', root => 'vi', root_canon => 'vi', root_ord => 9, system => 'roman' }
VI^	{ ext => '^', name => 'VI^', qual => '', root => 'VI', root_canon => 'VI', root_ord => 9, system => 'roman' }
vi^	{ ext => '^', name => 'vi^', qual => '-', root => 'vi', root_canon => 'vi', root_ord => 9, system => 'roman' }
VIh	{ ext => 'h', name => 'VIh', qual => '', root => 'VI', root_canon => 'VI', root_ord => 9, system => 'roman' }
vih	{ ext => 'h', name => 'vih', qual => '-', root => 'vi', root_canon => 'vi', root_ord => 9, system => 'roman' }
VIh7	{ ext => 'h7', name => 'VIh7', qual => '', root => 'VI', root_canon => 'VI', root_ord => 9, system => 'roman' }
vih7	{ ext => 'h7', name => 'vih7', qual => '-', root => 'vi', root_canon => 'vi', root_ord => 9, system => 'roman' }
VI^7	{ ext => '^7', name => 'VI^7', qual => '', root => 'VI', root_canon => 'VI', root_ord => 9, system => 'roman' }
vi^7	{ ext => '^7', name => 'vi^7', qual => '-', root => 'vi', root_canon => 'vi', root_ord => 9, system => 'roman' }
VI0	{ ext => '', name => 'VI0', qual => 0, root => 'VI', root_canon => 'VI', root_ord => 9, system => 'roman' }
vi0	{ ext => '', name => 'vi0', qual => '-', root => 'vi', root_canon => 'vi', root_ord => 9, system => 'roman' }
VI07	{ ext => 7, name => 'VI07', qual => 0, root => 'VI', root_canon => 'VI', root_ord => 9, system => 'roman' }
vi07	{ ext => 7, name => 'vi07', qual => '-', root => 'vi', root_canon => 'vi', root_ord => 9, system => 'roman' }
VI0^	{ ext => '^', name => 'VI0^', qual => 0, root => 'VI', root_canon => 'VI', root_ord => 9, system => 'roman' }
vi0^	{ ext => '^', name => 'vi0^', qual => '-', root => 'vi', root_canon => 'vi', root_ord => 9, system => 'roman' }
VI0h	{ ext => 'h', name => 'VI0h', qual => 0, root => 'VI', root_canon => 'VI', root_ord => 9, system => 'roman' }
vi0h	{ ext => 'h', name => 'vi0h', qual => '-', root => 'vi', root_canon => 'vi', root_ord => 9, system => 'roman' }
VI0h7	{ ext => 'h7', name => 'VI0h7', qual => 0, root => 'VI', root_canon => 'VI', root_ord => 9, system => 'roman' }
vi0h7	{ ext => 'h7', name => 'vi0h7', qual => '-', root => 'vi', root_canon => 'vi', root_ord => 9, system => 'roman' }
VI0^7	{ ext => '^7', name => 'VI0^7', qual => 0, root => 'VI', root_canon => 'VI', root_ord => 9, system => 'roman' }
vi0^7	{ ext => '^7', name => 'vi0^7', qual => '-', root => 'vi', root_canon => 'vi', root_ord => 9, system => 'roman' }
VI+	{ ext => '', name => 'VI+', qual => '+', root => 'VI', root_canon => 'VI', root_ord => 9, system => 'roman' }
vi+	{ ext => '', name => 'vi+', qual => '-', root => 'vi', root_canon => 'vi', root_ord => 9, system => 'roman' }
VI+7	{ ext => 7, name => 'VI+7', qual => '+', root => 'VI', root_canon => 'VI', root_ord => 9, system => 'roman' }
vi+7	{ ext => 7, name => 'vi+7', qual => '-', root => 'vi', root_canon => 'vi', root_ord => 9, system => 'roman' }
VI+^	{ ext => '^', name => 'VI+^', qual => '+', root => 'VI', root_canon => 'VI', root_ord => 9, system => 'roman' }
vi+^	{ ext => '^', name => 'vi+^', qual => '-', root => 'vi', root_canon => 'vi', root_ord => 9, system => 'roman' }
VI+h	{ ext => 'h', name => 'VI+h', qual => '+', root => 'VI', root_canon => 'VI', root_ord => 9, system => 'roman' }
vi+h	{ ext => 'h', name => 'vi+h', qual => '-', root => 'vi', root_canon => 'vi', root_ord => 9, system => 'roman' }
VI+h7	{ ext => 'h7', name => 'VI+h7', qual => '+', root => 'VI', root_canon => 'VI', root_ord => 9, system => 'roman' }
vi+h7	{ ext => 'h7', name => 'vi+h7', qual => '-', root => 'vi', root_canon => 'vi', root_ord => 9, system => 'roman' }
VI+^7	{ ext => '^7', name => 'VI+^7', qual => '+', root => 'VI', root_canon => 'VI', root_ord => 9, system => 'roman' }
vi+^7	{ ext => '^7', name => 'vi+^7', qual => '-', root => 'vi', root_canon => 'vi', root_ord => 9, system => 'roman' }
#VI	{ ext => '', name => '#VI', qual => '', root => 'VI', root_canon => 'VI', root_mod => 1, root_ord => 10, system => 'roman' }
#vi	{ ext => '', name => '#vi', qual => '-', root => 'vi', root_canon => 'vi', root_mod => 1, root_ord => 10, system => 'roman' }
#VI7	{ ext => 7, name => '#VI7', qual => '', root => 'VI', root_canon => 'VI', root_mod => 1, root_ord => 10, system => 'roman' }
#vi7	{ ext => 7, name => '#vi7', qual => '-', root => 'vi', root_canon => 'vi', root_mod => 1, root_ord => 10, system => 'roman' }
#VI^	{ ext => '^', name => '#VI^', qual => '', root => 'VI', root_canon => 'VI', root_mod => 1, root_ord => 10, system => 'roman' }
#vi^	{ ext => '^', name => '#vi^', qual => '-', root => 'vi', root_canon => 'vi', root_mod => 1, root_ord => 10, system => 'roman' }
#VIh	{ ext => 'h', name => '#VIh', qual => '', root => 'VI', root_canon => 'VI', root_mod => 1, root_ord => 10, system => 'roman' }
#vih	{ ext => 'h', name => '#vih', qual => '-', root => 'vi', root_canon => 'vi', root_mod => 1, root_ord => 10, system => 'roman' }
#VIh7	{ ext => 'h7', name => '#VIh7', qual => '', root => 'VI', root_canon => 'VI', root_mod => 1, root_ord => 10, system => 'roman' }
#vih7	{ ext => 'h7', name => '#vih7', qual => '-', root => 'vi', root_canon => 'vi', root_mod => 1, root_ord => 10, system => 'roman' }
#VI^7	{ ext => '^7', name => '#VI^7', qual => '', root => 'VI', root_canon => 'VI', root_mod => 1, root_ord => 10, system => 'roman' }
#vi^7	{ ext => '^7', name => '#vi^7', qual => '-', root => 'vi', root_canon => 'vi', root_mod => 1, root_ord => 10, system => 'roman' }
#VI0	{ ext => '', name => '#VI0', qual => 0, root => 'VI', root_canon => 'VI', root_mod => 1, root_ord => 10, system => 'roman' }
#vi0	{ ext => '', name => '#vi0', qual => '-', root => 'vi', root_canon => 'vi', root_mod => 1, root_ord => 10, system => 'roman' }
#VI07	{ ext => 7, name => '#VI07', qual => 0, root => 'VI', root_canon => 'VI', root_mod => 1, root_ord => 10, system => 'roman' }
#vi07	{ ext => 7, name => '#vi07', qual => '-', root => 'vi', root_canon => 'vi', root_mod => 1, root_ord => 10, system => 'roman' }
#VI0^	{ ext => '^', name => '#VI0^', qual => 0, root => 'VI', root_canon => 'VI', root_mod => 1, root_ord => 10, system => 'roman' }
#vi0^	{ ext => '^', name => '#vi0^', qual => '-', root => 'vi', root_canon => 'vi', root_mod => 1, root_ord => 10, system => 'roman' }
#VI0h	{ ext => 'h', name => '#VI0h', qual => 0, root => 'VI', root_canon => 'VI', root_mod => 1, root_ord => 10, system => 'roman' }
#vi0h	{ ext => 'h', name => '#vi0h', qual => '-', root => 'vi', root_canon => 'vi', root_mod => 1, root_ord => 10, system => 'roman' }
#VI0h7	{ ext => 'h7', name => '#VI0h7', qual => 0, root => 'VI', root_canon => 'VI', root_mod => 1, root_ord => 10, system => 'roman' }
#vi0h7	{ ext => 'h7', name => '#vi0h7', qual => '-', root => 'vi', root_canon => 'vi', root_mod => 1, root_ord => 10, system => 'roman' }
#VI0^7	{ ext => '^7', name => '#VI0^7', qual => 0, root => 'VI', root_canon => 'VI', root_mod => 1, root_ord => 10, system => 'roman' }
#vi0^7	{ ext => '^7', name => '#vi0^7', qual => '-', root => 'vi', root_canon => 'vi', root_mod => 1, root_ord => 10, system => 'roman' }
#VI+	{ ext => '', name => '#VI+', qual => '+', root => 'VI', root_canon => 'VI', root_mod => 1, root_ord => 10, system => 'roman' }
#vi+	{ ext => '', name => '#vi+', qual => '-', root => 'vi', root_canon => 'vi', root_mod => 1, root_ord => 10, system => 'roman' }
#VI+7	{ ext => 7, name => '#VI+7', qual => '+', root => 'VI', root_canon => 'VI', root_mod => 1, root_ord => 10, system => 'roman' }
#vi+7	{ ext => 7, name => '#vi+7', qual => '-', root => 'vi', root_canon => 'vi', root_mod => 1, root_ord => 10, system => 'roman' }
#VI+^	{ ext => '^', name => '#VI+^', qual => '+', root => 'VI', root_canon => 'VI', root_mod => 1, root_ord => 10, system => 'roman' }
#vi+^	{ ext => '^', name => '#vi+^', qual => '-', root => 'vi', root_canon => 'vi', root_mod => 1, root_ord => 10, system => 'roman' }
#VI+h	{ ext => 'h', name => '#VI+h', qual => '+', root => 'VI', root_canon => 'VI', root_mod => 1, root_ord => 10, system => 'roman' }
#vi+h	{ ext => 'h', name => '#vi+h', qual => '-', root => 'vi', root_canon => 'vi', root_mod => 1, root_ord => 10, system => 'roman' }
#VI+h7	{ ext => 'h7', name => '#VI+h7', qual => '+', root => 'VI', root_canon => 'VI', root_mod => 1, root_ord => 10, system => 'roman' }
#vi+h7	{ ext => 'h7', name => '#vi+h7', qual => '-', root => 'vi', root_canon => 'vi', root_mod => 1, root_ord => 10, system => 'roman' }
#VI+^7	{ ext => '^7', name => '#VI+^7', qual => '+', root => 'VI', root_canon => 'VI', root_mod => 1, root_ord => 10, system => 'roman' }
#vi+^7	{ ext => '^7', name => '#vi+^7', qual => '-', root => 'vi', root_canon => 'vi', root_mod => 1, root_ord => 10, system => 'roman' }
bVII	{ ext => '', name => 'bVII', qual => '', root => 'VII', root_canon => 'VII', root_mod => -1, root_ord => 10, system => 'roman' }
bvii	{ ext => '', name => 'bvii', qual => '-', root => 'vii', root_canon => 'vii', root_mod => -1, root_ord => 10, system => 'roman' }
bVII7	{ ext => 7, name => 'bVII7', qual => '', root => 'VII', root_canon => 'VII', root_mod => -1, root_ord => 10, system => 'roman' }
bvii7	{ ext => 7, name => 'bvii7', qual => '-', root => 'vii', root_canon => 'vii', root_mod => -1, root_ord => 10, system => 'roman' }
bVII^	{ ext => '^', name => 'bVII^', qual => '', root => 'VII', root_canon => 'VII', root_mod => -1, root_ord => 10, system => 'roman' }
bvii^	{ ext => '^', name => 'bvii^', qual => '-', root => 'vii', root_canon => 'vii', root_mod => -1, root_ord => 10, system => 'roman' }
bVIIh	{ ext => 'h', name => 'bVIIh', qual => '', root => 'VII', root_canon => 'VII', root_mod => -1, root_ord => 10, system => 'roman' }
bviih	{ ext => 'h', name => 'bviih', qual => '-', root => 'vii', root_canon => 'vii', root_mod => -1, root_ord => 10, system => 'roman' }
bVIIh7	{ ext => 'h7', name => 'bVIIh7', qual => '', root => 'VII', root_canon => 'VII', root_mod => -1, root_ord => 10, system => 'roman' }
bviih7	{ ext => 'h7', name => 'bviih7', qual => '-', root => 'vii', root_canon => 'vii', root_mod => -1, root_ord => 10, system => 'roman' }
bVII^7	{ ext => '^7', name => 'bVII^7', qual => '', root => 'VII', root_canon => 'VII', root_mod => -1, root_ord => 10, system => 'roman' }
bvii^7	{ ext => '^7', name => 'bvii^7', qual => '-', root => 'vii', root_canon => 'vii', root_mod => -1, root_ord => 10, system => 'roman' }
bVII0	{ ext => '', name => 'bVII0', qual => 0, root => 'VII', root_canon => 'VII', root_mod => -1, root_ord => 10, system => 'roman' }
bvii0	{ ext => '', name => 'bvii0', qual => '-', root => 'vii', root_canon => 'vii', root_mod => -1, root_ord => 10, system => 'roman' }
bVII07	{ ext => 7, name => 'bVII07', qual => 0, root => 'VII', root_canon => 'VII', root_mod => -1, root_ord => 10, system => 'roman' }
bvii07	{ ext => 7, name => 'bvii07', qual => '-', root => 'vii', root_canon => 'vii', root_mod => -1, root_ord => 10, system => 'roman' }
bVII0^	{ ext => '^', name => 'bVII0^', qual => 0, root => 'VII', root_canon => 'VII', root_mod => -1, root_ord => 10, system => 'roman' }
bvii0^	{ ext => '^', name => 'bvii0^', qual => '-', root => 'vii', root_canon => 'vii', root_mod => -1, root_ord => 10, system => 'roman' }
bVII0h	{ ext => 'h', name => 'bVII0h', qual => 0, root => 'VII', root_canon => 'VII', root_mod => -1, root_ord => 10, system => 'roman' }
bvii0h	{ ext => 'h', name => 'bvii0h', qual => '-', root => 'vii', root_canon => 'vii', root_mod => -1, root_ord => 10, system => 'roman' }
bVII0h7	{ ext => 'h7', name => 'bVII0h7', qual => 0, root => 'VII', root_canon => 'VII', root_mod => -1, root_ord => 10, system => 'roman' }
bvii0h7	{ ext => 'h7', name => 'bvii0h7', qual => '-', root => 'vii', root_canon => 'vii', root_mod => -1, root_ord => 10, system => 'roman' }
bVII0^7	{ ext => '^7', name => 'bVII0^7', qual => 0, root => 'VII', root_canon => 'VII', root_mod => -1, root_ord => 10, system => 'roman' }
bvii0^7	{ ext => '^7', name => 'bvii0^7', qual => '-', root => 'vii', root_canon => 'vii', root_mod => -1, root_ord => 10, system => 'roman' }
bVII+	{ ext => '', name => 'bVII+', qual => '+', root => 'VII', root_canon => 'VII', root_mod => -1, root_ord => 10, system => 'roman' }
bvii+	{ ext => '', name => 'bvii+', qual => '-', root => 'vii', root_canon => 'vii', root_mod => -1, root_ord => 10, system => 'roman' }
bVII+7	{ ext => 7, name => 'bVII+7', qual => '+', root => 'VII', root_canon => 'VII', root_mod => -1, root_ord => 10, system => 'roman' }
bvii+7	{ ext => 7, name => 'bvii+7', qual => '-', root => 'vii', root_canon => 'vii', root_mod => -1, root_ord => 10, system => 'roman' }
bVII+^	{ ext => '^', name => 'bVII+^', qual => '+', root => 'VII', root_canon => 'VII', root_mod => -1, root_ord => 10, system => 'roman' }
bvii+^	{ ext => '^', name => 'bvii+^', qual => '-', root => 'vii', root_canon => 'vii', root_mod => -1, root_ord => 10, system => 'roman' }
bVII+h	{ ext => 'h', name => 'bVII+h', qual => '+', root => 'VII', root_canon => 'VII', root_mod => -1, root_ord => 10, system => 'roman' }
bvii+h	{ ext => 'h', name => 'bvii+h', qual => '-', root => 'vii', root_canon => 'vii', root_mod => -1, root_ord => 10, system => 'roman' }
bVII+h7	{ ext => 'h7', name => 'bVII+h7', qual => '+', root => 'VII', root_canon => 'VII', root_mod => -1, root_ord => 10, system => 'roman' }
bvii+h7	{ ext => 'h7', name => 'bvii+h7', qual => '-', root => 'vii', root_canon => 'vii', root_mod => -1, root_ord => 10, system => 'roman' }
bVII+^7	{ ext => '^7', name => 'bVII+^7', qual => '+', root => 'VII', root_canon => 'VII', root_mod => -1, root_ord => 10, system => 'roman' }
bvii+^7	{ ext => '^7', name => 'bvii+^7', qual => '-', root => 'vii', root_canon => 'vii', root_mod => -1, root_ord => 10, system => 'roman' }
VII	{ ext => '', name => 'VII', qual => '', root => 'VII', root_canon => 'VII', root_ord => 11, system => 'roman' }
vii	{ ext => '', name => 'vii', qual => '-', root => 'vii', root_canon => 'vii', root_ord => 11, system => 'roman' }
VII7	{ ext => 7, name => 'VII7', qual => '', root => 'VII', root_canon => 'VII', root_ord => 11, system => 'roman' }
vii7	{ ext => 7, name => 'vii7', qual => '-', root => 'vii', root_canon => 'vii', root_ord => 11, system => 'roman' }
VII^	{ ext => '^', name => 'VII^', qual => '', root => 'VII', root_canon => 'VII', root_ord => 11, system => 'roman' }
vii^	{ ext => '^', name => 'vii^', qual => '-', root => 'vii', root_canon => 'vii', root_ord => 11, system => 'roman' }
VIIh	{ ext => 'h', name => 'VIIh', qual => '', root => 'VII', root_canon => 'VII', root_ord => 11, system => 'roman' }
viih	{ ext => 'h', name => 'viih', qual => '-', root => 'vii', root_canon => 'vii', root_ord => 11, system => 'roman' }
VIIh7	{ ext => 'h7', name => 'VIIh7', qual => '', root => 'VII', root_canon => 'VII', root_ord => 11, system => 'roman' }
viih7	{ ext => 'h7', name => 'viih7', qual => '-', root => 'vii', root_canon => 'vii', root_ord => 11, system => 'roman' }
VII^7	{ ext => '^7', name => 'VII^7', qual => '', root => 'VII', root_canon => 'VII', root_ord => 11, system => 'roman' }
vii^7	{ ext => '^7', name => 'vii^7', qual => '-', root => 'vii', root_canon => 'vii', root_ord => 11, system => 'roman' }
VII0	{ ext => '', name => 'VII0', qual => 0, root => 'VII', root_canon => 'VII', root_ord => 11, system => 'roman' }
vii0	{ ext => '', name => 'vii0', qual => '-', root => 'vii', root_canon => 'vii', root_ord => 11, system => 'roman' }
VII07	{ ext => 7, name => 'VII07', qual => 0, root => 'VII', root_canon => 'VII', root_ord => 11, system => 'roman' }
vii07	{ ext => 7, name => 'vii07', qual => '-', root => 'vii', root_canon => 'vii', root_ord => 11, system => 'roman' }
VII0^	{ ext => '^', name => 'VII0^', qual => 0, root => 'VII', root_canon => 'VII', root_ord => 11, system => 'roman' }
vii0^	{ ext => '^', name => 'vii0^', qual => '-', root => 'vii', root_canon => 'vii', root_ord => 11, system => 'roman' }
VII0h	{ ext => 'h', name => 'VII0h', qual => 0, root => 'VII', root_canon => 'VII', root_ord => 11, system => 'roman' }
vii0h	{ ext => 'h', name => 'vii0h', qual => '-', root => 'vii', root_canon => 'vii', root_ord => 11, system => 'roman' }
VII0h7	{ ext => 'h7', name => 'VII0h7', qual => 0, root => 'VII', root_canon => 'VII', root_ord => 11, system => 'roman' }
vii0h7	{ ext => 'h7', name => 'vii0h7', qual => '-', root => 'vii', root_canon => 'vii', root_ord => 11, system => 'roman' }
VII0^7	{ ext => '^7', name => 'VII0^7', qual => 0, root => 'VII', root_canon => 'VII', root_ord => 11, system => 'roman' }
vii0^7	{ ext => '^7', name => 'vii0^7', qual => '-', root => 'vii', root_canon => 'vii', root_ord => 11, system => 'roman' }
VII+	{ ext => '', name => 'VII+', qual => '+', root => 'VII', root_canon => 'VII', root_ord => 11, system => 'roman' }
vii+	{ ext => '', name => 'vii+', qual => '-', root => 'vii', root_canon => 'vii', root_ord => 11, system => 'roman' }
VII+7	{ ext => 7, name => 'VII+7', qual => '+', root => 'VII', root_canon => 'VII', root_ord => 11, system => 'roman' }
vii+7	{ ext => 7, name => 'vii+7', qual => '-', root => 'vii', root_canon => 'vii', root_ord => 11, system => 'roman' }
VII+^	{ ext => '^', name => 'VII+^', qual => '+', root => 'VII', root_canon => 'VII', root_ord => 11, system => 'roman' }
vii+^	{ ext => '^', name => 'vii+^', qual => '-', root => 'vii', root_canon => 'vii', root_ord => 11, system => 'roman' }
VII+h	{ ext => 'h', name => 'VII+h', qual => '+', root => 'VII', root_canon => 'VII', root_ord => 11, system => 'roman' }
vii+h	{ ext => 'h', name => 'vii+h', qual => '-', root => 'vii', root_canon => 'vii', root_ord => 11, system => 'roman' }
VII+h7	{ ext => 'h7', name => 'VII+h7', qual => '+', root => 'VII', root_canon => 'VII', root_ord => 11, system => 'roman' }
vii+h7	{ ext => 'h7', name => 'vii+h7', qual => '-', root => 'vii', root_canon => 'vii', root_ord => 11, system => 'roman' }
VII+^7	{ ext => '^7', name => 'VII+^7', qual => '+', root => 'VII', root_canon => 'VII', root_ord => 11, system => 'roman' }
vii+^7	{ ext => '^7', name => 'vii+^7', qual => '-', root => 'vii', root_canon => 'vii', root_ord => 11, system => 'roman' }
