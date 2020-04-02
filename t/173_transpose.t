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
{title: Transpositions}
{key: D}

{start_of_chorus}
Swing [D]low, sweet [G]chari[D]ot,
{end_of_chorus}

I [D]looked over Jordan, and [G]what did I [D]see,
{chorus}

{transpose +2}
I [D]looked over Jordan, and [G]what did I [D]see,
{chorus}

{transpose +2}
I [D]looked over Jordan, and [G]what did I [D]see,
{chorus}

{transpose}
I [D]looked over Jordan, and [G]what did I [D]see,
{chorus}

{transpose}
I [D]looked over Jordan, and [G]what did I [D]see,
{chorus}
EOD

eval { $s->parsefile( \$data, { transpose => -10 } ) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'App::Music::ChordPro::Song', "It's a song" );

my $song = {
  body => [
    {
      context => '',
      type => 'empty',
    },
    {
      chords => [
        '',
        'E',
        'A',
        'E',
      ],
      context => 'chorus',
      phrases => [
        'Swing ',
        'low, sweet ',
        'chari',
        'ot,',
      ],
      type => 'songline',
    },
    {
     context => 'chorus',
     type => 'set',
     value => '',
     name => 'context'
    },
    {
      context => '',
      type => 'empty',
    },
    {
      chords => [
        '',
        'E',
        'A',
        'E',
      ],
      context => '',
      phrases => [
        'I ',
        'looked over Jordan, and ',
        'what did I ',
        'see,',
      ],
      type => 'songline',
    },
    {
      chorus => [
        {
          chords => [
            '',
            'E',
            'A',
            'E',
          ],
          context => 'chorus',
          phrases => [
            'Swing ',
            'low, sweet ',
            'chari',
            'ot,',
          ],
          type => 'songline',
        },
	{
	 context => 'chorus',
	 type => 'set',
	 value => '',
	 name => 'context'
	},
      ],
      context => '',
      transpose => 0,
      type => 'rechorus',
    },
    {
      context => '',
      type => 'empty',
    },
    {
      chords => [
        '',
        'Gb',
        'B',
        'Gb',
      ],
      context => '',
      phrases => [
        'I ',
        'looked over Jordan, and ',
        'what did I ',
        'see,',
      ],
      type => 'songline',
    },
    {
      chorus => [
        {
          chords => [
            '',
            'Gb',
            'B',
            'Gb',
          ],
          context => 'chorus',
          phrases => [
            'Swing ',
            'low, sweet ',
            'chari',
            'ot,',
          ],
          type => 'songline',
        },
	{
	 context => 'chorus',
	 type => 'set',
	 value => '',
	 name => 'context'
	},
      ],
      context => '',
      transpose => 2,
      type => 'rechorus',
    },
    {
      context => '',
      type => 'empty',
    },
    {
      chords => [
        '',
        'Ab',
        'Db',
        'Ab',
      ],
      context => '',
      phrases => [
        'I ',
        'looked over Jordan, and ',
        'what did I ',
        'see,',
      ],
      type => 'songline',
    },
    {
      chorus => [
        {
          chords => [
            '',
            'Ab',
            'Db',
            'Ab',
          ],
          context => 'chorus',
          phrases => [
            'Swing ',
            'low, sweet ',
            'chari',
            'ot,',
          ],
          type => 'songline',
        },
	{
	 context => 'chorus',
	 type => 'set',
	 value => '',
	 name => 'context'
	},
      ],
      context => '',
      transpose => 4,
      type => 'rechorus',
    },
    {
      context => '',
      type => 'empty',
    },
    {
      chords => [
        '',
        'Gb',
        'B',
        'Gb',
      ],
      context => '',
      phrases => [
        'I ',
        'looked over Jordan, and ',
        'what did I ',
        'see,',
      ],
      type => 'songline',
    },
    {
      chorus => [
        {
          chords => [
            '',
            'Gb',
            'B',
            'Gb',
          ],
          context => 'chorus',
          phrases => [
            'Swing ',
            'low, sweet ',
            'chari',
            'ot,',
          ],
          type => 'songline',
        },
	{
	 context => 'chorus',
	 type => 'set',
	 value => '',
	 name => 'context'
	},
      ],
      context => '',
      transpose => 2,
      type => 'rechorus',
    },
    {
      context => '',
      type => 'empty',
    },
    {
      chords => [
        '',
        'E',
        'A',
        'E',
      ],
      context => '',
      phrases => [
        'I ',
        'looked over Jordan, and ',
        'what did I ',
        'see,',
      ],
      type => 'songline',
    },
    {
      chorus => [
        {
          chords => [
            '',
            'E',
            'A',
            'E',
          ],
          context => 'chorus',
          phrases => [
            'Swing ',
            'low, sweet ',
            'chari',
            'ot,',
          ],
          type => 'songline',
        },
	{
	 context => 'chorus',
	 type => 'set',
	 value => '',
	 name => 'context'
	},
      ],
      context => '',
      transpose => 0,
      type => 'rechorus',
    },
  ],
  chords => {
    origin => 'song',
      type => 'diagrams',
      show => 'all',
      chords => [ 'E', 'A', 'Gb', 'B', 'Ab', 'Db' ]
  },
  meta => {
    songindex => 1,
    key => [
      'E',
    ],
    key_actual => [
      'E',
    ],
    key_from => [
      'F#',
    ],
    title => [
      'Transpositions',
    ],
  },
  settings => {},
  source => { file => "__STRING__", line => 1 },
  structure => 'linear',
	    'system' => 'common',
  title => 'Transpositions',
};

is_deeply( { %{ $s->{songs}->[0] } }, $song, "Song contents" );
