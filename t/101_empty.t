#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Songbook;

plan tests => 1;

# Prevent a dummy {body} for chord grids.
$config->{diagrams}->{show} = 0;

my $s = ChordPro::Songbook->new;

my $data = <<EOD;
EOD

eval { $s->parse_file(\$data); 1 } or diag("$@");
#use DDumper; DDumper( $s->{songs} );
ok( scalar( @{ $s->{songs} } ) == 0, "No song" );
#isa_ok( $s->{songs}->[0], 'ChordPro::Song', "It's a song" );
#
#my $song = {
#	    'settings' => {},
#	    'structure' => 'linear',
#	    'system' => 'common',
#	   };
#
#is_deeply( { %{ $s->{songs}->[0] } }, $song, "Song contents" );
