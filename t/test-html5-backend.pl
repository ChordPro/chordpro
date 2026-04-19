#!/usr/bin/perl

# Quick test of HTML5 backend with real ChordPro processing

use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";

use ChordPro::Songbook;
use ChordPro::Config;
use ChordPro::Output::HTML5;

# Set up configuration
my $config = ChordPro::Config::configurator({
    verbose => 0,
    output => "html5-test.html",
});

# Process test song
my $songbook = ChordPro::Songbook->new;
$songbook->parsefile("$FindBin::Bin/test-html5.cho", $config);

# Get songs
my $songs = $songbook->{songs};

if (!$songs || @$songs == 0) {
    die "No songs parsed\n";
}

print "Parsed ", scalar(@$songs), " song(s)\n";

# Create HTML5 backend
my $backend = ChordPro::Output::HTML5->new(
    config => $config,
    options => {},
);

# Open output file
open(my $fh, '>:utf8', 'html5-test.html') or die "Cannot write: $!\n";

# Generate document
print $fh $backend->render_document_begin({
    title => $songs->[0]->{title} // 'Test Song',
    songs => scalar(@$songs),
});

# Generate each song
foreach my $song (@$songs) {
    my $output = $backend->generate_song($song);
    print $fh join('', @$output);
}

# Close document
print $fh $backend->render_document_end();

close $fh;

print "HTML5 output written to html5-test.html\n";
print "Open it in a browser to view the results!\n";
