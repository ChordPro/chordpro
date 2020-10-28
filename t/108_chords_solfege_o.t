#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Test::More;

use App::Packager ( ':name', 'App::Music::ChordPro' );
use App::Music::ChordPro::Config;
use App::Music::ChordPro::Chords;
use App::Music::ChordPro::Chords::Parser;

my %tbl;

our $config =
      App::Music::ChordPro::Config::configurator
	  ( { nosysconfig => 1, nolegacyconfig => 1, nouserconfig => 1,
	      config => getresource("notes/solfege.json") } );

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
Doo	{ ext => '', ext_canon => '', name => 'Doo', qual => 'o', qual_canon => 0, root => 'Do', root_canon => 'Do', root_mod => 0, root_ord => 0, system => 'solfege' }
Dio	{ ext => '', ext_canon => '', name => 'Dio', qual => 'o', qual_canon => 0, root => 'Di', root_canon => 'Di', root_mod => 1, root_ord => 1, system => 'solfege' }
Rao	{ ext => '', ext_canon => '', name => 'Rao', qual => 'o', qual_canon => 0, root => 'Ra', root_canon => 'Ra', root_mod => -1, root_ord => 1, system => 'solfege' }
Reo	{ ext => '', ext_canon => '', name => 'Reo', qual => 'o', qual_canon => 0, root => 'Re', root_canon => 'Re', root_mod => 0, root_ord => 2, system => 'solfege' }
Rio	{ ext => '', ext_canon => '', name => 'Rio', qual => 'o', qual_canon => 0, root => 'Ri', root_canon => 'Ri', root_mod => 1, root_ord => 3, system => 'solfege' }
Meo	{ ext => '', ext_canon => '', name => 'Meo', qual => 'o', qual_canon => 0, root => 'Me', root_canon => 'Me', root_mod => -1, root_ord => 3, system => 'solfege' }
Mio	{ ext => '', ext_canon => '', name => 'Mio', qual => 'o', qual_canon => 0, root => 'Mi', root_canon => 'Mi', root_mod => 0, root_ord => 4, system => 'solfege' }
Fao	{ ext => '', ext_canon => '', name => 'Fao', qual => 'o', qual_canon => 0, root => 'Fa', root_canon => 'Fa', root_mod => 0, root_ord => 5, system => 'solfege' }
Fio	{ ext => '', ext_canon => '', name => 'Fio', qual => 'o', qual_canon => 0, root => 'Fi', root_canon => 'Fi', root_mod => 1, root_ord => 6, system => 'solfege' }
Seo	{ ext => '', ext_canon => '', name => 'Seo', qual => 'o', qual_canon => 0, root => 'Se', root_canon => 'Se', root_mod => -1, root_ord => 6, system => 'solfege' }
Soo	{ ext => '', ext_canon => '', name => 'Soo', qual => 'o', qual_canon => 0, root => 'So', root_canon => 'So', root_mod => 0, root_ord => 7, system => 'solfege' }
Sio	{ ext => '', ext_canon => '', name => 'Sio', qual => 'o', qual_canon => 0, root => 'Si', root_canon => 'Si', root_mod => 1, root_ord => 8, system => 'solfege' }
Leo	{ ext => '', ext_canon => '', name => 'Leo', qual => 'o', qual_canon => 0, root => 'Le', root_canon => 'Le', root_mod => -1, root_ord => 8, system => 'solfege' }
Lao	{ ext => '', ext_canon => '', name => 'Lao', qual => 'o', qual_canon => 0, root => 'La', root_canon => 'La', root_mod => 0, root_ord => 9, system => 'solfege' }
Lio	{ ext => '', ext_canon => '', name => 'Lio', qual => 'o', qual_canon => 0, root => 'Li', root_canon => 'Li', root_mod => 1, root_ord => 10, system => 'solfege' }
Teo	{ ext => '', ext_canon => '', name => 'Teo', qual => 'o', qual_canon => 0, root => 'Te', root_canon => 'Te', root_mod => -1, root_ord => 10, system => 'solfege' }
Tio	{ ext => '', ext_canon => '', name => 'Tio', qual => 'o', qual_canon => 0, root => 'Ti', root_canon => 'Ti', root_mod => 0, root_ord => 11, system => 'solfege' }
