#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Test::More tests => 4;

use App::Packager ( ':name', 'App::Music::ChordPro' );
use App::Music::ChordPro::Config;
use App::Music::ChordPro::Songbook;

# For transcoding, both source and target notation systems must be
# defined. The source system must be last, so it is current and used
# to parse the the input data.

our $config =
  eval {
      App::Music::ChordPro::Config::configurator
	  ( { nosysconfig => 1, nolegacyconfig => 1, nouserconfig => 1,
	      config => [ getresource("notes/latin.json"),
			  getresource("notes/common.json") ],
	      transcode => "latin"
	    } );
  };
ok( $config, "got config" );
my $s = App::Music::ChordPro::Songbook->new;

my $data = <<EOD;
{title: Swing Low Sweet Chariot}
{key: D}
I [D]looked over Jordan, and [Gm7]what did I [D]see,
EOD

eval { $s->parse_file( \$data ) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'App::Music::ChordPro::Song', "It's a song" );

my $song = {
	    'settings' => {},
	    'meta' => {
		       'songindex' => 1,
		       'key' => [ 'Re' ],
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
				      'Re',
				      'Solm7'
				     ]
			},
	    'body' => [
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
				       'Re',
				       'Solm7',
				       'Re'
				     ],
			 'type' => 'songline'
		       }
		      ],
	    'source' => { file => "__STRING__", line => 1 },
	    'structure' => 'linear',
	    'system' => 'common',
	   };

is_deeply( { %{ $s->{songs}->[0] } }, $song, "Song contents" );
