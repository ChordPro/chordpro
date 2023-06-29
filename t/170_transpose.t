#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Songbook;

plan tests => 6;

my $s = ChordPro::Songbook->new;

my $data = <<EOD;
{title: Swing Low Sweet Chariot}
{key: D}
I [D]looked over Jordan, [NC]and [G/B]what did I [D]see,
{transpose: 2}
I [D]looked over Jordan, [NC]and [G/B]what did I [D]see, %{key_actual}
{transpose}
EOD

ChordPro::Chords::add_config_chord
  ( { name => [ "NC", "N.C." ], frets => [ -1, -1, -1, -1, -1, -1 ] } );

eval { $s->parse_file( \$data, { transpose => 0 } ) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'ChordPro::Song', "It's a song" );

my $song = {
	    'settings' => {},
	    'meta' => {
		       'songindex' => 1,
		       'key'   => [ 'D' ],
#		       'key_from'   => [ 'D' ],
#		       'key_actual'   => [ 'E' ],
		       'title' => [
				   'Swing Low Sweet Chariot'
				  ],
		      },
	    'title' => 'Swing Low Sweet Chariot',
	    'chords' => {
			 'origin' => 'song',
			 'type' => 'diagrams',
			 'show' => 'all',
			 'chords' => [
				      'D',
				      'G/B',
				      'E',
				      'A/C#'
				     ]
			},
	    'body' => [
                       {
			 'context' => '',
			 'phrases' => [
					'I ',
				        'looked over Jordan, ',
				        'and ',
					'what did I ',
					'see,'
				      ],
			 'chords' => [
				       '',
				       'D',
				       'NC',
				       'G/B',
				       'D'
				     ],
			 'type' => 'songline'
		       },
                       {
			 'context' => '',
			 'phrases' => [
					'I ',
				        'looked over Jordan, ',
				        'and ',
					'what did I ',
					'see, E'
				      ],
			 'chords' => [
				       '',
				       'E',
				       'NC',
				       'A/C#',
				       'E'
				     ],
			 'orig' => 'I [D]looked over Jordan, [NC]and [G/B]what did I [D]see, %{key_actual}',
			 'type' => 'songline'
		       }
		      ],
	    'chordsinfo' => { map { $_ => $_ } qw( D G/B E ), 'A/C#', 'NC' },
	    'source' => { file => "__STRING__", line => 1 },
	    'structure' => 'linear',
	    'system' => 'common',
	   };

is_deeply( { %{ $s->{songs}->[0] } }, $song, "Song contents" );

$data = <<EOD;
{title: Swing Low Sweet Chariot}
{key: D}
I [D]looked over Jordan, [N.C.]and [G/B]what did I [D]see,
EOD

eval { $s->parse_file( \$data, { transpose => 3 } ) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 2, "One more song" );
isa_ok( $s->{songs}->[1], 'ChordPro::Song', "It's a song" );

$song = {
	    'settings' => {},
	    'meta' => {
		       'songindex' => 2,
		       'key'   => [ 'F' ],
		       'title' => [
				   'Swing Low Sweet Chariot'
				  ],
		      },
	    'title' => 'Swing Low Sweet Chariot',
	    'chords' => {
			 'origin' => 'song',
			 'type' => 'diagrams',
			 'show' => 'all',
			 'chords' => [
				      'F',
				      'A#/D'
				     ]
			},
	    'body' => [
                       {
			 'context' => '',
			 'phrases' => [
					'I ',
				        'looked over Jordan, ',
				        'and ',
					'what did I ',
					'see,'
				      ],
			 'chords' => [
				       '',
				       'F',
				       'N.C.',
				       'A#/D',
				       'F'
				     ],
			 'type' => 'songline'
		       }
		      ],
	    'chordsinfo' => { map { $_ => $_ } qw( F ), 'A#/D', 'N.C.' },
	    'source' => { file => "__STRING__", line => 1 },
	    'structure' => 'linear',
	    'system' => 'common',
	   };

is_deeply( { %{ $s->{songs}->[1] } }, $song, "Song contents" );
