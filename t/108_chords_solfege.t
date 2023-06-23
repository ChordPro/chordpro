#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use App::Music::ChordPro::Testing;
use App::Music::ChordPro::Chords;
use App::Music::ChordPro::Chords::Parser;

my %tbl;

our $config =
      App::Music::ChordPro::Config::configurator
	  ( { nosysconfig => 1, nolegacyconfig => 1, nouserconfig => 1,
	      config => getresource("config/notes/solfege.json") } );

=begin regenerate

# Enable this section to generate new reference data.

my $p = App::Music::ChordPro::Chords::Parser->get_parser("solfege");

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
	s!^C#!Di! or
	s!^C!Do! or
	s!^Db!Ra! or
	s!^D#!Ri! or
	s!^D!Re! or
	s!^Eb!Me! or
	s!^E!Mi! or
	s!^F#!Fi! or
	s!^F!Fa! or
	s!^Gb!Se! or
	s!^G#!Si! or
	s!^G!So! or
	s!^Ab!Le! or
	s!^A#!Li! or
	s!^A!La! or
	s!^Bb!Te! or
	s!^B!Ti!;

	s!/C#!/Di! or
	s!/C!/Do! or
	s!/Db!/Ra! or
	s!/D#!/Ri! or
	s!/D!/Re! or
	s!/Eb!/Me! or
	s!/E!/Mi! or
	s!/F#!/Fi! or
	s!/F!/Fa! or
	s!/Gb!/Se! or
	s!/G#!/Si! or
	s!/G!/So! or
	s!/Ab!/Le! or
	s!/A#!/Li! or
	s!/A!/La! or
	s!/Bb!/Te! or
	s!/B!/Ti!;
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
Do	{ bass => '', ext => '', ext_canon => '', name => 'Do', qual => '', qual_canon => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'solfege' }
Do+	{ bass => '', ext => '', ext_canon => '', name => 'Do+', qual => '+', qual_canon => '+', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'solfege' }
Do4	{ bass => '', ext => 4, ext_canon => 4, name => 'Do4', qual => '', qual_canon => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'solfege' }
Do6	{ bass => '', ext => 6, ext_canon => 6, name => 'Do6', qual => '', qual_canon => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'solfege' }
Do7	{ bass => '', ext => 7, ext_canon => 7, name => 'Do7', qual => '', qual_canon => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'solfege' }
Do9	{ bass => '', ext => 9, ext_canon => 9, name => 'Do9', qual => '', qual_canon => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'solfege' }
Do9(11)	{ bass => '', ext => 911, ext_canon => 911, name => 'Do911', qual => '', qual_canon => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'solfege' }
Do11	{ bass => '', ext => 11, ext_canon => 11, name => 'Do11', qual => '', qual_canon => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'solfege' }
Dosus	{ bass => '', ext => 'sus', ext_canon => 'sus4', name => 'Dosus', qual => '', qual_canon => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'solfege' }
Dosus2	{ bass => '', ext => 'sus2', ext_canon => 'sus2', name => 'Dosus2', qual => '', qual_canon => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'solfege' }
Dosus4	{ bass => '', ext => 'sus4', ext_canon => 'sus4', name => 'Dosus4', qual => '', qual_canon => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'solfege' }
Dosus9	{ bass => '', ext => 'sus9', ext_canon => 'sus9', name => 'Dosus9', qual => '', qual_canon => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'solfege' }
Domaj	{ bass => '', ext => '', ext_canon => '', name => 'Domaj', qual => '', qual_canon => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'solfege' }
Domaj7	{ bass => '', ext => 'maj7', ext_canon => 'maj7', name => 'Domaj7', qual => '', qual_canon => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'solfege' }
Dom	{ bass => '', ext => '', ext_canon => '', name => 'Dom', qual => 'm', qual_canon => '-', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'solfege' }
Domin	{ bass => '', ext => '', ext_canon => '', name => 'Domin', qual => 'min', qual_canon => '-', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'solfege' }
Dodim	{ bass => '', ext => '', ext_canon => '', name => 'Dodim', qual => 'dim', qual_canon => 0, root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'solfege' }
Do/Ti	{ bass => 'Ti', bass_canon => 'Ti', bass_mod => 0, bass_ord => 11, ext => '', ext_canon => '', name => 'Do/Ti', qual => '', qual_canon => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'solfege' }
Doadd9	{ bass => '', ext => 'add9', ext_canon => 'add9', name => 'Doadd9', qual => '', qual_canon => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'solfege' }
Do3	{ bass => '', ext => 3, ext_canon => 3, name => 'Do3', qual => '', qual_canon => '', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'solfege' }
Dom7	{ bass => '', ext => 7, ext_canon => 7, name => 'Dom7', qual => 'm', qual_canon => '-', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'solfege' }
Dom11	{ bass => '', ext => 11, ext_canon => 11, name => 'Dom11', qual => 'm', qual_canon => '-', root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'solfege' }
Di	{ bass => '', ext => '', ext_canon => '', name => 'Di', qual => '', qual_canon => '', root => 'Di', root_canon => 'Di', root_mod => 1, root_ord => 1, system => 'solfege' }
Di+	{ bass => '', ext => '', ext_canon => '', name => 'Di+', qual => '+', qual_canon => '+', root => 'Di', root_canon => 'Di', root_mod => 1, root_ord => 1, system => 'solfege' }
Di4	{ bass => '', ext => 4, ext_canon => 4, name => 'Di4', qual => '', qual_canon => '', root => 'Di', root_canon => 'Di', root_mod => 1, root_ord => 1, system => 'solfege' }
Di7	{ bass => '', ext => 7, ext_canon => 7, name => 'Di7', qual => '', qual_canon => '', root => 'Di', root_canon => 'Di', root_mod => 1, root_ord => 1, system => 'solfege' }
Di7(b5)	{ bass => '', ext => '7b5', ext_canon => '7b5', name => 'Di7b5', qual => '', qual_canon => '', root => 'Di', root_canon => 'Di', root_mod => 1, root_ord => 1, system => 'solfege' }
Disus	{ bass => '', ext => 'sus', ext_canon => 'sus4', name => 'Disus', qual => '', qual_canon => '', root => 'Di', root_canon => 'Di', root_mod => 1, root_ord => 1, system => 'solfege' }
Disus4	{ bass => '', ext => 'sus4', ext_canon => 'sus4', name => 'Disus4', qual => '', qual_canon => '', root => 'Di', root_canon => 'Di', root_mod => 1, root_ord => 1, system => 'solfege' }
Dimaj	{ bass => '', ext => '', ext_canon => '', name => 'Dimaj', qual => '', qual_canon => '', root => 'Di', root_canon => 'Di', root_mod => 1, root_ord => 1, system => 'solfege' }
Dimaj7	{ bass => '', ext => 'maj7', ext_canon => 'maj7', name => 'Dimaj7', qual => '', qual_canon => '', root => 'Di', root_canon => 'Di', root_mod => 1, root_ord => 1, system => 'solfege' }
Didim	{ bass => '', ext => '', ext_canon => '', name => 'Didim', qual => 'dim', qual_canon => 0, root => 'Di', root_canon => 'Di', root_mod => 1, root_ord => 1, system => 'solfege' }
Dim	{ bass => '', ext => '', ext_canon => '', name => 'Dim', qual => 'm', qual_canon => '-', root => 'Di', root_canon => 'Di', root_mod => 1, root_ord => 1, system => 'solfege' }
Dimin	{ bass => '', ext => '', ext_canon => '', name => 'Dimin', qual => 'min', qual_canon => '-', root => 'Di', root_canon => 'Di', root_mod => 1, root_ord => 1, system => 'solfege' }
Diadd9	{ bass => '', ext => 'add9', ext_canon => 'add9', name => 'Diadd9', qual => '', qual_canon => '', root => 'Di', root_canon => 'Di', root_mod => 1, root_ord => 1, system => 'solfege' }
Di(add9)	{ bass => '', ext => 'add9', ext_canon => 'add9', name => 'Diadd9', qual => '', qual_canon => '', root => 'Di', root_canon => 'Di', root_mod => 1, root_ord => 1, system => 'solfege' }
Dim7	{ bass => '', ext => 7, ext_canon => 7, name => 'Dim7', qual => 'm', qual_canon => '-', root => 'Di', root_canon => 'Di', root_mod => 1, root_ord => 1, system => 'solfege' }
Ra	{ bass => '', ext => '', ext_canon => '', name => 'Ra', qual => '', qual_canon => '', root => 'Ra', root_canon => 'Ra', root_mod => -1, root_ord => 1, system => 'solfege' }
Ra+	{ bass => '', ext => '', ext_canon => '', name => 'Ra+', qual => '+', qual_canon => '+', root => 'Ra', root_canon => 'Ra', root_mod => -1, root_ord => 1, system => 'solfege' }
Ra7	{ bass => '', ext => 7, ext_canon => 7, name => 'Ra7', qual => '', qual_canon => '', root => 'Ra', root_canon => 'Ra', root_mod => -1, root_ord => 1, system => 'solfege' }
Rasus	{ bass => '', ext => 'sus', ext_canon => 'sus4', name => 'Rasus', qual => '', qual_canon => '', root => 'Ra', root_canon => 'Ra', root_mod => -1, root_ord => 1, system => 'solfege' }
Rasus4	{ bass => '', ext => 'sus4', ext_canon => 'sus4', name => 'Rasus4', qual => '', qual_canon => '', root => 'Ra', root_canon => 'Ra', root_mod => -1, root_ord => 1, system => 'solfege' }
Ramaj	{ bass => '', ext => '', ext_canon => '', name => 'Ramaj', qual => '', qual_canon => '', root => 'Ra', root_canon => 'Ra', root_mod => -1, root_ord => 1, system => 'solfege' }
Ramaj7	{ bass => '', ext => 'maj7', ext_canon => 'maj7', name => 'Ramaj7', qual => '', qual_canon => '', root => 'Ra', root_canon => 'Ra', root_mod => -1, root_ord => 1, system => 'solfege' }
Radim	{ bass => '', ext => '', ext_canon => '', name => 'Radim', qual => 'dim', qual_canon => 0, root => 'Ra', root_canon => 'Ra', root_mod => -1, root_ord => 1, system => 'solfege' }
Ram	{ bass => '', ext => '', ext_canon => '', name => 'Ram', qual => 'm', qual_canon => '-', root => 'Ra', root_canon => 'Ra', root_mod => -1, root_ord => 1, system => 'solfege' }
Ramin	{ bass => '', ext => '', ext_canon => '', name => 'Ramin', qual => 'min', qual_canon => '-', root => 'Ra', root_canon => 'Ra', root_mod => -1, root_ord => 1, system => 'solfege' }
Ram7	{ bass => '', ext => 7, ext_canon => 7, name => 'Ram7', qual => 'm', qual_canon => '-', root => 'Ra', root_canon => 'Ra', root_mod => -1, root_ord => 1, system => 'solfege' }
Re	{ bass => '', ext => '', ext_canon => '', name => 'Re', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'solfege' }
Re+	{ bass => '', ext => '', ext_canon => '', name => 'Re+', qual => '+', qual_canon => '+', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'solfege' }
Re4	{ bass => '', ext => 4, ext_canon => 4, name => 'Re4', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'solfege' }
Re6	{ bass => '', ext => 6, ext_canon => 6, name => 'Re6', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'solfege' }
Re7	{ bass => '', ext => 7, ext_canon => 7, name => 'Re7', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'solfege' }
Re7#9	{ bass => '', ext => '7#9', ext_canon => '7#9', name => 'Re7#9', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'solfege' }
Re7(#9)	{ bass => '', ext => '7#9', ext_canon => '7#9', name => 'Re7#9', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'solfege' }
Re9	{ bass => '', ext => 9, ext_canon => 9, name => 'Re9', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'solfege' }
Re11	{ bass => '', ext => 11, ext_canon => 11, name => 'Re11', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'solfege' }
Resus	{ bass => '', ext => 'sus', ext_canon => 'sus4', name => 'Resus', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'solfege' }
Resus2	{ bass => '', ext => 'sus2', ext_canon => 'sus2', name => 'Resus2', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'solfege' }
Resus4	{ bass => '', ext => 'sus4', ext_canon => 'sus4', name => 'Resus4', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'solfege' }
Re7sus2	{ bass => '', ext => '7sus2', ext_canon => '7sus2', name => 'Re7sus2', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'solfege' }
Re7sus4	{ bass => '', ext => '7sus4', ext_canon => '7sus4', name => 'Re7sus4', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'solfege' }
Remaj	{ bass => '', ext => '', ext_canon => '', name => 'Remaj', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'solfege' }
Remaj7	{ bass => '', ext => 'maj7', ext_canon => 'maj7', name => 'Remaj7', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'solfege' }
Redim	{ bass => '', ext => '', ext_canon => '', name => 'Redim', qual => 'dim', qual_canon => 0, root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'solfege' }
Rem	{ bass => '', ext => '', ext_canon => '', name => 'Rem', qual => 'm', qual_canon => '-', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'solfege' }
Remin	{ bass => '', ext => '', ext_canon => '', name => 'Remin', qual => 'min', qual_canon => '-', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'solfege' }
Re/La	{ bass => 'La', bass_canon => 'La', bass_mod => 0, bass_ord => 9, ext => '', ext_canon => '', name => 'Re/La', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'solfege' }
Re/Ti	{ bass => 'Ti', bass_canon => 'Ti', bass_mod => 0, bass_ord => 11, ext => '', ext_canon => '', name => 'Re/Ti', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'solfege' }
Re/Do	{ bass => 'Do', bass_canon => 'Do', bass_mod => 0, bass_ord => 0, ext => '', ext_canon => '', name => 'Re/Do', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'solfege' }
Re/Di	{ bass => 'Di', bass_canon => 'Di', bass_mod => 1, bass_ord => 1, ext => '', ext_canon => '', name => 'Re/Di', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'solfege' }
Re/Mi	{ bass => 'Mi', bass_canon => 'Mi', bass_mod => 0, bass_ord => 4, ext => '', ext_canon => '', name => 'Re/Mi', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'solfege' }
Re/So	{ bass => 'So', bass_canon => 'So', bass_mod => 0, bass_ord => 7, ext => '', ext_canon => '', name => 'Re/So', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'solfege' }
Re5/Mi	{ bass => 'Mi', bass_canon => 'Mi', bass_mod => 0, bass_ord => 4, ext => 5, ext_canon => 5, name => 'Re5/Mi', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'solfege' }
Readd9	{ bass => '', ext => 'add9', ext_canon => 'add9', name => 'Readd9', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'solfege' }
Re9add6	{ bass => '', ext => '9add6', ext_canon => '9add6', name => 'Re9add6', qual => '', qual_canon => '', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'solfege' }
Rem7	{ bass => '', ext => 7, ext_canon => 7, name => 'Rem7', qual => 'm', qual_canon => '-', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'solfege' }
Rem#5	{ bass => '', ext => '#5', ext_canon => '#5', name => 'Rem#5', qual => 'm', qual_canon => '-', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'solfege' }
Rem#7	{ bass => '', ext => '#7', ext_canon => '#7', name => 'Rem#7', qual => 'm', qual_canon => '-', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'solfege' }
Rem/La	{ bass => 'La', bass_canon => 'La', bass_mod => 0, bass_ord => 9, ext => '', ext_canon => '', name => 'Rem/La', qual => 'm', qual_canon => '-', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'solfege' }
Rem/Ti	{ bass => 'Ti', bass_canon => 'Ti', bass_mod => 0, bass_ord => 11, ext => '', ext_canon => '', name => 'Rem/Ti', qual => 'm', qual_canon => '-', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'solfege' }
Rem/Do	{ bass => 'Do', bass_canon => 'Do', bass_mod => 0, bass_ord => 0, ext => '', ext_canon => '', name => 'Rem/Do', qual => 'm', qual_canon => '-', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'solfege' }
Rem/Di	{ bass => 'Di', bass_canon => 'Di', bass_mod => 1, bass_ord => 1, ext => '', ext_canon => '', name => 'Rem/Di', qual => 'm', qual_canon => '-', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'solfege' }
Rem9	{ bass => '', ext => 9, ext_canon => 9, name => 'Rem9', qual => 'm', qual_canon => '-', root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'solfege' }
Ri	{ bass => '', ext => '', ext_canon => '', name => 'Ri', qual => '', qual_canon => '', root => 'Ri', root_canon => 'Ri', root_mod => 1, root_ord => 3, system => 'solfege' }
Ri+	{ bass => '', ext => '', ext_canon => '', name => 'Ri+', qual => '+', qual_canon => '+', root => 'Ri', root_canon => 'Ri', root_mod => 1, root_ord => 3, system => 'solfege' }
Ri4	{ bass => '', ext => 4, ext_canon => 4, name => 'Ri4', qual => '', qual_canon => '', root => 'Ri', root_canon => 'Ri', root_mod => 1, root_ord => 3, system => 'solfege' }
Ri7	{ bass => '', ext => 7, ext_canon => 7, name => 'Ri7', qual => '', qual_canon => '', root => 'Ri', root_canon => 'Ri', root_mod => 1, root_ord => 3, system => 'solfege' }
Risus	{ bass => '', ext => 'sus', ext_canon => 'sus4', name => 'Risus', qual => '', qual_canon => '', root => 'Ri', root_canon => 'Ri', root_mod => 1, root_ord => 3, system => 'solfege' }
Risus4	{ bass => '', ext => 'sus4', ext_canon => 'sus4', name => 'Risus4', qual => '', qual_canon => '', root => 'Ri', root_canon => 'Ri', root_mod => 1, root_ord => 3, system => 'solfege' }
Rimaj	{ bass => '', ext => '', ext_canon => '', name => 'Rimaj', qual => '', qual_canon => '', root => 'Ri', root_canon => 'Ri', root_mod => 1, root_ord => 3, system => 'solfege' }
Rimaj7	{ bass => '', ext => 'maj7', ext_canon => 'maj7', name => 'Rimaj7', qual => '', qual_canon => '', root => 'Ri', root_canon => 'Ri', root_mod => 1, root_ord => 3, system => 'solfege' }
Ridim	{ bass => '', ext => '', ext_canon => '', name => 'Ridim', qual => 'dim', qual_canon => 0, root => 'Ri', root_canon => 'Ri', root_mod => 1, root_ord => 3, system => 'solfege' }
Rim	{ bass => '', ext => '', ext_canon => '', name => 'Rim', qual => 'm', qual_canon => '-', root => 'Ri', root_canon => 'Ri', root_mod => 1, root_ord => 3, system => 'solfege' }
Rimin	{ bass => '', ext => '', ext_canon => '', name => 'Rimin', qual => 'min', qual_canon => '-', root => 'Ri', root_canon => 'Ri', root_mod => 1, root_ord => 3, system => 'solfege' }
Rim7	{ bass => '', ext => 7, ext_canon => 7, name => 'Rim7', qual => 'm', qual_canon => '-', root => 'Ri', root_canon => 'Ri', root_mod => 1, root_ord => 3, system => 'solfege' }
Me	{ bass => '', ext => '', ext_canon => '', name => 'Me', qual => '', qual_canon => '', root => 'Me', root_canon => 'Me', root_mod => -1, root_ord => 3, system => 'solfege' }
Me+	{ bass => '', ext => '', ext_canon => '', name => 'Me+', qual => '+', qual_canon => '+', root => 'Me', root_canon => 'Me', root_mod => -1, root_ord => 3, system => 'solfege' }
Me4	{ bass => '', ext => 4, ext_canon => 4, name => 'Me4', qual => '', qual_canon => '', root => 'Me', root_canon => 'Me', root_mod => -1, root_ord => 3, system => 'solfege' }
Me7	{ bass => '', ext => 7, ext_canon => 7, name => 'Me7', qual => '', qual_canon => '', root => 'Me', root_canon => 'Me', root_mod => -1, root_ord => 3, system => 'solfege' }
Mesus	{ bass => '', ext => 'sus', ext_canon => 'sus4', name => 'Mesus', qual => '', qual_canon => '', root => 'Me', root_canon => 'Me', root_mod => -1, root_ord => 3, system => 'solfege' }
Mesus4	{ bass => '', ext => 'sus4', ext_canon => 'sus4', name => 'Mesus4', qual => '', qual_canon => '', root => 'Me', root_canon => 'Me', root_mod => -1, root_ord => 3, system => 'solfege' }
Memaj	{ bass => '', ext => '', ext_canon => '', name => 'Memaj', qual => '', qual_canon => '', root => 'Me', root_canon => 'Me', root_mod => -1, root_ord => 3, system => 'solfege' }
Memaj7	{ bass => '', ext => 'maj7', ext_canon => 'maj7', name => 'Memaj7', qual => '', qual_canon => '', root => 'Me', root_canon => 'Me', root_mod => -1, root_ord => 3, system => 'solfege' }
Medim	{ bass => '', ext => '', ext_canon => '', name => 'Medim', qual => 'dim', qual_canon => 0, root => 'Me', root_canon => 'Me', root_mod => -1, root_ord => 3, system => 'solfege' }
Meadd9	{ bass => '', ext => 'add9', ext_canon => 'add9', name => 'Meadd9', qual => '', qual_canon => '', root => 'Me', root_canon => 'Me', root_mod => -1, root_ord => 3, system => 'solfege' }
Me(add9)	{ bass => '', ext => 'add9', ext_canon => 'add9', name => 'Meadd9', qual => '', qual_canon => '', root => 'Me', root_canon => 'Me', root_mod => -1, root_ord => 3, system => 'solfege' }
Mem	{ bass => '', ext => '', ext_canon => '', name => 'Mem', qual => 'm', qual_canon => '-', root => 'Me', root_canon => 'Me', root_mod => -1, root_ord => 3, system => 'solfege' }
Memin	{ bass => '', ext => '', ext_canon => '', name => 'Memin', qual => 'min', qual_canon => '-', root => 'Me', root_canon => 'Me', root_mod => -1, root_ord => 3, system => 'solfege' }
Mem7	{ bass => '', ext => 7, ext_canon => 7, name => 'Mem7', qual => 'm', qual_canon => '-', root => 'Me', root_canon => 'Me', root_mod => -1, root_ord => 3, system => 'solfege' }
Mi	{ bass => '', ext => '', ext_canon => '', name => 'Mi', qual => '', qual_canon => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'solfege' }
Mi+	{ bass => '', ext => '', ext_canon => '', name => 'Mi+', qual => '+', qual_canon => '+', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'solfege' }
Mi5	{ bass => '', ext => 5, ext_canon => 5, name => 'Mi5', qual => '', qual_canon => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'solfege' }
Mi6	{ bass => '', ext => 6, ext_canon => 6, name => 'Mi6', qual => '', qual_canon => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'solfege' }
Mi7	{ bass => '', ext => 7, ext_canon => 7, name => 'Mi7', qual => '', qual_canon => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'solfege' }
Mi7#9	{ bass => '', ext => '7#9', ext_canon => '7#9', name => 'Mi7#9', qual => '', qual_canon => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'solfege' }
Mi7(#9)	{ bass => '', ext => '7#9', ext_canon => '7#9', name => 'Mi7#9', qual => '', qual_canon => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'solfege' }
Mi7(b5)	{ bass => '', ext => '7b5', ext_canon => '7b5', name => 'Mi7b5', qual => '', qual_canon => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'solfege' }
Mi7b9	{ bass => '', ext => '7b9', ext_canon => '7b9', name => 'Mi7b9', qual => '', qual_canon => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'solfege' }
Mi7(11)	{ bass => '', ext => 711, ext_canon => 711, name => 'Mi711', qual => '', qual_canon => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'solfege' }
Mi9	{ bass => '', ext => 9, ext_canon => 9, name => 'Mi9', qual => '', qual_canon => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'solfege' }
Mi11	{ bass => '', ext => 11, ext_canon => 11, name => 'Mi11', qual => '', qual_canon => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'solfege' }
Misus	{ bass => '', ext => 'sus', ext_canon => 'sus4', name => 'Misus', qual => '', qual_canon => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'solfege' }
Mimaj	{ bass => '', ext => '', ext_canon => '', name => 'Mimaj', qual => '', qual_canon => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'solfege' }
Mimaj7	{ bass => '', ext => 'maj7', ext_canon => 'maj7', name => 'Mimaj7', qual => '', qual_canon => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'solfege' }
Midim	{ bass => '', ext => '', ext_canon => '', name => 'Midim', qual => 'dim', qual_canon => 0, root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'solfege' }
Mim	{ bass => '', ext => '', ext_canon => '', name => 'Mim', qual => 'm', qual_canon => '-', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'solfege' }
Mimin	{ bass => '', ext => '', ext_canon => '', name => 'Mimin', qual => 'min', qual_canon => '-', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'solfege' }
Mim6	{ bass => '', ext => 6, ext_canon => 6, name => 'Mim6', qual => 'm', qual_canon => '-', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'solfege' }
Mim7	{ bass => '', ext => 7, ext_canon => 7, name => 'Mim7', qual => 'm', qual_canon => '-', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'solfege' }
Mim/Ti	{ bass => 'Ti', bass_canon => 'Ti', bass_mod => 0, bass_ord => 11, ext => '', ext_canon => '', name => 'Mim/Ti', qual => 'm', qual_canon => '-', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'solfege' }
Mim/Re	{ bass => 'Re', bass_canon => 'Re', bass_mod => 0, bass_ord => 2, ext => '', ext_canon => '', name => 'Mim/Re', qual => 'm', qual_canon => '-', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'solfege' }
Mim7/Re	{ bass => 'Re', bass_canon => 'Re', bass_mod => 0, bass_ord => 2, ext => 7, ext_canon => 7, name => 'Mim7/Re', qual => 'm', qual_canon => '-', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'solfege' }
Mimsus4	{ bass => '', ext => 'sus4', ext_canon => 'sus4', name => 'Mimsus4', qual => 'm', qual_canon => '-', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'solfege' }
Mimadd9	{ bass => '', ext => 'add9', ext_canon => 'add9', name => 'Mimadd9', qual => 'm', qual_canon => '-', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'solfege' }
Fa	{ bass => '', ext => '', ext_canon => '', name => 'Fa', qual => '', qual_canon => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'solfege' }
Fa+	{ bass => '', ext => '', ext_canon => '', name => 'Fa+', qual => '+', qual_canon => '+', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'solfege' }
Fa4	{ bass => '', ext => 4, ext_canon => 4, name => 'Fa4', qual => '', qual_canon => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'solfege' }
Fa6	{ bass => '', ext => 6, ext_canon => 6, name => 'Fa6', qual => '', qual_canon => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'solfege' }
Fa7	{ bass => '', ext => 7, ext_canon => 7, name => 'Fa7', qual => '', qual_canon => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'solfege' }
Fa9	{ bass => '', ext => 9, ext_canon => 9, name => 'Fa9', qual => '', qual_canon => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'solfege' }
Fa11	{ bass => '', ext => 11, ext_canon => 11, name => 'Fa11', qual => '', qual_canon => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'solfege' }
Fasus	{ bass => '', ext => 'sus', ext_canon => 'sus4', name => 'Fasus', qual => '', qual_canon => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'solfege' }
Fasus4	{ bass => '', ext => 'sus4', ext_canon => 'sus4', name => 'Fasus4', qual => '', qual_canon => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'solfege' }
Famaj	{ bass => '', ext => '', ext_canon => '', name => 'Famaj', qual => '', qual_canon => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'solfege' }
Famaj7	{ bass => '', ext => 'maj7', ext_canon => 'maj7', name => 'Famaj7', qual => '', qual_canon => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'solfege' }
Fadim	{ bass => '', ext => '', ext_canon => '', name => 'Fadim', qual => 'dim', qual_canon => 0, root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'solfege' }
Fam	{ bass => '', ext => '', ext_canon => '', name => 'Fam', qual => 'm', qual_canon => '-', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'solfege' }
Famin	{ bass => '', ext => '', ext_canon => '', name => 'Famin', qual => 'min', qual_canon => '-', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'solfege' }
Fa/La	{ bass => 'La', bass_canon => 'La', bass_mod => 0, bass_ord => 9, ext => '', ext_canon => '', name => 'Fa/La', qual => '', qual_canon => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'solfege' }
Fa/Do	{ bass => 'Do', bass_canon => 'Do', bass_mod => 0, bass_ord => 0, ext => '', ext_canon => '', name => 'Fa/Do', qual => '', qual_canon => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'solfege' }
Fa/Re	{ bass => 'Re', bass_canon => 'Re', bass_mod => 0, bass_ord => 2, ext => '', ext_canon => '', name => 'Fa/Re', qual => '', qual_canon => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'solfege' }
Fa/So	{ bass => 'So', bass_canon => 'So', bass_mod => 0, bass_ord => 7, ext => '', ext_canon => '', name => 'Fa/So', qual => '', qual_canon => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'solfege' }
Fa7/La	{ bass => 'La', bass_canon => 'La', bass_mod => 0, bass_ord => 9, ext => 7, ext_canon => 7, name => 'Fa7/La', qual => '', qual_canon => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'solfege' }
Famaj7/La	{ bass => 'La', bass_canon => 'La', bass_mod => 0, bass_ord => 9, ext => 'maj7', ext_canon => 'maj7', name => 'Famaj7/La', qual => '', qual_canon => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'solfege' }
Famaj7/Do	{ bass => 'Do', bass_canon => 'Do', bass_mod => 0, bass_ord => 0, ext => 'maj7', ext_canon => 'maj7', name => 'Famaj7/Do', qual => '', qual_canon => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'solfege' }
Faadd9	{ bass => '', ext => 'add9', ext_canon => 'add9', name => 'Faadd9', qual => '', qual_canon => '', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'solfege' }
Fam6	{ bass => '', ext => 6, ext_canon => 6, name => 'Fam6', qual => 'm', qual_canon => '-', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'solfege' }
Fam7	{ bass => '', ext => 7, ext_canon => 7, name => 'Fam7', qual => 'm', qual_canon => '-', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'solfege' }
Fammaj7	{ bass => '', ext => 'maj7', ext_canon => 'maj7', name => 'Fammaj7', qual => 'm', qual_canon => '-', root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'solfege' }
Fi	{ bass => '', ext => '', ext_canon => '', name => 'Fi', qual => '', qual_canon => '', root => 'Fi', root_canon => 'Fi', root_mod => 1, root_ord => 6, system => 'solfege' }
Fi+	{ bass => '', ext => '', ext_canon => '', name => 'Fi+', qual => '+', qual_canon => '+', root => 'Fi', root_canon => 'Fi', root_mod => 1, root_ord => 6, system => 'solfege' }
Fi7	{ bass => '', ext => 7, ext_canon => 7, name => 'Fi7', qual => '', qual_canon => '', root => 'Fi', root_canon => 'Fi', root_mod => 1, root_ord => 6, system => 'solfege' }
Fi9	{ bass => '', ext => 9, ext_canon => 9, name => 'Fi9', qual => '', qual_canon => '', root => 'Fi', root_canon => 'Fi', root_mod => 1, root_ord => 6, system => 'solfege' }
Fi11	{ bass => '', ext => 11, ext_canon => 11, name => 'Fi11', qual => '', qual_canon => '', root => 'Fi', root_canon => 'Fi', root_mod => 1, root_ord => 6, system => 'solfege' }
Fisus	{ bass => '', ext => 'sus', ext_canon => 'sus4', name => 'Fisus', qual => '', qual_canon => '', root => 'Fi', root_canon => 'Fi', root_mod => 1, root_ord => 6, system => 'solfege' }
Fisus4	{ bass => '', ext => 'sus4', ext_canon => 'sus4', name => 'Fisus4', qual => '', qual_canon => '', root => 'Fi', root_canon => 'Fi', root_mod => 1, root_ord => 6, system => 'solfege' }
Fimaj7	{ bass => '', ext => 'maj7', ext_canon => 'maj7', name => 'Fimaj7', qual => '', qual_canon => '', root => 'Fi', root_canon => 'Fi', root_mod => 1, root_ord => 6, system => 'solfege' }
Fidim	{ bass => '', ext => '', ext_canon => '', name => 'Fidim', qual => 'dim', qual_canon => 0, root => 'Fi', root_canon => 'Fi', root_mod => 1, root_ord => 6, system => 'solfege' }
Fim	{ bass => '', ext => '', ext_canon => '', name => 'Fim', qual => 'm', qual_canon => '-', root => 'Fi', root_canon => 'Fi', root_mod => 1, root_ord => 6, system => 'solfege' }
Fimin	{ bass => '', ext => '', ext_canon => '', name => 'Fimin', qual => 'min', qual_canon => '-', root => 'Fi', root_canon => 'Fi', root_mod => 1, root_ord => 6, system => 'solfege' }
Fi/Mi	{ bass => 'Mi', bass_canon => 'Mi', bass_mod => 0, bass_ord => 4, ext => '', ext_canon => '', name => 'Fi/Mi', qual => '', qual_canon => '', root => 'Fi', root_canon => 'Fi', root_mod => 1, root_ord => 6, system => 'solfege' }
Fi4	{ bass => '', ext => 4, ext_canon => 4, name => 'Fi4', qual => '', qual_canon => '', root => 'Fi', root_canon => 'Fi', root_mod => 1, root_ord => 6, system => 'solfege' }
Fim6	{ bass => '', ext => 6, ext_canon => 6, name => 'Fim6', qual => 'm', qual_canon => '-', root => 'Fi', root_canon => 'Fi', root_mod => 1, root_ord => 6, system => 'solfege' }
Fim7	{ bass => '', ext => 7, ext_canon => 7, name => 'Fim7', qual => 'm', qual_canon => '-', root => 'Fi', root_canon => 'Fi', root_mod => 1, root_ord => 6, system => 'solfege' }
Fim7b5	{ bass => '', ext => '7b5', ext_canon => '7b5', name => 'Fim7b5', qual => 'm', qual_canon => '-', root => 'Fi', root_canon => 'Fi', root_mod => 1, root_ord => 6, system => 'solfege' }
Fim/Do	{ bass => 'Do', bass_canon => 'Do', bass_mod => 0, bass_ord => 0, ext => '', ext_canon => '', name => 'Fim/Do', qual => 'm', qual_canon => '-', root => 'Fi', root_canon => 'Fi', root_mod => 1, root_ord => 6, system => 'solfege' }
Se	{ bass => '', ext => '', ext_canon => '', name => 'Se', qual => '', qual_canon => '', root => 'Se', root_canon => 'Se', root_mod => -1, root_ord => 6, system => 'solfege' }
Se+	{ bass => '', ext => '', ext_canon => '', name => 'Se+', qual => '+', qual_canon => '+', root => 'Se', root_canon => 'Se', root_mod => -1, root_ord => 6, system => 'solfege' }
Se7	{ bass => '', ext => 7, ext_canon => 7, name => 'Se7', qual => '', qual_canon => '', root => 'Se', root_canon => 'Se', root_mod => -1, root_ord => 6, system => 'solfege' }
Se9	{ bass => '', ext => 9, ext_canon => 9, name => 'Se9', qual => '', qual_canon => '', root => 'Se', root_canon => 'Se', root_mod => -1, root_ord => 6, system => 'solfege' }
Sesus	{ bass => '', ext => 'sus', ext_canon => 'sus4', name => 'Sesus', qual => '', qual_canon => '', root => 'Se', root_canon => 'Se', root_mod => -1, root_ord => 6, system => 'solfege' }
Sesus4	{ bass => '', ext => 'sus4', ext_canon => 'sus4', name => 'Sesus4', qual => '', qual_canon => '', root => 'Se', root_canon => 'Se', root_mod => -1, root_ord => 6, system => 'solfege' }
Semaj	{ bass => '', ext => '', ext_canon => '', name => 'Semaj', qual => '', qual_canon => '', root => 'Se', root_canon => 'Se', root_mod => -1, root_ord => 6, system => 'solfege' }
Semaj7	{ bass => '', ext => 'maj7', ext_canon => 'maj7', name => 'Semaj7', qual => '', qual_canon => '', root => 'Se', root_canon => 'Se', root_mod => -1, root_ord => 6, system => 'solfege' }
Sedim	{ bass => '', ext => '', ext_canon => '', name => 'Sedim', qual => 'dim', qual_canon => 0, root => 'Se', root_canon => 'Se', root_mod => -1, root_ord => 6, system => 'solfege' }
Sem	{ bass => '', ext => '', ext_canon => '', name => 'Sem', qual => 'm', qual_canon => '-', root => 'Se', root_canon => 'Se', root_mod => -1, root_ord => 6, system => 'solfege' }
Semin	{ bass => '', ext => '', ext_canon => '', name => 'Semin', qual => 'min', qual_canon => '-', root => 'Se', root_canon => 'Se', root_mod => -1, root_ord => 6, system => 'solfege' }
Sem7	{ bass => '', ext => 7, ext_canon => 7, name => 'Sem7', qual => 'm', qual_canon => '-', root => 'Se', root_canon => 'Se', root_mod => -1, root_ord => 6, system => 'solfege' }
So	{ bass => '', ext => '', ext_canon => '', name => 'So', qual => '', qual_canon => '', root => 'So', root_canon => 'So', root_mod => 0, root_ord => 7, system => 'solfege' }
So+	{ bass => '', ext => '', ext_canon => '', name => 'So+', qual => '+', qual_canon => '+', root => 'So', root_canon => 'So', root_mod => 0, root_ord => 7, system => 'solfege' }
So4	{ bass => '', ext => 4, ext_canon => 4, name => 'So4', qual => '', qual_canon => '', root => 'So', root_canon => 'So', root_mod => 0, root_ord => 7, system => 'solfege' }
So6	{ bass => '', ext => 6, ext_canon => 6, name => 'So6', qual => '', qual_canon => '', root => 'So', root_canon => 'So', root_mod => 0, root_ord => 7, system => 'solfege' }
So7	{ bass => '', ext => 7, ext_canon => 7, name => 'So7', qual => '', qual_canon => '', root => 'So', root_canon => 'So', root_mod => 0, root_ord => 7, system => 'solfege' }
So7b9	{ bass => '', ext => '7b9', ext_canon => '7b9', name => 'So7b9', qual => '', qual_canon => '', root => 'So', root_canon => 'So', root_mod => 0, root_ord => 7, system => 'solfege' }
So7#9	{ bass => '', ext => '7#9', ext_canon => '7#9', name => 'So7#9', qual => '', qual_canon => '', root => 'So', root_canon => 'So', root_mod => 0, root_ord => 7, system => 'solfege' }
So9	{ bass => '', ext => 9, ext_canon => 9, name => 'So9', qual => '', qual_canon => '', root => 'So', root_canon => 'So', root_mod => 0, root_ord => 7, system => 'solfege' }
So9(11)	{ bass => '', ext => 911, ext_canon => 911, name => 'So911', qual => '', qual_canon => '', root => 'So', root_canon => 'So', root_mod => 0, root_ord => 7, system => 'solfege' }
So11	{ bass => '', ext => 11, ext_canon => 11, name => 'So11', qual => '', qual_canon => '', root => 'So', root_canon => 'So', root_mod => 0, root_ord => 7, system => 'solfege' }
Sosus	{ bass => '', ext => 'sus', ext_canon => 'sus4', name => 'Sosus', qual => '', qual_canon => '', root => 'So', root_canon => 'So', root_mod => 0, root_ord => 7, system => 'solfege' }
Sosus4	{ bass => '', ext => 'sus4', ext_canon => 'sus4', name => 'Sosus4', qual => '', qual_canon => '', root => 'So', root_canon => 'So', root_mod => 0, root_ord => 7, system => 'solfege' }
So6sus4	{ bass => '', ext => '6sus4', ext_canon => '6sus4', name => 'So6sus4', qual => '', qual_canon => '', root => 'So', root_canon => 'So', root_mod => 0, root_ord => 7, system => 'solfege' }
So7sus4	{ bass => '', ext => '7sus4', ext_canon => '7sus4', name => 'So7sus4', qual => '', qual_canon => '', root => 'So', root_canon => 'So', root_mod => 0, root_ord => 7, system => 'solfege' }
Somaj	{ bass => '', ext => '', ext_canon => '', name => 'Somaj', qual => '', qual_canon => '', root => 'So', root_canon => 'So', root_mod => 0, root_ord => 7, system => 'solfege' }
Somaj7	{ bass => '', ext => 'maj7', ext_canon => 'maj7', name => 'Somaj7', qual => '', qual_canon => '', root => 'So', root_canon => 'So', root_mod => 0, root_ord => 7, system => 'solfege' }
Somaj7sus4	{ bass => '', ext => 'maj7sus4', ext_canon => 'maj7sus4', name => 'Somaj7sus4', qual => '', qual_canon => '', root => 'So', root_canon => 'So', root_mod => 0, root_ord => 7, system => 'solfege' }
Somaj9	{ bass => '', ext => 'maj9', ext_canon => 'maj9', name => 'Somaj9', qual => '', qual_canon => '', root => 'So', root_canon => 'So', root_mod => 0, root_ord => 7, system => 'solfege' }
Som	{ bass => '', ext => '', ext_canon => '', name => 'Som', qual => 'm', qual_canon => '-', root => 'So', root_canon => 'So', root_mod => 0, root_ord => 7, system => 'solfege' }
Somin	{ bass => '', ext => '', ext_canon => '', name => 'Somin', qual => 'min', qual_canon => '-', root => 'So', root_canon => 'So', root_mod => 0, root_ord => 7, system => 'solfege' }
Sodim	{ bass => '', ext => '', ext_canon => '', name => 'Sodim', qual => 'dim', qual_canon => 0, root => 'So', root_canon => 'So', root_mod => 0, root_ord => 7, system => 'solfege' }
Soadd9	{ bass => '', ext => 'add9', ext_canon => 'add9', name => 'Soadd9', qual => '', qual_canon => '', root => 'So', root_canon => 'So', root_mod => 0, root_ord => 7, system => 'solfege' }
So(add9)	{ bass => '', ext => 'add9', ext_canon => 'add9', name => 'Soadd9', qual => '', qual_canon => '', root => 'So', root_canon => 'So', root_mod => 0, root_ord => 7, system => 'solfege' }
So/La	{ bass => 'La', bass_canon => 'La', bass_mod => 0, bass_ord => 9, ext => '', ext_canon => '', name => 'So/La', qual => '', qual_canon => '', root => 'So', root_canon => 'So', root_mod => 0, root_ord => 7, system => 'solfege' }
So/Ti	{ bass => 'Ti', bass_canon => 'Ti', bass_mod => 0, bass_ord => 11, ext => '', ext_canon => '', name => 'So/Ti', qual => '', qual_canon => '', root => 'So', root_canon => 'So', root_mod => 0, root_ord => 7, system => 'solfege' }
So/Re	{ bass => 'Re', bass_canon => 'Re', bass_mod => 0, bass_ord => 2, ext => '', ext_canon => '', name => 'So/Re', qual => '', qual_canon => '', root => 'So', root_canon => 'So', root_mod => 0, root_ord => 7, system => 'solfege' }
So/Fi	{ bass => 'Fi', bass_canon => 'Fi', bass_mod => 1, bass_ord => 6, ext => '', ext_canon => '', name => 'So/Fi', qual => '', qual_canon => '', root => 'So', root_canon => 'So', root_mod => 0, root_ord => 7, system => 'solfege' }
Som6	{ bass => '', ext => 6, ext_canon => 6, name => 'Som6', qual => 'm', qual_canon => '-', root => 'So', root_canon => 'So', root_mod => 0, root_ord => 7, system => 'solfege' }
Som7	{ bass => '', ext => 7, ext_canon => 7, name => 'Som7', qual => 'm', qual_canon => '-', root => 'So', root_canon => 'So', root_mod => 0, root_ord => 7, system => 'solfege' }
Som/Te	{ bass => 'Te', bass_canon => 'Te', bass_mod => -1, bass_ord => 10, ext => '', ext_canon => '', name => 'Som/Te', qual => 'm', qual_canon => '-', root => 'So', root_canon => 'So', root_mod => 0, root_ord => 7, system => 'solfege' }
Si	{ bass => '', ext => '', ext_canon => '', name => 'Si', qual => '', qual_canon => '', root => 'Si', root_canon => 'Si', root_mod => 1, root_ord => 8, system => 'solfege' }
Si+	{ bass => '', ext => '', ext_canon => '', name => 'Si+', qual => '+', qual_canon => '+', root => 'Si', root_canon => 'Si', root_mod => 1, root_ord => 8, system => 'solfege' }
Si4	{ bass => '', ext => 4, ext_canon => 4, name => 'Si4', qual => '', qual_canon => '', root => 'Si', root_canon => 'Si', root_mod => 1, root_ord => 8, system => 'solfege' }
Si7	{ bass => '', ext => 7, ext_canon => 7, name => 'Si7', qual => '', qual_canon => '', root => 'Si', root_canon => 'Si', root_mod => 1, root_ord => 8, system => 'solfege' }
Sisus	{ bass => '', ext => 'sus', ext_canon => 'sus4', name => 'Sisus', qual => '', qual_canon => '', root => 'Si', root_canon => 'Si', root_mod => 1, root_ord => 8, system => 'solfege' }
Sisus4	{ bass => '', ext => 'sus4', ext_canon => 'sus4', name => 'Sisus4', qual => '', qual_canon => '', root => 'Si', root_canon => 'Si', root_mod => 1, root_ord => 8, system => 'solfege' }
Simaj	{ bass => '', ext => '', ext_canon => '', name => 'Simaj', qual => '', qual_canon => '', root => 'Si', root_canon => 'Si', root_mod => 1, root_ord => 8, system => 'solfege' }
Simaj7	{ bass => '', ext => 'maj7', ext_canon => 'maj7', name => 'Simaj7', qual => '', qual_canon => '', root => 'Si', root_canon => 'Si', root_mod => 1, root_ord => 8, system => 'solfege' }
Sidim	{ bass => '', ext => '', ext_canon => '', name => 'Sidim', qual => 'dim', qual_canon => 0, root => 'Si', root_canon => 'Si', root_mod => 1, root_ord => 8, system => 'solfege' }
Sim	{ bass => '', ext => '', ext_canon => '', name => 'Sim', qual => 'm', qual_canon => '-', root => 'Si', root_canon => 'Si', root_mod => 1, root_ord => 8, system => 'solfege' }
Simin	{ bass => '', ext => '', ext_canon => '', name => 'Simin', qual => 'min', qual_canon => '-', root => 'Si', root_canon => 'Si', root_mod => 1, root_ord => 8, system => 'solfege' }
Sim6	{ bass => '', ext => 6, ext_canon => 6, name => 'Sim6', qual => 'm', qual_canon => '-', root => 'Si', root_canon => 'Si', root_mod => 1, root_ord => 8, system => 'solfege' }
Sim7	{ bass => '', ext => 7, ext_canon => 7, name => 'Sim7', qual => 'm', qual_canon => '-', root => 'Si', root_canon => 'Si', root_mod => 1, root_ord => 8, system => 'solfege' }
Sim9maj7	{ bass => '', ext => '9maj7', ext_canon => '9maj7', name => 'Sim9maj7', qual => 'm', qual_canon => '-', root => 'Si', root_canon => 'Si', root_mod => 1, root_ord => 8, system => 'solfege' }
Le	{ bass => '', ext => '', ext_canon => '', name => 'Le', qual => '', qual_canon => '', root => 'Le', root_canon => 'Le', root_mod => -1, root_ord => 8, system => 'solfege' }
Le+	{ bass => '', ext => '', ext_canon => '', name => 'Le+', qual => '+', qual_canon => '+', root => 'Le', root_canon => 'Le', root_mod => -1, root_ord => 8, system => 'solfege' }
Le4	{ bass => '', ext => 4, ext_canon => 4, name => 'Le4', qual => '', qual_canon => '', root => 'Le', root_canon => 'Le', root_mod => -1, root_ord => 8, system => 'solfege' }
Le7	{ bass => '', ext => 7, ext_canon => 7, name => 'Le7', qual => '', qual_canon => '', root => 'Le', root_canon => 'Le', root_mod => -1, root_ord => 8, system => 'solfege' }
Le11	{ bass => '', ext => 11, ext_canon => 11, name => 'Le11', qual => '', qual_canon => '', root => 'Le', root_canon => 'Le', root_mod => -1, root_ord => 8, system => 'solfege' }
Lesus	{ bass => '', ext => 'sus', ext_canon => 'sus4', name => 'Lesus', qual => '', qual_canon => '', root => 'Le', root_canon => 'Le', root_mod => -1, root_ord => 8, system => 'solfege' }
Lesus4	{ bass => '', ext => 'sus4', ext_canon => 'sus4', name => 'Lesus4', qual => '', qual_canon => '', root => 'Le', root_canon => 'Le', root_mod => -1, root_ord => 8, system => 'solfege' }
Ledim	{ bass => '', ext => '', ext_canon => '', name => 'Ledim', qual => 'dim', qual_canon => 0, root => 'Le', root_canon => 'Le', root_mod => -1, root_ord => 8, system => 'solfege' }
Lemaj	{ bass => '', ext => '', ext_canon => '', name => 'Lemaj', qual => '', qual_canon => '', root => 'Le', root_canon => 'Le', root_mod => -1, root_ord => 8, system => 'solfege' }
Lemaj7	{ bass => '', ext => 'maj7', ext_canon => 'maj7', name => 'Lemaj7', qual => '', qual_canon => '', root => 'Le', root_canon => 'Le', root_mod => -1, root_ord => 8, system => 'solfege' }
Lem	{ bass => '', ext => '', ext_canon => '', name => 'Lem', qual => 'm', qual_canon => '-', root => 'Le', root_canon => 'Le', root_mod => -1, root_ord => 8, system => 'solfege' }
Lemin	{ bass => '', ext => '', ext_canon => '', name => 'Lemin', qual => 'min', qual_canon => '-', root => 'Le', root_canon => 'Le', root_mod => -1, root_ord => 8, system => 'solfege' }
Lem7	{ bass => '', ext => 7, ext_canon => 7, name => 'Lem7', qual => 'm', qual_canon => '-', root => 'Le', root_canon => 'Le', root_mod => -1, root_ord => 8, system => 'solfege' }
La	{ bass => '', ext => '', ext_canon => '', name => 'La', qual => '', qual_canon => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'solfege' }
La+	{ bass => '', ext => '', ext_canon => '', name => 'La+', qual => '+', qual_canon => '+', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'solfege' }
La4	{ bass => '', ext => 4, ext_canon => 4, name => 'La4', qual => '', qual_canon => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'solfege' }
La6	{ bass => '', ext => 6, ext_canon => 6, name => 'La6', qual => '', qual_canon => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'solfege' }
La7	{ bass => '', ext => 7, ext_canon => 7, name => 'La7', qual => '', qual_canon => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'solfege' }
La9	{ bass => '', ext => 9, ext_canon => 9, name => 'La9', qual => '', qual_canon => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'solfege' }
La11	{ bass => '', ext => 11, ext_canon => 11, name => 'La11', qual => '', qual_canon => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'solfege' }
La13	{ bass => '', ext => 13, ext_canon => 13, name => 'La13', qual => '', qual_canon => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'solfege' }
La7sus4	{ bass => '', ext => '7sus4', ext_canon => '7sus4', name => 'La7sus4', qual => '', qual_canon => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'solfege' }
La9sus	{ bass => '', ext => '9sus', ext_canon => '9sus', name => 'La9sus', qual => '', qual_canon => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'solfege' }
Lasus	{ bass => '', ext => 'sus', ext_canon => 'sus4', name => 'Lasus', qual => '', qual_canon => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'solfege' }
Lasus2	{ bass => '', ext => 'sus2', ext_canon => 'sus2', name => 'Lasus2', qual => '', qual_canon => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'solfege' }
Lasus4	{ bass => '', ext => 'sus4', ext_canon => 'sus4', name => 'Lasus4', qual => '', qual_canon => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'solfege' }
Ladim	{ bass => '', ext => '', ext_canon => '', name => 'Ladim', qual => 'dim', qual_canon => 0, root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'solfege' }
Lamaj	{ bass => '', ext => '', ext_canon => '', name => 'Lamaj', qual => '', qual_canon => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'solfege' }
Lamaj7	{ bass => '', ext => 'maj7', ext_canon => 'maj7', name => 'Lamaj7', qual => '', qual_canon => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'solfege' }
Lam	{ bass => '', ext => '', ext_canon => '', name => 'Lam', qual => 'm', qual_canon => '-', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'solfege' }
Lamin	{ bass => '', ext => '', ext_canon => '', name => 'Lamin', qual => 'min', qual_canon => '-', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'solfege' }
La/Di	{ bass => 'Di', bass_canon => 'Di', bass_mod => 1, bass_ord => 1, ext => '', ext_canon => '', name => 'La/Di', qual => '', qual_canon => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'solfege' }
La/Re	{ bass => 'Re', bass_canon => 'Re', bass_mod => 0, bass_ord => 2, ext => '', ext_canon => '', name => 'La/Re', qual => '', qual_canon => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'solfege' }
La/Mi	{ bass => 'Mi', bass_canon => 'Mi', bass_mod => 0, bass_ord => 4, ext => '', ext_canon => '', name => 'La/Mi', qual => '', qual_canon => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'solfege' }
La/Fi	{ bass => 'Fi', bass_canon => 'Fi', bass_mod => 1, bass_ord => 6, ext => '', ext_canon => '', name => 'La/Fi', qual => '', qual_canon => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'solfege' }
La/Si	{ bass => 'Si', bass_canon => 'Si', bass_mod => 1, bass_ord => 8, ext => '', ext_canon => '', name => 'La/Si', qual => '', qual_canon => '', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'solfege' }
Lam#7	{ bass => '', ext => '#7', ext_canon => '#7', name => 'Lam#7', qual => 'm', qual_canon => '-', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'solfege' }
Lam6	{ bass => '', ext => 6, ext_canon => 6, name => 'Lam6', qual => 'm', qual_canon => '-', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'solfege' }
Lam7	{ bass => '', ext => 7, ext_canon => 7, name => 'Lam7', qual => 'm', qual_canon => '-', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'solfege' }
Lam7sus4	{ bass => '', ext => '7sus4', ext_canon => '7sus4', name => 'Lam7sus4', qual => 'm', qual_canon => '-', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'solfege' }
Lam9	{ bass => '', ext => 9, ext_canon => 9, name => 'Lam9', qual => 'm', qual_canon => '-', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'solfege' }
Lam/So	{ bass => 'So', bass_canon => 'So', bass_mod => 0, bass_ord => 7, ext => '', ext_canon => '', name => 'Lam/So', qual => 'm', qual_canon => '-', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'solfege' }
Lamadd9	{ bass => '', ext => 'add9', ext_canon => 'add9', name => 'Lamadd9', qual => 'm', qual_canon => '-', root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'solfege' }
Li	{ bass => '', ext => '', ext_canon => '', name => 'Li', qual => '', qual_canon => '', root => 'Li', root_canon => 'Li', root_mod => 1, root_ord => 10, system => 'solfege' }
Li+	{ bass => '', ext => '', ext_canon => '', name => 'Li+', qual => '+', qual_canon => '+', root => 'Li', root_canon => 'Li', root_mod => 1, root_ord => 10, system => 'solfege' }
Li4	{ bass => '', ext => 4, ext_canon => 4, name => 'Li4', qual => '', qual_canon => '', root => 'Li', root_canon => 'Li', root_mod => 1, root_ord => 10, system => 'solfege' }
Li7	{ bass => '', ext => 7, ext_canon => 7, name => 'Li7', qual => '', qual_canon => '', root => 'Li', root_canon => 'Li', root_mod => 1, root_ord => 10, system => 'solfege' }
Lisus	{ bass => '', ext => 'sus', ext_canon => 'sus4', name => 'Lisus', qual => '', qual_canon => '', root => 'Li', root_canon => 'Li', root_mod => 1, root_ord => 10, system => 'solfege' }
Lisus4	{ bass => '', ext => 'sus4', ext_canon => 'sus4', name => 'Lisus4', qual => '', qual_canon => '', root => 'Li', root_canon => 'Li', root_mod => 1, root_ord => 10, system => 'solfege' }
Limaj	{ bass => '', ext => '', ext_canon => '', name => 'Limaj', qual => '', qual_canon => '', root => 'Li', root_canon => 'Li', root_mod => 1, root_ord => 10, system => 'solfege' }
Limaj7	{ bass => '', ext => 'maj7', ext_canon => 'maj7', name => 'Limaj7', qual => '', qual_canon => '', root => 'Li', root_canon => 'Li', root_mod => 1, root_ord => 10, system => 'solfege' }
Lidim	{ bass => '', ext => '', ext_canon => '', name => 'Lidim', qual => 'dim', qual_canon => 0, root => 'Li', root_canon => 'Li', root_mod => 1, root_ord => 10, system => 'solfege' }
Lim	{ bass => '', ext => '', ext_canon => '', name => 'Lim', qual => 'm', qual_canon => '-', root => 'Li', root_canon => 'Li', root_mod => 1, root_ord => 10, system => 'solfege' }
Limin	{ bass => '', ext => '', ext_canon => '', name => 'Limin', qual => 'min', qual_canon => '-', root => 'Li', root_canon => 'Li', root_mod => 1, root_ord => 10, system => 'solfege' }
Lim7	{ bass => '', ext => 7, ext_canon => 7, name => 'Lim7', qual => 'm', qual_canon => '-', root => 'Li', root_canon => 'Li', root_mod => 1, root_ord => 10, system => 'solfege' }
Te	{ bass => '', ext => '', ext_canon => '', name => 'Te', qual => '', qual_canon => '', root => 'Te', root_canon => 'Te', root_mod => -1, root_ord => 10, system => 'solfege' }
Te+	{ bass => '', ext => '', ext_canon => '', name => 'Te+', qual => '+', qual_canon => '+', root => 'Te', root_canon => 'Te', root_mod => -1, root_ord => 10, system => 'solfege' }
Te4	{ bass => '', ext => 4, ext_canon => 4, name => 'Te4', qual => '', qual_canon => '', root => 'Te', root_canon => 'Te', root_mod => -1, root_ord => 10, system => 'solfege' }
Te6	{ bass => '', ext => 6, ext_canon => 6, name => 'Te6', qual => '', qual_canon => '', root => 'Te', root_canon => 'Te', root_mod => -1, root_ord => 10, system => 'solfege' }
Te7	{ bass => '', ext => 7, ext_canon => 7, name => 'Te7', qual => '', qual_canon => '', root => 'Te', root_canon => 'Te', root_mod => -1, root_ord => 10, system => 'solfege' }
Te9	{ bass => '', ext => 9, ext_canon => 9, name => 'Te9', qual => '', qual_canon => '', root => 'Te', root_canon => 'Te', root_mod => -1, root_ord => 10, system => 'solfege' }
Te11	{ bass => '', ext => 11, ext_canon => 11, name => 'Te11', qual => '', qual_canon => '', root => 'Te', root_canon => 'Te', root_mod => -1, root_ord => 10, system => 'solfege' }
Tesus	{ bass => '', ext => 'sus', ext_canon => 'sus4', name => 'Tesus', qual => '', qual_canon => '', root => 'Te', root_canon => 'Te', root_mod => -1, root_ord => 10, system => 'solfege' }
Tesus4	{ bass => '', ext => 'sus4', ext_canon => 'sus4', name => 'Tesus4', qual => '', qual_canon => '', root => 'Te', root_canon => 'Te', root_mod => -1, root_ord => 10, system => 'solfege' }
Temaj	{ bass => '', ext => '', ext_canon => '', name => 'Temaj', qual => '', qual_canon => '', root => 'Te', root_canon => 'Te', root_mod => -1, root_ord => 10, system => 'solfege' }
Temaj7	{ bass => '', ext => 'maj7', ext_canon => 'maj7', name => 'Temaj7', qual => '', qual_canon => '', root => 'Te', root_canon => 'Te', root_mod => -1, root_ord => 10, system => 'solfege' }
Tedim	{ bass => '', ext => '', ext_canon => '', name => 'Tedim', qual => 'dim', qual_canon => 0, root => 'Te', root_canon => 'Te', root_mod => -1, root_ord => 10, system => 'solfege' }
Tem	{ bass => '', ext => '', ext_canon => '', name => 'Tem', qual => 'm', qual_canon => '-', root => 'Te', root_canon => 'Te', root_mod => -1, root_ord => 10, system => 'solfege' }
Temin	{ bass => '', ext => '', ext_canon => '', name => 'Temin', qual => 'min', qual_canon => '-', root => 'Te', root_canon => 'Te', root_mod => -1, root_ord => 10, system => 'solfege' }
Tem7	{ bass => '', ext => 7, ext_canon => 7, name => 'Tem7', qual => 'm', qual_canon => '-', root => 'Te', root_canon => 'Te', root_mod => -1, root_ord => 10, system => 'solfege' }
Tem9	{ bass => '', ext => 9, ext_canon => 9, name => 'Tem9', qual => 'm', qual_canon => '-', root => 'Te', root_canon => 'Te', root_mod => -1, root_ord => 10, system => 'solfege' }
Ti	{ bass => '', ext => '', ext_canon => '', name => 'Ti', qual => '', qual_canon => '', root => 'Ti', root_canon => 'Ti', root_mod => 0, root_ord => 11, system => 'solfege' }
Ti+	{ bass => '', ext => '', ext_canon => '', name => 'Ti+', qual => '+', qual_canon => '+', root => 'Ti', root_canon => 'Ti', root_mod => 0, root_ord => 11, system => 'solfege' }
Ti4	{ bass => '', ext => 4, ext_canon => 4, name => 'Ti4', qual => '', qual_canon => '', root => 'Ti', root_canon => 'Ti', root_mod => 0, root_ord => 11, system => 'solfege' }
Ti7	{ bass => '', ext => 7, ext_canon => 7, name => 'Ti7', qual => '', qual_canon => '', root => 'Ti', root_canon => 'Ti', root_mod => 0, root_ord => 11, system => 'solfege' }
Ti7#9	{ bass => '', ext => '7#9', ext_canon => '7#9', name => 'Ti7#9', qual => '', qual_canon => '', root => 'Ti', root_canon => 'Ti', root_mod => 0, root_ord => 11, system => 'solfege' }
Ti9	{ bass => '', ext => 9, ext_canon => 9, name => 'Ti9', qual => '', qual_canon => '', root => 'Ti', root_canon => 'Ti', root_mod => 0, root_ord => 11, system => 'solfege' }
Ti11	{ bass => '', ext => 11, ext_canon => 11, name => 'Ti11', qual => '', qual_canon => '', root => 'Ti', root_canon => 'Ti', root_mod => 0, root_ord => 11, system => 'solfege' }
Ti13	{ bass => '', ext => 13, ext_canon => 13, name => 'Ti13', qual => '', qual_canon => '', root => 'Ti', root_canon => 'Ti', root_mod => 0, root_ord => 11, system => 'solfege' }
Tisus	{ bass => '', ext => 'sus', ext_canon => 'sus4', name => 'Tisus', qual => '', qual_canon => '', root => 'Ti', root_canon => 'Ti', root_mod => 0, root_ord => 11, system => 'solfege' }
Tisus4	{ bass => '', ext => 'sus4', ext_canon => 'sus4', name => 'Tisus4', qual => '', qual_canon => '', root => 'Ti', root_canon => 'Ti', root_mod => 0, root_ord => 11, system => 'solfege' }
Timaj	{ bass => '', ext => '', ext_canon => '', name => 'Timaj', qual => '', qual_canon => '', root => 'Ti', root_canon => 'Ti', root_mod => 0, root_ord => 11, system => 'solfege' }
Timaj7	{ bass => '', ext => 'maj7', ext_canon => 'maj7', name => 'Timaj7', qual => '', qual_canon => '', root => 'Ti', root_canon => 'Ti', root_mod => 0, root_ord => 11, system => 'solfege' }
Tidim	{ bass => '', ext => '', ext_canon => '', name => 'Tidim', qual => 'dim', qual_canon => 0, root => 'Ti', root_canon => 'Ti', root_mod => 0, root_ord => 11, system => 'solfege' }
Tim	{ bass => '', ext => '', ext_canon => '', name => 'Tim', qual => 'm', qual_canon => '-', root => 'Ti', root_canon => 'Ti', root_mod => 0, root_ord => 11, system => 'solfege' }
Timin	{ bass => '', ext => '', ext_canon => '', name => 'Timin', qual => 'min', qual_canon => '-', root => 'Ti', root_canon => 'Ti', root_mod => 0, root_ord => 11, system => 'solfege' }
Ti/Fi	{ bass => 'Fi', bass_canon => 'Fi', bass_mod => 1, bass_ord => 6, ext => '', ext_canon => '', name => 'Ti/Fi', qual => '', qual_canon => '', root => 'Ti', root_canon => 'Ti', root_mod => 0, root_ord => 11, system => 'solfege' }
Tim6	{ bass => '', ext => 6, ext_canon => 6, name => 'Tim6', qual => 'm', qual_canon => '-', root => 'Ti', root_canon => 'Ti', root_mod => 0, root_ord => 11, system => 'solfege' }
Tim7	{ bass => '', ext => 7, ext_canon => 7, name => 'Tim7', qual => 'm', qual_canon => '-', root => 'Ti', root_canon => 'Ti', root_mod => 0, root_ord => 11, system => 'solfege' }
Timmaj7	{ bass => '', ext => 'maj7', ext_canon => 'maj7', name => 'Timmaj7', qual => 'm', qual_canon => '-', root => 'Ti', root_canon => 'Ti', root_mod => 0, root_ord => 11, system => 'solfege' }
Timsus9	{ bass => '', ext => 'sus9', ext_canon => 'sus9', name => 'Timsus9', qual => 'm', qual_canon => '-', root => 'Ti', root_canon => 'Ti', root_mod => 0, root_ord => 11, system => 'solfege' }
Tim7b5	{ bass => '', ext => '7b5', ext_canon => '7b5', name => 'Tim7b5', qual => 'm', qual_canon => '-', root => 'Ti', root_canon => 'Ti', root_mod => 0, root_ord => 11, system => 'solfege' }
