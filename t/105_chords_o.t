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
Co	{ ext => '', ext_canon => '', name => 'Co', qual => 'o', qual_canon => 0, root => 'C', root_canon => 'C', root_mod => 0, root_ord => 0, system => 'common' }
C#o	{ ext => '', ext_canon => '', name => 'C#o', qual => 'o', qual_canon => 0, root => 'C#', root_canon => 'C#', root_mod => 1, root_ord => 1, system => 'common' }
Dbo	{ ext => '', ext_canon => '', name => 'Dbo', qual => 'o', qual_canon => 0, root => 'Db', root_canon => 'Db', root_mod => -1, root_ord => 1, system => 'common' }
Do	{ ext => '', ext_canon => '', name => 'Do', qual => 'o', qual_canon => 0, root => 'D', root_canon => 'D', root_mod => 0, root_ord => 2, system => 'common' }
D#o	{ ext => '', ext_canon => '', name => 'D#o', qual => 'o', qual_canon => 0, root => 'D#', root_canon => 'D#', root_mod => 1, root_ord => 3, system => 'common' }
Ebo	{ ext => '', ext_canon => '', name => 'Ebo', qual => 'o', qual_canon => 0, root => 'Eb', root_canon => 'Eb', root_mod => -1, root_ord => 3, system => 'common' }
Eo	{ ext => '', ext_canon => '', name => 'Eo', qual => 'o', qual_canon => 0, root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4, system => 'common' }
Fo	{ ext => '', ext_canon => '', name => 'Fo', qual => 'o', qual_canon => 0, root => 'F', root_canon => 'F', root_mod => 0, root_ord => 5, system => 'common' }
F#o	{ ext => '', ext_canon => '', name => 'F#o', qual => 'o', qual_canon => 0, root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6, system => 'common' }
Gbo	{ ext => '', ext_canon => '', name => 'Gbo', qual => 'o', qual_canon => 0, root => 'Gb', root_canon => 'Gb', root_mod => -1, root_ord => 6, system => 'common' }
Go	{ ext => '', ext_canon => '', name => 'Go', qual => 'o', qual_canon => 0, root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7, system => 'common' }
G#o	{ ext => '', ext_canon => '', name => 'G#o', qual => 'o', qual_canon => 0, root => 'G#', root_canon => 'G#', root_mod => 1, root_ord => 8, system => 'common' }
Abo	{ ext => '', ext_canon => '', name => 'Abo', qual => 'o', qual_canon => 0, root => 'Ab', root_canon => 'Ab', root_mod => -1, root_ord => 8, system => 'common' }
Ao	{ ext => '', ext_canon => '', name => 'Ao', qual => 'o', qual_canon => 0, root => 'A', root_canon => 'A', root_mod => 0, root_ord => 9, system => 'common' }
A#o	{ ext => '', ext_canon => '', name => 'A#o', qual => 'o', qual_canon => 0, root => 'A#', root_canon => 'A#', root_mod => 1, root_ord => 10, system => 'common' }
Bbo	{ ext => '', ext_canon => '', name => 'Bbo', qual => 'o', qual_canon => 0, root => 'Bb', root_canon => 'Bb', root_mod => -1, root_ord => 10, system => 'common' }
Bo	{ ext => '', ext_canon => '', name => 'Bo', qual => 'o', qual_canon => 0, root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11, system => 'common' }
