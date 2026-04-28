#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;

plan tests => 6;

my @songs = (
    "html5_sorting_1.cho",
    "html5_sorting_2.cho",
    "html5_sorting_3.cho",
);

sub run_sort_test {
    my ( $label, $config_json, $expected_titles ) = @_;

    my $out = "out/html5_sorting_${label}.html";
    my $cfg = "out/html5_sorting_${label}.json";

    open my $cfg_fh, '>:utf8', $cfg or die "Cannot create $cfg: $!";
    print {$cfg_fh} $config_json;
    close $cfg_fh;

    @ARGV = (
        "--no-default-configs",
        "--generate", "HTML5",
        "--config", $cfg,
        "--output", $out,
        @songs,
    );
    ::run();

    ok( -f $out, "Generated output for $label" );

    open my $out_fh, '<:utf8', $out or die "Cannot open $out: $!";
    my $content = do { local $/; <$out_fh> };
    close $out_fh;

    my @titles = $content =~ /<h1 class=\"cp-title\"[^>]*>(.*?)<\/h1>/g;
    is_deeply( \@titles, $expected_titles, "Sorted by $label" );

    unlink $out;
    unlink $cfg;
}

run_sort_test(
    "title",
    '{"pdf":{"songbook":{"sort-songs":"title"}}}',
    [ "Alpha Song", "Beta Song", "Gamma Song" ],
);

run_sort_test(
    "artist",
    '{"pdf":{"songbook":{"sort-songs":"artist"}}}',
    [ "Alpha Song", "Gamma Song", "Beta Song" ],
);

run_sort_test(
    "title_desc",
    '{"pdf":{"songbook":{"sort-songs":"-title"}}}',
    [ "Gamma Song", "Beta Song", "Alpha Song" ],
);
