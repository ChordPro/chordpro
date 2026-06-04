#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use File::Path qw(make_path);
use ChordPro::Testing;

plan tests => 24;

make_path('out');

my $input = 'html5_diagram_pos.cho';

sub run_position_test {
    my ($label, $config_json, $assert_cb) = @_;

    my $out = "out/html5_diagram_pos_${label}.html";
    my $cfg = "out/html5_diagram_pos_${label}.json";

    open my $cfg_fh, '>:utf8', $cfg or die "Cannot create $cfg: $!";
    print {$cfg_fh} $config_json;
    close $cfg_fh;

    @ARGV = (
        '--no-default-configs',
        '--generate', 'HTML5',
        '--config', $cfg,
        '--output', $out,
        $input,
    );
    ::run();

    ok(-f $out, "HTML5 output generated for $label placement");

    open my $out_fh, '<:utf8', $out or die "Cannot open $out: $!";
    my $content = do { local $/; <$out_fh> };
    close $out_fh;

    $assert_cb->($content);

    like(
        $content,
        qr/\.cp-diagram-svg\s*\{[^}]*max-width:\s*var\(--cp-diagram-width\)/s,
        'Diagram SVG sizing is constrained via CSS'
    );

    unlink $out;
    unlink $cfg;
}

run_position_test(
    'bottom',
    '{"diagrams":{"show":"all"},"pdf":{"diagrams":{"show":"bottom","align":"right"}}}',
    sub {
        my ($content) = @_;
        my ($tag, $song_html) = $content =~ /<(div|section)\b[^>]*class="[^"]*\bcp-song\b[^"]*"[^>]*>([\s\S]*?)<\/\1><!-- \.cp-song -->/;
        $song_html = $song_html // '';
        my $line_pos = index($song_html, 'Line one');
        my $diagram_pos = index($song_html, '<div class="cp-chord-diagrams');
        ok($diagram_pos > $line_pos, 'Bottom placement renders diagrams after body');
        like($content, qr/cp-chord-diagrams-align-right/, 'Bottom placement applies alignment class');
    },
);

run_position_test(
    'right',
    '{"diagrams":{"show":"all"},"pdf":{"diagrams":{"show":"right","align":"center"}}}',
    sub {
        my ($content) = @_;
        like($content, qr/cp-song-layout-right/, 'Right placement applies layout class');
        like($content, qr/class="cp-song-main-right"/, 'Right placement uses dedicated body+diagram wrapper');
        like($content, qr/class="cp-song-body"/, 'Right placement wraps body content');
        like($content, qr/\.cp-song-layout-right\s+\.cp-song-diagrams\s*\{[^}]*justify-self:\s*end[^}]*width:\s*fit-content/s,
             'Right placement CSS enforces right alignment and fit-content panel width');
    },
);

run_position_test(
    'right-default-vertical',
    '{"diagrams":{"show":"all"},"pdf":{"diagrams":{"show":"right"}}}',
    sub {
        my ($content) = @_;
        like(
            $content,
            qr/\.cp-song-layout-right\s+\.cp-chord-diagrams\s*\{[^}]*flex-direction:\s*column/s,
            'Default right layout: CSS rule stacks chord diagrams vertically'
        );
        like(
            $content,
            qr/cp-chord-diagrams-direction-vertical/,
            'Default right layout: vertical direction class emitted from built-in default'
        );
        like(
            $content,
            qr/\.cp-song-layout-right\s+\.cp-chord-diagrams\s*\{[^}]*width:\s*fit-content/s,
            'Default right layout: chord-diagrams box shrinks to content width'
        );
    },
);

run_position_test(
    'top',
    '{"diagrams":{"show":"all"},"pdf":{"diagrams":{"show":"top","align":"right"}}}',
    sub {
        my ($content) = @_;
        like($content, qr/cp-song-layout-top/, 'Top placement applies top layout class');
        like($content, qr/class="cp-song-main-top"/, 'Top placement uses dedicated top wrapper');
        like(
            $content,
            qr/\.cp-song-layout-top\s+\.cp-song-main-top\s*>\s*\.cp-song-diagrams\s*\{[^}]*margin-bottom:\s*0\.75em/s,
            'Top placement CSS applies spacing rule for diagram panel'
        );
    },
);

run_position_test(
    'right-horizontal',
    '{"diagrams":{"show":"all"},"pdf":{"diagrams":{"show":"right"}},"html5":{"diagrams":{"direction":"horizontal"}}}',
    sub {
        my ($content) = @_;
        like(
            $content,
            qr/cp-chord-diagrams-direction-horizontal/,
            'Explicit horizontal direction: direction class emitted in HTML'
        );
        like(
            $content,
            qr/\.cp-chord-diagrams-direction-horizontal\s*\{[^}]*flex-direction:\s*row/s,
            'Explicit horizontal direction: CSS rule overrides flex-direction to row'
        );
    },
);
