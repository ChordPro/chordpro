#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Test::More tests => 3;

use App::Music::ChordPro::Config;
use App::Music::ChordPro::Songbook;

my $config = App::Music::ChordPro::Config::configurator;
my $s = App::Music::ChordPro::Songbook->new;

my $data = <<EOD;
{title: Swing Low Sweet Chariot}
I [D]looked over Jordan, and [G]what did I [D]see,
EOD

eval { $s->parsefile(\$data) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'App::Music::ChordPro::Song', "It's a song" );

my $song = {
	    'settings' => {},
	    'meta' => {
		       'title' => [
				   'Swing Low Sweet Chariot'
				  ],
		      },
	    'title' => 'Swing Low Sweet Chariot',
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
				       'D',
				       'G',
				       'D'
				     ],
			 'type' => 'songline'
		       }
		      ],
	    'structure' => 'linear',
	   };

is_deeply( { %{ $s->{songs}->[0] } }, $song, "Song contents" );
