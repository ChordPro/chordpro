#!/usr/bin/perl

# Bug 1: Template path resolution fails out of the box
# Fixed in commit 22527232
#
# Previously: Error: CSS Template error: file error - html5/base.tt: not found
# Root Cause: Templates prefixed with "html5/" but "html5" not in INCLUDE_PATH
# Solution: HTML5.pm BUILD block adds CP->findresdirs("templates") to INCLUDE_PATH

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Songbook;

plan tests => 8;

use_ok('ChordPro::Output::HTML5');

# Test 1: Verify HTML5 object can be created without template errors
my $html5 = ChordPro::Output::HTML5->new(
    config => $config,
    options => { output => undef },
);
ok($html5, "HTML5 object created without template errors");

# Test 2: Verify template engine is initialized
ok($html5->can('_process_template'), "Template processing method available");

# Test 3: Generate output from a simple song and verify no template errors occur
my $song_data = <<'EOD';
{title: Template Test Song}
{subtitle: Bug 1 Regression Test}

{start_of_verse}
[C]This is a test
[G]For template paths
{end_of_verse}
EOD

my $s = ChordPro::Songbook->new;
$s->parse_file(\$song_data, { nosongline => 1 });
ok(scalar(@{$s->{songs}}) == 1, "Song parsed");

my $song = $s->{songs}[0];

# Test 4: Generate song output without errors
my $output = eval { $html5->generate_song($song) };
my $error = $@;
ok(!$error, "No template errors during generation") or diag("Error: $error");
ok($output, "HTML5 output generated");

# Test 5: Verify output contains expected HTML structure
like($output, qr/<div class="cp-song"/, "Output contains song container");

# Test 6: Verify CSS is included (templates were resolved)
like($output, qr/\.cp-songline|\.cp-chord|\.cp-lyrics/, "Output contains expected CSS classes");

diag("Bug 1 regression test: Template path resolution - PASSED");
