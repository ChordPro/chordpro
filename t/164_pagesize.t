#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Test::More tests => 6;

use App::Music::ChordPro::Config;
use App::Music::ChordPro::Songbook;

our $config = App::Music::ChordPro::Config::configurator;
# Prevent a dummy {body} for chord grids.
$config->{diagrams}->{show} = 0;

my $s = App::Music::ChordPro::Songbook->new;

# Columns.
my $data = <<EOD;
{title: Swing Low Sweet Chariot}
{pagesize: a4}
EOD

eval { $s->parsefile(\$data) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'App::Music::ChordPro::Song', "It's a song" );
#use Data::Dumper; warn(Dumper($s));
my $song = {
	    'settings' => {
			   'papersize' => 'a4',
			  },
	    'title' => 'Swing Low Sweet Chariot',
	    'source' => { file => "__STRING__", line => 1 },
	    'structure' => 'linear',
	    'system' => 'common',
	    'meta' => {
		       'title' => [
				   'Swing Low Sweet Chariot'
				  ]
		      },
	   };

is_deeply( { %{ $s->{songs}->[0] } }, $song,
	   "Papersize A4" );

$s = App::Music::ChordPro::Songbook->new;

# Columns.
$data = <<EOD;
{title: Swing Low Sweet Chariot}
{pagetype: letter}
EOD

eval { $s->parsefile(\$data) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'App::Music::ChordPro::Song', "It's a song" );
#use Data::Dumper; warn(Dumper($s));

$song->{settings}->{papersize} = 'letter';

is_deeply( { %{ $s->{songs}->[0] } }, $song,
	   "Papersize Letter" );
