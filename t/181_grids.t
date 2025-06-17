#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use ChordPro::Testing;
use ChordPro::Songbook;

plan tests => 18;

my $s = ChordPro::Songbook->new;

# Full test program at end.
my $data = <<EOD;
{t g}
{start_of_grid}
{end_of_grid}
{start_of_grid With a label}
{end_of_grid}
{start_of_grid 4x4}
{end_of_grid}
{start_of_grid 4x4 and label}
{end_of_grid}
{start_of_grid: shape="16x1"}
{end_of_grid}
{start_of_grid: label="Intro"}
{end_of_grid}
{start_of_grid: label="Intro" shape="12x1"}
{end_of_grid}
EOD

eval { $s->parse_file(\$data) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'ChordPro::Song', "It's a song" );
#use DDumper; warn(DDumper($s));exit;

my $sb = $s->{songs}->[0]->{body};
my $i = 0;

my $test = "default";
my $reset = {context => 'grid', name => 'context', type => 'set', value => ''};
my %param = (context => 'grid', name => 'gridparams', type => 'set');
my %label = (context => 'grid', name => 'label', type => 'set');

is_deeply( $sb->[$i], { %param,
			value => [4, 4, 1, 1], },
	   "$test" ); $i++;
is_deeply( $sb->[$i], $reset, "$test (reset)" ); $i++;

$test = "with a label (old style)";
is_deeply( $sb->[$i], { %param,
			value => [4, 4, 1, 1, 'With a label'] },
	   "$test" ); $i++;
is_deeply( $sb->[$i], $reset, "$test (reset)" ); $i++;

$test = "with a shape (old style)";
is_deeply( $sb->[$i], { %param, value => [4, 4, 0, 0] },
	   "$test" ); $i++;
is_deeply( $sb->[$i], $reset, "$test (reset)" ); $i++;

$test = "with shape and label (old style)";
is_deeply( $sb->[$i], { %param, value => [4, 4, 0, 0, 'and label'] },
	   "$test" ); $i++;
is_deeply( $sb->[$i], $reset, "$test (reset)" ); $i++;

$test = "with shape (new style)";
is_deeply( $sb->[$i], { %param, value => [16, 1, 0, 0] },
	   "$test (shape)" ); $i++;
is_deeply( $sb->[$i], $reset, "$test (reset)" ); $i++;

$test = "with label (new style)";
is_deeply( $sb->[$i], { %param, value => [16, 1, 0, 0] },
	   "$test (shape)" ); $i++;
is_deeply( $sb->[$i], { %label, value => 'Intro' },
	   "$test (label)" ); $i++;
is_deeply( $sb->[$i], $reset, "$test (reset)" ); $i++;

$test = "with shape and label (new style)";
is_deeply( $sb->[$i], { %param, value => [12, 1, 0, 0] },
	   "$test (shape)" ); $i++;
is_deeply( $sb->[$i], { %label, value => 'Intro' },
	   "$test (label)" ); $i++;
is_deeply( $sb->[$i], $reset, "$test (reset)" ); $i++;

__END__
{title: t/181_grids.t}
{start_of_grid}
| A |
{end_of_grid}
{start_of_grid With a label}
| A |
{end_of_grid}
{start_of_grid 4x4}
| A |
{end_of_grid}
{start_of_grid 4x4 and label}
| A |
{end_of_grid}
{start_of_grid: shape="16x1"}
| A |
{end_of_grid}
{start_of_grid: label="Intro"}
| A |
{end_of_grid}
{start_of_grid: label="Intro" shape="12x1"}
| A |
{end_of_grid}

