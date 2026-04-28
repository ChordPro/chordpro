#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;

plan tests => 6;

my $input = "html5_rechorus.cho";

sub run_rechorus_test {
    my ( $label, $config_json, $assert_cb ) = @_;

    my $out = "out/html5_rechorus_${label}.html";
    my $cfg = "out/html5_rechorus_${label}.json";

    open my $cfg_fh, '>:utf8', $cfg or die "Cannot create $cfg: $!";
    print {$cfg_fh} $config_json;
    close $cfg_fh;

    @ARGV = (
        "--no-default-configs",
        "--generate", "HTML5",
        "--config", $cfg,
        "--output", $out,
        $input,
    );
    ::run();

    ok( -f $out, "Generated output for $label" );

    open my $out_fh, '<:utf8', $out or die "Cannot open $out: $!";
    my $content = do { local $/; <$out_fh> };
    close $out_fh;

    $assert_cb->($content);

    unlink $out;
    unlink $cfg;
}

run_rechorus_test(
    "quote",
    '{"pdf":{"chorus":{"recall":{"quote":true}}}}',
    sub {
        my ($content) = @_;
        my @matches = $content =~ /Chorus line one/g;
        is( scalar @matches, 2, "Quote mode re-renders chorus content" );
    },
);

run_rechorus_test(
    "tag",
    '{"pdf":{"chorus":{"recall":{"type":"comment","tag":"Refrain"}}}}',
    sub {
        my ($content) = @_;
        like( $content, qr/<div class="cp-comment">Refrain<\/div>/, "Tag mode shows comment label" );
    },
);

run_rechorus_test(
    "default",
    '{"pdf":{"chorus":{"recall":{"type":"","tag":""}}}}',
    sub {
        my ($content) = @_;
        like(
            $content,
            qr/<div class="cp-rechorus">\s*Chorus\s*<\/div>/s,
            "Default mode shows rechorus label",
        );
    },
);
