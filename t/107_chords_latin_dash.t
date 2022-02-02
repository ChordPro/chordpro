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

open( my $fd, '<', "t/105_chords.t" );
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
Do#7(-5)	{ ext => '7-5', ext_canon => '7-5', name => 'Do#7-5', qual => '', qual_canon => '', root => 'Do#', root_canon => 'Do#', root_mod => 1, root_ord => 1, system => 'latin' }
Mi7(-5)	{ ext => '7-5', ext_canon => '7-5', name => 'Mi7-5', qual => '', qual_canon => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'latin' }
Mi7-9	{ ext => '7-9', ext_canon => '7-9', name => 'Mi7-9', qual => '', qual_canon => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'latin' }
Fa#m7-5	{ ext => '7-5', ext_canon => '7-5', name => 'Fa#m7-5', qual => 'm', qual_canon => '-', root => 'Fa#', root_canon => 'Fa#', root_mod => 1, root_ord => 6, system => 'latin' }
Sol7-9	{ ext => '7-9', ext_canon => '7-9', name => 'Sol7-9', qual => '', qual_canon => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7, system => 'latin' }
Sim7-5	{ ext => '7-5', ext_canon => '7-5', name => 'Sim7-5', qual => 'm', qual_canon => '-', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11, system => 'latin' }
