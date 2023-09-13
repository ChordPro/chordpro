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

# Fonts definitions.
my $data = <<EOD;
{title: Swing Low Sweet Chariot}
{textcolor: blue}
{choruscolor: red}
Song line in blue
{textcolor green}
Song line in green (chorus would be green as well)
{textcolour}
Song line in blue again
{start_of_chorus}
Chorus line should be red again
{end_of_chorus}
EOD

eval { $s->parse_file(\$data) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'ChordPro::Song', "It's a song" );
#use Data::Dumper; warn(Dumper($s));
my $song = {
	    'settings' => {},
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
	    'body' => [
			   {
			     'value' => 'blue',
			     'context' => '',
			     'name' => 'text-color',
			     'type' => 'control'
			   },
			   {
			     'value' => 'blue',
			     'context' => '',
			     'name' => 'chorus-color',
			     'type' => 'control'
			   },
			   {
			     'name' => 'chorus-color',
			     'type' => 'control',
			     'context' => '',
			     'value' => 'red'
			   },
			   {
			     'type' => 'songline',
			     'context' => '',
			     'phrases' => [
					    'Song line in blue'
					  ]
			   },
			   {
			     'value' => 'green',
			     'context' => '',
			     'name' => 'text-color',
			     'type' => 'control'
			   },
			   {
			     'name' => 'chorus-color',
			     'type' => 'control',
			     'value' => 'green',
			     'context' => ''
			   },
			   {
			     'phrases' => [
					    'Song line in green (chorus would be green as well)'
					  ],
			     'context' => '',
			     'type' => 'songline'
			   },
			   {
			     'type' => 'control',
			     'name' => 'text-color',
			     'value' => 'blue',
			     'context' => ''
			   },
			   {
			     'value' => 'red',
			     'context' => '',
			     'name' => 'chorus-color',
			     'type' => 'control'
			   },
			   {
			     'phrases' => [
					    'Song line in blue again'
					  ],
			     'context' => '',
			     'type' => 'songline'
			   },
			   {
			     'context' => 'chorus',
			     'phrases' => [
					    'Chorus line should be red again'
					  ],
			     'type' => 'songline'
			   },
			   {
			     'type' => 'set',
			     'name' => 'context',
			     'value' => '',
			     'context' => 'chorus'
			   }
		      ]
 	   };

is_deeply( { %{ $s->{songs}->[0] } }, $song, "Song contents" );
