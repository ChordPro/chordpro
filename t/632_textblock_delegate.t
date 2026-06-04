#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Test::More;
use ChordPro::Testing;
use ChordPro::Songbook;
use ChordPro::Delegate::TextBlock;
use ChordPro::Output::HTML;
use ChordPro::Output::HTML5;

plan tests => 9;

my $res = ChordPro::Delegate::TextBlock->txt2html(
    elt => {
        line => 1,
        opts => { textstyle => 'note' },
        data => [ 'Line <one>', q{Line "two"} ],
    },
);

is( $res->{type}, 'html', 'TextBlock delegate returns HTML payload' );
is_deeply(
    $res->{classes},
    [ 'cp-delegate', 'cp-delegate-textblock', 'cp-delegate-textblock-style-note' ],
    'TextBlock delegate exposes structured CSS classes'
);
is_deeply(
    $res->{data},
    [ 'Line &lt;one&gt;', 'Line &quot;two&quot;' ],
    'TextBlock delegate exposes HTML-escaped lines'
);

my $song_data = <<'EOD';
{title: Delegate TextBlock}
{start_of_textblock: textstyle=note}
Line <one>
Line "two"
{end_of_textblock}
EOD

sub parse_song {
    my $s = ChordPro::Songbook->new;
    $s->parse_file( \$song_data, { nosongline => 1 } );
    return $s->{songs}[0];
}

my $html5 = ChordPro::Output::HTML5->new( config => $::config );
my $html5_output = $html5->generate_song( parse_song() );

like(
    $html5_output,
    qr/class="cp-delegate cp-delegate-textblock cp-delegate-textblock-style-note"/,
    'HTML5 renders TextBlock delegate with structured classes'
);
like(
    $html5_output,
    qr/Line &lt;one&gt;<br\/>\s*Line &quot;two&quot;/,
    'HTML5 renders escaped TextBlock lines with line breaks'
);
unlike( $html5_output, qr/HASH\(/, 'HTML5 does not stringify delegate hashes' );

local $::options = { tidy => 0, 'single-space' => 0 };
my $html_output = join( "\n", @{ ChordPro::Output::HTML::generate_song( parse_song() ) } );

like(
    $html_output,
    qr/class="cp-delegate cp-delegate-textblock cp-delegate-textblock-style-note"/,
    'HTML renders TextBlock delegate with structured classes'
);
like(
    $html_output,
    qr/Line &lt;one&gt;<br\/>\s*Line &quot;two&quot;/,
    'HTML renders escaped TextBlock lines with line breaks'
);
unlike( $html_output, qr/HASH\(/, 'HTML does not stringify delegate hashes' );
