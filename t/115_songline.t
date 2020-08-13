#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Test::More tests => 3;

use App::Music::ChordPro::Config;
use App::Music::ChordPro::Songbook;

our $config = App::Music::ChordPro::Config::configurator;
# Prevent a dummy {body} for chord grids.
$config->{diagrams}->{show} = 0;
my $s = App::Music::ChordPro::Songbook->new;

# Song line with leading / trailing chords.
my $data = <<EOD;
{title: Swing Low Sweet Chariot}

[D]I looked over Jordan, and [G]what did I see,[D]

EOD

eval { $s->parse_file(\$data) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'App::Music::ChordPro::Song', "It's a song" );
#use Data::Dumper; warn(Dumper($s));
my $song = {
	    'settings' => {},
	    'meta' => {
		       'songindex' => 1,
		       'title' => [
				   'Swing Low Sweet Chariot'
				  ],
		      },
	    'title' => 'Swing Low Sweet Chariot',
	    'body' => [
		       {
			'type' => 'empty',
			'context' => ''
		       },
                       {
			 'context' => '',
			 'phrases' => [
					'I looked over Jordan, and ',
					'what did I see,',
					''
				      ],
			 'chords' => [
				       'D',
				       'G',
				       'D'
				     ],
			 'type' => 'songline'
		       },
		       {
			'type' => 'empty',
			'context' => ''
		       }
		      ],
	    'source' => { file => "__STRING__", line => 1 },
	    'structure' => 'linear',
	    'system' => 'common',
	   };

is_deeply( { %{ $s->{songs}->[0] } }, $song, "Song contents" );
