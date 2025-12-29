#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;

my $test = 0;

BAIL_OUT("Missing html5 test data") unless -d "html5";

opendir( my $dh, "html5" ) || BAIL_OUT("Cannot open html5 test data");
my @files = grep { /^.+\.cho$/ } readdir($dh);
close($dh);
diag("Testing ", scalar(@files), " cho files");

our $options;

foreach my $file ( sort @files ) {
    $test++;
    $file = "html5/$file";
    ( my $out = $file ) =~ s/\.cho/.tmp/;
    ( my $ref = $file ) =~ s/\.cho/.html/;
    @ARGV = ( "--no-default-configs",
	      "--generate", "HTML5",
	      "--output", $out,
	      $file );
    ::run();
    my $ok = !differ( $out, $ref );
    ok( $ok, $file );
    unlink($out), next if $ok;
    system( $ENV{CHORDPRO_DIFF}, $out, $ref) if $ENV{CHORDPRO_DIFF};
}

ok( $test++ == @files, "Tested @{[0+@files]} files" );

done_testing($test);
