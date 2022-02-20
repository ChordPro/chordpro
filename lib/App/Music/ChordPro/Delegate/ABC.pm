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
use feature 'state';

use App::Music::ChordPro::Utils;
use Text::ParseWords qw(shellwords);

sub DEBUG() { $config->{debug}->{abc} }

sub abc2image {
    my ( $s, $pr, $elt ) = @_;

    state $imgcnt = 0;
    state $td = File::Temp::tempdir( CLEANUP => !$config->{debug}->{abc} );
    my $cfg = $config->{delegates}->{abc};

    my $prep = make_preprocessor( $cfg->{preprocess} );

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

	# Suppress meaningless transpositions. ChordPro uses them to enforce
	# certain chord renderings.
	next if $_ ne "transpose";
	my $x = $elt->{opts}->{$_} % @{ $config->{notes}->{sharp} };
	print $fd '%%transpose'." $x\n";
	warn('%%transpose'." $x\n") if DEBUG;
    }

    for ( @{ $cfg->{preamble} } ) {
	print $fd "$_\n";
	warn( "$_\n") if DEBUG;
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
	warn("X:1 (added)\n") if DEBUG;
	@data = ( "X:1", @pre );
	@pre = ();
    }
    my $kv = { %$elt };
    $kv = parse_kv( @pre ) if @pre;
    # Copy. We assume the user knows how to write ABC.
    for ( @data ) {
	$prep->{abc}->($_) if $prep->{abc};
	print $fd $_, "\n";
	warn($_, "\n") if DEBUG;
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
    else {
	warn("No PerlMagick, hope you have ImageMagick installed...\n")
	  if $config->{debug}->{images} || DEBUG;
	$kv->{split} = 0;
    }

    state $abcm2ps = findexe("abcm2ps");
    unless ( $abcm2ps ) {
	warn("Error in ABC embedding: missing 'abcm2ps' tool.\n");
	return;
    }

    my $svg0 = File::Spec->catfile( $td, "tmp${imgcnt}.svg" );
    my $svg1 = File::Spec->catfile( $td, "tmp${imgcnt}001.svg" );
    my $fmt = $cfg->{config};
    my @cmd = ( $abcm2ps, qw(-g -q -m0cm), "-w" . $pw . "pt" );
    if ( $fmt =~ s/^none,?// ) {
	push( @cmd, "+F" );
    }
    push( @cmd, "-F", $fmt ) if $fmt && $fmt ne "default";
    push( @cmd, "-A" ) if $kv->{split};
    push( @cmd, "-O", $svg0, $src );
    warn( "+ @cmd\n" ) if DEBUG;
    if ( sys( @cmd )
	 or
	 ! -s $svg1 ) {
	warn("Error in ABC embedding\n");
	return;
    }
    $kv->{scale} ||= 1;

    my @res;
    my @lines;
    if ( 1 ) {
	# Sigh. ImageMagick uses librsvg, and this lib still does not
	# support font styles. So replace them with their explicit forms.
#	@lines = loadlines($svg1, { encoding => "ISO-8859-1" } );
	@lines = loadlines($svg1);
	for ( @lines ) {

	    $prep->{svg}->($_) if $prep->{svg};
	    next unless /^(.*)\bstyle="font:(.*)"(.*)$/;

	    my ( $pre, $style, $post ) = ( $1, $2, $3 );
	    my $f = {};
	    my @f;
	    for my $w ( shellwords($style) ) {
		if ( $w =~ /^(bold|light)$/ ) {
		    $f->{weight} = $1;
		}
		elsif ( $w =~ /^(italic|oblique)$/ ) {
		    $f->{style} = $1;
		}
		elsif ( $w =~ /^(\d+(?:\.\d*)?)px$/ ) {
		    $f->{size} = 0+$1;
		}
		else {
		    push( @f, $w );
		}
	    }
	    $f->{family} = @f ? "@f" : "Serif";

	    if ( 0 && is_msw() ) {
		# Windows doesn't seem to find the right fonts.
		# So lend a hand.
		$f->{family} = "Times New Roman" if $f->{family} eq "Times";
		$f->{family} = "Arial"           if $f->{family} eq "Helvetica";
		$f->{family} = "Courier New"     if $f->{family} eq "Courier";
	    }

	    $_ = $pre;
	    $_ .= "font-family=\"" . $f->{family} . '" ';
	    $_ .= "font-size=\""   . $f->{size} .   '" ' if $f->{size};
	    $_ .= "font-weight=\"" . $f->{weight} . '" ' if $f->{weight};
	    $_ .= $post;
	    warn("\"${pre}style=\"font:$style\"$post\" => \"$_\"\n")
	      if DEBUG;
	}
	unless ( $kv->{split} ) {
	    open( my $fd, '>:utf8', $svg1 )
	      or die("Cannot rewrite $svg1: $!\n");
	    print $fd ( "$_\n" ) for @lines;
	    close($fd) or die("Error rewriting $svg1: $!\n");;
	}
    }

    if ( $kv->{split} ) {
	require Image::Magick;

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
	    warn("Trim: ", join("x", $image->Get('width', 'height')).
		 " ", join("x", $image->Get('base-columns', 'base-rows')),
		 "+", join("+", $image->Get('page.x', 'page.y')), "\n")
	      if $config->{debug}->{images};
	    $fn =~ s/\.svg$/.jpg/;
	    $image->Set( magick => 'jpg' );
	    my $data = $image->ImageToBlob;
	    my $assetid = sprintf("ABCasset%03d", $imgcnt++);
	    warn("Created asset $assetid (jpg, ", length($data), " bytes)\n")
	      if $config->{debug}->{images};
	    $App::Music::ChordPro::Output::PDF::assets->{$assetid} =
	      { type => "jpg", data => $data };

	    push( @res,
		  { type => "image",
		    uri  => "id=$assetid",
		    opts => { center => $kv->{center}, scale => $kv->{scale} * 0.16 } },
		  { type => "empty" },
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
	    if ( /^<g stroke-width=".*?" font-.*/
		 && @lines > 8
		 && $lines[0] =~ /^<path class="stroke" stroke-width="/
		 && $lines[2] =~ /^<abc type="B"/
		 or !$segment
	       ) {

		$pp->() if $fd;
		$fn = File::Spec->catfile( $td, sprintf( "out%03d.svg", ++$segment ) );
		warn("Writing: $fn ...\n") if $config->{debug}->{images};
		undef $fd;
		open( $fd, '>:utf8', $fn ) or die("$fn: $!\n");
		print $fd ( "$_\n" ) for @preamble;
	    }

	    last if /<\/svg>/;
	    print $fd ("$_\n") if $fd;
	}

	$pp->() if $fd;
	pop(@res);
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
	push( @cmd, qw(-density 600 -background white -trim), $svg1, $img );
	warn( "+ @cmd\n" ) if DEBUG;
	if ( sys( @cmd ) ) {
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
		     opts => { center => $kv->{center}, scale => $kv->{scale} * 0.16 } },
	    );
	warn("Asset $assetid options:",
	     " scale=", $kv->{scale} * 0.16,
	     " center=", $kv->{center}//0,
	     "\n")
	  if $config->{debug}->{images};
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
