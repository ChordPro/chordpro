#! perl

use strict;
use Test::More;
use App::Packager qw( :name App::Music::ChordPro );

-d "t" && chdir "t";
use_ok "App::Music::ChordPro::A2Crd";
require_ok "./differ.pl";
my $test = 2;

BAIL_OUT("Missing a2crd test data") unless -d "a2crd";

opendir( my $dh, "a2crd" ) || BAIL_OUT("Cannot open a2crd test data");
my @files = grep { /^.+\.crd$/ } readdir($dh);
close($dh);
#diag("Testing ", scalar(@files), " crd files");

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
	      "--output", $out,
	      $file );
    ::run();
    my $ok = !differ( $out, $ref );
    ok( $ok, $file );
    unlink($out) if $ok;
}

ok( $test++ == @files+2, "Tested @{[0+@files]} files" );

done_testing($test);
