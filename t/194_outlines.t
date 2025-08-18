#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Songbook;
use ChordPro::Output::Common;

plan tests => 3;

# For transcoding, both source and target notation systems must be
# defined. The source system must be last, so it is current and used
# to parse the the input data.

my $s = ChordPro::Songbook->new;

my $data = <<EOD;
{title: De Fietspomp}
{meta: sorttitle Fietspomp, De}
{meta: artist September}
{key: A}
{key: Am}

Should sort at F

{ns}
{title: 24 Fietsen}
{meta: sorttitle Vierentwintig Fietsen}
{artist: September}
{artist: December}
{key: D}

Should sort at V

{ns}
{title: Het Fietsenhok}
{meta: sorttitle Fietsenhok, Het}
{title: De Fietsenstalling}
{meta: sorttitle Fietsenstalling, De}
{artist: September}
{artist: December}
{key: C}

Dual title
EOD

eval { $s->parse_file( \$data ) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 3, "three songs" );
isa_ok( $s->{songs}->[0], 'ChordPro::Song', "It's a song" );

my $book = [ map { { meta => $_->{meta} } } @{$s->{songs}} ];

# Test reverse sort.
my $ctl = { fields => [ qw( -key ) ] };
my $res = ChordPro::Output::Common::prep_outlines( $book, $ctl );

my $xp = [
  [
    'd',
    {
      meta => {
        artist => [
          'September',
          'December',
        ],
	chords => [
	],
        key => [
          'D',
        ],
        key_actual => [
          'D',
        ],
        numchords => [
          0,
        ],
        songindex => 2,
        sorttitle => [
          'Vierentwintig Fietsen',
        ],
        title => [
          '24 Fietsen',
        ],
      },
    },
  ],
  [
    'c',
    {
      meta => {
        artist => [
          'September',
          'December',
        ],
	chords => [
	],
        key => [
          'C',
        ],
        key_actual => [
          'C',
        ],
        numchords => [
          0,
        ],
        songindex => 3,
        sorttitle => [
           'Fietsenhok, Het',
	   'Fietsenstalling, De',
        ],
        title => [
          'Het Fietsenhok',
          'De Fietsenstalling',
        ],
      },
    },
  ],
  [
    'am',
    {
      meta => {
        artist => [
          'September',
        ],
	chords => [
	],
        key => [
          'Am',
        ],
        key_actual => [
          'Am',
        ],
        numchords => [
          0,
        ],
        songindex => 1,
        sorttitle => [
          'Fietspomp, De',
        ],
        title => [
          'De Fietspomp',
        ],
      },
    },
  ],
  [
    'a',
    {
      meta => {
        artist => [
          'September',
        ],
	chords => [
	],
        numchords => [
          0,
        ],
        key => [
          'A',
        ],
        key_actual => [
          'Am',
        ],
        songindex => 1,
        sorttitle => [
          'Fietspomp, De',
        ],
        title => [
          'De Fietspomp',
        ],
      },
    },
  ],
];

foreach ( @$res ) {
    delete $_->[1]->{meta}->{_configversion};
    delete $_->[1]->{meta}->{bookmark};
}
is_deeply( $res, $xp, "outlined");
