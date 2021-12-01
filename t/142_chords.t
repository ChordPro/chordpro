#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use App::Music::ChordPro::Testing;
use App::Music::ChordPro::Songbook;

plan tests => 3;

# Prevent a dummy {body} for chord grids.
$config->{diagrams}->{show} = 0;
my $s = App::Music::ChordPro::Songbook->new;

# Chord definitions.
my $data = <<EOD;
{title: Swing Low Sweet Chariot}

Hello World!

{define Fas base-fret 2 frets x 0 3 2 1 0 fingers x x 3 2 1 x}
{chord Fus base-fret 2 frets x 0 3 2 1 0}
{chord: Fos base-fret 2 frets x 0 3 2 1 0 fingers x x 1 2 3 x}

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
			  'fingers' => [ -1, -1, '3', '2', '1', -1 ],
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
			'chords' => [ ' ch001', ' ch002' ],
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
		      ],
	      'chordsinfo' => { ' ch001' => 'Fus', ' ch002' => 'Fos' },
	   };

is_deeply( { %{ $s->{songs}->[0] } }, $song, "Song contents" );
