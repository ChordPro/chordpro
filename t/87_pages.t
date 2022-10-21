#! perl

use strict;
use warnings;
use utf8;
use Test::More tests => 7;

use App::Music::ChordPro::Testing;

use_ok "App::Music::ChordPro";

my $test = 1;

BAIL_OUT("Missing out dir") unless -d "out";

my $base = "out/87_pages.";

my $pdf = $base . "pdf";
my $cho = $base . "cho";
my $csv = $base . "csv";
( my $ref = $csv ) =~ s/out/ref/;

my $front = $base . "front.pdf";
my $back  = $base . "back.pdf";

use PDF::API2 2.042;

my $p = PDF::API2->new( file => $front );
my $page = $p->page;
$page->size("A4");
my $text = $page->text;
$text->font( $p->corefont("Times-Roman"), 100 );
$text->translate( 297, 600 );
$text->text( "FRONT", align => "center" );
$p->save;

$p = PDF::API2->new( file => $back );
$page = $p->page;
$page->size("A4");
$text = $page->text;
$text->font( $p->font("Times-Roman"),100 );
$text->translate( 297, 300 );
$text->text( "BACK", align => "center" );
$p->save;

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
	  "--define", "pdf.pagealign-songs=2",
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

