#! perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;

use_ok "ChordPro::A2Crd";

my $test = 1;

BAIL_OUT("Missing a2crd test data") unless -d "a2crd";

opendir( my $dh, "a2crd" ) || BAIL_OUT("Cannot open a2crd test data");
my @files = grep { /^.+\.crd$/ } readdir($dh);
close($dh);
diag("Testing ", scalar(@files), " crd files");

our $options;
$options->{fragment} = 1;

foreach my $file ( sort @files ) {
    $test++;
    $file = "a2crd/$file";
    #diag("Testing: $file");
    ( my $out = $file ) =~ s/\.crd/.tmp/;
    ( my $ref = $file ) =~ s/\.crd/.cho/;
    @ARGV = ( "--a2crd",
	      "--no-default-configs",
	      "--generate", "ChordPro",
	      "--output", $out,
	      $file );
    ::run();
    my $ok = !differ( $out, $ref );
    ok( $ok, $file );
    unlink($out) if $ok;
}

ok( $test++ == @files+1, "Tested @{[0+@files]} files" );

done_testing($test);
