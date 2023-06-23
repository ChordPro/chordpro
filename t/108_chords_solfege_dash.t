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
Tim7-5	{ bass => '', ext => '7-5', ext_canon => '7-5', name => 'Tim7-5', qual => 'm', qual_canon => '-', root => 'Ti', root_canon => 'Ti', root_mod => 0, root_ord => 11, system => 'solfege' }
Di7(-5)	{ bass => '', ext => '7-5', ext_canon => '7-5', name => 'Di7-5', qual => '', qual_canon => '', root => 'Di', root_canon => 'Di', root_mod => 1, root_ord => 1, system => 'solfege' }
Mi7(-5)	{ bass => '', ext => '7-5', ext_canon => '7-5', name => 'Mi7-5', qual => '', qual_canon => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'solfege' }
Mi7-9	{ bass => '', ext => '7-9', ext_canon => '7-9', name => 'Mi7-9', qual => '', qual_canon => '', root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'solfege' }
Fim7-5	{ bass => '', ext => '7-5', ext_canon => '7-5', name => 'Fim7-5', qual => 'm', qual_canon => '-', root => 'Fi', root_canon => 'Fi', root_mod => 1, root_ord => 6, system => 'solfege' }
So7-9	{ bass => '', ext => '7-9', ext_canon => '7-9', name => 'So7-9', qual => '', qual_canon => '', root => 'So', root_canon => 'So', root_mod => 0, root_ord => 7, system => 'solfege' }
Tim7-5	{ bass => '', ext => '7-5', ext_canon => '7-5', name => 'Tim7-5', qual => 'm', qual_canon => '-', root => 'Ti', root_canon => 'Ti', root_mod => 0, root_ord => 11, system => 'solfege' }
