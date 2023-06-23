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
Do	{ bass => '', ext => '', ext_canon => '', name => 'Do', qual => '', qual_canon => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'latin' }
Do+	{ bass => '', ext => '', ext_canon => '', name => 'Do+', qual => '+', qual_canon => '+', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'latin' }
Do4	{ bass => '', ext => 4, ext_canon => 4, name => 'Do4', qual => '', qual_canon => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'latin' }
Do6	{ bass => '', ext => 6, ext_canon => 6, name => 'Do6', qual => '', qual_canon => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'latin' }
Do7	{ bass => '', ext => 7, ext_canon => 7, name => 'Do7', qual => '', qual_canon => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'latin' }
Do9	{ bass => '', ext => 9, ext_canon => 9, name => 'Do9', qual => '', qual_canon => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'latin' }
Do9(11)	{ bass => '', ext => 911, ext_canon => 911, name => 'Do911', qual => '', qual_canon => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'latin' }
Do11	{ bass => '', ext => 11, ext_canon => 11, name => 'Do11', qual => '', qual_canon => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'latin' }
Dosus	{ bass => '', ext => 'sus', ext_canon => 'sus4', name => 'Dosus', qual => '', qual_canon => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'latin' }
Dosus2	{ bass => '', ext => 'sus2', ext_canon => 'sus2', name => 'Dosus2', qual => '', qual_canon => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'latin' }
Dosus4	{ bass => '', ext => 'sus4', ext_canon => 'sus4', name => 'Dosus4', qual => '', qual_canon => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'latin' }
Dosus9	{ bass => '', ext => 'sus9', ext_canon => 'sus9', name => 'Dosus9', qual => '', qual_canon => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'latin' }
Domaj	{ bass => '', ext => '', ext_canon => '', name => 'Domaj', qual => '', qual_canon => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'latin' }
Domaj7	{ bass => '', ext => 'maj7', ext_canon => 'maj7', name => 'Domaj7', qual => '', qual_canon => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'latin' }
Dom	{ bass => '', ext => '', ext_canon => '', name => 'Dom', qual => 'm', qual_canon => '-', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'latin' }
Domin	{ bass => '', ext => '', ext_canon => '', name => 'Domin', qual => 'min', qual_canon => '-', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'latin' }
Dodim	{ bass => '', ext => '', ext_canon => '', name => 'Dodim', qual => 'dim', qual_canon => 0, root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'latin' }
Do/Si	{ bass => 'Si', bass_canon => 'Si', bass_mod => 0, bass_ord => 11, ext => '', ext_canon => '', name => 'Do/Si', qual => '', qual_canon => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'latin' }
Doadd9	{ bass => '', ext => 'add9', ext_canon => 'add9', name => 'Doadd9', qual => '', qual_canon => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'latin' }
Do3	{ bass => '', ext => 3, ext_canon => 3, name => 'Do3', qual => '', qual_canon => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'latin' }
Dom7	{ bass => '', ext => 7, ext_canon => 7, name => 'Dom7', qual => 'm', qual_canon => '-', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'latin' }
Dom11	{ bass => '', ext => 11, ext_canon => 11, name => 'Dom11', qual => 'm', qual_canon => '-', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'latin' }
Do#	{ bass => '', ext => '', ext_canon => '', name => 'Do#', qual => '', qual_canon => '', root => 'Do#', root_canon => 'Do#', root_mod => 1, root_ord => 1, system => 'latin' }
Do#+	{ bass => '', ext => '', ext_canon => '', name => 'Do#+', qual => '+', qual_canon => '+', root => 'Do#', root_canon => 'Do#', root_mod => 1, root_ord => 1, system => 'latin' }
Do#4	{ bass => '', ext => 4, ext_canon => 4, name => 'Do#4', qual => '', qual_canon => '', root => 'Do#', root_canon => 'Do#', root_mod => 1, root_ord => 1, system => 'latin' }
Do#7	{ bass => '', ext => 7, ext_canon => 7, name => 'Do#7', qual => '', qual_canon => '', root => 'Do#', root_canon => 'Do#', root_mod => 1, root_ord => 1, system => 'latin' }
Do#7(b5)	{ bass => '', ext => '7b5', ext_canon => '7b5', name => 'Do#7b5', qual => '', qual_canon => '', root => 'Do#', root_canon => 'Do#', root_mod => 1, root_ord => 1, system => 'latin' }
Do#sus	{ bass => '', ext => 'sus', ext_canon => 'sus4', name => 'Do#sus', qual => '', qual_canon => '', root => 'Do#', root_canon => 'Do#', root_mod => 1, root_ord => 1, system => 'latin' }
Do#sus4	{ bass => '', ext => 'sus4', ext_canon => 'sus4', name => 'Do#sus4', qual => '', qual_canon => '', root => 'Do#', root_canon => 'Do#', root_mod => 1, root_ord => 1, system => 'latin' }
Do#maj	{ bass => '', ext => '', ext_canon => '', name => 'Do#maj', qual => '', qual_canon => '', root => 'Do#', root_canon => 'Do#', root_mod => 1, root_ord => 1, system => 'latin' }
Do#maj7	{ bass => '', ext => 'maj7', ext_canon => 'maj7', name => 'Do#maj7', qual => '', qual_canon => '', root => 'Do#', root_canon => 'Do#', root_mod => 1, root_ord => 1, system => 'latin' }
Do#dim	{ bass => '', ext => '', ext_canon => '', name => 'Do#dim', qual => 'dim', qual_canon => 0, root => 'Do#', root_canon => 'Do#', root_mod => 1, root_ord => 1, system => 'latin' }
Do#m	{ bass => '', ext => '', ext_canon => '', name => 'Do#m', qual => 'm', qual_canon => '-', root => 'Do#', root_canon => 'Do#', root_mod => 1, root_ord => 1, system => 'latin' }
Do#min	{ bass => '', ext => '', ext_canon => '', name => 'Do#min', qual => 'min', qual_canon => '-', root => 'Do#', root_canon => 'Do#', root_mod => 1, root_ord => 1, system => 'latin' }
Do#add9	{ bass => '', ext => 'add9', ext_canon => 'add9', name => 'Do#add9', qual => '', qual_canon => '', root => 'Do#', root_canon => 'Do#', root_mod => 1, root_ord => 1, system => 'latin' }
Do#(add9)	{ bass => '', ext => 'add9', ext_canon => 'add9', name => 'Do#add9', qual => '', qual_canon => '', root => 'Do#', root_canon => 'Do#', root_mod => 1, root_ord => 1, system => 'latin' }
Do#m7	{ bass => '', ext => 7, ext_canon => 7, name => 'Do#m7', qual => 'm', qual_canon => '-', root => 'Do#', root_canon => 'Do#', root_mod => 1, root_ord => 1, system => 'latin' }
Reb	{ bass => '', ext => '', ext_canon => '', name => 'Reb', qual => '', qual_canon => '', root => 'Reb', root_canon => 'Reb', root_mod => -1, root_ord => 1, system => 'latin' }
Reb+	{ bass => '', ext => '', ext_canon => '', name => 'Reb+', qual => '+', qual_canon => '+', root => 'Reb', root_canon => 'Reb', root_mod => -1, root_ord => 1, system => 'latin' }
Reb7	{ bass => '', ext => 7, ext_canon => 7, name => 'Reb7', qual => '', qual_canon => '', root => 'Reb', root_canon => 'Reb', root_mod => -1, root_ord => 1, system => 'latin' }
Rebsus	{ bass => '', ext => 'sus', ext_canon => 'sus4', name => 'Rebsus', qual => '', qual_canon => '', root => 'Reb', root_canon => 'Reb', root_mod => -1, root_ord => 1, system => 'latin' }
Rebsus4	{ bass => '', ext => 'sus4', ext_canon => 'sus4', name => 'Rebsus4', qual => '', qual_canon => '', root => 'Reb', root_canon => 'Reb', root_mod => -1, root_ord => 1, system => 'latin' }
Rebmaj	{ bass => '', ext => '', ext_canon => '', name => 'Rebmaj', qual => '', qual_canon => '', root => 'Reb', root_canon => 'Reb', root_mod => -1, root_ord => 1, system => 'latin' }
Rebmaj7	{ bass => '', ext => 'maj7', ext_canon => 'maj7', name => 'Rebmaj7', qual => '', qual_canon => '', root => 'Reb', root_canon => 'Reb', root_mod => -1, root_ord => 1, system => 'latin' }
Rebdim	{ bass => '', ext => '', ext_canon => '', name => 'Rebdim', qual => 'dim', qual_canon => 0, root => 'Reb', root_canon => 'Reb', root_mod => -1, root_ord => 1, system => 'latin' }
Rebm	{ bass => '', ext => '', ext_canon => '', name => 'Rebm', qual => 'm', qual_canon => '-', root => 'Reb', root_canon => 'Reb', root_mod => -1, root_ord => 1, system => 'latin' }
Rebmin	{ bass => '', ext => '', ext_canon => '', name => 'Rebmin', qual => 'min', qual_canon => '-', root => 'Reb', root_canon => 'Reb', root_mod => -1, root_ord => 1, system => 'latin' }
Rebm7	{ bass => '', ext => 7, ext_canon => 7, name => 'Rebm7', qual => 'm', qual_canon => '-', root => 'Reb', root_canon => 'Reb', root_mod => -1, root_ord => 1, system => 'latin' }
Re	{ bass => '', ext => '', ext_canon => '', name => 'Re', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'latin' }
Re+	{ bass => '', ext => '', ext_canon => '', name => 'Re+', qual => '+', qual_canon => '+', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'latin' }
Re4	{ bass => '', ext => 4, ext_canon => 4, name => 'Re4', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'latin' }
Re6	{ bass => '', ext => 6, ext_canon => 6, name => 'Re6', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'latin' }
Re7	{ bass => '', ext => 7, ext_canon => 7, name => 'Re7', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'latin' }
Re7#9	{ bass => '', ext => '7#9', ext_canon => '7#9', name => 'Re7#9', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'latin' }
Re7(#9)	{ bass => '', ext => '7#9', ext_canon => '7#9', name => 'Re7#9', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'latin' }
Re9	{ bass => '', ext => 9, ext_canon => 9, name => 'Re9', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'latin' }
Re11	{ bass => '', ext => 11, ext_canon => 11, name => 'Re11', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'latin' }
Resus	{ bass => '', ext => 'sus', ext_canon => 'sus4', name => 'Resus', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'latin' }
Resus2	{ bass => '', ext => 'sus2', ext_canon => 'sus2', name => 'Resus2', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'latin' }
Resus4	{ bass => '', ext => 'sus4', ext_canon => 'sus4', name => 'Resus4', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'latin' }
Re7sus2	{ bass => '', ext => '7sus2', ext_canon => '7sus2', name => 'Re7sus2', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'latin' }
Re7sus4	{ bass => '', ext => '7sus4', ext_canon => '7sus4', name => 'Re7sus4', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'latin' }
Remaj	{ bass => '', ext => '', ext_canon => '', name => 'Remaj', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'latin' }
Remaj7	{ bass => '', ext => 'maj7', ext_canon => 'maj7', name => 'Remaj7', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'latin' }
Redim	{ bass => '', ext => '', ext_canon => '', name => 'Redim', qual => 'dim', qual_canon => 0, root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'latin' }
Rem	{ bass => '', ext => '', ext_canon => '', name => 'Rem', qual => 'm', qual_canon => '-', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'latin' }
Remin	{ bass => '', ext => '', ext_canon => '', name => 'Remin', qual => 'min', qual_canon => '-', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'latin' }
Re/La	{ bass => 'La', bass_canon => 'La', bass_mod => 0, bass_ord => 9, ext => '', ext_canon => '', name => 'Re/La', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'latin' }
Re/Si	{ bass => 'Si', bass_canon => 'Si', bass_mod => 0, bass_ord => 11, ext => '', ext_canon => '', name => 'Re/Si', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'latin' }
Re/Do	{ bass => 'Do', bass_canon => 'Do', bass_mod => 0, bass_ord => 0, ext => '', ext_canon => '', name => 'Re/Do', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'latin' }
Re/Do#	{ bass => 'Do#', bass_canon => 'Do#', bass_mod => 1, bass_ord => 1, ext => '', ext_canon => '', name => 'Re/Do#', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'latin' }
Re/Mi	{ bass => 'Mi', bass_canon => 'Mi', bass_mod => 0, bass_ord => 4, ext => '', ext_canon => '', name => 'Re/Mi', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'latin' }
Re/Sol	{ bass => 'Sol', bass_canon => 'Sol', bass_mod => 0, bass_ord => 7, ext => '', ext_canon => '', name => 'Re/Sol', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'latin' }
Re5/Mi	{ bass => 'Mi', bass_canon => 'Mi', bass_mod => 0, bass_ord => 4, ext => 5, ext_canon => 5, name => 'Re5/Mi', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'latin' }
Readd9	{ bass => '', ext => 'add9', ext_canon => 'add9', name => 'Readd9', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'latin' }
Re9add6	{ bass => '', ext => '9add6', ext_canon => '9add6', name => 'Re9add6', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'latin' }
Rem7	{ bass => '', ext => 7, ext_canon => 7, name => 'Rem7', qual => 'm', qual_canon => '-', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'latin' }
Rem#5	{ bass => '', ext => '#5', ext_canon => '#5', name => 'Rem#5', qual => 'm', qual_canon => '-', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'latin' }
Rem#7	{ bass => '', ext => '#7', ext_canon => '#7', name => 'Rem#7', qual => 'm', qual_canon => '-', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'latin' }
Rem/La	{ bass => 'La', bass_canon => 'La', bass_mod => 0, bass_ord => 9, ext => '', ext_canon => '', name => 'Rem/La', qual => 'm', qual_canon => '-', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'latin' }
Rem/Si	{ bass => 'Si', bass_canon => 'Si', bass_mod => 0, bass_ord => 11, ext => '', ext_canon => '', name => 'Rem/Si', qual => 'm', qual_canon => '-', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'latin' }
Rem/Do	{ bass => 'Do', bass_canon => 'Do', bass_mod => 0, bass_ord => 0, ext => '', ext_canon => '', name => 'Rem/Do', qual => 'm', qual_canon => '-', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'latin' }
Rem/Do#	{ bass => 'Do#', bass_canon => 'Do#', bass_mod => 1, bass_ord => 1, ext => '', ext_canon => '', name => 'Rem/Do#', qual => 'm', qual_canon => '-', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'latin' }
Rem9	{ bass => '', ext => 9, ext_canon => 9, name => 'Rem9', qual => 'm', qual_canon => '-', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'latin' }
Re#	{ bass => '', ext => '', ext_canon => '', name => 'Re#', qual => '', qual_canon => '', root => 'Re#', root_canon => 'Re#', root_mod => 1, root_ord => 3, system => 'latin' }
Re#+	{ bass => '', ext => '', ext_canon => '', name => 'Re#+', qual => '+', qual_canon => '+', root => 'Re#', root_canon => 'Re#', root_mod => 1, root_ord => 3, system => 'latin' }
Re#4	{ bass => '', ext => 4, ext_canon => 4, name => 'Re#4', qual => '', qual_canon => '', root => 'Re#', root_canon => 'Re#', root_mod => 1, root_ord => 3, system => 'latin' }
Re#7	{ bass => '', ext => 7, ext_canon => 7, name => 'Re#7', qual => '', qual_canon => '', root => 'Re#', root_canon => 'Re#', root_mod => 1, root_ord => 3, system => 'latin' }
Re#sus	{ bass => '', ext => 'sus', ext_canon => 'sus4', name => 'Re#sus', qual => '', qual_canon => '', root => 'Re#', root_canon => 'Re#', root_mod => 1, root_ord => 3, system => 'latin' }
Re#sus4	{ bass => '', ext => 'sus4', ext_canon => 'sus4', name => 'Re#sus4', qual => '', qual_canon => '', root => 'Re#', root_canon => 'Re#', root_mod => 1, root_ord => 3, system => 'latin' }
Re#maj	{ bass => '', ext => '', ext_canon => '', name => 'Re#maj', qual => '', qual_canon => '', root => 'Re#', root_canon => 'Re#', root_mod => 1, root_ord => 3, system => 'latin' }
Re#maj7	{ bass => '', ext => 'maj7', ext_canon => 'maj7', name => 'Re#maj7', qual => '', qual_canon => '', root => 'Re#', root_canon => 'Re#', root_mod => 1, root_ord => 3, system => 'latin' }
Re#dim	{ bass => '', ext => '', ext_canon => '', name => 'Re#dim', qual => 'dim', qual_canon => 0, root => 'Re#', root_canon => 'Re#', root_mod => 1, root_ord => 3, system => 'latin' }
Re#m	{ bass => '', ext => '', ext_canon => '', name => 'Re#m', qual => 'm', qual_canon => '-', root => 'Re#', root_canon => 'Re#', root_mod => 1, root_ord => 3, system => 'latin' }
Re#min	{ bass => '', ext => '', ext_canon => '', name => 'Re#min', qual => 'min', qual_canon => '-', root => 'Re#', root_canon => 'Re#', root_mod => 1, root_ord => 3, system => 'latin' }
Re#m7	{ bass => '', ext => 7, ext_canon => 7, name => 'Re#m7', qual => 'm', qual_canon => '-', root => 'Re#', root_canon => 'Re#', root_mod => 1, root_ord => 3, system => 'latin' }
Mib	{ bass => '', ext => '', ext_canon => '', name => 'Mib', qual => '', qual_canon => '', root => 'Mib', root_canon => 'Mib', root_mod => -1, root_ord => 3, system => 'latin' }
Mib+	{ bass => '', ext => '', ext_canon => '', name => 'Mib+', qual => '+', qual_canon => '+', root => 'Mib', root_canon => 'Mib', root_mod => -1, root_ord => 3, system => 'latin' }
Mib4	{ bass => '', ext => 4, ext_canon => 4, name => 'Mib4', qual => '', qual_canon => '', root => 'Mib', root_canon => 'Mib', root_mod => -1, root_ord => 3, system => 'latin' }
Mib7	{ bass => '', ext => 7, ext_canon => 7, name => 'Mib7', qual => '', qual_canon => '', root => 'Mib', root_canon => 'Mib', root_mod => -1, root_ord => 3, system => 'latin' }
Mibsus	{ bass => '', ext => 'sus', ext_canon => 'sus4', name => 'Mibsus', qual => '', qual_canon => '', root => 'Mib', root_canon => 'Mib', root_mod => -1, root_ord => 3, system => 'latin' }
Mibsus4	{ bass => '', ext => 'sus4', ext_canon => 'sus4', name => 'Mibsus4', qual => '', qual_canon => '', root => 'Mib', root_canon => 'Mib', root_mod => -1, root_ord => 3, system => 'latin' }
Mibmaj	{ bass => '', ext => '', ext_canon => '', name => 'Mibmaj', qual => '', qual_canon => '', root => 'Mib', root_canon => 'Mib', root_mod => -1, root_ord => 3, system => 'latin' }
Mibmaj7	{ bass => '', ext => 'maj7', ext_canon => 'maj7', name => 'Mibmaj7', qual => '', qual_canon => '', root => 'Mib', root_canon => 'Mib', root_mod => -1, root_ord => 3, system => 'latin' }
Mibdim	{ bass => '', ext => '', ext_canon => '', name => 'Mibdim', qual => 'dim', qual_canon => 0, root => 'Mib', root_canon => 'Mib', root_mod => -1, root_ord => 3, system => 'latin' }
Mibadd9	{ bass => '', ext => 'add9', ext_canon => 'add9', name => 'Mibadd9', qual => '', qual_canon => '', root => 'Mib', root_canon => 'Mib', root_mod => -1, root_ord => 3, system => 'latin' }
Mib(add9)	{ bass => '', ext => 'add9', ext_canon => 'add9', name => 'Mibadd9', qual => '', qual_canon => '', root => 'Mib', root_canon => 'Mib', root_mod => -1, root_ord => 3, system => 'latin' }
Mibm	{ bass => '', ext => '', ext_canon => '', name => 'Mibm', qual => 'm', qual_canon => '-', root => 'Mib', root_canon => 'Mib', root_mod => -1, root_ord => 3, system => 'latin' }
Mibmin	{ bass => '', ext => '', ext_canon => '', name => 'Mibmin', qual => 'min', qual_canon => '-', root => 'Mib', root_canon => 'Mib', root_mod => -1, root_ord => 3, system => 'latin' }
Mibm7	{ bass => '', ext => 7, ext_canon => 7, name => 'Mibm7', qual => 'm', qual_canon => '-', root => 'Mib', root_canon => 'Mib', root_mod => -1, root_ord => 3, system => 'latin' }
Mi	{ bass => '', ext => '', ext_canon => '', name => 'Mi', qual => '', qual_canon => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'latin' }
Mi+	{ bass => '', ext => '', ext_canon => '', name => 'Mi+', qual => '+', qual_canon => '+', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'latin' }
Mi5	{ bass => '', ext => 5, ext_canon => 5, name => 'Mi5', qual => '', qual_canon => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'latin' }
Mi6	{ bass => '', ext => 6, ext_canon => 6, name => 'Mi6', qual => '', qual_canon => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'latin' }
Mi7	{ bass => '', ext => 7, ext_canon => 7, name => 'Mi7', qual => '', qual_canon => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'latin' }
Mi7#9	{ bass => '', ext => '7#9', ext_canon => '7#9', name => 'Mi7#9', qual => '', qual_canon => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'latin' }
Mi7(#9)	{ bass => '', ext => '7#9', ext_canon => '7#9', name => 'Mi7#9', qual => '', qual_canon => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'latin' }
Mi7(b5)	{ bass => '', ext => '7b5', ext_canon => '7b5', name => 'Mi7b5', qual => '', qual_canon => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'latin' }
Mi7b9	{ bass => '', ext => '7b9', ext_canon => '7b9', name => 'Mi7b9', qual => '', qual_canon => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'latin' }
Mi7(11)	{ bass => '', ext => 711, ext_canon => 711, name => 'Mi711', qual => '', qual_canon => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'latin' }
Mi9	{ bass => '', ext => 9, ext_canon => 9, name => 'Mi9', qual => '', qual_canon => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'latin' }
Mi11	{ bass => '', ext => 11, ext_canon => 11, name => 'Mi11', qual => '', qual_canon => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'latin' }
Misus	{ bass => '', ext => 'sus', ext_canon => 'sus4', name => 'Misus', qual => '', qual_canon => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'latin' }
Mimaj	{ bass => '', ext => '', ext_canon => '', name => 'Mimaj', qual => '', qual_canon => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'latin' }
Mimaj7	{ bass => '', ext => 'maj7', ext_canon => 'maj7', name => 'Mimaj7', qual => '', qual_canon => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'latin' }
Midim	{ bass => '', ext => '', ext_canon => '', name => 'Midim', qual => 'dim', qual_canon => 0, root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'latin' }
Mim	{ bass => '', ext => '', ext_canon => '', name => 'Mim', qual => 'm', qual_canon => '-', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'latin' }
Mimin	{ bass => '', ext => '', ext_canon => '', name => 'Mimin', qual => 'min', qual_canon => '-', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'latin' }
Mim6	{ bass => '', ext => 6, ext_canon => 6, name => 'Mim6', qual => 'm', qual_canon => '-', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'latin' }
Mim7	{ bass => '', ext => 7, ext_canon => 7, name => 'Mim7', qual => 'm', qual_canon => '-', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'latin' }
Mim/Si	{ bass => 'Si', bass_canon => 'Si', bass_mod => 0, bass_ord => 11, ext => '', ext_canon => '', name => 'Mim/Si', qual => 'm', qual_canon => '-', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'latin' }
Mim/Re	{ bass => 'Re', bass_canon => 'Re', bass_mod => 0, bass_ord => 2, ext => '', ext_canon => '', name => 'Mim/Re', qual => 'm', qual_canon => '-', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'latin' }
Mim7/Re	{ bass => 'Re', bass_canon => 'Re', bass_mod => 0, bass_ord => 2, ext => 7, ext_canon => 7, name => 'Mim7/Re', qual => 'm', qual_canon => '-', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'latin' }
Mimsus4	{ bass => '', ext => 'sus4', ext_canon => 'sus4', name => 'Mimsus4', qual => 'm', qual_canon => '-', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'latin' }
Mimadd9	{ bass => '', ext => 'add9', ext_canon => 'add9', name => 'Mimadd9', qual => 'm', qual_canon => '-', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'latin' }
Fa	{ bass => '', ext => '', ext_canon => '', name => 'Fa', qual => '', qual_canon => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'latin' }
Fa+	{ bass => '', ext => '', ext_canon => '', name => 'Fa+', qual => '+', qual_canon => '+', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'latin' }
Fa4	{ bass => '', ext => 4, ext_canon => 4, name => 'Fa4', qual => '', qual_canon => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'latin' }
Fa6	{ bass => '', ext => 6, ext_canon => 6, name => 'Fa6', qual => '', qual_canon => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'latin' }
Fa7	{ bass => '', ext => 7, ext_canon => 7, name => 'Fa7', qual => '', qual_canon => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'latin' }
Fa9	{ bass => '', ext => 9, ext_canon => 9, name => 'Fa9', qual => '', qual_canon => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'latin' }
Fa11	{ bass => '', ext => 11, ext_canon => 11, name => 'Fa11', qual => '', qual_canon => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'latin' }
Fasus	{ bass => '', ext => 'sus', ext_canon => 'sus4', name => 'Fasus', qual => '', qual_canon => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'latin' }
Fasus4	{ bass => '', ext => 'sus4', ext_canon => 'sus4', name => 'Fasus4', qual => '', qual_canon => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'latin' }
Famaj	{ bass => '', ext => '', ext_canon => '', name => 'Famaj', qual => '', qual_canon => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'latin' }
Famaj7	{ bass => '', ext => 'maj7', ext_canon => 'maj7', name => 'Famaj7', qual => '', qual_canon => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'latin' }
Fadim	{ bass => '', ext => '', ext_canon => '', name => 'Fadim', qual => 'dim', qual_canon => 0, root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'latin' }
Fam	{ bass => '', ext => '', ext_canon => '', name => 'Fam', qual => 'm', qual_canon => '-', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'latin' }
Famin	{ bass => '', ext => '', ext_canon => '', name => 'Famin', qual => 'min', qual_canon => '-', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'latin' }
Fa/La	{ bass => 'La', bass_canon => 'La', bass_mod => 0, bass_ord => 9, ext => '', ext_canon => '', name => 'Fa/La', qual => '', qual_canon => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'latin' }
Fa/Do	{ bass => 'Do', bass_canon => 'Do', bass_mod => 0, bass_ord => 0, ext => '', ext_canon => '', name => 'Fa/Do', qual => '', qual_canon => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'latin' }
Fa/Re	{ bass => 'Re', bass_canon => 'Re', bass_mod => 0, bass_ord => 2, ext => '', ext_canon => '', name => 'Fa/Re', qual => '', qual_canon => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'latin' }
Fa/Sol	{ bass => 'Sol', bass_canon => 'Sol', bass_mod => 0, bass_ord => 7, ext => '', ext_canon => '', name => 'Fa/Sol', qual => '', qual_canon => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'latin' }
Fa7/La	{ bass => 'La', bass_canon => 'La', bass_mod => 0, bass_ord => 9, ext => 7, ext_canon => 7, name => 'Fa7/La', qual => '', qual_canon => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'latin' }
Famaj7/La	{ bass => 'La', bass_canon => 'La', bass_mod => 0, bass_ord => 9, ext => 'maj7', ext_canon => 'maj7', name => 'Famaj7/La', qual => '', qual_canon => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'latin' }
Famaj7/Do	{ bass => 'Do', bass_canon => 'Do', bass_mod => 0, bass_ord => 0, ext => 'maj7', ext_canon => 'maj7', name => 'Famaj7/Do', qual => '', qual_canon => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'latin' }
Faadd9	{ bass => '', ext => 'add9', ext_canon => 'add9', name => 'Faadd9', qual => '', qual_canon => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'latin' }
Fam6	{ bass => '', ext => 6, ext_canon => 6, name => 'Fam6', qual => 'm', qual_canon => '-', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'latin' }
Fam7	{ bass => '', ext => 7, ext_canon => 7, name => 'Fam7', qual => 'm', qual_canon => '-', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'latin' }
Fammaj7	{ bass => '', ext => 'maj7', ext_canon => 'maj7', name => 'Fammaj7', qual => 'm', qual_canon => '-', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'latin' }
Fa#	{ bass => '', ext => '', ext_canon => '', name => 'Fa#', qual => '', qual_canon => '', root => 'Fa#', root_canon => 'Fa#', root_mod => 1, root_ord => 6, system => 'latin' }
Fa#+	{ bass => '', ext => '', ext_canon => '', name => 'Fa#+', qual => '+', qual_canon => '+', root => 'Fa#', root_canon => 'Fa#', root_mod => 1, root_ord => 6, system => 'latin' }
Fa#7	{ bass => '', ext => 7, ext_canon => 7, name => 'Fa#7', qual => '', qual_canon => '', root => 'Fa#', root_canon => 'Fa#', root_mod => 1, root_ord => 6, system => 'latin' }
Fa#9	{ bass => '', ext => 9, ext_canon => 9, name => 'Fa#9', qual => '', qual_canon => '', root => 'Fa#', root_canon => 'Fa#', root_mod => 1, root_ord => 6, system => 'latin' }
Fa#11	{ bass => '', ext => 11, ext_canon => 11, name => 'Fa#11', qual => '', qual_canon => '', root => 'Fa#', root_canon => 'Fa#', root_mod => 1, root_ord => 6, system => 'latin' }
Fa#sus	{ bass => '', ext => 'sus', ext_canon => 'sus4', name => 'Fa#sus', qual => '', qual_canon => '', root => 'Fa#', root_canon => 'Fa#', root_mod => 1, root_ord => 6, system => 'latin' }
Fa#sus4	{ bass => '', ext => 'sus4', ext_canon => 'sus4', name => 'Fa#sus4', qual => '', qual_canon => '', root => 'Fa#', root_canon => 'Fa#', root_mod => 1, root_ord => 6, system => 'latin' }
Fa#maj7	{ bass => '', ext => 'maj7', ext_canon => 'maj7', name => 'Fa#maj7', qual => '', qual_canon => '', root => 'Fa#', root_canon => 'Fa#', root_mod => 1, root_ord => 6, system => 'latin' }
Fa#dim	{ bass => '', ext => '', ext_canon => '', name => 'Fa#dim', qual => 'dim', qual_canon => 0, root => 'Fa#', root_canon => 'Fa#', root_mod => 1, root_ord => 6, system => 'latin' }
Fa#m	{ bass => '', ext => '', ext_canon => '', name => 'Fa#m', qual => 'm', qual_canon => '-', root => 'Fa#', root_canon => 'Fa#', root_mod => 1, root_ord => 6, system => 'latin' }
Fa#min	{ bass => '', ext => '', ext_canon => '', name => 'Fa#min', qual => 'min', qual_canon => '-', root => 'Fa#', root_canon => 'Fa#', root_mod => 1, root_ord => 6, system => 'latin' }
Fa#/Mi	{ bass => 'Mi', bass_canon => 'Mi', bass_mod => 0, bass_ord => 4, ext => '', ext_canon => '', name => 'Fa#/Mi', qual => '', qual_canon => '', root => 'Fa#', root_canon => 'Fa#', root_mod => 1, root_ord => 6, system => 'latin' }
Fa#4	{ bass => '', ext => 4, ext_canon => 4, name => 'Fa#4', qual => '', qual_canon => '', root => 'Fa#', root_canon => 'Fa#', root_mod => 1, root_ord => 6, system => 'latin' }
Fa#m6	{ bass => '', ext => 6, ext_canon => 6, name => 'Fa#m6', qual => 'm', qual_canon => '-', root => 'Fa#', root_canon => 'Fa#', root_mod => 1, root_ord => 6, system => 'latin' }
Fa#m7	{ bass => '', ext => 7, ext_canon => 7, name => 'Fa#m7', qual => 'm', qual_canon => '-', root => 'Fa#', root_canon => 'Fa#', root_mod => 1, root_ord => 6, system => 'latin' }
Fa#m7b5	{ bass => '', ext => '7b5', ext_canon => '7b5', name => 'Fa#m7b5', qual => 'm', qual_canon => '-', root => 'Fa#', root_canon => 'Fa#', root_mod => 1, root_ord => 6, system => 'latin' }
Fa#m/Do	{ bass => 'Do', bass_canon => 'Do', bass_mod => 0, bass_ord => 0, ext => '', ext_canon => '', name => 'Fa#m/Do', qual => 'm', qual_canon => '-', root => 'Fa#', root_canon => 'Fa#', root_mod => 1, root_ord => 6, system => 'latin' }
Solb	{ bass => '', ext => '', ext_canon => '', name => 'Solb', qual => '', qual_canon => '', root => 'Solb', root_canon => 'Solb', root_mod => -1, root_ord => 6, system => 'latin' }
Solb+	{ bass => '', ext => '', ext_canon => '', name => 'Solb+', qual => '+', qual_canon => '+', root => 'Solb', root_canon => 'Solb', root_mod => -1, root_ord => 6, system => 'latin' }
Solb7	{ bass => '', ext => 7, ext_canon => 7, name => 'Solb7', qual => '', qual_canon => '', root => 'Solb', root_canon => 'Solb', root_mod => -1, root_ord => 6, system => 'latin' }
Solb9	{ bass => '', ext => 9, ext_canon => 9, name => 'Solb9', qual => '', qual_canon => '', root => 'Solb', root_canon => 'Solb', root_mod => -1, root_ord => 6, system => 'latin' }
Solbsus	{ bass => '', ext => 'sus', ext_canon => 'sus4', name => 'Solbsus', qual => '', qual_canon => '', root => 'Solb', root_canon => 'Solb', root_mod => -1, root_ord => 6, system => 'latin' }
Solbsus4	{ bass => '', ext => 'sus4', ext_canon => 'sus4', name => 'Solbsus4', qual => '', qual_canon => '', root => 'Solb', root_canon => 'Solb', root_mod => -1, root_ord => 6, system => 'latin' }
Solbmaj	{ bass => '', ext => '', ext_canon => '', name => 'Solbmaj', qual => '', qual_canon => '', root => 'Solb', root_canon => 'Solb', root_mod => -1, root_ord => 6, system => 'latin' }
Solbmaj7	{ bass => '', ext => 'maj7', ext_canon => 'maj7', name => 'Solbmaj7', qual => '', qual_canon => '', root => 'Solb', root_canon => 'Solb', root_mod => -1, root_ord => 6, system => 'latin' }
Solbdim	{ bass => '', ext => '', ext_canon => '', name => 'Solbdim', qual => 'dim', qual_canon => 0, root => 'Solb', root_canon => 'Solb', root_mod => -1, root_ord => 6, system => 'latin' }
Solbm	{ bass => '', ext => '', ext_canon => '', name => 'Solbm', qual => 'm', qual_canon => '-', root => 'Solb', root_canon => 'Solb', root_mod => -1, root_ord => 6, system => 'latin' }
Solbmin	{ bass => '', ext => '', ext_canon => '', name => 'Solbmin', qual => 'min', qual_canon => '-', root => 'Solb', root_canon => 'Solb', root_mod => -1, root_ord => 6, system => 'latin' }
Solbm7	{ bass => '', ext => 7, ext_canon => 7, name => 'Solbm7', qual => 'm', qual_canon => '-', root => 'Solb', root_canon => 'Solb', root_mod => -1, root_ord => 6, system => 'latin' }
Sol	{ bass => '', ext => '', ext_canon => '', name => 'Sol', qual => '', qual_canon => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7, system => 'latin' }
Sol+	{ bass => '', ext => '', ext_canon => '', name => 'Sol+', qual => '+', qual_canon => '+', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7, system => 'latin' }
Sol4	{ bass => '', ext => 4, ext_canon => 4, name => 'Sol4', qual => '', qual_canon => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7, system => 'latin' }
Sol6	{ bass => '', ext => 6, ext_canon => 6, name => 'Sol6', qual => '', qual_canon => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7, system => 'latin' }
Sol7	{ bass => '', ext => 7, ext_canon => 7, name => 'Sol7', qual => '', qual_canon => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7, system => 'latin' }
Sol7b9	{ bass => '', ext => '7b9', ext_canon => '7b9', name => 'Sol7b9', qual => '', qual_canon => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7, system => 'latin' }
Sol7#9	{ bass => '', ext => '7#9', ext_canon => '7#9', name => 'Sol7#9', qual => '', qual_canon => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7, system => 'latin' }
Sol9	{ bass => '', ext => 9, ext_canon => 9, name => 'Sol9', qual => '', qual_canon => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7, system => 'latin' }
Sol9(11)	{ bass => '', ext => 911, ext_canon => 911, name => 'Sol911', qual => '', qual_canon => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7, system => 'latin' }
Sol11	{ bass => '', ext => 11, ext_canon => 11, name => 'Sol11', qual => '', qual_canon => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7, system => 'latin' }
Solsus	{ bass => '', ext => 'sus', ext_canon => 'sus4', name => 'Solsus', qual => '', qual_canon => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7, system => 'latin' }
Solsus4	{ bass => '', ext => 'sus4', ext_canon => 'sus4', name => 'Solsus4', qual => '', qual_canon => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7, system => 'latin' }
Sol6sus4	{ bass => '', ext => '6sus4', ext_canon => '6sus4', name => 'Sol6sus4', qual => '', qual_canon => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7, system => 'latin' }
Sol7sus4	{ bass => '', ext => '7sus4', ext_canon => '7sus4', name => 'Sol7sus4', qual => '', qual_canon => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7, system => 'latin' }
Solmaj	{ bass => '', ext => '', ext_canon => '', name => 'Solmaj', qual => '', qual_canon => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7, system => 'latin' }
Solmaj7	{ bass => '', ext => 'maj7', ext_canon => 'maj7', name => 'Solmaj7', qual => '', qual_canon => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7, system => 'latin' }
Solmaj7sus4	{ bass => '', ext => 'maj7sus4', ext_canon => 'maj7sus4', name => 'Solmaj7sus4', qual => '', qual_canon => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7, system => 'latin' }
Solmaj9	{ bass => '', ext => 'maj9', ext_canon => 'maj9', name => 'Solmaj9', qual => '', qual_canon => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7, system => 'latin' }
Solm	{ bass => '', ext => '', ext_canon => '', name => 'Solm', qual => 'm', qual_canon => '-', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7, system => 'latin' }
Solmin	{ bass => '', ext => '', ext_canon => '', name => 'Solmin', qual => 'min', qual_canon => '-', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7, system => 'latin' }
Soldim	{ bass => '', ext => '', ext_canon => '', name => 'Soldim', qual => 'dim', qual_canon => 0, root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7, system => 'latin' }
Soladd9	{ bass => '', ext => 'add9', ext_canon => 'add9', name => 'Soladd9', qual => '', qual_canon => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7, system => 'latin' }
Sol(add9)	{ bass => '', ext => 'add9', ext_canon => 'add9', name => 'Soladd9', qual => '', qual_canon => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7, system => 'latin' }
Sol/La	{ bass => 'La', bass_canon => 'La', bass_mod => 0, bass_ord => 9, ext => '', ext_canon => '', name => 'Sol/La', qual => '', qual_canon => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7, system => 'latin' }
Sol/Si	{ bass => 'Si', bass_canon => 'Si', bass_mod => 0, bass_ord => 11, ext => '', ext_canon => '', name => 'Sol/Si', qual => '', qual_canon => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7, system => 'latin' }
Sol/Re	{ bass => 'Re', bass_canon => 'Re', bass_mod => 0, bass_ord => 2, ext => '', ext_canon => '', name => 'Sol/Re', qual => '', qual_canon => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7, system => 'latin' }
Sol/Fa#	{ bass => 'Fa#', bass_canon => 'Fa#', bass_mod => 1, bass_ord => 6, ext => '', ext_canon => '', name => 'Sol/Fa#', qual => '', qual_canon => '', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7, system => 'latin' }
Solm6	{ bass => '', ext => 6, ext_canon => 6, name => 'Solm6', qual => 'm', qual_canon => '-', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7, system => 'latin' }
Solm7	{ bass => '', ext => 7, ext_canon => 7, name => 'Solm7', qual => 'm', qual_canon => '-', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7, system => 'latin' }
Solm/Sib	{ bass => 'Sib', bass_canon => 'Sib', bass_mod => -1, bass_ord => 10, ext => '', ext_canon => '', name => 'Solm/Sib', qual => 'm', qual_canon => '-', root => 'Sol', root_canon => 'Sol', root_mod => 0, root_ord => 7, system => 'latin' }
Sol#	{ bass => '', ext => '', ext_canon => '', name => 'Sol#', qual => '', qual_canon => '', root => 'Sol#', root_canon => 'Sol#', root_mod => 1, root_ord => 8, system => 'latin' }
Sol#+	{ bass => '', ext => '', ext_canon => '', name => 'Sol#+', qual => '+', qual_canon => '+', root => 'Sol#', root_canon => 'Sol#', root_mod => 1, root_ord => 8, system => 'latin' }
Sol#4	{ bass => '', ext => 4, ext_canon => 4, name => 'Sol#4', qual => '', qual_canon => '', root => 'Sol#', root_canon => 'Sol#', root_mod => 1, root_ord => 8, system => 'latin' }
Sol#7	{ bass => '', ext => 7, ext_canon => 7, name => 'Sol#7', qual => '', qual_canon => '', root => 'Sol#', root_canon => 'Sol#', root_mod => 1, root_ord => 8, system => 'latin' }
Sol#sus	{ bass => '', ext => 'sus', ext_canon => 'sus4', name => 'Sol#sus', qual => '', qual_canon => '', root => 'Sol#', root_canon => 'Sol#', root_mod => 1, root_ord => 8, system => 'latin' }
Sol#sus4	{ bass => '', ext => 'sus4', ext_canon => 'sus4', name => 'Sol#sus4', qual => '', qual_canon => '', root => 'Sol#', root_canon => 'Sol#', root_mod => 1, root_ord => 8, system => 'latin' }
Sol#maj	{ bass => '', ext => '', ext_canon => '', name => 'Sol#maj', qual => '', qual_canon => '', root => 'Sol#', root_canon => 'Sol#', root_mod => 1, root_ord => 8, system => 'latin' }
Sol#maj7	{ bass => '', ext => 'maj7', ext_canon => 'maj7', name => 'Sol#maj7', qual => '', qual_canon => '', root => 'Sol#', root_canon => 'Sol#', root_mod => 1, root_ord => 8, system => 'latin' }
Sol#dim	{ bass => '', ext => '', ext_canon => '', name => 'Sol#dim', qual => 'dim', qual_canon => 0, root => 'Sol#', root_canon => 'Sol#', root_mod => 1, root_ord => 8, system => 'latin' }
Sol#m	{ bass => '', ext => '', ext_canon => '', name => 'Sol#m', qual => 'm', qual_canon => '-', root => 'Sol#', root_canon => 'Sol#', root_mod => 1, root_ord => 8, system => 'latin' }
Sol#min	{ bass => '', ext => '', ext_canon => '', name => 'Sol#min', qual => 'min', qual_canon => '-', root => 'Sol#', root_canon => 'Sol#', root_mod => 1, root_ord => 8, system => 'latin' }
Sol#m6	{ bass => '', ext => 6, ext_canon => 6, name => 'Sol#m6', qual => 'm', qual_canon => '-', root => 'Sol#', root_canon => 'Sol#', root_mod => 1, root_ord => 8, system => 'latin' }
Sol#m7	{ bass => '', ext => 7, ext_canon => 7, name => 'Sol#m7', qual => 'm', qual_canon => '-', root => 'Sol#', root_canon => 'Sol#', root_mod => 1, root_ord => 8, system => 'latin' }
Sol#m9maj7	{ bass => '', ext => '9maj7', ext_canon => '9maj7', name => 'Sol#m9maj7', qual => 'm', qual_canon => '-', root => 'Sol#', root_canon => 'Sol#', root_mod => 1, root_ord => 8, system => 'latin' }
Lab	{ bass => '', ext => '', ext_canon => '', name => 'Lab', qual => '', qual_canon => '', root => 'Lab', root_canon => 'Lab', root_mod => -1, root_ord => 8, system => 'latin' }
Lab+	{ bass => '', ext => '', ext_canon => '', name => 'Lab+', qual => '+', qual_canon => '+', root => 'Lab', root_canon => 'Lab', root_mod => -1, root_ord => 8, system => 'latin' }
Lab4	{ bass => '', ext => 4, ext_canon => 4, name => 'Lab4', qual => '', qual_canon => '', root => 'Lab', root_canon => 'Lab', root_mod => -1, root_ord => 8, system => 'latin' }
Lab7	{ bass => '', ext => 7, ext_canon => 7, name => 'Lab7', qual => '', qual_canon => '', root => 'Lab', root_canon => 'Lab', root_mod => -1, root_ord => 8, system => 'latin' }
Lab11	{ bass => '', ext => 11, ext_canon => 11, name => 'Lab11', qual => '', qual_canon => '', root => 'Lab', root_canon => 'Lab', root_mod => -1, root_ord => 8, system => 'latin' }
Labsus	{ bass => '', ext => 'sus', ext_canon => 'sus4', name => 'Labsus', qual => '', qual_canon => '', root => 'Lab', root_canon => 'Lab', root_mod => -1, root_ord => 8, system => 'latin' }
Labsus4	{ bass => '', ext => 'sus4', ext_canon => 'sus4', name => 'Labsus4', qual => '', qual_canon => '', root => 'Lab', root_canon => 'Lab', root_mod => -1, root_ord => 8, system => 'latin' }
Labdim	{ bass => '', ext => '', ext_canon => '', name => 'Labdim', qual => 'dim', qual_canon => 0, root => 'Lab', root_canon => 'Lab', root_mod => -1, root_ord => 8, system => 'latin' }
Labmaj	{ bass => '', ext => '', ext_canon => '', name => 'Labmaj', qual => '', qual_canon => '', root => 'Lab', root_canon => 'Lab', root_mod => -1, root_ord => 8, system => 'latin' }
Labmaj7	{ bass => '', ext => 'maj7', ext_canon => 'maj7', name => 'Labmaj7', qual => '', qual_canon => '', root => 'Lab', root_canon => 'Lab', root_mod => -1, root_ord => 8, system => 'latin' }
Labm	{ bass => '', ext => '', ext_canon => '', name => 'Labm', qual => 'm', qual_canon => '-', root => 'Lab', root_canon => 'Lab', root_mod => -1, root_ord => 8, system => 'latin' }
Labmin	{ bass => '', ext => '', ext_canon => '', name => 'Labmin', qual => 'min', qual_canon => '-', root => 'Lab', root_canon => 'Lab', root_mod => -1, root_ord => 8, system => 'latin' }
Labm7	{ bass => '', ext => 7, ext_canon => 7, name => 'Labm7', qual => 'm', qual_canon => '-', root => 'Lab', root_canon => 'Lab', root_mod => -1, root_ord => 8, system => 'latin' }
La	{ bass => '', ext => '', ext_canon => '', name => 'La', qual => '', qual_canon => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'latin' }
La+	{ bass => '', ext => '', ext_canon => '', name => 'La+', qual => '+', qual_canon => '+', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'latin' }
La4	{ bass => '', ext => 4, ext_canon => 4, name => 'La4', qual => '', qual_canon => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'latin' }
La6	{ bass => '', ext => 6, ext_canon => 6, name => 'La6', qual => '', qual_canon => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'latin' }
La7	{ bass => '', ext => 7, ext_canon => 7, name => 'La7', qual => '', qual_canon => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'latin' }
La9	{ bass => '', ext => 9, ext_canon => 9, name => 'La9', qual => '', qual_canon => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'latin' }
La11	{ bass => '', ext => 11, ext_canon => 11, name => 'La11', qual => '', qual_canon => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'latin' }
La13	{ bass => '', ext => 13, ext_canon => 13, name => 'La13', qual => '', qual_canon => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'latin' }
La7sus4	{ bass => '', ext => '7sus4', ext_canon => '7sus4', name => 'La7sus4', qual => '', qual_canon => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'latin' }
La9sus	{ bass => '', ext => '9sus', ext_canon => '9sus', name => 'La9sus', qual => '', qual_canon => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'latin' }
Lasus	{ bass => '', ext => 'sus', ext_canon => 'sus4', name => 'Lasus', qual => '', qual_canon => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'latin' }
Lasus2	{ bass => '', ext => 'sus2', ext_canon => 'sus2', name => 'Lasus2', qual => '', qual_canon => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'latin' }
Lasus4	{ bass => '', ext => 'sus4', ext_canon => 'sus4', name => 'Lasus4', qual => '', qual_canon => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'latin' }
Ladim	{ bass => '', ext => '', ext_canon => '', name => 'Ladim', qual => 'dim', qual_canon => 0, root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'latin' }
Lamaj	{ bass => '', ext => '', ext_canon => '', name => 'Lamaj', qual => '', qual_canon => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'latin' }
Lamaj7	{ bass => '', ext => 'maj7', ext_canon => 'maj7', name => 'Lamaj7', qual => '', qual_canon => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'latin' }
Lam	{ bass => '', ext => '', ext_canon => '', name => 'Lam', qual => 'm', qual_canon => '-', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'latin' }
Lamin	{ bass => '', ext => '', ext_canon => '', name => 'Lamin', qual => 'min', qual_canon => '-', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'latin' }
La/Do#	{ bass => 'Do#', bass_canon => 'Do#', bass_mod => 1, bass_ord => 1, ext => '', ext_canon => '', name => 'La/Do#', qual => '', qual_canon => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'latin' }
La/Re	{ bass => 'Re', bass_canon => 'Re', bass_mod => 0, bass_ord => 2, ext => '', ext_canon => '', name => 'La/Re', qual => '', qual_canon => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'latin' }
La/Mi	{ bass => 'Mi', bass_canon => 'Mi', bass_mod => 0, bass_ord => 4, ext => '', ext_canon => '', name => 'La/Mi', qual => '', qual_canon => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'latin' }
La/Fa#	{ bass => 'Fa#', bass_canon => 'Fa#', bass_mod => 1, bass_ord => 6, ext => '', ext_canon => '', name => 'La/Fa#', qual => '', qual_canon => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'latin' }
La/Sol#	{ bass => 'Sol#', bass_canon => 'Sol#', bass_mod => 1, bass_ord => 8, ext => '', ext_canon => '', name => 'La/Sol#', qual => '', qual_canon => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'latin' }
Lam#7	{ bass => '', ext => '#7', ext_canon => '#7', name => 'Lam#7', qual => 'm', qual_canon => '-', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'latin' }
Lam6	{ bass => '', ext => 6, ext_canon => 6, name => 'Lam6', qual => 'm', qual_canon => '-', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'latin' }
Lam7	{ bass => '', ext => 7, ext_canon => 7, name => 'Lam7', qual => 'm', qual_canon => '-', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'latin' }
Lam7sus4	{ bass => '', ext => '7sus4', ext_canon => '7sus4', name => 'Lam7sus4', qual => 'm', qual_canon => '-', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'latin' }
Lam9	{ bass => '', ext => 9, ext_canon => 9, name => 'Lam9', qual => 'm', qual_canon => '-', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'latin' }
Lam/Sol	{ bass => 'Sol', bass_canon => 'Sol', bass_mod => 0, bass_ord => 7, ext => '', ext_canon => '', name => 'Lam/Sol', qual => 'm', qual_canon => '-', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'latin' }
Lamadd9	{ bass => '', ext => 'add9', ext_canon => 'add9', name => 'Lamadd9', qual => 'm', qual_canon => '-', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'latin' }
La#	{ bass => '', ext => '', ext_canon => '', name => 'La#', qual => '', qual_canon => '', root => 'La#', root_canon => 'La#', root_mod => 1, root_ord => 10, system => 'latin' }
La#+	{ bass => '', ext => '', ext_canon => '', name => 'La#+', qual => '+', qual_canon => '+', root => 'La#', root_canon => 'La#', root_mod => 1, root_ord => 10, system => 'latin' }
La#4	{ bass => '', ext => 4, ext_canon => 4, name => 'La#4', qual => '', qual_canon => '', root => 'La#', root_canon => 'La#', root_mod => 1, root_ord => 10, system => 'latin' }
La#7	{ bass => '', ext => 7, ext_canon => 7, name => 'La#7', qual => '', qual_canon => '', root => 'La#', root_canon => 'La#', root_mod => 1, root_ord => 10, system => 'latin' }
La#sus	{ bass => '', ext => 'sus', ext_canon => 'sus4', name => 'La#sus', qual => '', qual_canon => '', root => 'La#', root_canon => 'La#', root_mod => 1, root_ord => 10, system => 'latin' }
La#sus4	{ bass => '', ext => 'sus4', ext_canon => 'sus4', name => 'La#sus4', qual => '', qual_canon => '', root => 'La#', root_canon => 'La#', root_mod => 1, root_ord => 10, system => 'latin' }
La#maj	{ bass => '', ext => '', ext_canon => '', name => 'La#maj', qual => '', qual_canon => '', root => 'La#', root_canon => 'La#', root_mod => 1, root_ord => 10, system => 'latin' }
La#maj7	{ bass => '', ext => 'maj7', ext_canon => 'maj7', name => 'La#maj7', qual => '', qual_canon => '', root => 'La#', root_canon => 'La#', root_mod => 1, root_ord => 10, system => 'latin' }
La#dim	{ bass => '', ext => '', ext_canon => '', name => 'La#dim', qual => 'dim', qual_canon => 0, root => 'La#', root_canon => 'La#', root_mod => 1, root_ord => 10, system => 'latin' }
La#m	{ bass => '', ext => '', ext_canon => '', name => 'La#m', qual => 'm', qual_canon => '-', root => 'La#', root_canon => 'La#', root_mod => 1, root_ord => 10, system => 'latin' }
La#min	{ bass => '', ext => '', ext_canon => '', name => 'La#min', qual => 'min', qual_canon => '-', root => 'La#', root_canon => 'La#', root_mod => 1, root_ord => 10, system => 'latin' }
La#m7	{ bass => '', ext => 7, ext_canon => 7, name => 'La#m7', qual => 'm', qual_canon => '-', root => 'La#', root_canon => 'La#', root_mod => 1, root_ord => 10, system => 'latin' }
Sib	{ bass => '', ext => '', ext_canon => '', name => 'Sib', qual => '', qual_canon => '', root => 'Sib', root_canon => 'Sib', root_mod => -1, root_ord => 10, system => 'latin' }
Sib+	{ bass => '', ext => '', ext_canon => '', name => 'Sib+', qual => '+', qual_canon => '+', root => 'Sib', root_canon => 'Sib', root_mod => -1, root_ord => 10, system => 'latin' }
Sib4	{ bass => '', ext => 4, ext_canon => 4, name => 'Sib4', qual => '', qual_canon => '', root => 'Sib', root_canon => 'Sib', root_mod => -1, root_ord => 10, system => 'latin' }
Sib6	{ bass => '', ext => 6, ext_canon => 6, name => 'Sib6', qual => '', qual_canon => '', root => 'Sib', root_canon => 'Sib', root_mod => -1, root_ord => 10, system => 'latin' }
Sib7	{ bass => '', ext => 7, ext_canon => 7, name => 'Sib7', qual => '', qual_canon => '', root => 'Sib', root_canon => 'Sib', root_mod => -1, root_ord => 10, system => 'latin' }
Sib9	{ bass => '', ext => 9, ext_canon => 9, name => 'Sib9', qual => '', qual_canon => '', root => 'Sib', root_canon => 'Sib', root_mod => -1, root_ord => 10, system => 'latin' }
Sib11	{ bass => '', ext => 11, ext_canon => 11, name => 'Sib11', qual => '', qual_canon => '', root => 'Sib', root_canon => 'Sib', root_mod => -1, root_ord => 10, system => 'latin' }
Sibsus	{ bass => '', ext => 'sus', ext_canon => 'sus4', name => 'Sibsus', qual => '', qual_canon => '', root => 'Sib', root_canon => 'Sib', root_mod => -1, root_ord => 10, system => 'latin' }
Sibsus4	{ bass => '', ext => 'sus4', ext_canon => 'sus4', name => 'Sibsus4', qual => '', qual_canon => '', root => 'Sib', root_canon => 'Sib', root_mod => -1, root_ord => 10, system => 'latin' }
Sibmaj	{ bass => '', ext => '', ext_canon => '', name => 'Sibmaj', qual => '', qual_canon => '', root => 'Sib', root_canon => 'Sib', root_mod => -1, root_ord => 10, system => 'latin' }
Sibmaj7	{ bass => '', ext => 'maj7', ext_canon => 'maj7', name => 'Sibmaj7', qual => '', qual_canon => '', root => 'Sib', root_canon => 'Sib', root_mod => -1, root_ord => 10, system => 'latin' }
Sibdim	{ bass => '', ext => '', ext_canon => '', name => 'Sibdim', qual => 'dim', qual_canon => 0, root => 'Sib', root_canon => 'Sib', root_mod => -1, root_ord => 10, system => 'latin' }
Sibm	{ bass => '', ext => '', ext_canon => '', name => 'Sibm', qual => 'm', qual_canon => '-', root => 'Sib', root_canon => 'Sib', root_mod => -1, root_ord => 10, system => 'latin' }
Sibmin	{ bass => '', ext => '', ext_canon => '', name => 'Sibmin', qual => 'min', qual_canon => '-', root => 'Sib', root_canon => 'Sib', root_mod => -1, root_ord => 10, system => 'latin' }
Sibm7	{ bass => '', ext => 7, ext_canon => 7, name => 'Sibm7', qual => 'm', qual_canon => '-', root => 'Sib', root_canon => 'Sib', root_mod => -1, root_ord => 10, system => 'latin' }
Sibm9	{ bass => '', ext => 9, ext_canon => 9, name => 'Sibm9', qual => 'm', qual_canon => '-', root => 'Sib', root_canon => 'Sib', root_mod => -1, root_ord => 10, system => 'latin' }
Si	{ bass => '', ext => '', ext_canon => '', name => 'Si', qual => '', qual_canon => '', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11, system => 'latin' }
Si+	{ bass => '', ext => '', ext_canon => '', name => 'Si+', qual => '+', qual_canon => '+', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11, system => 'latin' }
Si4	{ bass => '', ext => 4, ext_canon => 4, name => 'Si4', qual => '', qual_canon => '', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11, system => 'latin' }
Si7	{ bass => '', ext => 7, ext_canon => 7, name => 'Si7', qual => '', qual_canon => '', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11, system => 'latin' }
Si7#9	{ bass => '', ext => '7#9', ext_canon => '7#9', name => 'Si7#9', qual => '', qual_canon => '', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11, system => 'latin' }
Si9	{ bass => '', ext => 9, ext_canon => 9, name => 'Si9', qual => '', qual_canon => '', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11, system => 'latin' }
Si11	{ bass => '', ext => 11, ext_canon => 11, name => 'Si11', qual => '', qual_canon => '', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11, system => 'latin' }
Si13	{ bass => '', ext => 13, ext_canon => 13, name => 'Si13', qual => '', qual_canon => '', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11, system => 'latin' }
Sisus	{ bass => '', ext => 'sus', ext_canon => 'sus4', name => 'Sisus', qual => '', qual_canon => '', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11, system => 'latin' }
Sisus4	{ bass => '', ext => 'sus4', ext_canon => 'sus4', name => 'Sisus4', qual => '', qual_canon => '', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11, system => 'latin' }
Simaj	{ bass => '', ext => '', ext_canon => '', name => 'Simaj', qual => '', qual_canon => '', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11, system => 'latin' }
Simaj7	{ bass => '', ext => 'maj7', ext_canon => 'maj7', name => 'Simaj7', qual => '', qual_canon => '', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11, system => 'latin' }
Sidim	{ bass => '', ext => '', ext_canon => '', name => 'Sidim', qual => 'dim', qual_canon => 0, root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11, system => 'latin' }
Sim	{ bass => '', ext => '', ext_canon => '', name => 'Sim', qual => 'm', qual_canon => '-', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11, system => 'latin' }
Simin	{ bass => '', ext => '', ext_canon => '', name => 'Simin', qual => 'min', qual_canon => '-', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11, system => 'latin' }
Si/Fa#	{ bass => 'Fa#', bass_canon => 'Fa#', bass_mod => 1, bass_ord => 6, ext => '', ext_canon => '', name => 'Si/Fa#', qual => '', qual_canon => '', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11, system => 'latin' }
Sim6	{ bass => '', ext => 6, ext_canon => 6, name => 'Sim6', qual => 'm', qual_canon => '-', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11, system => 'latin' }
Sim7	{ bass => '', ext => 7, ext_canon => 7, name => 'Sim7', qual => 'm', qual_canon => '-', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11, system => 'latin' }
Simmaj7	{ bass => '', ext => 'maj7', ext_canon => 'maj7', name => 'Simmaj7', qual => 'm', qual_canon => '-', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11, system => 'latin' }
Simsus9	{ bass => '', ext => 'sus9', ext_canon => 'sus9', name => 'Simsus9', qual => 'm', qual_canon => '-', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11, system => 'latin' }
Sim7b5	{ bass => '', ext => '7b5', ext_canon => '7b5', name => 'Sim7b5', qual => 'm', qual_canon => '-', root => 'Si', root_canon => 'Si', root_mod => 0, root_ord => 11, system => 'latin' }
