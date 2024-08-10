#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Songbook;

plan tests => 6;

# Prevent a dummy {body} for chord grids.
$config->{diagrams}->{show} = 1;
$config->{diagrams}->{sorted} = 0;
my $s = ChordPro::Songbook->new;

# Chord definitions.
my $data = <<EOD;
{t Sorting Diagrams}
[B]Hello, [A]World
[E]How [F]are [G]you
EOD

eval { $s->parse_file(\$data) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'ChordPro::Song', "It's a song" );
#use Data::Dumper; warn(Dumper($s));
is_deeply( $s->{songs}->[0]->{meta}->{chords}, [qw(B A E F G)], "Song chords (unsorted)" );

$config->{diagrams}->{sorted} = 1;
$s = ChordPro::Songbook->new;

eval { $s->parse_file(\$data) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'ChordPro::Song', "It's a song" );
#use Data::Dumper; warn(Dumper($s));
is_deeply( $s->{songs}->[0]->{meta}->{chords}, [qw(E F G A B)], "Song chords (sorted)" );

