#!/usr/bin/perl

# Test HTML5Paged backend

use strict;
use warnings;
use Test::More tests => 12;
use File::Temp qw(tempfile);
use FindBin qw($Bin);
use lib "$Bin/../lib";

# Test 1: Module loads
BEGIN { use_ok('ChordPro::Output::HTML5Paged') };

# Test 2: Can create instance
my $backend;
eval {
    $backend = ChordPro::Output::HTML5Paged->new(
        config => {},
        options => {},
    );
};
ok(!$@, 'Backend instantiation succeeds');
isa_ok($backend, 'ChordPro::Output::HTML5Paged', 'Backend is correct class');

# Test 3: Backend extends HTML5
isa_ok($backend, 'ChordPro::Output::HTML5', 'Backend extends HTML5');

# Test 4: Check paged.js script inclusion in document begin
my $doc_begin = $backend->render_document_begin({ title => 'Test', songs => 1 });
like($doc_begin, qr/pagedjs/, 'Document begin includes paged.js reference');
like($doc_begin, qr/unpkg\.com\/pagedjs/, 'Document begin has paged.js CDN URL');

# Test 5: Check wrapper div
like($doc_begin, qr/<div class="book-content">/, 'Document begin has book-content wrapper');

# Test 6: Check body classes
like($doc_begin, qr/chordpro-paged/, 'Body has chordpro-paged class');

# Test 7: Check @page rules in CSS
my $css = $backend->generate_paged_css();
like($css, qr/\@page/, 'CSS includes @page rules');
like($css, qr/size:\s*A4/, 'CSS specifies A4 page size');

# Test 8: Check running header setup
like($css, qr/string-set:\s*song-title/, 'CSS sets up string-set for running headers');

# Test 9: Document end closes wrapper
my $doc_end = $backend->render_document_end();
like($doc_end, qr!</div>!, 'Document end closes wrapper div');

done_testing();
