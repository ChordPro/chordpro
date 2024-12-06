#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Songbook;

my $s = ChordPro::Songbook->new;

# Just see if all directives are recognized and handled.
my $data = <<EOD;
{new_song}
{ns}
{album: 0}
{arranger: 0}
{artist: 0}
{c: 0}
{capo: 0}
{cb: 0}
{cf: 0}
{chord: C}
{chorus: 0}
{ci: 0}
{colb: 0}
{column_break: 0}
{columns: 0}
{comment: 0}
{comment_box: 0}
{comment_italic: 0}
{composer: 0}
{copyright: 0}
{cs: 0}
{define: 0}
{diagrams: 0}
{duration: 0}
{g: 0}
{grid: 0}
{highlight: 0}
{image: 0}
{key: C}
{lyricist: 0}
{meta: title 0}
{new_page: 0}
{new_physical_page: 0}
{ng: 0}
{no_grid: 0}
{np: 0}
{npp: 0}
{pagesize: a4}
{pagetype: A4}
{sob}
{eob}
{soc}
{eoc}
{sot}
{eot}
{sov}
{eov}
{sorttitle: 0}
{st: 0}
{start_of_bridge}
{end_of_bridge}
{start_of_chorus}
{end_of_chorus}
{start_of_grid}
{end_of_grid}
{start_of_tab}
{end_of_tab}
{start_of_verse}
{end_of_verse}
{subtitle: 0}
{t: 0}
{tempo: 120}
{tf: 0}
{time: 4/4}
{title: 0}
{titles: left}
{transpose: 0}
{ts: 0}
{year: 0}
EOD

for ( qw( chord chorus diagrams footer grid label tab text title toc ) ) {
    $data .= <<EOD;
{${_}color: green}
{${_}colour: lime}
{${_}font: Helvetica}
{${_}size: 10}
EOD
}

my @data = split( /[\r\n]+/, $data );

plan tests => 1 + 2 * @data;

eval { $s->parse_file(\$data); 1 } or diag("$@");
ok( scalar( @{ $s->{songs} } ) == 1, "Directives parsed" );

my $song = $s->{songs}->[0];

# Add a dummy selector to each directive.
for ( @data ) {
    s/^\{(.*?)(\s*:.*)\}$/$1-foo$2/mg
      or s/^\{(.*?)\}$/$1-foo/mg;
}

# Verify that the directives are ignored.
for my $dir ( @data ) {
    my $result = $song->parse_directive($dir);
    ok( $result->{omit} > 0, "ignored ok: $dir ($result->{name})" );
    next if $result->{omit} > 0;
    require DDP; DDP::p($result);
}

$song->{meta}->{foo} = [ 1 ];
# Verify that the directives are not ignored.
for my $dir ( @data ) {
    my $result = $song->parse_directive($dir);
    ok( $result->{omit} == 0, "not ignored ok: $dir ($result->{name})" );
    next if $result->{omit} == 0;
    require DDP; DDP::p($result);
}
