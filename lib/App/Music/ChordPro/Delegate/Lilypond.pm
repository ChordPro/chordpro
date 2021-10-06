#!/usr/bin/perl

package main;

our $config;
our $options;

package App::Music::ChordPro::Delegate::Lilypond;

use strict;
use warnings;
use utf8;
use File::Spec;
use File::Temp ();
use feature 'state';

use App::Music::ChordPro::Utils;

sub LYDEBUG() { $config->{debug}->{ly} }

sub ly2image {
    my ( $s, $pr, $elt ) = @_;
    state $imgcnt = 0;
    state $td = File::Temp::tempdir( CLEANUP => !$config->{debug}->{ly} );
    my $src  = File::Spec->catfile( $td, "tmp${imgcnt}.ly" );
    my $img  = File::Spec->catfile( $td, "tmp${imgcnt}.png" );

    my $fd;
    unless ( open( $fd, '>:utf8', $src ) ) {
	warn("Error in Lilypond embedding: $src: $!\n");
	return;
    }

    print $fd "\\version \"2.21.0\"\n";
    print $fd "\\header { tagline = ##f }\n";
    for ( keys(%{$elt->{opts}}) ) {
	print $fd '%%'.$_." ".$elt->{opts}->{$_}."\n";
    }
    for ( @{$elt->{data}} ) {
	print $fd $_, "\n";
    }

    unless ( close($fd) ) {
	warn("Error in Lilypond embedding: $src: $!\n");
	return;
    }

    # Available width and height.
    my $pw;
    my $ps = $pr->{ps};
    if ( $ps->{columns} > 1 ) {
	$pw = $ps->{columnoffsets}->[1]
	  - $ps->{columnoffsets}->[0]
	  - $ps->{columnspace};
    }
    else {
	$pw = $ps->{__rightmargin} - $ps->{_leftmargin};
    }

    state $lilypond = findexe("lilypond");
    unless ( $lilypond ) {
	warn("Error in Lilypond embedding: missing 'lilypond' tool.\n");
	return;
    }

    my @cmd;
    if ( is_msw() ) {
	state $magick = findexe("magick");
	unless ( $magick ) {
	    warn("Error in Lilypond embedding: missing 'imagemagick/convert' tool.\n");
	    return;
	}
	@cmd = ( $magick, "convert" );
    }
    else {
	state $convert = findexe("convert");
	unless ( $convert ) {
	    warn("Error in Lilypond embedding: missing 'imagemagick/convert' tool.\n");
	    return;
	}
	@cmd = ( $convert );
    }

    my $png = File::Spec->catfile( $td, "tmp${imgcnt}" );
    if ( sys( qw(lilypond -s --png -dresolution=820),
	      "-o", $png, $src ) ) {
	warn("Error in Lilypond embedding\n");
	return;
    }
    if ( sys( @cmd, qw(-background white -trim), $img, $img ) ) {
	warn("Error in Lilypond embedding\n");
	return;
    }

    return [
	    { type => "image",
	      uri  => $img,
	      opts => { center => 0, scale => 0.1 } },
	   ];

}

1;
