#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use App::Music::ChordPro::Testing;
use App::Music::ChordPro::Songbook;

plan tests => 12;

# Prevent a dummy {body} for chord grids.
$config->{diagrams}->{show} = 0;

my $s = App::Music::ChordPro::Songbook->new;

# New page.
my $data = <<EOD;
{title: Swing Low Sweet Chariot}
{new_page}
EOD

eval { $s->parse_file(\$data) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'App::Music::ChordPro::Song', "It's a song" );
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
			'context' => '',
			'type' => 'newpage'
		       }
		      ],
	   };

is_deeply( { %{ $s->{songs}->[0] } }, $song,
	   "New page" );

$s = App::Music::ChordPro::Songbook->new;

# New page.
$data = <<EOD;
{title: Swing Low Sweet Chariot}
{np}
EOD

eval { $s->parse_file(\$data) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'App::Music::ChordPro::Song', "It's a song" );
#use Data::Dumper; warn(Dumper($s));

is_deeply( { %{ $s->{songs}->[0] } }, $song,
	   "Newpage (np)" );

$s = App::Music::ChordPro::Songbook->new;

# New physical page.
$data = <<EOD;
{title: Swing Low Sweet Chariot}
{new_physical_page}
EOD

eval { $s->parse_file(\$data) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'App::Music::ChordPro::Song', "It's a song" );
#use Data::Dumper; warn(Dumper($s));

is_deeply( { %{ $s->{songs}->[0] } }, $song,
	   "New physical page" );

$s = App::Music::ChordPro::Songbook->new;

# New physical page.
$data = <<EOD;
{title: Swing Low Sweet Chariot}
{npp}
EOD

eval { $s->parse_file(\$data) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'App::Music::ChordPro::Song', "It's a song" );
#use Data::Dumper; warn(Dumper($s));

is_deeply( { %{ $s->{songs}->[0] } }, $song,
	   "New physical page (npp)" );

