#! perl

package App::Music::ChordPro::Output::PDF;

use strict;
use warnings;
use Carp;

my $pdfapi;
my $pdfapiv;

# PDF::API2 2.033 is ok, 2.035 is better, 2.036 is best.
for ( qw( Pango@1.227 PDF::Builder@3.016 PDF::API2@2.035 ) ) {
    next if $ENV{CHORDPRO_PDF} && ! /^\Q$ENV{CHORDPRO_PDF}\E/i;
    ( $pdfapi, $pdfapiv ) = split( '@', $_ );
    eval "require $pdfapi" or next;
    eval '$pdfapiv = $pdfapi->VERSION($pdfapiv)' or next;
    last;
}

croak("No PDF backend found") unless $pdfapi;

my $vv;
if ( $pdfapi eq "Pango" ) {
    $vv = "PDF: Pango ($pdfapi $Pango::VERSION)";
    $pdfapi = "PDFPango";
}
elsif ( eval { require Text::Layout } ) {
    $vv = "PDF: Markup ($pdfapi $pdfapiv, Text::Layout $Text::Layout::VERSION)";
    $pdfapi = "PDFMarkup";
}
else {
    $vv = "PDF: Classic ($pdfapi $pdfapiv)";
    $pdfapi = "PDFClassic";
}

our @ISA = ( __PACKAGE__ =~ s;PDF:*$;$pdfapi\:\:PDF;r );

eval "require $ISA[0]" or croak("No PDF backend $ISA[0]");

sub version {
    warn("$vv\n");
}

1;
