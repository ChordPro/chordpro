#!/usr/bin/perl

package main;

our $config;
our $options;

package ChordPro::Delegate::ABC;

use strict;
use warnings;
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
my $embedded;

sub abc2svg_qjs {
    my ( $s, $pw, $elt ) = @_;

    # Embedded QuickJS.

    my $dir = ::rsc_or_file("abc/");
    my $x;
    if ( -x "$dir/qjs" ) {
	$x = "$dir/qjs";
    }
    elsif ( is_msw() and -s "$dir/qjs.exe" ) {
	$x = "$dir/qjs.exe";
    }
    if ( $x ) {
	$abc2svg = [ $x, "--std", "$dir/chordproabc.js", "$dir/abc2svg/" ];
    }
    $embedded = 1;
    return _abc2svg( $abc2svg, $s, $pw, $elt );
}

sub abc2svg {
    my ( $s, $pw, $elt ) = @_;

    # Native.
    unless ( $abc2svg ) {
	$embedded = 0;
	$abc2svg = findexe( "abc2svg", "silent" );
    }

    # Try node.
    unless ( $abc2svg ) {
	my $x;
	if ( $x = findexe( "npx", "silent" )
	     or is_msw() and $x = findexe( "npx.cmd", "silent" ) ) {
	    my $dir = ::rsc_or_file("abc2svg/");;
	    $abc2svg = [ $x, "$dir/abc2svg" ];
	}
    }

    if ( $abc2svg ) {
	return _abc2svg( $abc2svg, $s, $pw, $elt );
    }

    # Try (embedded) QuickJS.
    return abc2svg_qjs( $s, $pw, $elt );
}

sub _abc2svg {
    my ( $abc2svg, $s, $pw, $elt ) = @_;

    state $imgcnt = 0;
    state $td = File::Temp::tempdir( CLEANUP => !$config->{debug}->{abc} );
    my $cfg = $config->{delegates}->{abc};

    unless ( $abc2svg ) {
	warn("Error in ABC embedding: need 'abc2svg' tool.\n");
	return;
    }

    my $prep = make_preprocessor( $cfg->{preprocess} );

    $imgcnt++;
    my $src  = File::Spec->catfile( $td, "tmp${imgcnt}.abc" );
    my $svg  = File::Spec->catfile( $td, "tmp${imgcnt}.svg" );
    my $out  = File::Spec->catfile( $td, "tmp${imgcnt}.out" );
    my $err  = File::Spec->catfile( $td, "tmp${imgcnt}.err" );

    my $fd;
    unless ( open( $fd, '>:utf8', $src ) ) {
	warn("Error in ABC embedding: $src: $!\n");
	return;
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

    my @lines;
    my $ret;

    push( @cmd, "toxhtml.js", $src );
    if ( $embedded  ) {
	splice( @cmd, 3, 0, $out ); # insert output name.
	if ( DEBUG ) {
	    warn( "+ @cmd\n" );
	    $ENV{CHORDPRO_ABC_DEBUG} = 1;
	}
	$ret = eval { sys( @cmd ) };
	@lines = loadlines($out)
    }

    elsif ( ! main->can("OnInit") ) {

	warn( "+ @cmd\n" ) if DEBUG;

	# Command line use. Redirect stdout/err.
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

	$ret = eval { sys(@cmd) };

	open(STDOUT, ">&", $oldout)
	  or die "Can't dup OLDOUT: $!";
	open(STDERR, ">&", $olderr)
	  or die "Can't dup OLDERR: $!";
	select STDERR; $| = 1;  # make unbuffered

	if ( -s $err ) {
	    open( $fd, '<:utf8', $err );
	    while ( <$fd> ) {
		warn("ABC: $_");
	    }
	    close($fd);
	}

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
    warn("SVG: ", scalar(@lines), " lines (raw)\n") if DEBUG();

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
    warn("SVG: ", 1+$lines, " lines (", -s $svg, " bytes)\n") if DEBUG();
    my @res;
    push( @res,
	  { type => "svg",
	    uri  => $svg,
	    opts => { center => $kv->{center},
		      scale  => $kv->{scale},
		      split  => $kv->{split},
		      sep    => $kv->{staffsep},
		    } } );

    return \@res;
}

sub abc2image {

    croak("ABC: Please adjust your config to use ABC handler \"abc2svg\" instead of \"abc2image\"");

}

1;
