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
use File::LoadLines;
use feature 'state';

use App::Music::ChordPro::Utils;
use Text::ParseWords qw(shellwords);

sub DEBUG() { $config->{debug}->{ly} }

sub ly2image {
    my ( $s, $pw, $elt ) = @_;

    state $imgcnt = 0;
    state $td = File::Temp::tempdir( CLEANUP => !$config->{debug}->{ly} );

    $imgcnt++;
    my $src  = File::Spec->catfile( $td, "tmp${imgcnt}.ly" );
    my $img  = File::Spec->catfile( $td, "tmp${imgcnt}.png" );

    my $fd;
    unless ( open( $fd, '>:utf8', $src ) ) {
	warn("Error in Lilypond embedding: $src: $!\n");
	return;
    }

    my $need_version = 1;
    my @pre;
    for ( keys(%{$elt->{opts}}) ) {

	if ( $_ eq "version" ) {
	    push( @pre, "\\version \"", $elt->{opts}->{$_}, "\"" );
	    warn ( "\\version \"", $elt->{opts}->{$_}, "\"\n" ) if DEBUG;
	    $need_version = 0;
	}
	else {
	    push( @pre, '%%'.$_." ".$elt->{opts}->{$_} );
	    warn('%%'.$_." ".$elt->{opts}->{$_}."\n") if DEBUG;
	}
    }

    for ( @{ $config->{delegates}->{ly}->{preamble} } ) {
	push( @pre, $_ );
	warn( "$_\n") if DEBUG;
	$need_version = 0 if /^\\version\s+/;
    }

    if ( $need_version ) {
	my $v = "2.21.0";
	unshift( @pre, "\\version \"$v\"",
		 "\\header { tagline = ##f }" );
	warn("ly: no \\version seen, assuming \"$v\"\n");
    }
    printf $fd "$_\n" for @pre;

    @pre = ();
    my @data = @{$elt->{data}};
    while ( @data ) {
	$_ = shift(@data);
	unshift( @data, $_ ), last if /^[%\\]/; # LP data
	push( @pre, $_ );
    }
    if ( @pre && !@data ) {	# no LP found
	@data = @pre;
	@pre = ();
    }

    my $kv = { %$elt };
    $kv = parse_kv( @pre ) if @pre;
    # Copy. We assume the user knows how to write LilyPond.
    for ( @data ) {
	print $fd $_, "\n";
	warn($_, "\n") if DEBUG;
    }

    unless ( close($fd) ) {
	warn("Error in Lilypond embedding: $src: $!\n");
	return;
    }

    if ( $kv->{width} ) {
	$pw = $kv->{width};
    }

    state $lilypond = findexe("lilypond");
    unless ( $lilypond ) {
	warn("Error in Lilypond embedding: missing 'lilypond' tool.\n");
	return;
    }

    my @cmd = ( $lilypond, qw( --png -dresolution=820) );
    push( @cmd, "--silent" ) unless DEBUG;
    ( my $im1 = $img ) =~ s/\.\w+$//;
    push( @cmd, "-o", $im1, $src );
    if ( sys( @cmd )
	 or
	 ! -s $img ) {
	warn("Error in Lilypond embedding\n");
	return;
    }

    my $have_magick = do {
        local $SIG{__WARN__} = sub {};
	local $SIG{__DIE__} = sub {};
	eval { require Image::Magick;
	       $Image::Magick::VERSION || "6.x?" };
    };
    if ( $have_magick ) {
	warn("Using PerlMagick version ", $have_magick, "\n")
	  if $config->{debug}->{images} || DEBUG;
    }
    elsif ( is_msw() ) {
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

    my @res;
    if ( $have_magick ) {
	require Image::Magick;
	my $image = Image::Magick->new( density => 600, background => 'white' );
	my $x = $image->Read($img);
	warn $x if $x;
	$x = $image->Trim;
	warn $x if $x;
	warn("Trim: ", join("x", $image->Get('width', 'height')).
	     " ", join("x", $image->Get('base-columns', 'base-rows')),
	     "+", join("+", $image->Get('page.x', 'page.y')), "\n")
	  if $config->{debug}->{images};

	$image->Set( magick => 'jpg' );
	my $data = $image->ImageToBlob;
	my $assetid = sprintf("LYasset%03d", $imgcnt++);
	warn("Created asset $assetid (jpg, ", length($data), " bytes)\n")
	  if $config->{debug}->{images};
	$App::Music::ChordPro::Output::PDF::assets->{$assetid} =
	  { type => "jpg", data => $data };

	push( @res,
	      { type => "image",
		uri  => "id=$assetid",
		opts => { center => $kv->{center},
			  $kv->{scale} ? ( scale => $kv->{scale} * 0.16 ) : (),
			} },
	      { type => "empty" },
	    );
	warn("Asset $assetid options:",
	     $kv->{scale} ? ( " scale=", $kv->{scale} * 0.16 ) : (),
	     " center=", $kv->{center}//0,
	     "\n")
	  if $config->{debug}->{images};
    }
    else {
	if ( sys( @cmd, qw(-background white -trim), $img, $img ) ) {
	    warn("Error in Lilypond embedding\n");
	    return;
	}

	warn("Reading $img...\n") if $config->{debug}->{images};
	open( my $im, '<:raw', $img );
	my $data = do { local $/; <$im> };
	close($im);

	my $assetid = sprintf("LYasset%03d", $imgcnt);
	warn("Created asset $assetid (png, ", length($data), " bytes)\n")
	  if $config->{debug}->{images};
	$App::Music::ChordPro::Output::PDF::assets->{$assetid} =
	  { type => "png", data => $data };

	push( @res,{ type => "image",
		     uri  => "id=$assetid",
		opts => { center => $kv->{center},
			  $kv->{scale} ? ( scale => $kv->{scale} * 0.16 ) : (),
			} },
	    );
	warn("Asset $assetid options:",
	     $kv->{scale} ? ( " scale=", $kv->{scale} * 0.16 ) : (),
	     " center=", $kv->{center}//0,
	     "\n")
	  if $config->{debug}->{images};
    }

    return \@res;

}

1;
