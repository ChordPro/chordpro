#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use App::Music::ChordPro::Testing;
use App::Music::ChordPro::Chords;
use App::Music::ChordPro::Chords::Parser;

my %tbl;

our $options = { verbose => 0 };
our $config =
  eval {
      App::Music::ChordPro::Config::configurator
	  ( { nosysconfig => 1, nolegacyconfig => 1, nouserconfig => 1,
	      config => getresource("config/notes/latin.json") } );
  };
die unless App::Music::ChordPro::Chords::Parser->get_parser($::config->{notes}->{system},1);

=begin regenerate

# Enable this section to generate new reference data.

my $p = App::Music::ChordPro::Chords::Parser->get_parser("latin");

open( my $fd, '<', "t/105_chords_o.t" );
my $skip = 1;
while ( <$fd> ) {
    chomp;
    if ( $skip && /__DATA__/ ) {
        $skip = 0;
        next;
    }
    next if $skip;
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
    my $res = $p->parse($c);
    unless ( $res ) {
	print( "$chord\tFAIL\n");
	next;
    }
    $res = {%$res};
    delete($res->{parser});
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

plan tests => 0 + keys(%tbl);

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
Doo	{ ext => '', ext_canon => '', name => 'Doo', qual => 'o', qual_canon => 0, root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'latin' }
Do#o	{ ext => '', ext_canon => '', name => 'Do#o', qual => 'o', qual_canon => 0, root => 'Do#', root_canon => 'Do#', root_mod => 1, root_ord => 1, system => 'latin' }
Rebo	{ ext => '', ext_canon => '', name => 'Rebo', qual => 'o', qual_canon => 0, root => 'Reb', root_canon => 'Reb', root_mod => -1, root_ord => 1, system => 'latin' }
Reo	{ ext => '', ext_canon => '', name => 'Reo', qual => 'o', qual_canon => 0, root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'latin' }
Re#o	{ ext => '', ext_canon => '', name => 'Re#o', qual => 'o', qual_canon => 0, root => 'Re#', root_canon => 'Re#', root_mod => 1, root_ord => 3, system => 'latin' }
Mibo	{ ext => '', ext_canon => '', name => 'Mibo', qual => 'o', qual_canon => 0, root => 'Mib', root_canon => 'Mib', root_mod => -1, root_ord => 3, system => 'latin' }
Mio	{ ext => '', ext_canon => '', name => 'Mio', qual => 'o', qual_canon => 0, root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'latin' }
Fao	{ ext => '', ext_canon => '', name => 'Fao', qual => 'o', qual_canon => 0, root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'latin' }
Fa#o	{ ext => '', ext_canon => '', name => 'Fa#o', qual => 'o', qual_canon => 0, root => 'Fa#', root_canon => 'Fa#', root_mod => 1, root_ord => 6, system => 'latin' }
Solbo	{ ext => '', ext_canon => '', name => 'Solbo', qual => 'o', qual_canon => 0, root => 'Solb', root_canon => 'Solb', root_mod => -1, root_ord => 6, system => 'latin' }
Solo	{ ext => '', ext_canon => '', name => 'Solo', qual => 'o', qual_canon => 0, root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7, system => 'latin' }
Sol#o	{ ext => '', ext_canon => '', name => 'Sol#o', qual => 'o', qual_canon => 0, root => 'Sol#', root_canon => 'Sol#', root_mod => 1, root_ord => 8, system => 'latin' }
Labo	{ ext => '', ext_canon => '', name => 'Labo', qual => 'o', qual_canon => 0, root => 'Lab', root_canon => 'Lab', root_mod => -1, root_ord => 8, system => 'latin' }
Lao	{ ext => '', ext_canon => '', name => 'Lao', qual => 'o', qual_canon => 0, root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'latin' }
La#o	{ ext => '', ext_canon => '', name => 'La#o', qual => 'o', qual_canon => 0, root => 'La#', root_canon => 'La#', root_mod => 1, root_ord => 10, system => 'latin' }
Sibo	{ ext => '', ext_canon => '', name => 'Sibo', qual => 'o', qual_canon => 0, root => 'Sib', root_canon => 'Sib', root_mod => -1, root_ord => 10, system => 'latin' }
Sio	{ ext => '', ext_canon => '', name => 'Sio', qual => 'o', qual_canon => 0, root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11, system => 'latin' }
