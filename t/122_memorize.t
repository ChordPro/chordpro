#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use App::Music::ChordPro::Testing;
use App::Music::ChordPro::Config;
use App::Music::ChordPro::Songbook;

plan tests => 4;

our $config = App::Music::ChordPro::Config::configurator;
$config->{settings}->{memorize} = 1;
# Prevent a dummy {body} for chord grids.
$config->{diagrams}->{show} = 0;
my $s = App::Music::ChordPro::Songbook->new;

#### meta as meta.

my $data = <<EOD;
{title: Test Memorize}
{start_of_verse}
The [A]quick [B]brown [F]ox jumps over the lazy [D]dog
[A]The quick [NC]brown [F]ox jumps over the lazy [D]dog
{end_of_verse}
{start_of_verse2}
[E]The quick [B]brown [F]ox jumps over the lazy [D]dog
The [E]quick [C]brown [F]ox jumps over the lazy [D]dog
{end_of_verse2}
{start_of_verse}
^The quick ^brown ^ox jumps over the lazy ^dog
^The quick [G]brown ^ox jumps over the lazy ^dog
{end_of_verse}
{start_of_verse2}
The ^quick ^brown ^ox jumps over the lazy ^dog
^The quick ^brown ^ox jumps over the lazy ^dog
{end_of_verse2}
{start_of_verse3}
^The quick ^brown ^ox jumps over the lazy ^dog
^The quick ^brown ^ox jumps over the lazy ^dog
{end_of_verse3}
EOD

my $warning;
{
    local $SIG{__WARN__} = sub { $warning = "@_" };
    eval { $s->parse_file(\$data) } or diag("$@");
}

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
ok( $warning =~ /No chords memorized for verse3/, "You have been warned" );
isa_ok( $s->{songs}->[0], 'App::Music::ChordPro::Song', "It's a song" );
#use Data::Dumper; warn(Dumper($s));
my $song = {
	    'meta' => {
		       'songindex' => 1,
		       'title' => [
				   'Test Memorize'
				  ]
		      },
	    'body' => [
		       {
			'type' => 'songline',
			'phrases' => [
				      'The ',
				      'quick ',
				      'brown ',
				      'ox jumps over the lazy ',
				      'dog'
				     ],
			'context' => 'verse',
			'chords' => [
				     '',
				     'A',
				     'B',
				     'F',
				     'D'
				    ]
		       },
		       {
			'chords' => [
				     'A',
				     'NC',
				     'F',
				     'D'
				    ],
			'context' => 'verse',
			'phrases' => [
				      'The quick ',
				      'brown ',
				      'ox jumps over the lazy ',
				      'dog'
				     ],
			'type' => 'songline'
		       },
		       {
			'value' => '',
			'context' => 'verse',
			'name' => 'context',
			'type' => 'set'
		       },
		       {
			'type' => 'songline',
			'phrases' => [
				      'The quick ',
				      'brown ',
				      'ox jumps over the lazy ',
				      'dog'
				     ],
			'context' => 'verse2',
			'chords' => [
				     'E',
				     'B',
				     'F',
				     'D'
				    ]
		       },
		       {
			'type' => 'songline',
			'chords' => [
				     '',
				     'E',
				     'C',
				     'F',
				     'D'
				    ],
			'context' => 'verse2',
			'phrases' => [
				      'The ',
				      'quick ',
				      'brown ',
				      'ox jumps over the lazy ',
				      'dog'
				     ]
		       },
		       {
			'value' => '',
			'context' => 'verse2',
			'name' => 'context',
			'type' => 'set'
		       },
		       {
			'phrases' => [
				      'The quick ',
				      'brown ',
				      'ox jumps over the lazy ',
				      'dog'
				     ],
			'context' => 'verse',
			'chords' => [
				     'A',
				     'B',
				     'F',
				     'D'
				    ],
			'type' => 'songline'
		       },
		       {
			'chords' => [
				     'A',
				     'G',
				     'F',
				     'D'
				    ],
			'context' => 'verse',
			'phrases' => [
				      'The quick ',
				      'brown ',
				      'ox jumps over the lazy ',
				      'dog'
				     ],
			'type' => 'songline'
		       },
		       {
			'value' => '',
			'context' => 'verse',
			'name' => 'context',
			'type' => 'set'
		       },
		       {
			'chords' => [
				     '',
				     'E',
				     'B',
				     'F',
				     'D'
				    ],
			'context' => 'verse2',
			'phrases' => [
				      'The ',
				      'quick ',
				      'brown ',
				      'ox jumps over the lazy ',
				      'dog'
				     ],
			'type' => 'songline'
		       },
		       {
			'type' => 'songline',
			'chords' => [
				     'E',
				     'C',
				     'F',
				     'D'
				    ],
			'context' => 'verse2',
			'phrases' => [
				      'The quick ',
				      'brown ',
				      'ox jumps over the lazy ',
				      'dog'
				     ]
		       },
		       {
			'value' => '',
			'context' => 'verse2',
			'name' => 'context',
			'type' => 'set'
		       },
		       {
			'phrases' => [
				      'The quick ',
				      'brown ',
				      'ox jumps over the lazy ',
				      'dog'
				     ],
			'chords' => [
				     '^',
				     '^',
				     '^',
				     '^'
				    ],
			'type' => 'songline',
			'context' => 'verse3'
		       },
		       {
			'phrases' => [
				      'The quick ',
				      'brown ',
				      'ox jumps over the lazy ',
				      'dog'
				     ],
			'chords' => [
				     '^',
				     '^',
				     '^',
				     '^'
				    ],
			'type' => 'songline',
			'context' => 'verse3'
		       },
		       {
			'value' => '',
			'context' => 'verse3',
			'name' => 'context',
			'type' => 'set'
		       },
		      ],
	    'source' => {
			 'line' => 1,
			 'file' => '__STRING__'
			},
	    'title' => 'Test Memorize',
	    'system' => 'common',
	    'structure' => 'linear',
	    'settings' => {},
	   };

is_deeply( { %{ $s->{songs}->[0] } }, $song, "Song contents" );

