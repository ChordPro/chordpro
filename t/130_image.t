#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Songbook;

plan tests => 6;

# Prevent a dummy {body} for chord grids.
$config->{diagrams}->{show} = 0;
my $s = ChordPro::Songbook->new;

# Image (minimal).
my $data = <<EOD;
{title: Swing Low Sweet Chariot}
{image 130_image.jpg}
EOD

eval { $s->parse_file(\$data) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'ChordPro::Song', "It's a song" );
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
			'context' => '',
			'uri' => './130_image.jpg',
			'type' => 'image',
			'opts' => {}
		       }
		      ],
	    'source' => { file => "__STRING__", line => 1 },
	    'structure' => 'linear',
	    'system' => 'common',
	   };

is_deeply( { %{ $s->{songs}->[0] } }, $song, "Song contents" );

# Image (all options).
$s = ChordPro::Songbook->new;
$data = <<EOD;
{title: Swing Low Sweet Chariot}
{image 130_image.jpg width=200 height=150 border=2 center scale=4 title="A red image"}
EOD

eval { $s->parse_file(\$data) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'ChordPro::Song', "It's a song" );
#use Data::Dumper; warn(Dumper($s));
$song = {
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
	    'settings' => {},
	    'body' => [
		       {
			'type' => 'image',
			'opts' => {
				   'title' => 'A red image',
				   'height' => '150',
				   'border' => '2',
				   'scale' => '4',
				   'center' => 1,
				   'width' => '200'
				  },
			'uri' => './130_image.jpg',
			'context' => ''
		       }
		      ],
	      'chordsinfo' => {},
	   };

is_deeply( { %{ $s->{songs}->[0] } }, $song, "Song contents" );
