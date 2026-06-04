#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use ChordPro::Testing;
use ChordPro::Songbook;

plan tests => 17;

# Prevent a dummy {body} for chord grids.
$config->{diagrams}->{show} = 0;
my $s = ChordPro::Songbook->new;

my $data = <<EOD;
{title Grids}
{start_of_grid 4x3}
| B . . | C . . | D~C . . | E . . |
| B . . | C . . | D . . | E . . |
| B . . | C . . | D . . | E . . |
| B . . | C . . | D . . | E . . |
{end_of_grid}
EOD

eval { $s->parse_file(\$data) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'ChordPro::Song', "It's a song" );
#use DDumper; warn(DDumper($s));
my $song = {
      meta => {
        songindex => 1,
        title => ['Grids'],
      },
      settings => {},
      source => { file => "__STRING__", line => 1 },
      structure => 'linear',
	    'system' => 'common',
      title => 'Grids',
      chordsinfo => { map { $_ => $_ } qw( B C D E ) },
      body => [
	       { context => 'grid',
		 name => 'gridparams',
		 type => 'set',
		 value => [4, 3, 0, 0]},
	       { context => 'grid',
		 type => 'gridline',
		 tokens => [
			   { class => 'bar', symbol => '|' },
			   { chord => 'B', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			   { chord => 'C', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			   { chords => ['D','C'], class => 'chords' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			   { chord => 'E', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			  ],
	       },
	       { context => 'grid',
		 type => 'gridline',
		 tokens => [
			   { class => 'bar', symbol => '|' },
			   { chord => 'B', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			   { chord => 'C', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			   { chord => 'D', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			   { chord => 'E', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			  ],
	       },
	       { context => 'grid',
		 type => 'gridline',
		 tokens => [
			   { class => 'bar', symbol => '|' },
			   { chord => 'B', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			   { chord => 'C', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			   { chord => 'D', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			   { chord => 'E', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			  ],
	       },
	       { context => 'grid',
		 type => 'gridline',
		 tokens => [
			   { class => 'bar', symbol => '|' },
			   { chord => 'B', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			   { chord => 'C', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			   { chord => 'D', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			   { chord => 'E', class => 'chord' },
			   { class => 'space', symbol => '.' },
			   { class => 'space', symbol => '.' },
			   { class => 'bar', symbol => '|' },
			  ],
	       },
	       {
		'value' => '',
		'context' => 'grid',
		'name' => 'context',
		'type' => 'set'
	       },
	      ],
	   };

is_deeply( { %{ $s->{songs}->[0] } }, $song, "Song contents" );

# Chord definitions.
$data = <<EOD;
{title Grids}
{start_of_grid 1+4x3+2}
| B . . | C . . | D . . | E . . |
{end_of_grid}
{start_of_grid}
| B . . | C . . | D . . | E . . |
{end_of_grid}
{start_of_grid}
| B . . | C . . | D . . | E . . |
{end_of_grid}
{start_of_grid}
| B . . | C . . | D . . | E . . |
{end_of_grid}
EOD

eval { $s->parse_file( \$data, { transpose => 2 } ) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 2, "One more song" );
isa_ok( $s->{songs}->[1], 'ChordPro::Song', "It's a song" );

$song = {
  body => [
    {
      context => 'grid',
      name => 'gridparams',
      type => 'set',
      value => [ 4, 3, 1, 2 ],
    },
    {
      context => 'grid',
      tokens => [
        {
          class => 'bar',
          symbol => '|',
        },
        {
          chord => 'C#',
          class => 'chord',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'bar',
          symbol => '|',
        },
        {
          chord => 'D',
          class => 'chord',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'bar',
          symbol => '|',
        },
        {
          chord => 'E',
          class => 'chord',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'bar',
          symbol => '|',
        },
        {
          chord => 'F#',
          class => 'chord',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'bar',
          symbol => '|',
        },
      ],
      type => 'gridline',
    },
    {
      context => 'grid',
      name => 'context',
      type => 'set',
      value => '',
    },
    {
      context => 'grid',
      name => 'gridparams',
      type => 'set',
      value => [ 4, 3, 1, 2 ],
    },
    {
      context => 'grid',
      tokens => [
        {
          class => 'bar',
          symbol => '|',
        },
        {
          chord => 'C#',
          class => 'chord',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'bar',
          symbol => '|',
        },
        {
          chord => 'D',
          class => 'chord',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'bar',
          symbol => '|',
        },
        {
          chord => 'E',
          class => 'chord',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'bar',
          symbol => '|',
        },
        {
          chord => 'F#',
          class => 'chord',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'bar',
          symbol => '|',
        },
      ],
      type => 'gridline',
    },
    {
      context => 'grid',
      name => 'context',
      type => 'set',
      value => '',
    },
    {
      context => 'grid',
      name => 'gridparams',
      type => 'set',
      value => [ 4, 3, 1, 2 ],
    },
    {
      context => 'grid',
      tokens => [
        {
          class => 'bar',
          symbol => '|',
        },
        {
          chord => 'C#',
          class => 'chord',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'bar',
          symbol => '|',
        },
        {
          chord => 'D',
          class => 'chord',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'bar',
          symbol => '|',
        },
        {
          chord => 'E',
          class => 'chord',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'bar',
          symbol => '|',
        },
        {
          chord => 'F#',
          class => 'chord',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'bar',
          symbol => '|',
        },
      ],
      type => 'gridline',
    },
    {
      context => 'grid',
      name => 'context',
      type => 'set',
      value => '',
    },
    {
      context => 'grid',
      name => 'gridparams',
      type => 'set',
      value => [ 4, 3, 1, 2 ],
    },
    {
      context => 'grid',
      tokens => [
        {
          class => 'bar',
          symbol => '|',
        },
        {
          chord => 'C#',
          class => 'chord',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'bar',
          symbol => '|',
        },
        {
          chord => 'D',
          class => 'chord',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'bar',
          symbol => '|',
        },
        {
          chord => 'E',
          class => 'chord',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'bar',
          symbol => '|',
        },
        {
          chord => 'F#',
          class => 'chord',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'space',
          symbol => '.',
        },
        {
          class => 'bar',
          symbol => '|',
        },
      ],
      type => 'gridline',
    },
    {
      context => 'grid',
      name => 'context',
      type => 'set',
      value => '',
    },
  ],
  meta => {
    songindex => 2,
    title => [
      'Grids',
    ],
  },
  settings => {},
  source => {
    file => '__STRING__',
    line => 1,
  },
  structure => 'linear',
  system => 'common',
  title => 'Grids',
  chordsinfo => { map { $_ => $_ } qw ( D E ), 'C#', 'F#' },
};

is_deeply( { %{ $s->{songs}->[1] } }, $song, "Song contents" );

$data = <<'EOD';
{title Grid Repeat Tokens}
{start_of_grid}
| % . . | %% . . |
{end_of_grid}
EOD

eval { $s->parse_file(\$data) } or diag("$@");

my $repeat_song = $s->{songs}->[2];
my ($repeat_gridline) = grep { ($_->{type} // '') eq 'gridline' } @{ $repeat_song->{body} // [] };
my %repeat_classes = map { ( $_->{class} // '' ) => 1 } @{ $repeat_gridline->{tokens} // [] };

ok( $repeat_classes{repeat1}, "Repeat token class repeat1 parsed from %" );
ok( $repeat_classes{repeat2}, "Repeat token class repeat2 parsed from %%" );

$data = <<'EOD';
{title Grid Strum Repeat Expansion}
{start_of_grid}
| C . . . | G . . . |
|s dn up dn up | % |
{end_of_grid}
EOD

eval { $s->parse_file(\$data) } or diag("$@");
my $strum_repeat_song = $s->{songs}->[3];
my ($strum_repeat_line) = grep { ($_->{type} // '') eq 'strumline' } @{ $strum_repeat_song->{body} // [] };
ok( $strum_repeat_line, "Strumline with % repeat parsed" );

my %strum_repeat_classes = map { ( $_->{class} // '' ) => 1 } @{ $strum_repeat_line->{tokens} // [] };
ok( !$strum_repeat_classes{repeat1}, "Strumline % is expanded to strum tokens (no repeat1 marker token left)" );
my $strum_repeat_cells = scalar grep { (($_->{class}//'') ne 'bar') } @{ $strum_repeat_line->{tokens} // [] };
is( $strum_repeat_cells, 8, "Strumline % expands to one full prior 4-beat strum measure" );

$data = <<'EOD';
{title Grid Strum Repeat Error Percent}
{start_of_grid}
| C . . . |
|s % |
{end_of_grid}
EOD

my $ok_percent = eval { $s->parse_file(\$data); 1 };
ok( !$ok_percent && $@ =~ /Strum repeat % requires one prior strum measure/, "Strumline % without prior strum bar is a parse error" );

$data = <<'EOD';
{title Grid Strum Repeat Error DoublePercent}
{start_of_grid}
| C . . . | G . . . |
|s dn up dn up | %% |
{end_of_grid}
EOD

my $ok_double = eval { $s->parse_file(\$data); 1 };
ok( !$ok_double && $@ =~ /Strum repeat %% requires two prior strum measures/, "Strumline %% with fewer than two prior strum bars is a parse error" );

$data = <<'EOD';
{title Grid Mixed Repeat Slot Validation}
{start_of_grid shape="1+4x4+0"}
|: C . . . | Am . . . | % | % :|
|s dn~up dn~up dn~up dn~up | dn~up dn~up dn~up dn~up | % | % |
{end_of_grid}
EOD

my $ok_mixed = eval { $s->parse_file(\$data); 1 };
ok( $ok_mixed, "Chord % markers and strum % expansions stay slot-compatible for dn~up repeat rows" );

$data = <<'EOD';
{title Grid Double Repeat Width}
{start_of_grid shape="0+4x4+0"}
| C . . . | Am . . . | %% | . . . . |
{end_of_grid}
EOD

my $warn = '';
{
  local $SIG{__WARN__} = sub { $warn .= shift };
  eval { $s->parse_file(\$data); 1 };
}
unlike( $warn, qr/Too few cells for grid content/,
  "Chord %% spanning two measures does not trigger false Too few cells warning" );

$data = <<'EOD';
{title Grid Repeat Display Expansion}
{start_of_grid}
| C . . . | Am . . . | % |
{end_of_grid}

{start_of_grid}
| C . . . | Am . . . | %% | . . . . |
{end_of_grid}
EOD

eval { $s->parse_file(\$data) } or diag("$@");
my $repeat_display_song = $s->{songs}->[6];
my @repeat_display_lines = grep { ($_->{type} // '') eq 'gridline' } @{ $repeat_display_song->{body} // [] };
my ($repeat1_token) = grep { (($_->{class} // '') eq 'repeat1') } @{ $repeat_display_lines[0]->{tokens} // [] };
my ($repeat2_token) = grep { (($_->{class} // '') eq 'repeat2') } @{ $repeat_display_lines[1]->{tokens} // [] };
is( $repeat1_token->{symbol} // '', '%',
    "Chord % token keeps literal repeat symbol for renderer" );
is( $repeat2_token->{symbol} // '', '%%',
    "Chord %% token keeps literal repeat symbol for renderer" );
