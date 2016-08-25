#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Test::More tests => 6;

use App::Music::ChordPro::Config;
use App::Music::ChordPro::Songbook;

our $config = App::Music::ChordPro::Config::configurator;
# Prevent a dummy {body} for chord grids.
$config->{chordgrid}->{show} = 0;

my $s = App::Music::ChordPro::Songbook->new;

# Columns.
my $data = <<EOD;
{title: Swing Low Sweet Chariot}
{columns: 2}
EOD

eval { $s->parsefile(\$data) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'App::Music::ChordPro::Song', "It's a song" );
#use Data::Dumper; warn(Dumper($s));
my $song = {
	    'settings' => {
			   'columns' => '2',
			  },
	    'title' => 'Swing Low Sweet Chariot',
	    'structure' => 'linear',
	    'meta' => {
		       'title' => [
				   'Swing Low Sweet Chariot'
				  ]
		      },
	   };

is_deeply( { %{ $s->{songs}->[0] } }, $song,
	   "Two columns" );

$s = App::Music::ChordPro::Songbook->new;

# Columns.
$data = <<EOD;
{title: Swing Low Sweet Chariot}
{column_break}
EOD

eval { $s->parsefile(\$data) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'App::Music::ChordPro::Song', "It's a song" );
#use Data::Dumper; warn(Dumper($s));

$song = {
	    'settings' => {},
	    'title' => 'Swing Low Sweet Chariot',
	    'structure' => 'linear',
	    'meta' => {
		       'title' => [
				   'Swing Low Sweet Chariot'
				  ]
		      },
	    'body' => [
		       {
			'context' => '',
			'type' => 'colb'
		       }
		      ],
	   };

is_deeply( { %{ $s->{songs}->[0] } }, $song,
	   "Column break" );
