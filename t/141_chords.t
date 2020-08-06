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

# Chord definitions.
my $data = <<EOD;
{title: Swing Low Sweet Chariot}

Hello World!

{define Fas base-fret 2 frets x 0 3 2 1 0}
{chord Fus base-fret 2 frets x 0 3 2 1 0}
{chord: Fos base-fret 2 frets x 0 3 2 1 0}

Hi there.
EOD

eval { $s->parse_file(\$data) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'App::Music::ChordPro::Song', "It's a song" );
#use Data::Dumper; $Data::Dumper::Indent=1; warn(Dumper($s));
my $song = {
	    'settings' => {},
	    'title' => 'Swing Low Sweet Chariot',
	    'source' => { file => "__STRING__", line => 1 },
	    'structure' => 'linear',
	    'system' => 'common',
	    'meta' => {
		       'songindex' => 1,
		       'title' => [
				   'Swing Low Sweet Chariot'
				  ]
		      },
	    'define' => [
			 {
			  'name' => 'Fas',
			  'base' => '2',
			  'frets' => [ -1, '0', '3', '2', '1', '0' ],
			 },
			],
	    'body' => [
		       {
			'context' => '',
			'type' => 'empty'
		       },
		       {
			'context' => '',
			'type' => 'songline',
			'phrases' => [
				      'Hello World!'
				     ]
		       },
		       {
			'type' => 'empty',
			'context' => ''
		       },
		       {
			'context' => '',
			'origin' => 'chord',
			'type' => 'diagrams',
			'show' => 'user',
			'chords' => [
			 {
			  'name' => 'Fus',
			  'base' => '2',
			  'frets' => [ -1, '0', '3', '2', '1', '0' ],
			 },
			 {
			  'name' => 'Fos',
			  'base' => '2',
			  'frets' => [ -1, '0', '3', '2', '1', '0' ],
			 },
				     ],
		       },
		       {
			'type' => 'empty',
			'context' => ''
		       },
		       {
			'context' => '',
			'type' => 'songline',
			'phrases' => [
				      'Hi there.'
				     ]
		       }
		      ]
	   };

is_deeply( { %{ $s->{songs}->[0] } }, $song, "Song contents" );

$s = App::Music::ChordPro::Songbook->new;

# Chord definitions.
$data = <<EOD;
{title: Swing Low Sweet Chariot}
{define Fus frets x 0 3 2 1 0}
{define: Fos frets x 0 3 2 1 0}
{define Fas: frets x 0 3 2 1 0}
EOD

eval { $s->parse_file(\$data) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'App::Music::ChordPro::Song', "It's a song" );

$song = {
	    'settings' => {},
	    'title' => 'Swing Low Sweet Chariot',
	    'source' => { file => "__STRING__", line => 1 },
	    'structure' => 'linear',
	    'system' => 'common',
	    'meta' => {
		       'songindex' => 1,
		       'title' => [
				   'Swing Low Sweet Chariot'
				  ]
		      },
	    'define' => [
			 {
			  'name' => 'Fus',
			  'base' => '1',
			  'frets' => [ -1, '0', '3', '2', '1', '0' ],
			 },
			 {
			  'name' => 'Fos',
			  'base' => '1',
			  'frets' => [ -1, '0', '3', '2', '1', '0' ],
			 },
			 {
			  'name' => 'Fas',
			  'base' => '1',
			  'frets' => [ -1, '0', '3', '2', '1', '0' ],
			 }
			]
	   };

is_deeply( { %{ $s->{songs}->[0] } }, $song, "Song contents" );
