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

# Image (minimal).
my $data = <<EOD;
{title: Swing Low Sweet Chariot}
{image red.jpg}
EOD

eval { $s->parsefile(\$data) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'App::Music::ChordPro::Song', "It's a song" );
#use Data::Dumper; warn(Dumper($s));
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
			'uri' => 'red.jpg',
			'type' => 'image',
			'opts' => {}
		       }
		      ],
	    'structure' => 'linear',
	   };

is_deeply( { %{ $s->{songs}->[0] } }, $song, "Song contents" );

# Image (all options).
$s = App::Music::ChordPro::Songbook->new;
$data = <<EOD;
{title: Swing Low Sweet Chariot}
{image red.jpg width=200 height=150 border=2 center scale=4 title="A red image"}
EOD

eval { $s->parsefile(\$data) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'App::Music::ChordPro::Song', "It's a song" );
#use Data::Dumper; warn(Dumper($s));
$song = {
	    'title' => 'Swing Low Sweet Chariot',
	    'structure' => 'linear',
	    'meta' => {
		       'title' => [
				   'Swing Low Sweet Chariot'
				  ]
		      },
	    'settings' => {},
	    'body' => [
		       {
			'type' => 'image',
			'opts' => {
				   'title' => 'title',
				   'height' => '150',
				   'border' => '2',
				   'scale' => '4',
				   'center' => 1,
				   'width' => '200'
				  },
			'uri' => 'red.jpg',
			'context' => ''
		       }
		      ]
	   };

is_deeply( { %{ $s->{songs}->[0] } }, $song, "Song contents" );
