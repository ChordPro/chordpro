#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Test::More tests => 3;

use App::Music::ChordPro::Config;
use App::Music::ChordPro::Songbook;

our $config = App::Music::ChordPro::Config::configurator;
my $s = App::Music::ChordPro::Songbook->new;

my $data = <<EOD;
{transpose: +5}
{title: Transpositions}
{Chorus}
{start_of_chorus}
[D]Chorus line in D.
{end_of_chorus}
[D]Song line in D.
{Chorus}
[D]Song line in D.
{Chorus}
{transpose: +2}
{Chorus}
EOD

eval { $s->parsefile( \$data, { transpose => 0 } ) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'App::Music::ChordPro::Song', "It's a song" );

my $song = {
  'body' => [
    {
      'context' => '',
      'type' => 'rechorus'
    },
    {
      'chords' => [
	'G'
      ],
      'context' => 'chorus',
      'phrases' => [
	'Chorus line in D.'
      ],
      'type' => 'songline'
    },
	{
	 'value' => '',
	 'context' => 'chorus',
	 'name' => 'context',
	 'type' => 'set'
	},
    {
      'chords' => [
	'G'
      ],
      'context' => '',
      'phrases' => [
	'Song line in D.'
      ],
      'type' => 'songline'
    },
    {
      'chorus' => [
	{
	  'chords' => [
	    'G'
	  ],
	  'context' => 'chorus',
	  'phrases' => [
	    'Chorus line in D.'
	  ],
	  'type' => 'songline'
	},
	{
	 'value' => '',
	 'context' => 'chorus',
	 'name' => 'context',
	 'type' => 'set'
	},
      ],
      'context' => '',
      'transpose' => 0,
      'type' => 'rechorus'
    },
    {
      'chords' => [
	'G'
      ],
      'context' => '',
      'phrases' => [
	'Song line in D.'
      ],
      'type' => 'songline'
    },
    {
      'chorus' => [
	{
	  'chords' => [
	    'G'
	  ],
	  'context' => 'chorus',
	  'phrases' => [
	    'Chorus line in D.'
	  ],
	  'type' => 'songline'
	},
	{
	 'value' => '',
	 'context' => 'chorus',
	 'name' => 'context',
	 'type' => 'set'
	},
      ],
      'context' => '',
      'transpose' => 0,
      'type' => 'rechorus'
    },
    {
      'chorus' => [
	{
	  'chords' => [
	    'A'
	  ],
	  'context' => 'chorus',
	  'phrases' => [
	    'Chorus line in D.'
	  ],
	  'type' => 'songline'
	},
	{
	 'value' => '',
	 'context' => 'chorus',
	 'name' => 'context',
	 'type' => 'set'
	},
      ],
      'context' => '',
      'transpose' => 2,
      'type' => 'rechorus'
    }
  ],
  'chords' => {
    'chords' => [
      'G'
    ],
    'origin' => 'song',
    'show' => 'all',
    'type' => 'diagrams'
  },
  'meta' => {
    'songindex' => 1,
    'title' => [
      'Transpositions'
    ]
  },
  settings => {},
  source => { file => "__STRING__", line => 1 },
  structure => 'linear',
  system => 'common',
  title => 'Transpositions',
};

is_deeply( { %{ $s->{songs}->[0] } }, $song, "Song contents" );
