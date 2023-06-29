#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Songbook;

plan tests => 3;

my $s = ChordPro::Songbook->new;

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

eval { $s->parse_file( \$data, { transpose => 0 } ) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'ChordPro::Song', "It's a song" );

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
  chordsinfo => { map { $_ => $_ } qw( A G )  },
  source => { file => "__STRING__", line => 1 },
  structure => 'linear',
  system => 'common',
  title => 'Transpositions',
};

is_deeply( { %{ $s->{songs}->[0] } }, $song, "Song contents" );
