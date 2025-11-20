#! perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;

use_ok "ChordPro";

my $test = 1;

BAIL_OUT("Missing chordpro test data") unless -d "cho";

opendir( my $dh, "cho" ) || BAIL_OUT("Cannot open chordpro test data");
my @files = grep { /^.+\.cho$/ } readdir($dh);
close($dh);
diag("Testing ", scalar(@files), " chordpro files");

our $options;
#$options->{fragment} = 1;

foreach my $file ( sort @files ) {
    $test++;
    $file = "cho/$file";
    #diag("Testing: $file");
    ( my $out = $file ) =~ s/\.cho/.out/;
    ( my $ref = $file ) =~ s/\.cho/.ref/;
    @ARGV = ( "--no-default-configs",
	      "--generate", "ChordPro",
	      "--backend-option", "expand=1",
	      "--output", $out,
	      $file );
    if ( $file =~ /n\./ ) {
	splice( @ARGV, -1, 0, "--transcode", "nashville",
		"--define", "diagrams.show=false",
	      );
    }
    elsif ( $file =~ /r\./ ) {
	splice( @ARGV, -1, 0, "--transcode", "roman",
		"--define", "diagrams.show=false",
	      );
    }
    ::run();
    my $ok = !differ( $out, $ref );
    ok( $ok, $file );
    unlink($out), next if $ok;
    system( $ENV{CHORDPRO_DIFF}, $out, $ref) if $ENV{CHORDPRO_DIFF};
}

ok( $test++ == @files+1, "Tested @{[0+@files]} files" );

done_testing($test);
