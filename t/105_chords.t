#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Test::More;

use App::Packager ( ':name', 'App::Music::ChordPro' );
use App::Music::ChordPro::Config;
use App::Music::ChordPro::Chords;

my %tbl;

our $config =
  eval {
      App::Music::ChordPro::Config::configurator
	  ( { nosysconfig => 1, nolegacyconfig => 1, nouserconfig => 1,
	      config => getresource("notes/common.json") } );
  };

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
    print("$chord\t", reformat($res), "\n");
}

exit;

=cut

while ( <DATA> ) {
    chomp;
    my ( $chord, $info ) = split( /\t/, $_ );
    my $c = $chord;
    $c =~ s/[()]//g;
    $tbl{$c} = $info;
}

plan tests => 1 + keys(%tbl);

ok( $config, "got config" );

while ( my ( $c, $info ) = each %tbl ) {
    my $res = App::Music::ChordPro::Chords::parse_chord($c);
    $res //= "FAIL";
    if ( UNIVERSAL::isa( $res, 'HASH' ) ) {
        $res = reformat($res);
    }
    is( $res, $info, "parsing chord $c");
}

sub reformat {
    my ( $res ) = @_;
    $res = {%$res};
    delete($res->{parser});
    use Data::Dumper qw();
    local $Data::Dumper::Sortkeys  = 1;
    local $Data::Dumper::Indent    = 1;
    local $Data::Dumper::Quotekeys = 0;
    local $Data::Dumper::Deparse   = 1;
    local $Data::Dumper::Terse     = 1;
    local $Data::Dumper::Trailingcomma = 1;
    local $Data::Dumper::Useperl = 1;
    local $Data::Dumper::Useqq     = 0; # I want unicode visible
    my $s = Data::Dumper::Dumper($res);
    $s =~ s/\s+/ /gs;
    $s =~ s/, \}/ }/gs;
    $s =~ s/\s+$//;
    return $s;
}

