#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Test::More;
use ChordPro::Testing;

plan tests => 17;

use_ok('ChordPro');

BAIL_OUT('Missing out dir') unless -d 'out';

my $cho = 'out/94_html5_page_breaks.cho';
open my $cho_fh, '>:utf8', $cho or die "Cannot create $cho: $!";
print {$cho_fh} <<'EOD';
{title: Page Break One}
[C]Hello [G]World

{new_song}
{title: Page Break Two}
[Am]Second [Em]Song
EOD
close $cho_fh;

sub run_break_test {
    my ($label, $break_value, $expect_before, $expect_after) = @_;

    my $out = "out/94_html5_page_breaks_${label}.html";
    my $cfg = "out/94_html5_page_breaks_${label}.json";

    open my $cfg_fh, '>:utf8', $cfg or die "Cannot create $cfg: $!";
    print {$cfg_fh} qq|{
  "html5": {
    "mode": "print",
    "paged": {
      "song": {
        "page-break": "$break_value"
      }
    }
  },
  "pdf": {
    "papersize": "a4",
    "margintop": 80,
    "marginbottom": 40,
    "marginleft": 40,
    "marginright": 40,
    "headspace": 60,
    "footspace": 20,
    "formats": {
      "default": {
        "footer": ["%{title}", "%{page}", ""]
      }
    }
  }
}|
    ;
    close $cfg_fh;

    @ARGV = (
        '--no-default-configs',
        '--generate', 'HTML5',
        '--config', $cfg,
        '--output', $out,
        $cho,
    );
    ::run();

    ok(-f $out, "HTML5 paged output generated for $label");

    open my $out_fh, '<:utf8', $out or die "Cannot open $out: $!";
    my $content = do { local $/; <$out_fh> };
    close $out_fh;

    my $before_rx = qr/class="cp-song-break\b[^"]*\bcp-page-break-before\b/;
    my $before_song_rx = qr/<section\b[^>]*class="[^"]*\bcp-song\b[^"]*\bcp-page-break-before\b/;
    my $after_rx = qr/class="cp-song[^"]*\bcp-page-break-after\b/;

    if ($expect_before) {
      like($content, $before_rx, "$label includes page-break before class");
      unlike($content, $before_song_rx, "$label omits page-break before class on song");
    } else {
      unlike($content, $before_rx, "$label omits page-break before class");
      unlike($content, $before_song_rx, "$label omits page-break before class on song");
    }

    if ($expect_after) {
      like($content, $after_rx, "$label includes page-break after class");
    } else {
      unlike($content, $after_rx, "$label omits page-break after class");
    }

    unlink $out;
    unlink $cfg;
}

run_break_test('none', 'none', 0, 0);
run_break_test('before', 'before', 1, 0);
run_break_test('after', 'after', 0, 1);
run_break_test('both', 'both', 1, 1);

unlink $cho;
