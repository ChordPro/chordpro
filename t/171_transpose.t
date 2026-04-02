#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Songbook;
use ChordPro::Chords::Transpose;

plan tests => 3;

my $s = ChordPro::Songbook->new;

my $data = <<EOD;
{title: Swing Low Sweet Chariot}
{key: D}
I [D]looked over Jordan, and [Gm7]what did I [D]see,
EOD

eval { $s->parse_file( \$data, { transpose => parse_transpose(-4) } ) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'ChordPro::Song', "It's a song" );

my $song = {
	    'settings' => {},
	    'meta' => {
		       'songindex' => 1,
		       'key' => [ 'D' ],
		       'key_print' => [ 'Bb' ],
		       'key_sound' => [ 'Bb' ],
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
				      'Bb',
				      'Ebm7'
				     ]
			},
	    'body' => [
		       { context => '', type => "meta",
			 key => "key", value => [ "Bb" ] },
                       {
			 'context' => '',
			 'phrases' => [
					'I ',
					'looked over Jordan, and ',
					'what did I ',
					'see,'
				      ],
			 'chords' => [
				       '',
				       'Bb',
				       'Ebm7',
				       'Bb'
				     ],
			 'type' => 'songline'
		       }
		      ],
	    'chordsinfo' => { map { $_ => $_ } qw( D Bb Ebm7 ) },
	    'source' => { file => "__STRING__", line => 1 },
	    'structure' => 'linear',
	    'system' => 'common',
	   };

is_deeply( { %{ $s->{songs}->[0] } }, $song, "Song contents" );
