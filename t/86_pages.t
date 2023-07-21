#! perl

use strict;
use warnings;
use utf8;
use Test::More tests => 7;

use ChordPro::Testing;

use_ok "ChordPro";

my $test = 1;

BAIL_OUT("Missing out dir") unless -d "out";

my $base = "out/86_pages.";

my $pdf = $base . "pdf";
my $cho = $base . "cho";
my $csv = $base . "csv";
( my $ref = $csv ) =~ s/out/ref/;

my $front = $base . "front.pdf";
my $back  = $base . "back.pdf";

use ChordPro::Output::PDF;
my $api = ChordPro::Output::PDF::config_pdfapi;

my $p = $api->new( file => $front );
my $page = $p->page;
$page->mediabox("A4");
my $text = $page->text;
$text->font( $p->corefont("Times-Roman"), 100 );
$text->translate( 297, 600 );
$text->text( "FRONT", align => "center" );
$p->saveas($front);

$p = $api->new( file => $back );
$page = $p->page;
$page->mediabox("A4");
$text = $page->text;
$text->font( $p->corefont("Times-Roman"),100 );
$text->translate( 297, 300 );
$text->text( "BACK", align => "center" );
$p->saveas($back);

our $options;

ok( open( my $fd, '>:utf8', $cho ), "Create $cho" );
print $fd <<EOD;
{title: Song1}
{artist: Artist1}
{composer: Composer1}
{key: A}

[A]Hello, [Bm]World!
[A]Hello, [Bm]World!
[A]Hello, [Bm]World!

{new_song}
{title: Song2}
{artist: Artist2}
{composer: Composer2}
{key: B}

[A]Hello, [Bm]World!
[A]Hello, [Bm]World!
[A]Hello, [Bm]World!

{new_song}
{title: Song3}
{artist: Artist3}
{composer: Composer3}
{key: C}

[A]Hello, [Bm]World!
[A]Hello, [Bm]World!
[A]Hello, [Bm]World!
EOD

ok( close($fd), "Close $cho" );

@ARGV = ( "--no-default-configs",
	  "--define", "pdf.csv.songsonly=0",
	  "--define", "pdf.pagealign-songs=1",
	  "--front-matter", $front,
	  "--back-matter", $back,
	  "--output", $pdf, "--csv",
	  $cho );
::run();

ok( unlink($pdf),   "Removed PDF" );
ok( unlink($front), "Removed front matter" );
ok( unlink($back),  "Removed back matter" );

my $ok = !differ( $csv, $ref );
ok( $ok, $csv );
unlink($csv) if $ok;

