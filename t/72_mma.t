#! perl

use strict;
use App::Music::ChordPro::Testing;
use App::Packager qw( :name App::Music::ChordPro );

-d "t" && chdir "t";
use_ok "App::Music::ChordPro";
require_ok "./differ.pl";
my $test = 2;

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
    unlink($out) if $ok;
}

ok( $test++ == @files+2, "Tested @{[0+@files]} files" );

done_testing($test);
