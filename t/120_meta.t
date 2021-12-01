#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use App::Music::ChordPro::Testing;
use App::Music::ChordPro::Songbook;

plan tests => 16;

# Prevent a dummy {body} for chord grids.
$config->{diagrams}->{show} = 0;
my $s = App::Music::ChordPro::Songbook->new;

#### meta as meta.

my $data = <<EOD;
{title: Swing Low Sweet Chariot}
{meta: artist The Artist}
{meta: composer The Composer}
{meta: album The Album}
{meta: key F}
{meta: time 3/4}
{meta: tempo 320}
{meta: capo 2}
EOD

eval { $s->parse_file(\$data) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'App::Music::ChordPro::Song', "It's a song" );
#use Data::Dumper; warn(Dumper($s));
my $song = {
	    'settings' => {},
	    'meta' => {
		       'songindex' => 1,
		       'title' => [
				   'Swing Low Sweet Chariot'
				  ],
		       'artist' => [ 'The Artist' ],
		       'composer' => [ 'The Composer' ],
		       'album' => [ 'The Album' ],
		       'key' => [ 'F' ],
		       'tempo' => [ '320' ],
		       'time' => [ '3/4' ],
		       'capo' => [ '2' ],
		      },
	    'chordsinfo' => { map { $_ => $_ } qw( F ) },
	    'title' => 'Swing Low Sweet Chariot',
	    'source' => { file => "__STRING__", line => 1 },
	    'structure' => 'linear',
	    'system' => 'common',
	   };

is_deeply( { %{ $s->{songs}->[0] } }, $song, "[meta meta] Song contents" );

#### meta as directives.

$s = App::Music::ChordPro::Songbook->new;

$data = <<EOD;
{title: Swing Low Sweet Chariot}
{artist: The Artist}
{composer The Composer}
{album The Album}
{key F}
{time 3/4}
{capo: 2}
{tempo 320}
EOD

eval { $s->parse_file(\$data) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'App::Music::ChordPro::Song', "It's a song" );
#use Data::Dumper; warn(Dumper($s));

is_deeply( { %{ $s->{songs}->[0] } }, $song, "[meta as dir] Song contents" );

#### combinations.

$s = App::Music::ChordPro::Songbook->new;

$data = <<EOD;
{title: Swing Low Sweet Chariot}
{meta: artist The Artist}
{artist Another Artist}
{meta: composer The Composer}
{composer Another Composer}
{meta: album The Album}
{album Another Album}
{meta: key F}
{key G}
{capo: 2}
{meta: time 3/4}
{time 4/4}
{meta: tempo 320}
{meta: capo 3}
{tempo 220}
{c: %%}
EOD


my $warning = "";
{
    local $SIG{__WARN__} = sub { $warning .= "@_" };
    eval { $s->parse_file(\$data) } or diag("$@");
}
ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
ok( $warning =~ /Multiple capo settings may yield surprising results/,
    "You have been warned" );
isa_ok( $s->{songs}->[0], 'App::Music::ChordPro::Song', "It's a song" );
#use Data::Dumper; warn(Dumper($s));
$song = {
	    'settings' => {},
	    'meta' => {
		       'songindex' => 1,
		       'title' => [
				   'Swing Low Sweet Chariot'
				  ],
		       'artist' => [ 'The Artist', 'Another Artist' ],
		       'composer' => [ 'The Composer', 'Another Composer' ],
		       'album' => [ 'The Album', 'Another Album' ],
		       'capo' => [ '2', '3' ],
		       'key' => [ 'F', 'G' ],
		       'tempo' => [ '320', '220' ],
		       'time' => [ '3/4', '4/4' ],
		      },
	    'chordsinfo' => { map { $_ => $_ } qw( F G ) },
	    'title' => 'Swing Low Sweet Chariot',
	    'source' => { file => "__STRING__", line => 1 },
	    'structure' => 'linear',
	    'system' => 'common',
	    'body' => [
		       { context => '',
			 orig => '%%',
			 text => '%%',
			 type => 'comment',
		       },
		    ],
	   };

is_deeply( { %{ $s->{songs}->[0] } }, $song, "[combi's] Song contents" );

#### autosplit (default, on).

$s = App::Music::ChordPro::Songbook->new;

$data = <<EOD;
{title: Swing Low Sweet Chariot}
{artist Another Artist}
{composer Another Composer}
{album Another Album}
{key G}
{capo: 2}
{time 4/4}
{tempo 220; 260}
{c: %%}
EOD

$s->parse_file(\$data);
ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'App::Music::ChordPro::Song', "It's a song" );
#use Data::Dumper; warn(Dumper($s));
$song = {
	    'settings' => {},
	    'meta' => {
		       'songindex' => 1,
		       'title' => [
				   'Swing Low Sweet Chariot'
				  ],
		       'artist' => [ 'Another Artist' ],
		       'composer' => [ 'Another Composer' ],
		       'album' => [ 'Another Album' ],
		       'capo' => [ '2' ],
		       'key' => [ 'G' ],
		       'tempo' => [ '220', '260' ],
		       'time' => [ '4/4' ],
		      },
	    'chordsinfo' => { map { $_ => $_ } qw( G ) },
	    'title' => 'Swing Low Sweet Chariot',
	    'source' => { file => "__STRING__", line => 1 },
	    'structure' => 'linear',
	    'system' => 'common',
	    'body' => [
		       { context => '',
			 orig => '%%',
			 text => '%%',
			 type => 'comment',
		       },
		    ],
	   };

is_deeply( { %{ $s->{songs}->[0] } }, $song, "[autosplit] Song contents" );

#### No autosplit

$::config->{metadata}->{autosplit} = 0;

$s = App::Music::ChordPro::Songbook->new;

$data = <<EOD;
{title: Swing Low Sweet Chariot}
{artist Another Artist}
{composer Another Composer}
{album Another Album}
{key G}
{capo: 2}
{time 4/4}
{tempo 220; 260}
{c: %%}
EOD

$s->parse_file(\$data);
ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'App::Music::ChordPro::Song', "It's a song" );
#use Data::Dumper; warn(Dumper($s));
$song = {
	    'settings' => {},
	    'meta' => {
		       'songindex' => 1,
		       'title' => [
				   'Swing Low Sweet Chariot'
				  ],
		       'artist' => [ 'Another Artist' ],
		       'composer' => [ 'Another Composer' ],
		       'album' => [ 'Another Album' ],
		       'capo' => [ '2' ],
		       'key' => [ 'G' ],
		       'tempo' => [ '220; 260' ],
		       'time' => [ '4/4' ],
		      },
	    'chordsinfo' => { map { $_ => $_ } qw( G ) },
	    'title' => 'Swing Low Sweet Chariot',
	    'source' => { file => "__STRING__", line => 1 },
	    'structure' => 'linear',
	    'system' => 'common',
	    'body' => [
		       { context => '',
			 orig => '%%',
			 text => '%%',
			 type => 'comment',
		       },
		    ],
	   };

is_deeply( { %{ $s->{songs}->[0] } }, $song, "[no autosplit] Song contents" );
