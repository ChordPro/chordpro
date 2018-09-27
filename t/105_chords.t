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
	$res = {%$res};
	delete($res->{system});
	delete($res->{parser});
	delete($res->{qual_orig});
	delete($res->{ext_orig});
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
C/B	{ bass => 'B', bass_canon => 'B', bass_mod => 0, bass_ord => 11, ext => '', name => 'C/B', qual => '', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0 }
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
D/A	{ bass => 'A', bass_canon => 'A', bass_mod => 0, bass_ord => 9, ext => '', name => 'D/A', qual => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
D/B	{ bass => 'B', bass_canon => 'B', bass_mod => 0, bass_ord => 11, ext => '', name => 'D/B', qual => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
D/C	{ bass => 'C', bass_canon => 'C', bass_mod => 0, bass_ord => 0, ext => '', name => 'D/C', qual => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
D/C#	{ bass => 'C#', bass_canon => 'C#', bass_mod => 1, bass_ord => 1, ext => '', name => 'D/C#', qual => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
D/E	{ bass => 'E', bass_canon => 'E', bass_mod => 0, bass_ord => 4, ext => '', name => 'D/E', qual => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
D/G	{ bass => 'G', bass_canon => 'G', bass_mod => 0, bass_ord => 7, ext => '', name => 'D/G', qual => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
D5/E	{ bass => 'E', bass_canon => 'E', bass_mod => 0, bass_ord => 4, ext => 5, name => 'D5/E', qual => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
Dadd9	{ ext => 'add9', name => 'Dadd9', qual => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
D9add6	{ ext => '9add6', name => 'D9add6', qual => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
Dm7	{ ext => 7, name => 'Dm7', qual => '-', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
Dm#5	{ ext => '#5', name => 'Dm#5', qual => '-', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
Dm#7	{ ext => '#7', name => 'Dm#7', qual => '-', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
Dm/A	{ bass => 'A', bass_canon => 'A', bass_mod => 0, bass_ord => 9, ext => '', name => 'Dm/A', qual => '-', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
Dm/B	{ bass => 'B', bass_canon => 'B', bass_mod => 0, bass_ord => 11, ext => '', name => 'Dm/B', qual => '-', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
Dm/C	{ bass => 'C', bass_canon => 'C', bass_mod => 0, bass_ord => 0, ext => '', name => 'Dm/C', qual => '-', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
Dm/C#	{ bass => 'C#', bass_canon => 'C#', bass_mod => 1, bass_ord => 1, ext => '', name => 'Dm/C#', qual => '-', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2 }
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
Em/B	{ bass => 'B', bass_canon => 'B', bass_mod => 0, bass_ord => 11, ext => '', name => 'Em/B', qual => '-', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4 }
Em/D	{ bass => 'D', bass_canon => 'D', bass_mod => 0, bass_ord => 2, ext => '', name => 'Em/D', qual => '-', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4 }
Em7/D	{ bass => 'D', bass_canon => 'D', bass_mod => 0, bass_ord => 2, ext => 7, name => 'Em7/D', qual => '-', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4 }
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
F/A	{ bass => 'A', bass_canon => 'A', bass_mod => 0, bass_ord => 9, ext => '', name => 'F/A', qual => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5 }
F/C	{ bass => 'C', bass_canon => 'C', bass_mod => 0, bass_ord => 0, ext => '', name => 'F/C', qual => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5 }
F/D	{ bass => 'D', bass_canon => 'D', bass_mod => 0, bass_ord => 2, ext => '', name => 'F/D', qual => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5 }
F/G	{ bass => 'G', bass_canon => 'G', bass_mod => 0, bass_ord => 7, ext => '', name => 'F/G', qual => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5 }
F7/A	{ bass => 'A', bass_canon => 'A', bass_mod => 0, bass_ord => 9, ext => 7, name => 'F7/A', qual => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5 }
Fmaj7/A	{ bass => 'A', bass_canon => 'A', bass_mod => 0, bass_ord => 9, ext => 'maj7', name => 'Fmaj7/A', qual => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5 }
Fmaj7/C	{ bass => 'C', bass_canon => 'C', bass_mod => 0, bass_ord => 0, ext => 'maj7', name => 'Fmaj7/C', qual => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5 }
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
F#/E	{ bass => 'E', bass_canon => 'E', bass_mod => 0, bass_ord => 4, ext => '', name => 'F#/E', qual => '', root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6 }
F#4	{ ext => 4, name => 'F#4', qual => '', root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6 }
F#m6	{ ext => 6, name => 'F#m6', qual => '-', root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6 }
F#m7	{ ext => 7, name => 'F#m7', qual => '-', root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6 }
F#m7b5	{ ext => '7b5', name => 'F#m7b5', qual => '-', root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6 }
F#m/C	{ bass => 'C', bass_canon => 'C', bass_mod => 0, bass_ord => 0, ext => '', name => 'F#m/C', qual => '-', root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6 }
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
G/A	{ bass => 'A', bass_canon => 'A', bass_mod => 0, bass_ord => 9, ext => '', name => 'G/A', qual => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7 }
G/B	{ bass => 'B', bass_canon => 'B', bass_mod => 0, bass_ord => 11, ext => '', name => 'G/B', qual => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7 }
G/D	{ bass => 'D', bass_canon => 'D', bass_mod => 0, bass_ord => 2, ext => '', name => 'G/D', qual => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7 }
G/F#	{ bass => 'F#', bass_canon => 'F#', bass_mod => 1, bass_ord => 6, ext => '', name => 'G/F#', qual => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7 }
Gm6	{ ext => 6, name => 'Gm6', qual => '-', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7 }
Gm7	{ ext => 7, name => 'Gm7', qual => '-', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7 }
Gm/Bb	{ bass => 'Bb', bass_canon => 'Bb', bass_mod => -1, bass_ord => 10, ext => '', name => 'Gm/Bb', qual => '-', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7 }
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
A/C#	{ bass => 'C#', bass_canon => 'C#', bass_mod => 1, bass_ord => 1, ext => '', name => 'A/C#', qual => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
A/D	{ bass => 'D', bass_canon => 'D', bass_mod => 0, bass_ord => 2, ext => '', name => 'A/D', qual => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
A/E	{ bass => 'E', bass_canon => 'E', bass_mod => 0, bass_ord => 4, ext => '', name => 'A/E', qual => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
A/F#	{ bass => 'F#', bass_canon => 'F#', bass_mod => 1, bass_ord => 6, ext => '', name => 'A/F#', qual => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
A/G#	{ bass => 'G#', bass_canon => 'G#', bass_mod => 1, bass_ord => 8, ext => '', name => 'A/G#', qual => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
Am#7	{ ext => '#7', name => 'Am#7', qual => '-', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
Am6	{ ext => 6, name => 'Am6', qual => '-', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
Am7	{ ext => 7, name => 'Am7', qual => '-', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
Am7sus4	{ ext => '7sus4', name => 'Am7sus4', qual => '-', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
Am9	{ ext => 9, name => 'Am9', qual => '-', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
Am/G	{ bass => 'G', bass_canon => 'G', bass_mod => 0, bass_ord => 7, ext => '', name => 'Am/G', qual => '-', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9 }
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
B/F#	{ bass => 'F#', bass_canon => 'F#', bass_mod => 1, bass_ord => 6, ext => '', name => 'B/F#', qual => '', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11 }
Bm6	{ ext => 6, name => 'Bm6', qual => '-', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11 }
Bm7	{ ext => 7, name => 'Bm7', qual => '-', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11 }
Bmmaj7	{ ext => 'maj7', name => 'Bmmaj7', qual => '-', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11 }
Bmsus9	{ ext => 'sus9', name => 'Bmsus9', qual => '-', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11 }
Bm7b5	{ ext => '7b5', name => 'Bm7b5', qual => '-', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11 }
