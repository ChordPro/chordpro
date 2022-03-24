#!/usr/bin/perl

use v5.20;

use PDF::API2;

my $n = shift || 1;

my ( $width, $height ) = ( 595, 842 ); # 16/10 tablet

my $pdf = PDF::API2->new;
$pdf->mediabox( 0, 0, $width, $height );
my $font = $pdf->corefont("Helvetica");

my @tags = qw( FIRST First Other );

foreach my $t ( @tags ) {

    my $page = $pdf->page;
    my $text = $page->text;
    $text->font( $font, 140 );
    $text->fillcolor( "lightblue" );
    my $w = $text->advancewidth($t);
    $text->translate( 40, 500 );
    $text->text($t);

    $page = $pdf->page;
    $text = $page->text;
    $text->font( $font, 140 );
    $text->fillcolor( "lightblue" );
    my $w = $text->advancewidth($t);
    $text->translate( $width-$w-40, 500 );
    $text->text($t);
}

$pdf->saveas("bgdemo.pdf");
