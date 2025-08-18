#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Songbook;
use ChordPro::Output::Common;

plan tests => 4;

ok( $config, "got config" );

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

my $ctl = { fields => [ qw( sorttitle sortartist ) ] };
my $res = ChordPro::Output::Common::prep_outlines( $book, $ctl );

my $xp = [
  [
    'fietsenhok, het',
    'december',
    {
      meta => {
        artist => [
          'December',
        ],
	chords => [
	],
        numchords => [
          0,
        ],
        key => [
          'C',
        ],
        key_actual => [
          'C',
        ],
        songindex => 3,
        sortartist => [
          'December',
        ],
        sorttitle => [
          'Fietsenhok, Het',
        ],
        title => [
          'Het Fietsenhok',
        ],
      },
    },
  ],
  [
    'fietsenhok, het',
    'september',
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
          'C',
        ],
        key_actual => [
          'C',
        ],
        songindex => 3,
        sortartist => [
          'September',
        ],
        sorttitle => [
          'Fietsenhok, Het',
        ],
        title => [
          'Het Fietsenhok',
        ],
      },
    },
  ],
  [
    'fietsenstalling, de',
    'december',
    {
      meta => {
        artist => [
          'December',
        ],
	chords => [
	],
        numchords => [
          0,
        ],
        key => [
          'C',
        ],
        key_actual => [
          'C',
        ],
        songindex => 3,
        sortartist => [
          'December',
        ],
        sorttitle => [
          'Fietsenstalling, De',
        ],
        title => [
          'De Fietsenstalling',
        ],
      },
    },
  ],
  [
    'fietsenstalling, de',
    'september',
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
          'C',
        ],
        key_actual => [
          'C',
        ],
        songindex => 3,
        sortartist => [
          'September',
        ],
        sorttitle => [
          'Fietsenstalling, De',
        ],
        title => [
          'De Fietsenstalling',
        ],
      },
    },
  ],
  [
    'fietspomp, de',
    'september',
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
          'Am',
        ],
        key_actual => [
          'Am',
        ],
        songindex => 1,
        sortartist => [
          'September',
        ],
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
    'vierentwintig fietsen',
    'december',
    {
      meta => {
        artist => [
          'December',
        ],
	chords => [
	],
        numchords => [
          0,
        ],
        key => [
          'D',
        ],
        key_actual => [
          'D',
        ],
        songindex => 2,
        sortartist => [
          'December',
        ],
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
    'vierentwintig fietsen',
    'september',
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
          'D',
        ],
        key_actual => [
          'D',
        ],
        songindex => 2,
        sortartist => [
          'September',
        ],
        sorttitle => [
          'Vierentwintig Fietsen',
        ],
        title => [
          '24 Fietsen',
        ],
      },
    },
  ],
];

foreach ( @$res ) {
    delete $_->[2]->{meta}->{_configversion};
    delete $_->[2]->{meta}->{bookmark};
}
is_deeply( $res, $xp, "outlined");
