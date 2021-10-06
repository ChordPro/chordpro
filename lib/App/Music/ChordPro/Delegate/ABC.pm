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
use File::LoadLines;
use IO::String;

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
    $kv->{scale} ||= 1;

    my @res;

    if ( defined($kv->{split}) ? $kv->{split} : $config->{delegates}->{abc}->{split} ) {
	require Image::Magick;
	my @lines = loadlines($svg1);

	my $segment = 0;
	my $init = 1;

	my @preamble;

	my $fd;
	my $fn;

	my $pp = sub {
	    print $fd "</svg>\n";
	    close($fd);

	    my $image = Image::Magick->new( density => 600, background => 'white' );
	    my $x = $image->Read($fn);
	    warn $x if $x;
	    $x = $image->Trim;
	    warn $x if $x;
	    $fn =~ s/\.svg$/.jpg/;
	    $image->Set( magick => 'jpg' );
	    my $data = $image->ImageToBlob;
	    my $assetid = sprintf("ABCasset%03d", $imgcnt++);
	    warn("Created asset $assetid (jpg, ", length($data), " bytes)\n")
	      if $config->{debug}->{images};
	    $App::Music::ChordPro::Output::PDF::assets->{$assetid} =
	      { type => "jpg", data => $data };

	    push( @res,{ type => "image",
			 uri  => "id=$assetid",
			 opts => { center => 0, scale => $kv->{scale} * 0.16 } },
		);
	};

	while ( @lines ) {
	    $_ = shift(@lines);
	    if ( /^<(style|defs)\b/ ) {
		$init = 0;
		push( @preamble, $_ );
		print $fd "$_\n" if $segment;
		while ( @lines ) {
		    push( @preamble, $lines[0] );
		    print $fd "$lines[0]\n" if $segment;
		    last if shift @lines eq "</$1>";
		}
		next;
	    }
	    if ( $init ) {
		push( @preamble, $_ );
		print $fd "$_\n" if $segment;
		next;
	    }
	    if ( /<g stroke-width=".*?" style="font:.*">/
		 && @lines > 8
		 && $lines[0] =~ /<path class="stroke" stroke-width="/
		 && $lines[2] =~ /<path class="stroke" stroke-width="/
		 && $lines[4] =~ /<path class="stroke" stroke-width="/
		 && $lines[6] =~ /<path class="stroke" stroke-width="/
		 && $lines[8] =~ /<path class="stroke" stroke-width="/
		 or !$segment
	       ) {

		$pp->() if $fd;
		$fn = sprintf( "out%03d.svg", ++$segment );
		warn("Writing: $fn ...\n") if $config->{debug}->{images};
		undef $fd;
		open( $fd, '>:utf8', $fn );
		print $fd ( "$_\n" ) for @preamble;
	    }

	    last if /<\/svg>/;
	    print $fd ("$_\n") if $fd;
	}

	$pp->() if $fd;
    }
    else {
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

	warn("Reading $img...\n") if $config->{debug}->{images};
	open( my $im, '<:raw', $img );
	my $data = do { local $/; <$im> };
	close($im);

	my $assetid = sprintf("ABCasset%03d", $imgcnt);
	warn("Created asset $assetid (jpg, ", length($data), " bytes)\n")
	  if $config->{debug}->{images};
	$App::Music::ChordPro::Output::PDF::assets->{$assetid} =
	  { type => "jpg", data => $data };

	push( @res,{ type => "image",
		     uri  => "id=$assetid",
		     opts => { center => 0, scale => $kv->{scale} * 0.16 } },
	    );
    }


    return \@res;
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
