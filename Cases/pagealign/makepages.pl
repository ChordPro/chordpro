#!/usr/bin/perl

use v5.36;
use feature qw(signatures);
no warnings 'experimental::signatures';
use utf8;
my $verbose = 1;

use PDF::API2;

sub makepage($t) {
    my $title = $t eq "fill" ? "(fill)" : uc($t);
    for ( "", 2 ) {
	my $p = PDF::API2->new;
	my $page = $p->page;
	$page->mediabox("A4");
	my $text = $page->text;
	$text->font( $p->corefont("Helvetica-Bold"), 100 );
	$text->translate( 297, 380 );
	$text->text( $title, align => "center" );
	if ( $_ eq 2 ) {
	    $page = $p->page;
	    $text = $page->text;
	    $text->font( $p->corefont("Helvetica-Bold"), 100 );
	    $text->translate( 297, 380 );
	    $text->text( $title.$_, align => "center" );
	}
	$p->saveas($t.$_.".pdf");
	last if $t eq "fill";
    }
}

makepage($_) for qw( front cover back fill );
