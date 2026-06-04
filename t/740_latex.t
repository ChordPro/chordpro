#! perl

use strict;
use warnings;
use utf8;

use ChordPro::Testing;

BAIL_OUT("Missing md test data") unless -d "md";

opendir( my $dh, "latex" ) || BAIL_OUT("Cannot open md test data");
my @files = grep { /^.+\.cho$/ } readdir($dh);
close($dh);
my $numtests = @files;
my $test = 0;
plan tests => 1+$numtests;

SKIP: {

    unless ( eval { require Template } ) {
	diag( 'Skipped all tests -- missing Template module' );
	skip( 'Missing Template module', 1+$numtests );
    }

    unless ( eval { require LaTeX::Encode } ) {
	diag( 'Skipped all tests -- missing LaTeX::Encode module' );
	skip( 'Missing LaTeX::Encode module', 1+$numtests );
    }

    diag("Testing ", scalar(@files), " cho files");

    our $options;

    foreach my $file ( sort @files ) {
	$test++;
	$file = "latex/$file";
	#diag("Testing: $file");
	( my $out = $file ) =~ s/\.cho/.tmp/;
	( my $ref = $file ) =~ s/\.cho/.tex/;
	@ARGV = ( "--no-default-configs", "--config", "./latex/t_config.json",
		  "--generate", "LaTeX",
		  "--output", $out,
		  $file );
	::run();
	my $ok = !differ( $out, $ref );
	ok( $ok, $file );
	unlink($out), next if $ok;
	system( $ENV{CHORDPRO_DIFF}, $out, $ref) if $ENV{CHORDPRO_DIFF};
    }

    ok( $test++ == $numtests, "Tested $numtests files" );
}
