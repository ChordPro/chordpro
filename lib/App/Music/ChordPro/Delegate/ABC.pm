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

# ABC processing using abcm2ps and ImageMagick.

sub abc2image {
    my ( $s, $pw, $elt ) = @_;

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

# ABC processing using abc2svg and Chrome and ImageMagick.
# FOR EXPERIMENTAL PURPOSES ONLY!

sub xabc2image {
    my ( $s, $pw, $elt ) = @_;

    state $imgcnt = 0;
    state $td = File::Temp::tempdir( CLEANUP => !$config->{debug}->{abc} );
    my $cfg = $config->{delegates}->{abc};

    state $abc2svg = findexe("abc2svg"); # not yet
    state $chrome;
    unless ( $abc2svg ) {
	if ( is_msw() and my $x = findexe("npx.cmd") ) {
	    $abc2svg = [ $x, "abc2svg" ];
	}
    }
    unless ( $chrome ) {
	####TODO: MacOS
	for ( "chromium-freeworld", "chromium", "google-chrome" ) {
	    last if $chrome = findexe($_);
	}
	if ( !$chrome && is_msw() ) {
	    $chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe';
	    undef $chrome unless -x $chrome;
	}
	warn("Using \"$chrome\" for SVG processing\n");
    }
    state $abcm2ps = findexe("abcm2ps");
    unless ( $abcm2ps || $abc2svg ) {
	#warn("Error in ABC embedding: need 'abcm2ps' or 'abc2svg' tool.\n");
	warn("Error in ABC embedding: need 'abcm2ps' tool.\n");
	return;
    }

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

    if ( $abc2svg ) {
	my $f = ::rsc_or_file( "fonts/abc2svg.ttf" );
	for ( '%%fullsvg a', "%%musicfont abc2svg" ) {
	    print $fd "$_\n";
	    warn( "$_\n") if DEBUG;
	}
    }

    my @preamble = @{ $cfg->{preamble} };

    for ( keys(%{$elt->{opts}}) ) {

	# Suppress meaningless transpositions. ChordPro uses them to enforce
	# certain chord renderings.
	next if $_ ne "transpose";
	my $x = $elt->{opts}->{$_} % @{ $config->{notes}->{sharp} };
	unshift( @preamble, '%%transpose'." $x" );
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
    $kv->{split} = 1 if $abc2svg;

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

    if ( $kv->{split} && !$abc2svg ) {
	unshift( @preamble, '%%fullsvg a' );
    }
    unshift( @preamble,
	     "%%pagewidth " . $pw . "pt",
	     "%%leftmargin 0cm",
	     "%%rightmargin 0cm",
	   );

    # Copy. We assume the user knows how to write ABC.
    for ( @preamble ) {
	print $fd $_, "\n";
	warn($_, "\n") if DEBUG;
    }
    for ( @data ) {
	$prep->{abc}->($_) if $prep->{abc};
	print $fd $_, "\n";
	warn($_, "\n") if DEBUG;
    }

    unless ( close($fd) ) {
	warn("Error in ABC embedding: $src: $!\n");
	return;
    }

    my $svg0 = File::Spec->catfile( $td, "tmp${imgcnt}.svg" );
    my $svg1 = File::Spec->catfile( $td, "tmp${imgcnt}001.svg" );

    if ( $abc2svg ) {
	my @cmd = ref($abc2svg) ? ( @$abc2svg ) : ( $abc2svg );
	open( my $STDOLD, '>&', STDOUT );
	open( STDOUT, '>:utf8', $svg1 );
	push( @cmd, $src );
	warn( "+ @cmd\n" ) if DEBUG;
	my $ret = sys( @cmd );
	open( STDOUT, '>&', $STDOLD );
	if ( $ret or ! -s $svg1 ) {
	    warn("Error in ABC embedding\n");
	    return;
	}
    }
    else {
	my $fmt = $cfg->{config};
	my @cmd = ( $abcm2ps, qw(-g -q) );
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
    }
    $kv->{scale} ||= 1;

    my @res;
    my @lines;
    if ( 1 ) {
#	@lines = loadlines($svg1, { encoding => "ISO-8859-1" } );
	@lines = loadlines($svg1);
	my @lp;
	for ( @lines ) {

	    # =for abc2svg
	    # s|src:url\("data:application/octet-stream;base64,.* format\("truetype"\)|src:url("abc2svg.ttf")| and next;

	    # s;^(\.f\d+\{.*?px) music\};$1 abc2svg}; and next;

	    # abc2svg generates text elements with multiple x,y coordinates.
	    # librsvg cannot handle these, so split them out.
	    if ( /<text x="(.*?,.*?)"$/ ) { # multiple x
		$lp[0] = [ split(/,/, $1) ];
		$_ = ""; next;
	    }
	    elsif ( @lp == 1 && /y="(.*?,.*?)"$/ ) { # multiple y
		$lp[1] = [ split(/,/, $1) ];
		$_ = ""; next;
	    }
	    elsif ( @lp == 2 && m;^>(.*?)</text>; ) { # combine
		my @t = split(//, $1);
		warn("@t / @{ $lp[0] } / @{ $lp[1] }")
		  unless @t == @{ $lp[0] };
		$_ = "";
		for my $c ( @t ) {
		    $_ .= "\n" if $_;
		    $_ .= "<text x=\"" . shift(@{$lp[0]}) . "\" " .
		      "y=\"" . shift(@{$lp[1]}) . "\">" . $c . "</text>";
		}
		@lp = ();
		next;
	    }
	    # =end abc2svg

	    # Preprocessing.
	    $prep->{svg}->($_) if $prep->{svg};

	    # =for abcm2ps
	    # Sigh. ImageMagick uses librsvg, and this lib still does not
	    # support font styles. So replace them with their explicit forms.
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
	    # =end abcm2ps
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

	    warn("Processing split$segment \"$fn\"\n") if DEBUG;
	    if ( $chrome ) {
		my $f = $fn;
		$f =~ s/\.svg$/.png/;
		sys( $chrome, "--headless", "--disable-gpu",
		     "--screenshot=$f", "--force-device-scale-factor=8.333",
		     $fn );
		die("Error converting \"$fn\" tp \"$f\" using \"$chrome\"\n")
		  unless -s $f;
		$fn = $f;
	    }
	    my $image = Image::Magick->new( density => 600, background => 'white' );
	    warn("Reading $fn...\n") if $config->{debug}->{images};
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

	my $skip = $abc2svg;
	while ( @lines ) {
	    $_ = shift(@lines);

	    if ( $skip && /^<svg / ) {
		$skip = 0;
		$fn = File::Spec->catfile( $td, sprintf( "out%03d.svg", ++$segment ) );
		warn("Writing: $fn ...\n") if $config->{debug}->{images};
		undef $fd;
		open( $fd, '>:utf8', $fn ) or die("$fn: $!\n");
		print $fd ( "$_\n" );
		$init = 0;
		next;
	    }
	    else {
		next if $skip;
	    }
	    
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

	    if ( $fd && $abc2svg && /<\/svg>/ ) {
		$pp->();
		$fn = File::Spec->catfile( $td, sprintf( "out%03d.svg", ++$segment ) );
		warn("Writing: $fn ...\n") if $config->{debug}->{images};
		undef $fd;
		open( $fd, '>:utf8', $fn ) or die("$fn: $!\n");
		next;
	    }
	    last if /<\/svg>/;
	    print $fd ("$_\n") if $fd;
	}

	$pp->() if $fd && !$abc2svg;
	pop(@res);
    }
    else {			# no split, so no abc2svg
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

# chromium-freeworld --headless --disable-gpu --screenshot x1.svg
#
# "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless --screenshot  --default-background-color=0 image.svg
#
# 'C:\Program Files\Google\Chrome\Application\chrome.exe' --headless --screenshot=fullpathto.png  --default-background-color=0 fulpathtoimage.svg

# Install node,js
# open cmd window
# npx abc2svg
# (will install abc2svg)
# Install the abc2svg.ttf font in c:\Windows\Fonts
# (Add custom fonts, e.g. MuseJazzText.otf as well)
# Install Google Chrome

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

# ABC processing using abc2svg and custom SVG processor.
# FOR EXPERIMENTAL PURPOSES ONLY!

sub abc2svg {
    my ( $s, $pw, $elt ) = @_;

    state $imgcnt = 0;
    state $td = File::Temp::tempdir( CLEANUP => !$config->{debug}->{abc} );
    my $cfg = $config->{delegates}->{abc};

    state $abc2svg = findexe("abc2svg");
    unless ( $abc2svg ) {
	my $x;
	if ( $x = findexe("npx")
	     or is_msw() and $x = findexe("npx.cmd") ) {
	    $abc2svg = [ $x, "abc2svg" ];
	}
    }

    unless ( $abc2svg ) {
	warn("Error in ABC embedding: need 'abc2svg' tool.\n");
	return;
    }

    my $prep = make_preprocessor( $cfg->{preprocess} );

    $imgcnt++;
    my $src  = File::Spec->catfile( $td, "tmp${imgcnt}.abc" );
    my $svg  = File::Spec->catfile( $td, "tmp${imgcnt}.xhtml" );

    my $fd;
    unless ( open( $fd, '>:utf8', $src ) ) {
	warn("Error in ABC embedding: $src: $!\n");
	return;
    }

    if ( $abc2svg ) {
	my $f = ::rsc_or_file( "fonts/abc2svg.ttf" );
	# Currently we have a dup id when using fullsvg.
	for ( "%%musicfont abc2svg" ) {
	    print $fd "$_\n";
	    warn( "$_\n") if DEBUG;
	}
    }

    my @preamble = @{ $cfg->{preamble} };

    for ( keys(%{$elt->{opts}}) ) {

	# Suppress meaningless transpositions. ChordPro uses them to enforce
	# certain chord renderings.
	next if $_ ne "transpose";
	my $x = $elt->{opts}->{$_} % @{ $config->{notes}->{sharp} };
	unshift( @preamble, '%%transpose'." $x" );
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
    $kv->{split} = 1 if $abc2svg;
    $kv->{scale} ||= 1;
    if ( $kv->{width} ) {
	$pw = $kv->{width};
    }

    unshift( @preamble,
	     "%%pagewidth " . $pw . "px",
	     "%%leftmargin 0cm",
	     "%%rightmargin 0cm",
	   );

    # Copy. We assume the user knows how to write ABC.
    for ( @preamble ) {
	print $fd $_, "\n";
	warn($_, "\n") if DEBUG;
    }
    for ( @data ) {
	$prep->{abc}->($_) if $prep->{abc};
	print $fd $_, "\n";
	warn($_, "\n") if DEBUG;
    }

    unless ( close($fd) ) {
	warn("Error in ABC embedding: $src: $!\n");
	return;
    }

    my @cmd = ref($abc2svg) ? ( @$abc2svg ) : ( $abc2svg );
    open( my $STDOLD, '>&', STDOUT );
    open( STDOUT, '>:utf8', $svg );
    push( @cmd, "toxhtml.js", $src );
    warn( "+ @cmd\n" ) if DEBUG;
    my $ret = sys( @cmd );
    open( STDOUT, '>&', $STDOLD );
    if ( $ret or ! -s $svg ) {
	warn("Error in ABC embedding\n");
	return;
    }

    my @res;
    push( @res,
	  { type => "svg",
	    uri  => $svg,
	    opts => { center => $kv->{center}, scale => $kv->{scale} } } );

    return \@res;
}

1;
