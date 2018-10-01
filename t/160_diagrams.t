#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Test::More tests => 9;

use App::Music::ChordPro::Config;
use App::Music::ChordPro::Songbook;

our $config = App::Music::ChordPro::Config::configurator;
my $s = App::Music::ChordPro::Songbook->new;

# Chord grids. Added automatically.
my $data = <<EOD;
{title: Swing Low Sweet Chariot}
[G]Swing [D]low, sweet [G]chari[D]ot,
EOD

eval { $s->parsefile(\$data) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'App::Music::ChordPro::Song', "It's a song" );
#use Data::Dumper; warn(Dumper($s));
my $song = {
	    'settings' => {},
	    'title' => 'Swing Low Sweet Chariot',
	    'source' => { file => "__STRING__", line => 1 },
	    'structure' => 'linear',
	    'system' => 'common',
	    'meta' => {
		       'title' => [
				   'Swing Low Sweet Chariot'
				  ]
		      },
	    'body' => [
		       {
			'chords' => [
				     'G',
				     'D',
				     'G',
				     'D'
				    ],
			'type' => 'songline',
			'phrases' => [
				      'Swing ',
				      'low, sweet ',
				      'chari',
				      'ot,'
				     ],
			'context' => ''
		       },
		      ],
	    'chords' => {
			'chords' => [ 'G', 'D' ],
			'origin' => 'song',
			'show' => 'all',
			'type' => 'diagrams'
		       },
	   };

is_deeply( { %{ $s->{songs}->[-1] } }, $song,
	   "Grids are shown by default" );

$s = App::Music::ChordPro::Songbook->new;

# Chord grids. Added automatically. Suppressed.
$data = <<EOD;
{title: Swing Low Sweet Chariot}
{no_grid}
EOD

eval { $s->parsefile(\$data) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'App::Music::ChordPro::Song', "It's a song" );
#use Data::Dumper; warn(Dumper($s));
$song = {
	    'settings' => {
			   'diagrams' => 0
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
	   "Grids suppressed" );

# Prevent a dummy {body} for chord grids.
$config->{diagrams}->{show} = 0;

$s = App::Music::ChordPro::Songbook->new;

# Chord grids. Added automatically.
$data = <<EOD;
{title: Swing Low Sweet Chariot}
{grid}
EOD

eval { $s->parsefile(\$data) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'App::Music::ChordPro::Song', "It's a song" );
#use Data::Dumper; warn(Dumper($s));
$song = {
	    'settings' => {
			   'diagrams' => 1
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
	    'chords' => {
			'chords' => [],
			'origin' => 'song',
			'show' => 'all',
			'type' => 'diagrams'
		       },
	   };

is_deeply( { %{ $s->{songs}->[0] } }, $song,
	   "Grids hidden, but forced" );

