#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Test::More tests => 6;

use App::Music::ChordPro::Config;
use App::Music::ChordPro::Songbook;

our $config = App::Music::ChordPro::Config::configurator;
# Prevent a dummy {body} for chord grids.
$config->{diagrams}->{show} = 0;
my $s = App::Music::ChordPro::Songbook->new;

my $data = <<EOD;
{title Grids}
{start_of_grid 4x3}
| B . . | C . . | D . . | E . . |
| B . . | C . . | D . . | E . . |
| B . . | C . . | D . . | E . . |
| B . . | C . . | D . . | E . . |
{end_of_grid}
EOD

eval { $s->parsefile(\$data) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'App::Music::ChordPro::Song', "It's a song" );
#use DDumper; warn(DDumper($s));
my $song = {
      meta => {
        title => ['Grids'],
      },
      settings => {},
      source => { file => "__STRING__", line => 1 },
      structure => 'linear',
	    'system' => 'common',
      title => 'Grids',
      body => [
	       { context => 'grid',
		 name => 'gridparams',
		 type => 'set',
		 value => [4, 3, undef, undef, '']},
	       { context => 'grid',
		 type => 'gridline',
		 tokens => [
			   { class => 'bar', symbol => '|' },
			   { chord => 'B', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			   { chord => 'C', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			   { chord => 'D', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			   { chord => 'E', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			  ],
	       },
	       { context => 'grid',
		 type => 'gridline',
		 tokens => [
			   { class => 'bar', symbol => '|' },
			   { chord => 'B', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			   { chord => 'C', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			   { chord => 'D', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			   { chord => 'E', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			  ],
	       },
	       { context => 'grid',
		 type => 'gridline',
		 tokens => [
			   { class => 'bar', symbol => '|' },
			   { chord => 'B', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			   { chord => 'C', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			   { chord => 'D', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			   { chord => 'E', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			  ],
	       },
	       { context => 'grid',
		 type => 'gridline',
		 tokens => [
			   { class => 'bar', symbol => '|' },
			   { chord => 'B', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			   { chord => 'C', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			   { chord => 'D', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			   { chord => 'E', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			  ],
	       },
	       {
		'value' => '',
		'context' => 'grid',
		'name' => 'context',
		'type' => 'set'
	       },
	      ],
	   };

is_deeply( { %{ $s->{songs}->[0] } }, $song, "Song contents" );

$s = App::Music::ChordPro::Songbook->new;

# Chord definitions.
$data = <<EOD;
{title Grids}
{start_of_grid 1+4x3+2}
| A . . | Bb . . | C . . | D . . |
{end_of_grid}
{start_of_grid}
| A . . | Bb . . | C . . | D . . |
{end_of_grid}
{start_of_grid}
| A . . | Bb . . | C . . | D . . |
{end_of_grid}
{start_of_grid}
| A . . | Bb . . | C . . | D . . |
{end_of_grid}
EOD

eval { $s->parsefile( \$data, { transpose => 2 } ) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'App::Music::ChordPro::Song', "It's a song" );

$song->{body}->[0]->{value} = [ 4, 3, 1, 2, '' ];
splice( @{$song->{body}}, $_, 0,
	{ context => 'grid', value => '', name => 'context', type => 'set' },
	{ context => 'grid', name => 'gridparams',
	  type => 'set', value => [ 4, 3, 1, 2 ] } )
  for 2, 5, 8;
is_deeply( { %{ $s->{songs}->[0] } }, $song, "Song contents" );
