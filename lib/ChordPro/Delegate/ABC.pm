#!/usr/bin/perl

use v5.26;
use utf8;

package main;

our $config;
our $options;

package ChordPro::Delegate::ABC;

use strict;
use warnings;
use feature qw( signatures );
no warnings "experimental::signatures";
use utf8;
use Carp;
use File::Spec;
use File::Temp ();
use File::LoadLines;
use feature 'state';
use Encode 'decode_utf8';

use ChordPro::Utils;
use Text::ParseWords qw(shellwords);

sub DEBUG() { $config->{debug}->{abc} }

# ABC processing using abc2svg and custom SVG processor.

my $abc2svg;

# Default entry point.

sub abc2svg( $s, $pw, $elt ) {

    if ( DEBUG() ) {
	warn( sprintf( "ABC: abc2svg (tool = %s)\n",
		       ref($abc2svg)
		       ? $abc2svg->[0]
		       : ( $abc2svg) // "<undef>" ) );
    }

    state $cfg_checked;
    unless ( $cfg_checked++ ) {
	if ( ($config->{delegates}{abc}{config} // "default") ne "default" ) {
	    warn("ABC: delegates.abc.config is no longer used.\n");
	    warn("ABC: Config \"default.abc\" will be loaded instead.\n")
	      if -s "default.abc";
	}
    }

    # Try to find a way to run the abv2svg javascript code.
    # We support two strategies, in order:
    # 1. A program 'abc2svg' in PATH, that writes the SVG to standard out
    # 2. The QuickJS program, either in PATH or in our 'abc' resource
    #    directory. In this case, packaged abc2svg is used.
    # The actual command is stored in $abc2svg and retained across calls.
    #
    # Note we do not use 'node' since it is hard to instruct it not to use
    # global data.

    # First, try native program.
    unless ( $abc2svg ) {
	$abc2svg = findexe( "abc2svg", "silent" );
	$abc2svg = [ $abc2svg ] if $abc2svg;
    }

    # We know what to do.
    if ( $abc2svg ) {
	return _abc2svg( $s, $pw, $elt );
    }

    # Try (optionally packaged) QuickJS with packaged abc2svg.
    return abc2svg_qjs( $s, $pw, $elt );
}

# Alternative entry point that always uses QuickJS only.

sub packaged_qjs() {

    my $dir = ::rsc_or_file("abc/");
    my $qjs;

    # First, try packaged qjs.
    if ( -x "${dir}qjs" ) {
	$qjs = "${dir}qjs";
    }
    elsif ( is_msw() and -s "${dir}qjs.exe" ) {
	$qjs = "${dir}qjs.exe";
    }

    # Else try to find an installed qjs.
    else {
	$qjs = findexe("qjs");
    }

    # If so, check for packaged abc files.
    if ( $qjs
	 && -s "${dir}chordproabc.js"
	 && -s "${dir}abc2svg/tohtml.js" ) {
	return [ $qjs, "--std", "${dir}chordproabc.js", "${dir}abc2svg" ];
    }
    return 0;
}

sub abc2svg_qjs( $s, $pw, $elt ) {

    $abc2svg //= packaged_qjs();

    # This will bail out if we didn't find a suitable program.
    return _abc2svg( $s, $pw, $elt );
}

# Internal handler.

sub _abc2svg( $s, $pw, $elt ) {

    # Bail out if we don't have a suitable program.
    unless ( $abc2svg ) {
	warn("Error in ABC embedding: no 'abc2svg' or 'qjs' program found.\n");
	return;
    }

    state $td = File::Temp::tempdir( CLEANUP => !$config->{debug}->{abc} );
    my $cfg = $config->{delegates}->{abc};

    warn("ABC: Using config \"default.abc\".\n") if -s "default.abc";
    my $prep = make_preprocessor( $cfg->{preprocess} );

    # Prepare names for temporary files.
    state $imgcnt = 0;
    $imgcnt++;
    my $src  = File::Spec->catfile( $td, "tmp${imgcnt}.abc" );
    my $svg  = File::Spec->catfile( $td, "tmp${imgcnt}.svg" );
    my $out  = File::Spec->catfile( $td, "tmp${imgcnt}.out" );
    my $err  = File::Spec->catfile( $td, "tmp${imgcnt}.err" );

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
    $kv->{id} = 1;
    $kv->{split} = 1;
    $kv->{scale} ||= 1;
    if ( $kv->{width} ) {
	$pw = $kv->{width};
    }

    unshift( @preamble,
	     grep { /^%%/ } @pre,
	     $pw ? ( "%%pagewidth " . $pw . "px" ) : (),
	     "%%leftmargin 0cm",
	     "%%rightmargin 0cm",
	   );

    # Create the temp file for the ABC source.
    my $fd;
    unless ( open( $fd, '>:utf8', $src ) ) {
	warn("Error in ABC embedding: $src: $!\n");
	return;
    }

    # Copy. We assume the user knows how to write ABC.
    for ( @preamble ) {
	print $fd $_, "\n";
	warn($_, "\n") if DEBUG > 1;
    }
    for ( @data ) {
	$prep->{abc}->($_) if $prep->{abc};
	print $fd $_, "\n";
	warn($_, "\n") if DEBUG > 1;
    }

    unless ( close($fd) ) {
	warn("Error in ABC embedding: $src: $!\n");
	return;
    }

    my @cmd = @$abc2svg;

    my @lines;
    my $ret;

    if ( $cmd[0] =~ /qjs(?:\.w+)?$/ ) {

	# Packaged.
	push( @cmd, $out, $src );
	if ( DEBUG ) {
	    warn( "+ @cmd\n" );
	    $ENV{CHORDPRO_ABC_DEBUG} = 1;
	}

	# Run the command.
	$ret = eval { sys( @cmd ) };

	# Load data.
	@lines = loadlines($out)
    }

    # Not packaged. Check for Wx on Windows since we cannot redirect STD***.
    elsif ( !is_wx() && !is_msw() ) {

	push( @cmd, $src );
	warn( "+ @cmd\n" ) if DEBUG;

	# Setup redirection for STDOUT/ERR.
	my ( $oldout, $olderr );
	open( $oldout, ">&STDOUT" )
	  or die "Can't dup STDOUT: $!";
	open( $olderr,     ">&", \*STDERR )
	  or die "Can't dup STDERR: $!";

	open(STDOUT, '>:utf8', $out)
	  or die "Can't redirect STDOUT: $!";
	open(STDERR, ">:utf8", $err)
	  or die "Can't dup STDERR: $!";

	select STDERR; $| = 1;  # make unbuffered
	select STDOUT; $| = 1;  # make unbuffered

	# Run the command.
	$ret = eval { sys(@cmd) };

	# Reconnect STDOUT/ERR.
	open(STDOUT, ">&", $oldout)
	  or die "Can't dup OLDOUT: $!";
	open(STDERR, ">&", $olderr)
	  or die "Can't dup OLDERR: $!";
	select STDERR; $| = 1;  # make unbuffered

	# Load data.
	@lines = loadlines($out);
    }

    else {
	if ( 0 ) {
	    # This seemed a good idea but unfortunately Wx has problems
	    # returning the UTF8 data correctly. Non-ASCII characters are
	    # crippled.
	    warn( "+ @cmd\n" ) if DEBUG;
	    ( $ret, $out, $err ) = Wx::ExecuteStdoutStderr( "@cmd", 32 );
	    warn("ABC: $_") for @$err;
	    @lines = @$out;
	}
	else {
	    # This will cause a console window flash, but at least we get
	    # the data right.
	    warn( "+ @cmd > $out\n" ) if DEBUG;
	    system( "@cmd > $out" );
	    @lines = loadlines($out);
	}
    }

    if ( $ret ) {
	warn( sprintf( "Error in ABC embedding (ret = 0x%x)\n", $ret ) );
	return;
    }
    if ( ! @lines ) {
	warn("Error in ABC embedding (no output?)\n");
	return;
    }
    warn("SVG: ", scalar(@lines), " lines (raw)\n") if DEBUG > 1;

    # Postprocess the SVG data.
    open( $fd, '>:utf8', $svg );
    my $copy = 0;
    print $fd ("<div>\n");
    my $lines = 1;
    while ( @lines ) {
	$_ = shift(@lines);
	if ( /^<svg/ ) {
	    $copy++;
	}
	print( $fd $_, "\n"), $lines++ if $copy;
	if ( /^<\/svg/ && @lines && $lines[0] =~ /^<\/div/ ) {
	    last;
	}
    }
    print $fd ("</div>\n");
    close($fd);
    warn("SVG: ", 1+$lines, " lines (", -s $svg, " bytes)\n") if DEBUG > 1;

    my @res;
    push( @res,
	  { type => "svg",
	    uri  => $svg,
	    opts => { id     => $kv->{id},
		      center => $kv->{center},
		      scale  => $kv->{scale},
		      split  => $kv->{split},
		      sep    => $kv->{staffsep},
		    } } );

    return \@res;
}

sub abc2image( $s, $pw, $elt ) {

    croak("ABC: Please remove handler \"abc2image\" from your ABC delegates config");

}

1;
