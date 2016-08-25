#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Test::More tests => 3;

use App::Music::ChordPro::Config;
use App::Music::ChordPro::Songbook;

our $config = App::Music::ChordPro::Config::configurator;
# Prevent a dummy {body} for chord grids.
$config->{chordgrid}->{show} = 0;
my $s = App::Music::ChordPro::Songbook->new;

# Fonts definitions.
my $data = <<EOD;
{title: Swing Low Sweet Chariot}
{textfont: Times-Italic}
{textsize: 80%}
{textcolour: Yellow}
EOD

eval { $s->parsefile(\$data) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'App::Music::ChordPro::Song', "It's a song" );
#use Data::Dumper; warn(Dumper($s));
my $song = {
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
			'type' => 'control',
			'name' => 'text-font',
			'value' => 'Times-Italic',
			'context' => ''
		       },
		       {
			'context' => '',
			'type' => 'control',
			'value' => '80%',
			'name' => 'text-size'
		       },
		       {
			'context' => '',
			'type' => 'control',
			'value' => 'yellow',
			'name' => 'text-color'
		       }
		      ]
 	   };

is_deeply( { %{ $s->{songs}->[0] } }, $song, "Song contents" );
