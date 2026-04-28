#! perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;

my $test = 0;

BAIL_OUT("Missing MMA test data") unless -d "mma";

opendir( my $dh, "mma" ) || BAIL_OUT("Cannot open mma test data");
my @files = grep { /^.+\.cho$/ } readdir($dh);
close($dh);
diag("Testing ", scalar(@files), " cho files");

our $options;

foreach my $file ( sort @files ) {
    $test++;
    my $decoda = $file =~ /^decoda/i;
    $file = "mma/$file";
    #diag("Testing: $file");
    ( my $out = $file ) =~ s/\.cho/.tmp/;
    ( my $ref = $file ) =~ s/\.cho/.mma/;
    @ARGV = ( "--no-default-configs",
	      "--generate", "MMA",
	      $decoda ? ( "--backend-option", "decoda=1" ) : (),
	      "--backend-option", "groove=testing",
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
