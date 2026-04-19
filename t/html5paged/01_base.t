#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;
use ChordPro::Songbook;

plan tests => 12;

use_ok('ChordPro::Output::HTML5');

# Create HTML5 backend
my $paged = ChordPro::Output::HTML5->new(
    config => $config,
    options => { output => undef },
);
ok($paged, "HTML5 object created");

# Test that it inherits from HTML5
isa_ok($paged, 'ChordPro::Output::HTML5', "Inherits from HTML5");
isa_ok($paged, 'ChordPro::Output::ChordProBase', "Inherits from ChordProBase");

# Test Paged.js specific methods
can_ok($paged, '_generate_format_rules');
can_ok($paged, '_generate_format_rule');
can_ok($paged, '_generate_margin_boxes');
can_ok($paged, '_format_content_string');

# Test that markup processing is inherited
can_ok($paged, 'process_text_with_markup');

# Test basic output generation
my $song_data = <<'EOD';
{title: Test Song}
{subtitle: For Paged Output}

{start_of_verse}
[C]Simple test song
[G]With some chords
{end_of_verse}
EOD

my $s = ChordPro::Songbook->new;
$s->parse_file(\$song_data, { nosongline => 1 });
ok(scalar(@{$s->{songs}}) == 1, "Song parsed");

my $song = $s->{songs}[0];

my $output = $paged->generate_song($song);
ok($output, "HTML5 output generated");

# Test that output contains song content
like($output, qr/<div class="cp-song"/, "Output contains song container");

