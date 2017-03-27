#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Test::More tests => 3;

use App::Music::ChordPro::Config;
use App::Music::ChordPro::Songbook;

our $config = App::Music::ChordPro::Config::configurator;
# Prevent a dummy {body} for chord grids.
$config->{chordgrid}->{show} = 0;
my $s = App::Music::ChordPro::Songbook->new;

# Transposition happens at compile time, %{...} is handled by the backends.
my $data = <<EOD;
{t Swing Low Sweet Chariot}
{c This is a comment}
{c This song is %{title} in the key of [C]}
{highlight This is also a comment}
{ci This is a comment_italic}
{cb This is a comment_box}
EOD

eval { $s->parsefile(\$data, { transpose => 2 } ) } or diag("$@");

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
			'type' => 'comment',
			'context' => '',
			'text' => 'This is a comment',
			'orig' => 'This is a comment'
		       },
		       {
			'type' => 'comment',
			'context' => '',
			'phrases' => [ 'This song is %{title} in the key of ',
				       '',
				     ],
			'chords' => [ '', 'D' ],
			'orig' => 'This song is %{title} in the key of [C]',
		       },
		       {
			'type' => 'comment',
			'context' => '',
			'text' => 'This is also a comment',
			'orig' => 'This is also a comment',
		       },
		       {
			'context' => '',
			'type' => 'comment_italic',
			'text' => 'This is a comment_italic',
			'orig' => 'This is a comment_italic'
		       },
		       {
			'text' => 'This is a comment_box',
			'orig' => 'This is a comment_box',
			'context' => '',
			'type' => 'comment_box'
		       }
		      ],
	    'structure' => 'linear',
	   };

is_deeply( { %{ $s->{songs}->[0] } }, $song, "Song contents" );