__DATA__
C	{ ext => '', ext_canon => '', name => 'C', qual => '', qual_canon => '', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0, system => 'common' }
C+	{ ext => '', ext_canon => '', name => 'C+', qual => '+', qual_canon => '+', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0, system => 'common' }
C4	{ ext => 4, ext_canon => 4, name => 'C4', qual => '', qual_canon => '', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0, system => 'common' }
C6	{ ext => 6, ext_canon => 6, name => 'C6', qual => '', qual_canon => '', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0, system => 'common' }
C7	{ ext => 7, ext_canon => 7, name => 'C7', qual => '', qual_canon => '', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0, system => 'common' }
C9	{ ext => 9, ext_canon => 9, name => 'C9', qual => '', qual_canon => '', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0, system => 'common' }
C9(11)	{ ext => 911, ext_canon => 911, name => 'C911', qual => '', qual_canon => '', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0, system => 'common' }
C11	{ ext => 11, ext_canon => 11, name => 'C11', qual => '', qual_canon => '', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0, system => 'common' }
Csus	{ ext => 'sus', ext_canon => 'sus4', name => 'Csus', qual => '', qual_canon => '', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0, system => 'common' }
Csus2	{ ext => 'sus2', ext_canon => 'sus2', name => 'Csus2', qual => '', qual_canon => '', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0, system => 'common' }
Csus4	{ ext => 'sus4', ext_canon => 'sus4', name => 'Csus4', qual => '', qual_canon => '', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0, system => 'common' }
Csus9	{ ext => 'sus9', ext_canon => 'sus9', name => 'Csus9', qual => '', qual_canon => '', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0, system => 'common' }
Cmaj	{ ext => '', ext_canon => '', name => 'Cmaj', qual => '', qual_canon => '', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0, system => 'common' }
Cmaj7	{ ext => 'maj7', ext_canon => 'maj7', name => 'Cmaj7', qual => '', qual_canon => '', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0, system => 'common' }
Cm	{ ext => '', ext_canon => '', name => 'Cm', qual => 'm', qual_canon => '-', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0, system => 'common' }
Cmin	{ ext => '', ext_canon => '', name => 'Cmin', qual => 'min', qual_canon => '-', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0, system => 'common' }
Cdim	{ ext => '', ext_canon => '', name => 'Cdim', qual => 'dim', qual_canon => 0, root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0, system => 'common' }
C/B	{ bass => 'B', bass_canon => 'B', bass_mod => 0, bass_ord => 11, ext => '', ext_canon => '', name => 'C/B', qual => '', qual_canon => '', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0, system => 'common' }
Cadd9	{ ext => 'add9', ext_canon => 'add9', name => 'Cadd9', qual => '', qual_canon => '', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0, system => 'common' }
C3	{ ext => 3, ext_canon => 3, name => 'C3', qual => '', qual_canon => '', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0, system => 'common' }
Cm7	{ ext => 7, ext_canon => 7, name => 'Cm7', qual => 'm', qual_canon => '-', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0, system => 'common' }
Cm11	{ ext => 11, ext_canon => 11, name => 'Cm11', qual => 'm', qual_canon => '-', root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0, system => 'common' }
C#	{ ext => '', ext_canon => '', name => 'C#', qual => '', qual_canon => '', root => 'C#', root_canon => 'C#', root_mod => 1, root_ord => 1, system => 'common' }
C#+	{ ext => '', ext_canon => '', name => 'C#+', qual => '+', qual_canon => '+', root => 'C#', root_canon => 'C#', root_mod => 1, root_ord => 1, system => 'common' }
C#4	{ ext => 4, ext_canon => 4, name => 'C#4', qual => '', qual_canon => '', root => 'C#', root_canon => 'C#', root_mod => 1, root_ord => 1, system => 'common' }
C#7	{ ext => 7, ext_canon => 7, name => 'C#7', qual => '', qual_canon => '', root => 'C#', root_canon => 'C#', root_mod => 1, root_ord => 1, system => 'common' }
C#7(b5)	{ ext => '7b5', ext_canon => '7b5', name => 'C#7b5', qual => '', qual_canon => '', root => 'C#', root_canon => 'C#', root_mod => 1, root_ord => 1, system => 'common' }
C#sus	{ ext => 'sus', ext_canon => 'sus4', name => 'C#sus', qual => '', qual_canon => '', root => 'C#', root_canon => 'C#', root_mod => 1, root_ord => 1, system => 'common' }
C#sus4	{ ext => 'sus4', ext_canon => 'sus4', name => 'C#sus4', qual => '', qual_canon => '', root => 'C#', root_canon => 'C#', root_mod => 1, root_ord => 1, system => 'common' }
C#maj	{ ext => '', ext_canon => '', name => 'C#maj', qual => '', qual_canon => '', root => 'C#', root_canon => 'C#', root_mod => 1, root_ord => 1, system => 'common' }
C#maj7	{ ext => 'maj7', ext_canon => 'maj7', name => 'C#maj7', qual => '', qual_canon => '', root => 'C#', root_canon => 'C#', root_mod => 1, root_ord => 1, system => 'common' }
C#dim	{ ext => '', ext_canon => '', name => 'C#dim', qual => 'dim', qual_canon => 0, root => 'C#', root_canon => 'C#', root_mod => 1, root_ord => 1, system => 'common' }
C#m	{ ext => '', ext_canon => '', name => 'C#m', qual => 'm', qual_canon => '-', root => 'C#', root_canon => 'C#', root_mod => 1, root_ord => 1, system => 'common' }
C#min	{ ext => '', ext_canon => '', name => 'C#min', qual => 'min', qual_canon => '-', root => 'C#', root_canon => 'C#', root_mod => 1, root_ord => 1, system => 'common' }
C#add9	{ ext => 'add9', ext_canon => 'add9', name => 'C#add9', qual => '', qual_canon => '', root => 'C#', root_canon => 'C#', root_mod => 1, root_ord => 1, system => 'common' }
C#(add9)	{ ext => 'add9', ext_canon => 'add9', name => 'C#add9', qual => '', qual_canon => '', root => 'C#', root_canon => 'C#', root_mod => 1, root_ord => 1, system => 'common' }
C#m7	{ ext => 7, ext_canon => 7, name => 'C#m7', qual => 'm', qual_canon => '-', root => 'C#', root_canon => 'C#', root_mod => 1, root_ord => 1, system => 'common' }
Db	{ ext => '', ext_canon => '', name => 'Db', qual => '', qual_canon => '', root => 'Db', root_canon => 'Db', root_mod => -1, root_ord => 1, system => 'common' }
Db+	{ ext => '', ext_canon => '', name => 'Db+', qual => '+', qual_canon => '+', root => 'Db', root_canon => 'Db', root_mod => -1, root_ord => 1, system => 'common' }
Db7	{ ext => 7, ext_canon => 7, name => 'Db7', qual => '', qual_canon => '', root => 'Db', root_canon => 'Db', root_mod => -1, root_ord => 1, system => 'common' }
Dbsus	{ ext => 'sus', ext_canon => 'sus4', name => 'Dbsus', qual => '', qual_canon => '', root => 'Db', root_canon => 'Db', root_mod => -1, root_ord => 1, system => 'common' }
Dbsus4	{ ext => 'sus4', ext_canon => 'sus4', name => 'Dbsus4', qual => '', qual_canon => '', root => 'Db', root_canon => 'Db', root_mod => -1, root_ord => 1, system => 'common' }
Dbmaj	{ ext => '', ext_canon => '', name => 'Dbmaj', qual => '', qual_canon => '', root => 'Db', root_canon => 'Db', root_mod => -1, root_ord => 1, system => 'common' }
Dbmaj7	{ ext => 'maj7', ext_canon => 'maj7', name => 'Dbmaj7', qual => '', qual_canon => '', root => 'Db', root_canon => 'Db', root_mod => -1, root_ord => 1, system => 'common' }
Dbdim	{ ext => '', ext_canon => '', name => 'Dbdim', qual => 'dim', qual_canon => 0, root => 'Db', root_canon => 'Db', root_mod => -1, root_ord => 1, system => 'common' }
Dbm	{ ext => '', ext_canon => '', name => 'Dbm', qual => 'm', qual_canon => '-', root => 'Db', root_canon => 'Db', root_mod => -1, root_ord => 1, system => 'common' }
Dbmin	{ ext => '', ext_canon => '', name => 'Dbmin', qual => 'min', qual_canon => '-', root => 'Db', root_canon => 'Db', root_mod => -1, root_ord => 1, system => 'common' }
Dbm7	{ ext => 7, ext_canon => 7, name => 'Dbm7', qual => 'm', qual_canon => '-', root => 'Db', root_canon => 'Db', root_mod => -1, root_ord => 1, system => 'common' }
D	{ ext => '', ext_canon => '', name => 'D', qual => '', qual_canon => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2, system => 'common' }
D+	{ ext => '', ext_canon => '', name => 'D+', qual => '+', qual_canon => '+', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2, system => 'common' }
D4	{ ext => 4, ext_canon => 4, name => 'D4', qual => '', qual_canon => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2, system => 'common' }
D6	{ ext => 6, ext_canon => 6, name => 'D6', qual => '', qual_canon => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2, system => 'common' }
D7	{ ext => 7, ext_canon => 7, name => 'D7', qual => '', qual_canon => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2, system => 'common' }
D7#9	{ ext => '7#9', ext_canon => '7#9', name => 'D7#9', qual => '', qual_canon => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2, system => 'common' }
D7(#9)	{ ext => '7#9', ext_canon => '7#9', name => 'D7#9', qual => '', qual_canon => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2, system => 'common' }
D9	{ ext => 9, ext_canon => 9, name => 'D9', qual => '', qual_canon => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2, system => 'common' }
D11	{ ext => 11, ext_canon => 11, name => 'D11', qual => '', qual_canon => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2, system => 'common' }
Dsus	{ ext => 'sus', ext_canon => 'sus4', name => 'Dsus', qual => '', qual_canon => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2, system => 'common' }
Dsus2	{ ext => 'sus2', ext_canon => 'sus2', name => 'Dsus2', qual => '', qual_canon => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2, system => 'common' }
Dsus4	{ ext => 'sus4', ext_canon => 'sus4', name => 'Dsus4', qual => '', qual_canon => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2, system => 'common' }
D7sus2	{ ext => '7sus2', ext_canon => '7sus2', name => 'D7sus2', qual => '', qual_canon => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2, system => 'common' }
D7sus4	{ ext => '7sus4', ext_canon => '7sus4', name => 'D7sus4', qual => '', qual_canon => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2, system => 'common' }
Dmaj	{ ext => '', ext_canon => '', name => 'Dmaj', qual => '', qual_canon => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2, system => 'common' }
Dmaj7	{ ext => 'maj7', ext_canon => 'maj7', name => 'Dmaj7', qual => '', qual_canon => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2, system => 'common' }
Ddim	{ ext => '', ext_canon => '', name => 'Ddim', qual => 'dim', qual_canon => 0, root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2, system => 'common' }
Dm	{ ext => '', ext_canon => '', name => 'Dm', qual => 'm', qual_canon => '-', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2, system => 'common' }
Dmin	{ ext => '', ext_canon => '', name => 'Dmin', qual => 'min', qual_canon => '-', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2, system => 'common' }
D/A	{ bass => 'A', bass_canon => 'A', bass_mod => 0, bass_ord => 9, ext => '', ext_canon => '', name => 'D/A', qual => '', qual_canon => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2, system => 'common' }
D/B	{ bass => 'B', bass_canon => 'B', bass_mod => 0, bass_ord => 11, ext => '', ext_canon => '', name => 'D/B', qual => '', qual_canon => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2, system => 'common' }
D/C	{ bass => 'C', bass_canon => 'C', bass_mod => 0, bass_ord => 0, ext => '', ext_canon => '', name => 'D/C', qual => '', qual_canon => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2, system => 'common' }
D/C#	{ bass => 'C#', bass_canon => 'C#', bass_mod => 1, bass_ord => 1, ext => '', ext_canon => '', name => 'D/C#', qual => '', qual_canon => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2, system => 'common' }
D/E	{ bass => 'E', bass_canon => 'E', bass_mod => 0, bass_ord => 4, ext => '', ext_canon => '', name => 'D/E', qual => '', qual_canon => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2, system => 'common' }
D/G	{ bass => 'G', bass_canon => 'G', bass_mod => 0, bass_ord => 7, ext => '', ext_canon => '', name => 'D/G', qual => '', qual_canon => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2, system => 'common' }
D5/E	{ bass => 'E', bass_canon => 'E', bass_mod => 0, bass_ord => 4, ext => 5, ext_canon => 5, name => 'D5/E', qual => '', qual_canon => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2, system => 'common' }
Dadd9	{ ext => 'add9', ext_canon => 'add9', name => 'Dadd9', qual => '', qual_canon => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2, system => 'common' }
D9add6	{ ext => '9add6', ext_canon => '9add6', name => 'D9add6', qual => '', qual_canon => '', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2, system => 'common' }
Dm7	{ ext => 7, ext_canon => 7, name => 'Dm7', qual => 'm', qual_canon => '-', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2, system => 'common' }
Dm#5	{ ext => '#5', ext_canon => '#5', name => 'Dm#5', qual => 'm', qual_canon => '-', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2, system => 'common' }
Dm#7	{ ext => '#7', ext_canon => '#7', name => 'Dm#7', qual => 'm', qual_canon => '-', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2, system => 'common' }
Dm/A	{ bass => 'A', bass_canon => 'A', bass_mod => 0, bass_ord => 9, ext => '', ext_canon => '', name => 'Dm/A', qual => 'm', qual_canon => '-', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2, system => 'common' }
Dm/B	{ bass => 'B', bass_canon => 'B', bass_mod => 0, bass_ord => 11, ext => '', ext_canon => '', name => 'Dm/B', qual => 'm', qual_canon => '-', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2, system => 'common' }
Dm/C	{ bass => 'C', bass_canon => 'C', bass_mod => 0, bass_ord => 0, ext => '', ext_canon => '', name => 'Dm/C', qual => 'm', qual_canon => '-', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2, system => 'common' }
Dm/C#	{ bass => 'C#', bass_canon => 'C#', bass_mod => 1, bass_ord => 1, ext => '', ext_canon => '', name => 'Dm/C#', qual => 'm', qual_canon => '-', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2, system => 'common' }
Dm9	{ ext => 9, ext_canon => 9, name => 'Dm9', qual => 'm', qual_canon => '-', root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2, system => 'common' }
D#	{ ext => '', ext_canon => '', name => 'D#', qual => '', qual_canon => '', root => 'D#', root_canon => 'D#', root_mod => 1, root_ord => 3, system => 'common' }
D#+	{ ext => '', ext_canon => '', name => 'D#+', qual => '+', qual_canon => '+', root => 'D#', root_canon => 'D#', root_mod => 1, root_ord => 3, system => 'common' }
D#4	{ ext => 4, ext_canon => 4, name => 'D#4', qual => '', qual_canon => '', root => 'D#', root_canon => 'D#', root_mod => 1, root_ord => 3, system => 'common' }
D#7	{ ext => 7, ext_canon => 7, name => 'D#7', qual => '', qual_canon => '', root => 'D#', root_canon => 'D#', root_mod => 1, root_ord => 3, system => 'common' }
D#sus	{ ext => 'sus', ext_canon => 'sus4', name => 'D#sus', qual => '', qual_canon => '', root => 'D#', root_canon => 'D#', root_mod => 1, root_ord => 3, system => 'common' }
D#sus4	{ ext => 'sus4', ext_canon => 'sus4', name => 'D#sus4', qual => '', qual_canon => '', root => 'D#', root_canon => 'D#', root_mod => 1, root_ord => 3, system => 'common' }
D#maj	{ ext => '', ext_canon => '', name => 'D#maj', qual => '', qual_canon => '', root => 'D#', root_canon => 'D#', root_mod => 1, root_ord => 3, system => 'common' }
D#maj7	{ ext => 'maj7', ext_canon => 'maj7', name => 'D#maj7', qual => '', qual_canon => '', root => 'D#', root_canon => 'D#', root_mod => 1, root_ord => 3, system => 'common' }
D#dim	{ ext => '', ext_canon => '', name => 'D#dim', qual => 'dim', qual_canon => 0, root => 'D#', root_canon => 'D#', root_mod => 1, root_ord => 3, system => 'common' }
D#m	{ ext => '', ext_canon => '', name => 'D#m', qual => 'm', qual_canon => '-', root => 'D#', root_canon => 'D#', root_mod => 1, root_ord => 3, system => 'common' }
D#min	{ ext => '', ext_canon => '', name => 'D#min', qual => 'min', qual_canon => '-', root => 'D#', root_canon => 'D#', root_mod => 1, root_ord => 3, system => 'common' }
D#m7	{ ext => 7, ext_canon => 7, name => 'D#m7', qual => 'm', qual_canon => '-', root => 'D#', root_canon => 'D#', root_mod => 1, root_ord => 3, system => 'common' }
Eb	{ ext => '', ext_canon => '', name => 'Eb', qual => '', qual_canon => '', root => 'Eb', root_canon => 'Eb', root_mod => -1, root_ord => 3, system => 'common' }
Eb+	{ ext => '', ext_canon => '', name => 'Eb+', qual => '+', qual_canon => '+', root => 'Eb', root_canon => 'Eb', root_mod => -1, root_ord => 3, system => 'common' }
Eb4	{ ext => 4, ext_canon => 4, name => 'Eb4', qual => '', qual_canon => '', root => 'Eb', root_canon => 'Eb', root_mod => -1, root_ord => 3, system => 'common' }
Eb7	{ ext => 7, ext_canon => 7, name => 'Eb7', qual => '', qual_canon => '', root => 'Eb', root_canon => 'Eb', root_mod => -1, root_ord => 3, system => 'common' }
Ebsus	{ ext => 'sus', ext_canon => 'sus4', name => 'Ebsus', qual => '', qual_canon => '', root => 'Eb', root_canon => 'Eb', root_mod => -1, root_ord => 3, system => 'common' }
Ebsus4	{ ext => 'sus4', ext_canon => 'sus4', name => 'Ebsus4', qual => '', qual_canon => '', root => 'Eb', root_canon => 'Eb', root_mod => -1, root_ord => 3, system => 'common' }
Ebmaj	{ ext => '', ext_canon => '', name => 'Ebmaj', qual => '', qual_canon => '', root => 'Eb', root_canon => 'Eb', root_mod => -1, root_ord => 3, system => 'common' }
Ebmaj7	{ ext => 'maj7', ext_canon => 'maj7', name => 'Ebmaj7', qual => '', qual_canon => '', root => 'Eb', root_canon => 'Eb', root_mod => -1, root_ord => 3, system => 'common' }
Ebdim	{ ext => '', ext_canon => '', name => 'Ebdim', qual => 'dim', qual_canon => 0, root => 'Eb', root_canon => 'Eb', root_mod => -1, root_ord => 3, system => 'common' }
Ebadd9	{ ext => 'add9', ext_canon => 'add9', name => 'Ebadd9', qual => '', qual_canon => '', root => 'Eb', root_canon => 'Eb', root_mod => -1, root_ord => 3, system => 'common' }
Eb(add9)	{ ext => 'add9', ext_canon => 'add9', name => 'Ebadd9', qual => '', qual_canon => '', root => 'Eb', root_canon => 'Eb', root_mod => -1, root_ord => 3, system => 'common' }
Ebm	{ ext => '', ext_canon => '', name => 'Ebm', qual => 'm', qual_canon => '-', root => 'Eb', root_canon => 'Eb', root_mod => -1, root_ord => 3, system => 'common' }
Ebmin	{ ext => '', ext_canon => '', name => 'Ebmin', qual => 'min', qual_canon => '-', root => 'Eb', root_canon => 'Eb', root_mod => -1, root_ord => 3, system => 'common' }
Ebm7	{ ext => 7, ext_canon => 7, name => 'Ebm7', qual => 'm', qual_canon => '-', root => 'Eb', root_canon => 'Eb', root_mod => -1, root_ord => 3, system => 'common' }
E	{ ext => '', ext_canon => '', name => 'E', qual => '', qual_canon => '', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4, system => 'common' }
E+	{ ext => '', ext_canon => '', name => 'E+', qual => '+', qual_canon => '+', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4, system => 'common' }
E5	{ ext => 5, ext_canon => 5, name => 'E5', qual => '', qual_canon => '', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4, system => 'common' }
E6	{ ext => 6, ext_canon => 6, name => 'E6', qual => '', qual_canon => '', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4, system => 'common' }
E7	{ ext => 7, ext_canon => 7, name => 'E7', qual => '', qual_canon => '', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4, system => 'common' }
E7#9	{ ext => '7#9', ext_canon => '7#9', name => 'E7#9', qual => '', qual_canon => '', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4, system => 'common' }
E7(#9)	{ ext => '7#9', ext_canon => '7#9', name => 'E7#9', qual => '', qual_canon => '', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4, system => 'common' }
E7(b5)	{ ext => '7b5', ext_canon => '7b5', name => 'E7b5', qual => '', qual_canon => '', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4, system => 'common' }
E7b9	{ ext => '7b9', ext_canon => '7b9', name => 'E7b9', qual => '', qual_canon => '', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4, system => 'common' }
E7(11)	{ ext => 711, ext_canon => 711, name => 'E711', qual => '', qual_canon => '', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4, system => 'common' }
E9	{ ext => 9, ext_canon => 9, name => 'E9', qual => '', qual_canon => '', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4, system => 'common' }
E11	{ ext => 11, ext_canon => 11, name => 'E11', qual => '', qual_canon => '', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4, system => 'common' }
Esus	{ ext => 'sus', ext_canon => 'sus4', name => 'Esus', qual => '', qual_canon => '', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4, system => 'common' }
Emaj	{ ext => '', ext_canon => '', name => 'Emaj', qual => '', qual_canon => '', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4, system => 'common' }
Emaj7	{ ext => 'maj7', ext_canon => 'maj7', name => 'Emaj7', qual => '', qual_canon => '', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4, system => 'common' }
Edim	{ ext => '', ext_canon => '', name => 'Edim', qual => 'dim', qual_canon => 0, root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4, system => 'common' }
Em	{ ext => '', ext_canon => '', name => 'Em', qual => 'm', qual_canon => '-', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4, system => 'common' }
Emin	{ ext => '', ext_canon => '', name => 'Emin', qual => 'min', qual_canon => '-', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4, system => 'common' }
Em6	{ ext => 6, ext_canon => 6, name => 'Em6', qual => 'm', qual_canon => '-', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4, system => 'common' }
Em7	{ ext => 7, ext_canon => 7, name => 'Em7', qual => 'm', qual_canon => '-', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4, system => 'common' }
Em/B	{ bass => 'B', bass_canon => 'B', bass_mod => 0, bass_ord => 11, ext => '', ext_canon => '', name => 'Em/B', qual => 'm', qual_canon => '-', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4, system => 'common' }
Em/D	{ bass => 'D', bass_canon => 'D', bass_mod => 0, bass_ord => 2, ext => '', ext_canon => '', name => 'Em/D', qual => 'm', qual_canon => '-', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4, system => 'common' }
Em7/D	{ bass => 'D', bass_canon => 'D', bass_mod => 0, bass_ord => 2, ext => 7, ext_canon => 7, name => 'Em7/D', qual => 'm', qual_canon => '-', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4, system => 'common' }
Emsus4	{ ext => 'sus4', ext_canon => 'sus4', name => 'Emsus4', qual => 'm', qual_canon => '-', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4, system => 'common' }
Emadd9	{ ext => 'add9', ext_canon => 'add9', name => 'Emadd9', qual => 'm', qual_canon => '-', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4, system => 'common' }
F	{ ext => '', ext_canon => '', name => 'F', qual => '', qual_canon => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5, system => 'common' }
F+	{ ext => '', ext_canon => '', name => 'F+', qual => '+', qual_canon => '+', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5, system => 'common' }
F4	{ ext => 4, ext_canon => 4, name => 'F4', qual => '', qual_canon => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5, system => 'common' }
F6	{ ext => 6, ext_canon => 6, name => 'F6', qual => '', qual_canon => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5, system => 'common' }
F7	{ ext => 7, ext_canon => 7, name => 'F7', qual => '', qual_canon => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5, system => 'common' }
F9	{ ext => 9, ext_canon => 9, name => 'F9', qual => '', qual_canon => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5, system => 'common' }
F11	{ ext => 11, ext_canon => 11, name => 'F11', qual => '', qual_canon => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5, system => 'common' }
Fsus	{ ext => 'sus', ext_canon => 'sus4', name => 'Fsus', qual => '', qual_canon => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5, system => 'common' }
Fsus4	{ ext => 'sus4', ext_canon => 'sus4', name => 'Fsus4', qual => '', qual_canon => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5, system => 'common' }
Fmaj	{ ext => '', ext_canon => '', name => 'Fmaj', qual => '', qual_canon => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5, system => 'common' }
Fmaj7	{ ext => 'maj7', ext_canon => 'maj7', name => 'Fmaj7', qual => '', qual_canon => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5, system => 'common' }
Fdim	{ ext => '', ext_canon => '', name => 'Fdim', qual => 'dim', qual_canon => 0, root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5, system => 'common' }
Fm	{ ext => '', ext_canon => '', name => 'Fm', qual => 'm', qual_canon => '-', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5, system => 'common' }
Fmin	{ ext => '', ext_canon => '', name => 'Fmin', qual => 'min', qual_canon => '-', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5, system => 'common' }
F/A	{ bass => 'A', bass_canon => 'A', bass_mod => 0, bass_ord => 9, ext => '', ext_canon => '', name => 'F/A', qual => '', qual_canon => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5, system => 'common' }
F/C	{ bass => 'C', bass_canon => 'C', bass_mod => 0, bass_ord => 0, ext => '', ext_canon => '', name => 'F/C', qual => '', qual_canon => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5, system => 'common' }
F/D	{ bass => 'D', bass_canon => 'D', bass_mod => 0, bass_ord => 2, ext => '', ext_canon => '', name => 'F/D', qual => '', qual_canon => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5, system => 'common' }
F/G	{ bass => 'G', bass_canon => 'G', bass_mod => 0, bass_ord => 7, ext => '', ext_canon => '', name => 'F/G', qual => '', qual_canon => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5, system => 'common' }
F7/A	{ bass => 'A', bass_canon => 'A', bass_mod => 0, bass_ord => 9, ext => 7, ext_canon => 7, name => 'F7/A', qual => '', qual_canon => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5, system => 'common' }
Fmaj7/A	{ bass => 'A', bass_canon => 'A', bass_mod => 0, bass_ord => 9, ext => 'maj7', ext_canon => 'maj7', name => 'Fmaj7/A', qual => '', qual_canon => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5, system => 'common' }
Fmaj7/C	{ bass => 'C', bass_canon => 'C', bass_mod => 0, bass_ord => 0, ext => 'maj7', ext_canon => 'maj7', name => 'Fmaj7/C', qual => '', qual_canon => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5, system => 'common' }
Fadd9	{ ext => 'add9', ext_canon => 'add9', name => 'Fadd9', qual => '', qual_canon => '', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5, system => 'common' }
Fm6	{ ext => 6, ext_canon => 6, name => 'Fm6', qual => 'm', qual_canon => '-', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5, system => 'common' }
Fm7	{ ext => 7, ext_canon => 7, name => 'Fm7', qual => 'm', qual_canon => '-', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5, system => 'common' }
Fmmaj7	{ ext => 'maj7', ext_canon => 'maj7', name => 'Fmmaj7', qual => 'm', qual_canon => '-', root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5, system => 'common' }
F#	{ ext => '', ext_canon => '', name => 'F#', qual => '', qual_canon => '', root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6, system => 'common' }
F#+	{ ext => '', ext_canon => '', name => 'F#+', qual => '+', qual_canon => '+', root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6, system => 'common' }
F#7	{ ext => 7, ext_canon => 7, name => 'F#7', qual => '', qual_canon => '', root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6, system => 'common' }
F#9	{ ext => 9, ext_canon => 9, name => 'F#9', qual => '', qual_canon => '', root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6, system => 'common' }
F#11	{ ext => 11, ext_canon => 11, name => 'F#11', qual => '', qual_canon => '', root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6, system => 'common' }
F#sus	{ ext => 'sus', ext_canon => 'sus4', name => 'F#sus', qual => '', qual_canon => '', root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6, system => 'common' }
F#sus4	{ ext => 'sus4', ext_canon => 'sus4', name => 'F#sus4', qual => '', qual_canon => '', root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6, system => 'common' }
F#maj7	{ ext => 'maj7', ext_canon => 'maj7', name => 'F#maj7', qual => '', qual_canon => '', root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6, system => 'common' }
F#dim	{ ext => '', ext_canon => '', name => 'F#dim', qual => 'dim', qual_canon => 0, root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6, system => 'common' }
F#m	{ ext => '', ext_canon => '', name => 'F#m', qual => 'm', qual_canon => '-', root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6, system => 'common' }
F#min	{ ext => '', ext_canon => '', name => 'F#min', qual => 'min', qual_canon => '-', root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6, system => 'common' }
F#/E	{ bass => 'E', bass_canon => 'E', bass_mod => 0, bass_ord => 4, ext => '', ext_canon => '', name => 'F#/E', qual => '', qual_canon => '', root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6, system => 'common' }
F#4	{ ext => 4, ext_canon => 4, name => 'F#4', qual => '', qual_canon => '', root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6, system => 'common' }
F#m6	{ ext => 6, ext_canon => 6, name => 'F#m6', qual => 'm', qual_canon => '-', root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6, system => 'common' }
F#m7	{ ext => 7, ext_canon => 7, name => 'F#m7', qual => 'm', qual_canon => '-', root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6, system => 'common' }
F#m7b5	{ ext => '7b5', ext_canon => '7b5', name => 'F#m7b5', qual => 'm', qual_canon => '-', root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6, system => 'common' }
F#m/C	{ bass => 'C', bass_canon => 'C', bass_mod => 0, bass_ord => 0, ext => '', ext_canon => '', name => 'F#m/C', qual => 'm', qual_canon => '-', root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6, system => 'common' }
Gb	{ ext => '', ext_canon => '', name => 'Gb', qual => '', qual_canon => '', root => 'Gb', root_canon => 'Gb', root_mod => -1, root_ord => 6, system => 'common' }
Gb+	{ ext => '', ext_canon => '', name => 'Gb+', qual => '+', qual_canon => '+', root => 'Gb', root_canon => 'Gb', root_mod => -1, root_ord => 6, system => 'common' }
Gb7	{ ext => 7, ext_canon => 7, name => 'Gb7', qual => '', qual_canon => '', root => 'Gb', root_canon => 'Gb', root_mod => -1, root_ord => 6, system => 'common' }
Gb9	{ ext => 9, ext_canon => 9, name => 'Gb9', qual => '', qual_canon => '', root => 'Gb', root_canon => 'Gb', root_mod => -1, root_ord => 6, system => 'common' }
Gbsus	{ ext => 'sus', ext_canon => 'sus4', name => 'Gbsus', qual => '', qual_canon => '', root => 'Gb', root_canon => 'Gb', root_mod => -1, root_ord => 6, system => 'common' }
Gbsus4	{ ext => 'sus4', ext_canon => 'sus4', name => 'Gbsus4', qual => '', qual_canon => '', root => 'Gb', root_canon => 'Gb', root_mod => -1, root_ord => 6, system => 'common' }
Gbmaj	{ ext => '', ext_canon => '', name => 'Gbmaj', qual => '', qual_canon => '', root => 'Gb', root_canon => 'Gb', root_mod => -1, root_ord => 6, system => 'common' }
Gbmaj7	{ ext => 'maj7', ext_canon => 'maj7', name => 'Gbmaj7', qual => '', qual_canon => '', root => 'Gb', root_canon => 'Gb', root_mod => -1, root_ord => 6, system => 'common' }
Gbdim	{ ext => '', ext_canon => '', name => 'Gbdim', qual => 'dim', qual_canon => 0, root => 'Gb', root_canon => 'Gb', root_mod => -1, root_ord => 6, system => 'common' }
Gbm	{ ext => '', ext_canon => '', name => 'Gbm', qual => 'm', qual_canon => '-', root => 'Gb', root_canon => 'Gb', root_mod => -1, root_ord => 6, system => 'common' }
Gbmin	{ ext => '', ext_canon => '', name => 'Gbmin', qual => 'min', qual_canon => '-', root => 'Gb', root_canon => 'Gb', root_mod => -1, root_ord => 6, system => 'common' }
Gbm7	{ ext => 7, ext_canon => 7, name => 'Gbm7', qual => 'm', qual_canon => '-', root => 'Gb', root_canon => 'Gb', root_mod => -1, root_ord => 6, system => 'common' }
G	{ ext => '', ext_canon => '', name => 'G', qual => '', qual_canon => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7, system => 'common' }
G+	{ ext => '', ext_canon => '', name => 'G+', qual => '+', qual_canon => '+', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7, system => 'common' }
G4	{ ext => 4, ext_canon => 4, name => 'G4', qual => '', qual_canon => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7, system => 'common' }
G6	{ ext => 6, ext_canon => 6, name => 'G6', qual => '', qual_canon => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7, system => 'common' }
G7	{ ext => 7, ext_canon => 7, name => 'G7', qual => '', qual_canon => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7, system => 'common' }
G7b9	{ ext => '7b9', ext_canon => '7b9', name => 'G7b9', qual => '', qual_canon => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7, system => 'common' }
G7#9	{ ext => '7#9', ext_canon => '7#9', name => 'G7#9', qual => '', qual_canon => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7, system => 'common' }
G9	{ ext => 9, ext_canon => 9, name => 'G9', qual => '', qual_canon => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7, system => 'common' }
G9(11)	{ ext => 911, ext_canon => 911, name => 'G911', qual => '', qual_canon => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7, system => 'common' }
G11	{ ext => 11, ext_canon => 11, name => 'G11', qual => '', qual_canon => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7, system => 'common' }
Gsus	{ ext => 'sus', ext_canon => 'sus4', name => 'Gsus', qual => '', qual_canon => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7, system => 'common' }
Gsus4	{ ext => 'sus4', ext_canon => 'sus4', name => 'Gsus4', qual => '', qual_canon => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7, system => 'common' }
G6sus4	{ ext => '6sus4', ext_canon => '6sus4', name => 'G6sus4', qual => '', qual_canon => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7, system => 'common' }
G7sus4	{ ext => '7sus4', ext_canon => '7sus4', name => 'G7sus4', qual => '', qual_canon => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7, system => 'common' }
Gmaj	{ ext => '', ext_canon => '', name => 'Gmaj', qual => '', qual_canon => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7, system => 'common' }
Gmaj7	{ ext => 'maj7', ext_canon => 'maj7', name => 'Gmaj7', qual => '', qual_canon => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7, system => 'common' }
Gmaj7sus4	{ ext => 'maj7sus4', ext_canon => 'maj7sus4', name => 'Gmaj7sus4', qual => '', qual_canon => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7, system => 'common' }
Gmaj9	{ ext => 'maj9', ext_canon => 'maj9', name => 'Gmaj9', qual => '', qual_canon => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7, system => 'common' }
Gm	{ ext => '', ext_canon => '', name => 'Gm', qual => 'm', qual_canon => '-', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7, system => 'common' }
Gmin	{ ext => '', ext_canon => '', name => 'Gmin', qual => 'min', qual_canon => '-', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7, system => 'common' }
Gdim	{ ext => '', ext_canon => '', name => 'Gdim', qual => 'dim', qual_canon => 0, root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7, system => 'common' }
Gadd9	{ ext => 'add9', ext_canon => 'add9', name => 'Gadd9', qual => '', qual_canon => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7, system => 'common' }
G(add9)	{ ext => 'add9', ext_canon => 'add9', name => 'Gadd9', qual => '', qual_canon => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7, system => 'common' }
G/A	{ bass => 'A', bass_canon => 'A', bass_mod => 0, bass_ord => 9, ext => '', ext_canon => '', name => 'G/A', qual => '', qual_canon => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7, system => 'common' }
G/B	{ bass => 'B', bass_canon => 'B', bass_mod => 0, bass_ord => 11, ext => '', ext_canon => '', name => 'G/B', qual => '', qual_canon => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7, system => 'common' }
G/D	{ bass => 'D', bass_canon => 'D', bass_mod => 0, bass_ord => 2, ext => '', ext_canon => '', name => 'G/D', qual => '', qual_canon => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7, system => 'common' }
G/F#	{ bass => 'F#', bass_canon => 'F#', bass_mod => 1, bass_ord => 6, ext => '', ext_canon => '', name => 'G/F#', qual => '', qual_canon => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7, system => 'common' }
Gm6	{ ext => 6, ext_canon => 6, name => 'Gm6', qual => 'm', qual_canon => '-', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7, system => 'common' }
Gm7	{ ext => 7, ext_canon => 7, name => 'Gm7', qual => 'm', qual_canon => '-', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7, system => 'common' }
Gm/Bb	{ bass => 'Bb', bass_canon => 'Bb', bass_mod => -1, bass_ord => 10, ext => '', ext_canon => '', name => 'Gm/Bb', qual => 'm', qual_canon => '-', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7, system => 'common' }
G#	{ ext => '', ext_canon => '', name => 'G#', qual => '', qual_canon => '', root => 'G#', root_canon => 'G#', root_mod => 1, root_ord => 8, system => 'common' }
G#+	{ ext => '', ext_canon => '', name => 'G#+', qual => '+', qual_canon => '+', root => 'G#', root_canon => 'G#', root_mod => 1, root_ord => 8, system => 'common' }
G#4	{ ext => 4, ext_canon => 4, name => 'G#4', qual => '', qual_canon => '', root => 'G#', root_canon => 'G#', root_mod => 1, root_ord => 8, system => 'common' }
G#7	{ ext => 7, ext_canon => 7, name => 'G#7', qual => '', qual_canon => '', root => 'G#', root_canon => 'G#', root_mod => 1, root_ord => 8, system => 'common' }
G#sus	{ ext => 'sus', ext_canon => 'sus4', name => 'G#sus', qual => '', qual_canon => '', root => 'G#', root_canon => 'G#', root_mod => 1, root_ord => 8, system => 'common' }
G#sus4	{ ext => 'sus4', ext_canon => 'sus4', name => 'G#sus4', qual => '', qual_canon => '', root => 'G#', root_canon => 'G#', root_mod => 1, root_ord => 8, system => 'common' }
G#maj	{ ext => '', ext_canon => '', name => 'G#maj', qual => '', qual_canon => '', root => 'G#', root_canon => 'G#', root_mod => 1, root_ord => 8, system => 'common' }
G#maj7	{ ext => 'maj7', ext_canon => 'maj7', name => 'G#maj7', qual => '', qual_canon => '', root => 'G#', root_canon => 'G#', root_mod => 1, root_ord => 8, system => 'common' }
G#dim	{ ext => '', ext_canon => '', name => 'G#dim', qual => 'dim', qual_canon => 0, root => 'G#', root_canon => 'G#', root_mod => 1, root_ord => 8, system => 'common' }
G#m	{ ext => '', ext_canon => '', name => 'G#m', qual => 'm', qual_canon => '-', root => 'G#', root_canon => 'G#', root_mod => 1, root_ord => 8, system => 'common' }
G#min	{ ext => '', ext_canon => '', name => 'G#min', qual => 'min', qual_canon => '-', root => 'G#', root_canon => 'G#', root_mod => 1, root_ord => 8, system => 'common' }
G#m6	{ ext => 6, ext_canon => 6, name => 'G#m6', qual => 'm', qual_canon => '-', root => 'G#', root_canon => 'G#', root_mod => 1, root_ord => 8, system => 'common' }
G#m7	{ ext => 7, ext_canon => 7, name => 'G#m7', qual => 'm', qual_canon => '-', root => 'G#', root_canon => 'G#', root_mod => 1, root_ord => 8, system => 'common' }
G#m9maj7	{ ext => '9maj7', ext_canon => '9maj7', name => 'G#m9maj7', qual => 'm', qual_canon => '-', root => 'G#', root_canon => 'G#', root_mod => 1, root_ord => 8, system => 'common' }
Ab	{ ext => '', ext_canon => '', name => 'Ab', qual => '', qual_canon => '', root => 'Ab', root_canon => 'Ab', root_mod => -1, root_ord => 8, system => 'common' }
Ab+	{ ext => '', ext_canon => '', name => 'Ab+', qual => '+', qual_canon => '+', root => 'Ab', root_canon => 'Ab', root_mod => -1, root_ord => 8, system => 'common' }
Ab4	{ ext => 4, ext_canon => 4, name => 'Ab4', qual => '', qual_canon => '', root => 'Ab', root_canon => 'Ab', root_mod => -1, root_ord => 8, system => 'common' }
Ab7	{ ext => 7, ext_canon => 7, name => 'Ab7', qual => '', qual_canon => '', root => 'Ab', root_canon => 'Ab', root_mod => -1, root_ord => 8, system => 'common' }
Ab11	{ ext => 11, ext_canon => 11, name => 'Ab11', qual => '', qual_canon => '', root => 'Ab', root_canon => 'Ab', root_mod => -1, root_ord => 8, system => 'common' }
Absus	{ ext => 'sus', ext_canon => 'sus4', name => 'Absus', qual => '', qual_canon => '', root => 'Ab', root_canon => 'Ab', root_mod => -1, root_ord => 8, system => 'common' }
Absus4	{ ext => 'sus4', ext_canon => 'sus4', name => 'Absus4', qual => '', qual_canon => '', root => 'Ab', root_canon => 'Ab', root_mod => -1, root_ord => 8, system => 'common' }
Abdim	{ ext => '', ext_canon => '', name => 'Abdim', qual => 'dim', qual_canon => 0, root => 'Ab', root_canon => 'Ab', root_mod => -1, root_ord => 8, system => 'common' }
Abmaj	{ ext => '', ext_canon => '', name => 'Abmaj', qual => '', qual_canon => '', root => 'Ab', root_canon => 'Ab', root_mod => -1, root_ord => 8, system => 'common' }
Abmaj7	{ ext => 'maj7', ext_canon => 'maj7', name => 'Abmaj7', qual => '', qual_canon => '', root => 'Ab', root_canon => 'Ab', root_mod => -1, root_ord => 8, system => 'common' }
Abm	{ ext => '', ext_canon => '', name => 'Abm', qual => 'm', qual_canon => '-', root => 'Ab', root_canon => 'Ab', root_mod => -1, root_ord => 8, system => 'common' }
Abmin	{ ext => '', ext_canon => '', name => 'Abmin', qual => 'min', qual_canon => '-', root => 'Ab', root_canon => 'Ab', root_mod => -1, root_ord => 8, system => 'common' }
Abm7	{ ext => 7, ext_canon => 7, name => 'Abm7', qual => 'm', qual_canon => '-', root => 'Ab', root_canon => 'Ab', root_mod => -1, root_ord => 8, system => 'common' }
A	{ ext => '', ext_canon => '', name => 'A', qual => '', qual_canon => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9, system => 'common' }
A+	{ ext => '', ext_canon => '', name => 'A+', qual => '+', qual_canon => '+', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9, system => 'common' }
A4	{ ext => 4, ext_canon => 4, name => 'A4', qual => '', qual_canon => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9, system => 'common' }
A6	{ ext => 6, ext_canon => 6, name => 'A6', qual => '', qual_canon => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9, system => 'common' }
A7	{ ext => 7, ext_canon => 7, name => 'A7', qual => '', qual_canon => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9, system => 'common' }
A9	{ ext => 9, ext_canon => 9, name => 'A9', qual => '', qual_canon => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9, system => 'common' }
A11	{ ext => 11, ext_canon => 11, name => 'A11', qual => '', qual_canon => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9, system => 'common' }
A13	{ ext => 13, ext_canon => 13, name => 'A13', qual => '', qual_canon => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9, system => 'common' }
A7sus4	{ ext => '7sus4', ext_canon => '7sus4', name => 'A7sus4', qual => '', qual_canon => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9, system => 'common' }
A9sus	{ ext => '9sus', ext_canon => '9sus', name => 'A9sus', qual => '', qual_canon => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9, system => 'common' }
Asus	{ ext => 'sus', ext_canon => 'sus4', name => 'Asus', qual => '', qual_canon => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9, system => 'common' }
Asus2	{ ext => 'sus2', ext_canon => 'sus2', name => 'Asus2', qual => '', qual_canon => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9, system => 'common' }
Asus4	{ ext => 'sus4', ext_canon => 'sus4', name => 'Asus4', qual => '', qual_canon => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9, system => 'common' }
Adim	{ ext => '', ext_canon => '', name => 'Adim', qual => 'dim', qual_canon => 0, root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9, system => 'common' }
Amaj	{ ext => '', ext_canon => '', name => 'Amaj', qual => '', qual_canon => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9, system => 'common' }
Amaj7	{ ext => 'maj7', ext_canon => 'maj7', name => 'Amaj7', qual => '', qual_canon => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9, system => 'common' }
Am	{ ext => '', ext_canon => '', name => 'Am', qual => 'm', qual_canon => '-', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9, system => 'common' }
Amin	{ ext => '', ext_canon => '', name => 'Amin', qual => 'min', qual_canon => '-', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9, system => 'common' }
A/C#	{ bass => 'C#', bass_canon => 'C#', bass_mod => 1, bass_ord => 1, ext => '', ext_canon => '', name => 'A/C#', qual => '', qual_canon => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9, system => 'common' }
A/D	{ bass => 'D', bass_canon => 'D', bass_mod => 0, bass_ord => 2, ext => '', ext_canon => '', name => 'A/D', qual => '', qual_canon => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9, system => 'common' }
A/E	{ bass => 'E', bass_canon => 'E', bass_mod => 0, bass_ord => 4, ext => '', ext_canon => '', name => 'A/E', qual => '', qual_canon => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9, system => 'common' }
A/F#	{ bass => 'F#', bass_canon => 'F#', bass_mod => 1, bass_ord => 6, ext => '', ext_canon => '', name => 'A/F#', qual => '', qual_canon => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9, system => 'common' }
A/G#	{ bass => 'G#', bass_canon => 'G#', bass_mod => 1, bass_ord => 8, ext => '', ext_canon => '', name => 'A/G#', qual => '', qual_canon => '', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9, system => 'common' }
Am#7	{ ext => '#7', ext_canon => '#7', name => 'Am#7', qual => 'm', qual_canon => '-', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9, system => 'common' }
Am6	{ ext => 6, ext_canon => 6, name => 'Am6', qual => 'm', qual_canon => '-', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9, system => 'common' }
Am7	{ ext => 7, ext_canon => 7, name => 'Am7', qual => 'm', qual_canon => '-', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9, system => 'common' }
Am7sus4	{ ext => '7sus4', ext_canon => '7sus4', name => 'Am7sus4', qual => 'm', qual_canon => '-', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9, system => 'common' }
Am9	{ ext => 9, ext_canon => 9, name => 'Am9', qual => 'm', qual_canon => '-', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9, system => 'common' }
Am/G	{ bass => 'G', bass_canon => 'G', bass_mod => 0, bass_ord => 7, ext => '', ext_canon => '', name => 'Am/G', qual => 'm', qual_canon => '-', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9, system => 'common' }
Amadd9	{ ext => 'add9', ext_canon => 'add9', name => 'Amadd9', qual => 'm', qual_canon => '-', root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9, system => 'common' }
A#	{ ext => '', ext_canon => '', name => 'A#', qual => '', qual_canon => '', root => 'A#', root_canon => 'A#', root_mod => 1, root_ord => 10, system => 'common' }
A#+	{ ext => '', ext_canon => '', name => 'A#+', qual => '+', qual_canon => '+', root => 'A#', root_canon => 'A#', root_mod => 1, root_ord => 10, system => 'common' }
A#4	{ ext => 4, ext_canon => 4, name => 'A#4', qual => '', qual_canon => '', root => 'A#', root_canon => 'A#', root_mod => 1, root_ord => 10, system => 'common' }
A#7	{ ext => 7, ext_canon => 7, name => 'A#7', qual => '', qual_canon => '', root => 'A#', root_canon => 'A#', root_mod => 1, root_ord => 10, system => 'common' }
A#sus	{ ext => 'sus', ext_canon => 'sus4', name => 'A#sus', qual => '', qual_canon => '', root => 'A#', root_canon => 'A#', root_mod => 1, root_ord => 10, system => 'common' }
A#sus4	{ ext => 'sus4', ext_canon => 'sus4', name => 'A#sus4', qual => '', qual_canon => '', root => 'A#', root_canon => 'A#', root_mod => 1, root_ord => 10, system => 'common' }
A#maj	{ ext => '', ext_canon => '', name => 'A#maj', qual => '', qual_canon => '', root => 'A#', root_canon => 'A#', root_mod => 1, root_ord => 10, system => 'common' }
A#maj7	{ ext => 'maj7', ext_canon => 'maj7', name => 'A#maj7', qual => '', qual_canon => '', root => 'A#', root_canon => 'A#', root_mod => 1, root_ord => 10, system => 'common' }
A#dim	{ ext => '', ext_canon => '', name => 'A#dim', qual => 'dim', qual_canon => 0, root => 'A#', root_canon => 'A#', root_mod => 1, root_ord => 10, system => 'common' }
A#m	{ ext => '', ext_canon => '', name => 'A#m', qual => 'm', qual_canon => '-', root => 'A#', root_canon => 'A#', root_mod => 1, root_ord => 10, system => 'common' }
A#min	{ ext => '', ext_canon => '', name => 'A#min', qual => 'min', qual_canon => '-', root => 'A#', root_canon => 'A#', root_mod => 1, root_ord => 10, system => 'common' }
A#m7	{ ext => 7, ext_canon => 7, name => 'A#m7', qual => 'm', qual_canon => '-', root => 'A#', root_canon => 'A#', root_mod => 1, root_ord => 10, system => 'common' }
Bb	{ ext => '', ext_canon => '', name => 'Bb', qual => '', qual_canon => '', root => 'Bb', root_canon => 'Bb', root_mod => -1, root_ord => 10, system => 'common' }
Bb+	{ ext => '', ext_canon => '', name => 'Bb+', qual => '+', qual_canon => '+', root => 'Bb', root_canon => 'Bb', root_mod => -1, root_ord => 10, system => 'common' }
Bb4	{ ext => 4, ext_canon => 4, name => 'Bb4', qual => '', qual_canon => '', root => 'Bb', root_canon => 'Bb', root_mod => -1, root_ord => 10, system => 'common' }
Bb6	{ ext => 6, ext_canon => 6, name => 'Bb6', qual => '', qual_canon => '', root => 'Bb', root_canon => 'Bb', root_mod => -1, root_ord => 10, system => 'common' }
Bb7	{ ext => 7, ext_canon => 7, name => 'Bb7', qual => '', qual_canon => '', root => 'Bb', root_canon => 'Bb', root_mod => -1, root_ord => 10, system => 'common' }
Bb9	{ ext => 9, ext_canon => 9, name => 'Bb9', qual => '', qual_canon => '', root => 'Bb', root_canon => 'Bb', root_mod => -1, root_ord => 10, system => 'common' }
Bb11	{ ext => 11, ext_canon => 11, name => 'Bb11', qual => '', qual_canon => '', root => 'Bb', root_canon => 'Bb', root_mod => -1, root_ord => 10, system => 'common' }
Bbsus	{ ext => 'sus', ext_canon => 'sus4', name => 'Bbsus', qual => '', qual_canon => '', root => 'Bb', root_canon => 'Bb', root_mod => -1, root_ord => 10, system => 'common' }
Bbsus4	{ ext => 'sus4', ext_canon => 'sus4', name => 'Bbsus4', qual => '', qual_canon => '', root => 'Bb', root_canon => 'Bb', root_mod => -1, root_ord => 10, system => 'common' }
Bbmaj	{ ext => '', ext_canon => '', name => 'Bbmaj', qual => '', qual_canon => '', root => 'Bb', root_canon => 'Bb', root_mod => -1, root_ord => 10, system => 'common' }
Bbmaj7	{ ext => 'maj7', ext_canon => 'maj7', name => 'Bbmaj7', qual => '', qual_canon => '', root => 'Bb', root_canon => 'Bb', root_mod => -1, root_ord => 10, system => 'common' }
Bbdim	{ ext => '', ext_canon => '', name => 'Bbdim', qual => 'dim', qual_canon => 0, root => 'Bb', root_canon => 'Bb', root_mod => -1, root_ord => 10, system => 'common' }
Bbm	{ ext => '', ext_canon => '', name => 'Bbm', qual => 'm', qual_canon => '-', root => 'Bb', root_canon => 'Bb', root_mod => -1, root_ord => 10, system => 'common' }
Bbmin	{ ext => '', ext_canon => '', name => 'Bbmin', qual => 'min', qual_canon => '-', root => 'Bb', root_canon => 'Bb', root_mod => -1, root_ord => 10, system => 'common' }
Bbm7	{ ext => 7, ext_canon => 7, name => 'Bbm7', qual => 'm', qual_canon => '-', root => 'Bb', root_canon => 'Bb', root_mod => -1, root_ord => 10, system => 'common' }
Bbm9	{ ext => 9, ext_canon => 9, name => 'Bbm9', qual => 'm', qual_canon => '-', root => 'Bb', root_canon => 'Bb', root_mod => -1, root_ord => 10, system => 'common' }
B	{ ext => '', ext_canon => '', name => 'B', qual => '', qual_canon => '', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11, system => 'common' }
B+	{ ext => '', ext_canon => '', name => 'B+', qual => '+', qual_canon => '+', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11, system => 'common' }
B4	{ ext => 4, ext_canon => 4, name => 'B4', qual => '', qual_canon => '', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11, system => 'common' }
B7	{ ext => 7, ext_canon => 7, name => 'B7', qual => '', qual_canon => '', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11, system => 'common' }
B7#9	{ ext => '7#9', ext_canon => '7#9', name => 'B7#9', qual => '', qual_canon => '', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11, system => 'common' }
B9	{ ext => 9, ext_canon => 9, name => 'B9', qual => '', qual_canon => '', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11, system => 'common' }
B11	{ ext => 11, ext_canon => 11, name => 'B11', qual => '', qual_canon => '', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11, system => 'common' }
B13	{ ext => 13, ext_canon => 13, name => 'B13', qual => '', qual_canon => '', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11, system => 'common' }
Bsus	{ ext => 'sus', ext_canon => 'sus4', name => 'Bsus', qual => '', qual_canon => '', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11, system => 'common' }
Bsus4	{ ext => 'sus4', ext_canon => 'sus4', name => 'Bsus4', qual => '', qual_canon => '', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11, system => 'common' }
Bmaj	{ ext => '', ext_canon => '', name => 'Bmaj', qual => '', qual_canon => '', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11, system => 'common' }
Bmaj7	{ ext => 'maj7', ext_canon => 'maj7', name => 'Bmaj7', qual => '', qual_canon => '', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11, system => 'common' }
Bdim	{ ext => '', ext_canon => '', name => 'Bdim', qual => 'dim', qual_canon => 0, root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11, system => 'common' }
Bm	{ ext => '', ext_canon => '', name => 'Bm', qual => 'm', qual_canon => '-', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11, system => 'common' }
Bmin	{ ext => '', ext_canon => '', name => 'Bmin', qual => 'min', qual_canon => '-', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11, system => 'common' }
B/F#	{ bass => 'F#', bass_canon => 'F#', bass_mod => 1, bass_ord => 6, ext => '', ext_canon => '', name => 'B/F#', qual => '', qual_canon => '', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11, system => 'common' }
Bm6	{ ext => 6, ext_canon => 6, name => 'Bm6', qual => 'm', qual_canon => '-', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11, system => 'common' }
Bm7	{ ext => 7, ext_canon => 7, name => 'Bm7', qual => 'm', qual_canon => '-', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11, system => 'common' }
Bmmaj7	{ ext => 'maj7', ext_canon => 'maj7', name => 'Bmmaj7', qual => 'm', qual_canon => '-', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11, system => 'common' }
Bmsus9	{ ext => 'sus9', ext_canon => 'sus9', name => 'Bmsus9', qual => 'm', qual_canon => '-', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11, system => 'common' }
Bm7b5	{ ext => '7b5', ext_canon => '7b5', name => 'Bm7b5', qual => 'm', qual_canon => '-', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11, system => 'common' }
