#!/usr/bin/perl

package main;

our $config;
our $options;

package App::Music::ChordPro::Delegate::ABC;

use strict;
use warnings;
use utf8;
use File::Spec;
use File::Temp ();

use App::Music::ChordPro::Utils;

sub ABCDEBUG() { $config->{debug}->{abc} }

use feature 'state';

sub abc2image {
    my ( $s, $pr, $elt ) = @_;

    state $imgcnt = 0;
    state $td = File::Temp::tempdir( CLEANUP => !$config->{debug}->{abc} );

    $imgcnt++;
    my $src  = File::Spec->catfile( $td, "tmp${imgcnt}.abc" );
    my $img  = File::Spec->catfile( $td, "tmp${imgcnt}.jpg" );
    if ( $elt->{subtype} =~ /^image-(\w+)$/ ) {
	$img  = File::Spec->catfile( $td, "tmp${imgcnt}.$1" );
    }

    my $fd;
    unless ( open( $fd, '>:utf8', $src ) ) {
	warn("Error in ABC embedding: $src: $!\n");
	return;
    }

    for ( keys(%{$elt->{opts}}) ) {
	print $fd '%%'.$_." ".$elt->{opts}->{$_}."\n";
	warn('%%'.$_." ".$elt->{opts}->{$_}."\n") if ABCDEBUG;
    }

    # Add mandatory field.
    my @pre;
    my @data = @{$elt->{data}};
    while ( @data ) {
	$_ = shift(@data);
	unshift( @data, $_ ), last if /^X:/;
	push( @pre, $_ );
    }
    if ( @pre && !@data ) {	# no X: found
	warn("X:1 (added)\n") if ABCDEBUG;
	@data = ( "X:1", @pre );
	@pre = ();
    }
    my $kv = { %$elt };
    $kv = parse_kv( @pre );
    ::dump($kv) if $kv;
    # Copy. We assume the user knows how to write ABC.
    for ( @data ) {
	print $fd $_, "\n";
	warn($_, "\n") if ABCDEBUG;
    }

    unless ( close($fd) ) {
	warn("Error in ABC embedding: $src: $!\n");
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
    if ( $kv->{width} ) {
	$pw = $kv->{width};
    }
    state $abcm2ps = findexe("abcm2ps");
    unless ( $abcm2ps ) {
	warn("Error in ABC embedding: missing 'abcm2ps' tool.\n");
	return;
    }

    my $svg0 = File::Spec->catfile( $td, "tmp${imgcnt}.svg" );
    my $svg1 = File::Spec->catfile( $td, "tmp${imgcnt}001.svg" );
    warn( join(" ", $abcm2ps, qw(-g -q -m0cm),
	       "-w" . $pw . "pt",
	       "-O", $svg0, $src, "\n" ) ) if ABCDEBUG;
    if ( sys( $abcm2ps, qw(-g -q -m0cm),
	      "-w" . $pw . "pt",
	      "-O", $svg0, $src )
	 or
	 ! -s $svg1 ) {
	warn("Error in ABC embedding\n");
	return;
    }

    my @cmd;
    if ( is_msw() ) {
	state $magick = findexe("magick");
	unless ( $magick ) {
	    warn("Error in ABC embedding: missing 'imagemagick/convert' tool.\n");
	    return;
	}
	@cmd = ( $magick, "convert" );
    }
    else {
	state $convert = findexe("convert");
	unless ( $convert ) {
	    warn("Error in ABC embedding: missing 'imagemagick/convert' tool.\n");
	    return;
	}
	@cmd = ( $convert );
    }

    if ( sys( @cmd, qw(-density 600 -background white -trim),
	      $svg1, $img ) ) {
	warn("Error in ABC embedding\n");
	return;
    }
    $kv->{scale} ||= 1;

    return [
	    { type => "image",
	      uri  => $img,
	      opts => { center => 0, scale => $kv->{scale} * 0.16 } },
	   ];

}

1;

# =for later_maybe
#
#     # abcm2ps -> SVG -> rsvg-convert -> PNG. NO TRIM.
#     my $svg0 = File::Spec->catfile( $td, "tmp${imgcnt}.svg" );
#     my $svg1 = File::Spec->catfile( $td, "tmp${imgcnt}001.svg" );
#     $img  = File::Spec->catfile( $td, "tmp${imgcnt}.png" );
#     if ( sys( qw(abcm2ps -S -g -q -m0cm),
# 	      "-w" . $pw . "pt",
# 	      "-O", $svg0, $src ) ) {
# 	warn("Error in ABC embedding\n");
# 	return;
#     }
#
#     if ( sys( qw(rsvg-convert -z 6.67  --format png --background-color white),
# 	      $svg1, "-o", $img ) ) {
# 	warn("Error in ABC embedding\n");
# 	return;
#     }
#
#     # abcm2ps -> EPS -> eps2png -> PNG. NO TRIM.
#     my $eps0 = File::Spec->catfile( $td, "tmp${imgcnt}.eps" );
#     my $eps1 = File::Spec->catfile( $td, "tmp${imgcnt}001.eps" );
#     if ( sys(qw(abcm2ps -S -E -q -m0cm),
# 	     "-w", $pw."pt",
# 	     "-O", $eps0, $src ) ) {
# 	warn("Error in ABC embedding\n");
# 	return;
#     }
#     if ( sys( "eps2png", "-O", $img, $eps1 ) ) {
# 	warn("Error in ABC embedding\n");
# 	return;
#     }
#
# =cut
