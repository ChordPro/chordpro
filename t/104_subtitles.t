#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use ChordPro::Testing;
use ChordPro::Songbook;

plan tests => 3;

# Prevent a dummy {body} for chord grids.
$config->{diagrams}->{show} = 0;
my $s = ChordPro::Songbook->new;

my $data = <<EOD;
{title: Swing Low Sweet Chariot}
{subtitle: Sub Title 1}
{subtitle: Sub Title 2}
EOD

eval { $s->parse_file(\$data) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'ChordPro::Song', "It's a song" );

my $song = {
	    'settings' => {},
	    'meta' => {
		       'songindex' => 1,
		       'title' => [
				   'Swing Low Sweet Chariot'
				  ],
		       'subtitle' => [
				   'Sub Title 1',
				   'Sub Title 2',
				  ]
		      },
	    'title' => 'Swing Low Sweet Chariot',
	    'source' => { file => "__STRING__", line => 1 },
	    'structure' => 'linear',
	    'system' => 'common',
	    'subtitle' => [
			   'Sub Title 1',
			   'Sub Title 2',
			  ]
	   };

is_deeply( { %{ $s->{songs}->[0] } }, $song, "Song contents" );
