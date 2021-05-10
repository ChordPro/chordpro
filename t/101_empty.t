#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use App::Music::ChordPro::Testing;
use App::Music::ChordPro::Config;
use App::Music::ChordPro::Songbook;

plan tests => 1;

our $config = App::Music::ChordPro::Config::configurator;
# Prevent a dummy {body} for chord grids.
$config->{diagrams}->{show} = 0;

my $s = App::Music::ChordPro::Songbook->new;

my $data = <<EOD;
EOD

eval { $s->parse_file(\$data); 1 } or diag("$@");
#use DDumper; DDumper( $s->{songs} );
ok( scalar( @{ $s->{songs} } ) == 0, "No song" );
#isa_ok( $s->{songs}->[0], 'App::Music::ChordPro::Song', "It's a song" );
#
#my $song = {
#	    'settings' => {},
#	    'structure' => 'linear',
#	    'system' => 'common',
#	   };
#
#is_deeply( { %{ $s->{songs}->[0] } }, $song, "Song contents" );
