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

# Tabs.
my $data = <<EOD;
{title: Swing Low Sweet Chariot}
{start_of_verse}
I [D]looked over Jordan, and [G]what did I [D]see,
{end_of_verse}
EOD

eval { $s->parse_file(\$data) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'ChordPro::Song', "It's a song" );
#use Data::Dumper; warn(Dumper($s));
my $song = {
	    'settings' => {},
	    'meta' => {
		       'songindex' => 1,
		       'title' => [
				   'Swing Low Sweet Chariot'
				  ],
		      },
	    'title' => 'Swing Low Sweet Chariot',
	    'body' => [
                       {
			 'context' => 'verse',
			 'phrases' => [
					'I ',
					'looked over Jordan, and ',
					'what did I ',
					'see,'
				      ],
			 'chords' => [
				       '',
				       'D',
				       'G',
				       'D'
				     ],
			 'type' => 'songline'
		       },
		       {
			'value' => '',
			'context' => 'verse',
			'name' => 'context',
			'type' => 'set'
		       }
		      ],
	    'chordsinfo' => { map { $_ => $_ } qw( D G ) },
	    'source' => { file => "__STRING__", line => 1 },
	    'structure' => 'linear',
	    'system' => 'common',
	   };

is_deeply( { %{ $s->{songs}->[0] } }, $song, "Song contents" );
