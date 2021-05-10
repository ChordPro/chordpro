#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use App::Music::ChordPro::Testing;
use App::Music::ChordPro::Config;
use App::Music::ChordPro::Songbook;

plan tests => 3;

our $config = App::Music::ChordPro::Config::configurator;
# Prevent a dummy {body} for chord grids.
$config->{diagrams}->{show} = 0;
my $s = App::Music::ChordPro::Songbook->new;

my $data = <<EOD;
{new_song}
{new_song}
EOD

eval { $s->parse_file(\$data) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'App::Music::ChordPro::Song', "It's a song" );

my $song = {
	    'meta' => { songindex => 1 },
	    'settings' => {},
	    'structure' => 'linear',
	    'source' => { file => "__STRING__", line => 1 },
	    'system' => 'common',
	   };

is_deeply( { %{ $s->{songs}->[0] } }, $song, "Song contents" );
