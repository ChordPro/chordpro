#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use App::Music::ChordPro::Testing;
use App::Packager ( ':name', 'App::Music::ChordPro' );
use App::Music::ChordPro::Config;
use App::Music::ChordPro::Songbook;
use App::Music::ChordPro::Output::Common;

plan tests => 4;

# For transcoding, both source and target notation systems must be
# defined. The source system must be last, so it is current and used
# to parse the the input data.

our $config = App::Music::ChordPro::Config::configurator;
ok( $config, "got config" );

my $s = App::Music::ChordPro::Songbook->new;

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
isa_ok( $s->{songs}->[0], 'App::Music::ChordPro::Song', "It's a song" );

my $book = [ map { { meta => $_->{meta} } } @{$s->{songs}} ];

my $ctl = { fields => [ qw( title artist ) ] };
my $res = App::Music::ChordPro::Output::Common::prep_outlines( $book, $ctl );

my $xp = [
  [
    '24 fietsen',
    'december',
    {
      meta => {
        artist => [
          'December',
        ],
        key => [
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
    '24 fietsen',
    'september',
    {
      meta => {
        artist => [
          'September',
        ],
        key => [
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
  [
    'de fietsenstalling',
    'december',
    {
      meta => {
        artist => [
          'December',
        ],
        key => [
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
    'de fietsenstalling',
    'september',
    {
      meta => {
        artist => [
          'September',
        ],
        key => [
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
    'de fietspomp',
    'september',
    {
      meta => {
        artist => [
          'September',
        ],
        key => [
          'A',
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
    'het fietsenhok',
    'december',
    {
      meta => {
        artist => [
          'December',
        ],
        key => [
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
    'het fietsenhok',
    'september',
    {
      meta => {
        artist => [
          'September',
        ],
        key => [
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
];

is_deeply( $res, $xp, "outlined");
