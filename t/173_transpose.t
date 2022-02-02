#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use App::Music::ChordPro::Testing;
use App::Music::ChordPro::Songbook;

plan tests => 3;

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

eval { $s->parse_file( \$data, { transpose => -10 } ) } or diag("$@");

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
      type => 'rechorus',
    },
    {
      context => '',
      type => 'empty',
    },
    {
      chords => [
        '',
        'F#',
        'B',
        'F#',
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
            'F#',
            'B',
            'F#',
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
      type => 'rechorus',
    },
    {
      context => '',
      type => 'empty',
    },
    {
      chords => [
        '',
        'G#',
        'C#',
        'G#',
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
            'G#',
            'C#',
            'G#',
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
      type => 'rechorus',
    },
    {
      context => '',
      type => 'empty',
    },
    {
      chords => [
        '',
        'F#',
        'B',
        'F#',
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
            'F#',
            'B',
            'F#',
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
      type => 'rechorus',
    },
  ],
  chords => {
    chords => [ 'E', 'A', 'F#', 'B', 'G#', 'C#' ],
    origin => 'song',
    show => 'all',
    type => 'diagrams'
  },
  chordsinfo => { map { $_ => $_ } qw( E A B ), 'F#', 'C#', 'G#' },
  meta => {
    songindex => 1,
    key => [
      'E',
    ],
    title => [
      'Transpositions',
    ],
  },
  settings => {},
  source => { file => "__STRING__", line => 1 },
  structure => 'linear',
  system => 'common',
  title => 'Transpositions',
};

is_deeply( { %{ $s->{songs}->[0] } }, $song, "Song contents" );
