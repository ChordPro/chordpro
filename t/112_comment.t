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

my $data = <<EOD;
{title: Swing Low Sweet Chariot}
{comment: This is a comment}
{comment_italic: This is a comment_italic}
{comment_box: This is a comment_box}
EOD

eval { $s->parse_file(\$data) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'App::Music::ChordPro::Song', "It's a song" );

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
			'type' => 'comment',
			'context' => '',
			'text' => 'This is a comment',
			'orig' => 'This is a comment'
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
	    'source' => { file => "__STRING__", line => 1 },
	    'structure' => 'linear',
	    'system' => 'common',
	   };

is_deeply( { %{ $s->{songs}->[0] } }, $song, "Song contents" );
