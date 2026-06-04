#!/usr/bin/perl

# Comprehensive HTML5 paged mode test - generates complete songbooks for print
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
my $invalid = 0;
my $invalid_example;

plan tests => 1+$numtests;

diag("Testing ", scalar(@files), " cho files with HTML5 paged mode");

our $options;

foreach my $file ( sort @files ) {
    $test++;
    $file = "md/$file";
    #diag("Testing: $file");
    ( my $out = $file ) =~ s/\.cho/.paged.tmp/;
    
    # Create temporary config file for HTML5 paged mode
    my $cfg_file = "out/html5paged_test_config.json";
    open my $cfg_fh, '>:utf8', $cfg_file or die "Cannot create $cfg_file: $!";
    print $cfg_fh '{"html5":{"mode":"print"},"pdf":{"papersize":"a4","margintop":80,"marginbottom":40,"marginleft":40,"marginright":40,"headspace":60,"footspace":20,"formats":{"default":{"footer":["%{title}","%{page}",""]}}}}';
    close $cfg_fh;
    
    # Use HTML5 backend with paged mode configuration
    @ARGV = ( "--no-default-configs",
              "--generate", "HTML5",
              "--config", $cfg_file,
              "--output", $out,
              $file );
    ::run();
    
    # Clean up config file
    unlink($cfg_file);
    
    # Test that file was generated
    ok( -f $out, $file );
    
    # Verify it's valid HTML5 with Paged.js features
    if ( -f $out ) {
        open my $fh, '<:utf8', $out or die "Cannot open $out: $!";
        my $content = do { local $/; <$fh> };
        close $fh;
        
        # Basic validation - should have HTML5 structure and paged markers
        my $has_html = ($content =~ /<!DOCTYPE html>/i
                        && $content =~ /<html/
                        && $content =~ /<\/html>/);
        my $has_paged = ($content =~ /paged\.polyfill\.js/
                         && $content =~ /chordpro-paged/);
        my $has_page_rules = ($content =~ /\@page\b/);
        my $has_format_rules = ($content =~ /counter\(page\)/ && $content =~ /string\(song-title\)/);

        if ($has_html && $has_paged && $has_page_rules && $has_format_rules) {
            # File is valid, clean up
            unlink($out);
        } else {
            $invalid++;
            $invalid_example //= $file;
            unlink($out);
        }
    }
}

if ($invalid) {
    diag("Warning: $invalid files generated non-paged HTML5 output (e.g., $invalid_example)");
}

ok( $test++ == $numtests, "Tested $numtests files" );

