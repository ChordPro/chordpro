#! perl

use strict;
use warnings;
use utf8;
use Test::More;

use ChordPro::Testing;

use_ok "ChordPro";

mkdir("out") unless -d "out";

my $base = "out/90_pages.";

my $pdf = $base . "pdf";
my $cho = $base . "cho";
my $csv = $base . "csv";
my $ref = $base . "ref";

our $options;
my $config = ChordPro::Config::pristine_config();
my $tests = 2;

SKIP: {
    skip( "Feature 'sort-pages' not implemented, skipped", 1 )
      unless $config =~ /^\s+"sort-pages"\s*:/m;
    $tests += 4;
    ok( open( my $fd, '>:utf8', $cho ), "Create $cho" );
    print $fd <<EOD;
{title: BBBBB}
Hi
{np}
Ho
{ns}
{title AAAAA}
{sorttitle AAAAB}
Hi
{np}
Ho
{ns}
{title AAAAA}
Hi
{np}
Ho
{ns}
{title ZZZZ}
Hi
{np}
Ho
{ns}
{title EEEE}
Hi
{ns}
{title FFFF}
Hi
{ns}
{title POPPP}
Hi
{np}
Ho
EOD

    ok( close($fd), "Close $cho" );
    undef $fd;

    # Test 1: Default

    @ARGV = ( "--no-default-configs", "--no-toc",
	      "--output", $pdf, "--csv",
	      $cho );

    ok( open( $fd, '>', $ref ), "Create $ref" );
    print $fd <<EOD;
title;pages;sort title;artists;composers;collections;keys;years
BBBBB;1-2;;;;;;
AAAAA;3-4;AAAAB;;;;;
AAAAA;5-6;;;;;;
ZZZZ;7-8;;;;;;
EEEE;9;;;;;;
FFFF;11;;;;;;
POPPP;13-14;;;;;;
EOD
    close($fd);

    ::run();

    ok( unlink($pdf), "Removed PDF" );

    my $ok = !differ( $csv, $ref );
    ok( $ok, $csv );

    # Test 2: Sort on title

    $tests += 3;
    @ARGV = ( "--no-default-configs", "--no-toc",
	      "--output", $pdf, "--csv",
	      "--define", "pdf.sort-pages=title",
	      $cho );

    ok( open( $fd, '>', $ref ), "Create $ref" );
    print $fd <<EOD;
title;pages;sort title;artists;composers;collections;keys;years
AAAAA;1-2;AAAAA;;;;;
AAAAA;3-4;AAAAB;;;;;
BBBBB;5-6;BBBBB;;;;;
EEEE;7;EEEE;;;;;
FFFF;9;FFFF;;;;;
POPPP;11-12;POPPP;;;;;
ZZZZ;13-14;ZZZZ;;;;;
EOD
    close($fd);

    ::run();

    ok( unlink($pdf), "Removed PDF" );

    $ok = !differ( $csv, $ref );
    ok( $ok, "pdf.sort-pages=title" );

    # Test 3: Sort on title, 2page.

    $tests += 3;
    @ARGV = ( "--no-default-configs", "--no-toc",
	      "--output", $pdf, "--csv",
	      "--define", "pdf.sort-pages=title,2page",
	      $cho );

    ok( open( $fd, '>', $ref ), "Create $ref" );
    print $fd <<EOD;
title;pages;sort title;artists;composers;collections;keys;years
AAAAA;2-3;AAAAA;;;;;
AAAAA;4-5;AAAAB;;;;;
BBBBB;6-7;BBBBB;;;;;
EEEE;8;EEEE;;;;;
FFFF;9;FFFF;;;;;
POPPP;10-11;POPPP;;;;;
ZZZZ;12-13;ZZZZ;;;;;
EOD
    close($fd);

    ::run();

    ok( unlink($pdf), "Removed PDF" );

    $ok = !differ( $csv, $ref );
    ok( $ok, "pdf.sort-pages=title,2page" );

    # Test 4: Sort on title, 2page, compact.

    $tests += 3;
    @ARGV = ( "--no-default-configs", "--no-toc",
	      "--output", $pdf, "--csv",
	      "--define", "pdf.sort-pages=title,2page,compact",
	      $cho );

    ok( open( $fd, '>', $ref ), "Create $ref" );
    print $fd <<EOD;
title;pages;sort title;artists;composers;collections;keys;years
EEEE;1;EEEE;;;;;
AAAAA;2-3;AAAAA;;;;;
AAAAA;4-5;AAAAB;;;;;
BBBBB;6-7;BBBBB;;;;;
FFFF;8;FFFF;;;;;
POPPP;10-11;POPPP;;;;;
ZZZZ;12-13;ZZZZ;;;;;
EOD
    close($fd);

    ::run();

    ok( unlink($pdf), "Removed PDF" );

    $ok = !differ( $csv, $ref );
    ok( $ok, "pdf.sort-pages=title,2page,compact" );

    # End of tests.

    unlink( $csv, $cho, $ref ) if $ok;
}

done_testing($tests);
