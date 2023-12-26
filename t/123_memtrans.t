#!/usr/bin/perl

use strict;
use warnings;
use utf8;

# Issue 333

use ChordPro::Testing;
use ChordPro::Songbook;

plan tests => 3;

$config->{settings}->{memorize} = 1;
$config->{settings}->{transpose} = 2;
# Prevent a dummy {body} for chord grids.
$config->{diagrams}->{show} = 0;
my $s = ChordPro::Songbook->new;

#### meta as meta.

my $data = <<EOD;
{title: Test Memorize}
{start_of_verse}
[A]This is verse
{end_of_verse}
{start_of_verse}
^Another verse
{end_of_verse}
EOD

my $warning = "";
{
    local $SIG{__WARN__} = sub { $warning .= "@_" };
    eval { $s->parse_file(\$data) } or diag("$@");
}
ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'ChordPro::Song', "It's a song" );
# use ChordPro::Dumper; ddp($s->{songs}->[0]);
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
				      'This is verse',
				     ],
			'context' => 'verse',
			'chords' => [
				     'B',
				    ]
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
				      'Another verse'
				     ],
			'context' => 'verse',
			'chords' => [
				     'B',
				    ]
		       },
		       {
			'value' => '',
			'context' => 'verse',
			'name' => 'context',
			'type' => 'set'
		       }
		      ],
	    'source' => {
			 'line' => 1,
			 'file' => '__STRING__'
			},
	    'chordsinfo' => { map { $_ => $_ } qw( B ) },
	    'title' => 'Test Memorize',
	    'system' => 'common',
	    'structure' => 'linear',
	    'settings' => {},
	   };

is_deeply( { %{ $s->{songs}->[0] } }, $song, "Song contents" );

