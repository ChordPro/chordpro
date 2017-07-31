#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Test::More tests => 3;

use App::Music::ChordPro::Config;
use App::Music::ChordPro::Songbook;

our $config = App::Music::ChordPro::Config::configurator;
# Prevent a dummy {body} for chord grids.
$config->{diagrams}->{show} = 0;
my $s = App::Music::ChordPro::Songbook->new;

# Fonts definitions.
my $data = <<EOD;
{title: Swing Low Sweet Chariot}
{chordfont: Times-Italic}
{chordsize: 80%}
{chordcolour: Yellow}
{tabfont: Courier}
{tabsize: 80%}
{tabcolour: Red}
{gridfont: Arial}
{gridsize: 12}
{gridcolour: #010203}
{titlefont: Times-Bold}
{titlesize: 200%}
{titlecolour: black}
{footerfont: Times-Italic}
{footersize: 60%}
{footercolour: blue}
{tocfont: Times-Roman}
{tocsize: 80%}
{toccolour: Cyan}
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
			'name' => 'chord-font',
			'type' => 'control',
			'value' => 'Times-Italic',
			'context' => ''
		       },
		       {
			'name' => 'chord-size',
			'type' => 'control',
			'value' => '80%',
			'context' => ''
		       },
		       {
			'type' => 'control',
			'name' => 'chord-color',
			'context' => '',
			'value' => 'yellow'
		       },
		       {
			'context' => '',
			'value' => 'Courier',
			'type' => 'control',
			'name' => 'tab-font'
		       },
		       {
			'type' => 'control',
			'name' => 'tab-size',
			'context' => '',
			'value' => '80%'
		       },
		       {
			'value' => 'red',
			'context' => '',
			'type' => 'control',
			'name' => 'tab-color'
		       },
		       {
			'name' => 'grid-font',
			'type' => 'control',
			'context' => '',
			'value' => 'Arial'
		       },
		       {
			'name' => 'grid-size',
			'type' => 'control',
			'value' => '12',
			'context' => ''
		       },
		       {
			'type' => 'control',
			'name' => 'grid-color',
			'value' => '#010203',
			'context' => ''
		       },
		       {
			'name' => 'title-font',
			'type' => 'control',
			'context' => '',
			'value' => 'Times-Bold'
		       },
		       {
			'type' => 'control',
			'name' => 'title-size',
			'context' => '',
			'value' => '200%'
		       },
		       {
			'value' => 'black',
			'context' => '',
			'name' => 'title-color',
			'type' => 'control'
		       },
		       {
			'context' => '',
			'value' => 'Times-Italic',
			'name' => 'footer-font',
			'type' => 'control'
		       },
		       {
			'value' => '60%',
			'context' => '',
			'name' => 'footer-size',
			'type' => 'control'
		       },
		       {
			'type' => 'control',
			'name' => 'footer-color',
			'value' => 'blue',
			'context' => ''
		       },
		       {
			'context' => '',
			'value' => 'Times-Roman',
			'name' => 'toc-font',
			'type' => 'control'
		       },
		       {
			'name' => 'toc-size',
			'type' => 'control',
			'context' => '',
			'value' => '80%'
		       },
		       {
			'value' => 'cyan',
			'context' => '',
			'type' => 'control',
			'name' => 'toc-color'
		       }
		      ]
 	   };

is_deeply( { %{ $s->{songs}->[0] } }, $song, "Song contents" );
