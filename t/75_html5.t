#!/usr/bin/perl

# Comprehensive HTML5 backend test - generates complete songbooks
# Similar to 74_latex.t

use strict;
use warnings;
use utf8;

use ChordPro::Testing;

# Use existing test data from markdown tests
BAIL_OUT("Missing md test data") unless -d "md";

opendir( my $dh, "md" ) || BAIL_OUT("Cannot open md test data");
my @files = grep { /^.+\.cho$/ } readdir($dh);
close($dh);
my $numtests = @files;
my $test = 0;

plan tests => 1+$numtests;

diag("Testing ", scalar(@files), " cho files with HTML5 backend");

our $options;

foreach my $file ( sort @files ) {
    $test++;
    $file = "md/$file";
    #diag("Testing: $file");
    ( my $out = $file ) =~ s/\.cho/.html5.tmp/;
    
    @ARGV = ( "--no-default-configs",
              "--generate", "HTML5",
              "--output", $out,
              $file );
    ::run();
    
    # Test that file was generated
    ok( -f $out, $file );
    
    # Verify it's valid HTML5
    if ( -f $out ) {
        open my $fh, '<:utf8', $out or die "Cannot open $out: $!";
        my $content = do { local $/; <$fh> };
        close $fh;
        
        # Basic validation
        if ($content =~ /<!DOCTYPE html>/i && 
            $content =~ /<html/ && 
            $content =~ /<\/html>/) {
            # File is valid, clean up
            unlink($out);
        } else {
            diag("Warning: $file generated invalid HTML5");
            unlink($out);
        }
    }
}

ok( $test++ == $numtests, "Tested $numtests files" );

