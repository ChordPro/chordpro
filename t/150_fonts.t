#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Songbook;

plan tests => 3;

# Prevent a dummy {body} for chord grids.
$config->{diagrams}->{show} = 0;
my $s = ChordPro::Songbook->new;

# Fonts definitions.
my $data = <<EOD;
{title: Swing Low Sweet Chariot}
{textfont: Times-Italic}
{textsize: 80%}
{textcolour: Yellow}
EOD

eval { $s->parse_file(\$data) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'ChordPro::Song', "It's a song" );
#use Data::Dumper; warn(Dumper($s));
my $song = {
	    'settings' => {},
	    'title' => 'Swing Low Sweet Chariot',
	    'source' => { file => "__STRING__", line => 1 },
	    'structure' => 'linear',
	    'system' => 'common',
	    'meta' => {
		       'songindex' => 1,
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
			'type' => 'control',
			'name' => 'chorus-font',
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
			'value' => '80%',
			'name' => 'chorus-size'
		       },
		       {
			'context' => '',
			'type' => 'control',
			'value' => 'yellow',
			'name' => 'text-color'
		       },
		       {
			'context' => '',
			'type' => 'control',
			'value' => 'yellow',
			'name' => 'chorus-color'
		       }
		      ]
 	   };

is_deeply( { %{ $s->{songs}->[0] } }, $song, "Song contents" );
