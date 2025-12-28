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
use File::Temp ();
use File::LoadLines;
use feature 'state';

use ChordPro::Files;
use ChordPro::Paths;
use ChordPro::Utils;
use Text::ParseWords qw(shellwords);

use constant { QUICKJS   => "QuickJS",
	       QUICKJSXS => "QuickJS_XS" };

sub DEBUG() { $config->{debug}->{abc} }

# ABC processing using abc2svg and custom SVG processor.
# See info() below how the method is determined.

# Song and PDF module uses 'can' to get at this.
sub can( $class, $method ) {
    if ( $method eq "options" ) {
	return \&options;
    }
    # abc2svg handlers are sorted out by info().
    return \&abc2svg;
}

# Default entry point.

sub abc2svg( $song, %args ) {

    my $abc2svg = info();

    if ( DEBUG() ) {
	::dump($abc2svg);
    }

    state $cfg_checked;
    unless ( $cfg_checked++ ) {
	if ( ($config->{delegates}{abc}{config} // "default") ne "default" ) {
	    warn("ABC: delegates.abc.config is no longer used.\n");
	    warn("ABC: Config \"default.abc\" will be loaded instead.\n")
	      if !$abc2svg->{external} && fs_test( s => "default.abc" );
	}
    }

    my ( $elt, $pw ) = @args{qw(elt pagewidth)};

    return { type => "ignore" } unless @{ $elt->{data} };
    # Bail out if we don't have a suitable program.
    unless ( $abc2svg->{method} ) {
	warn("Error in ABC embedding. Please install the JavaScript::QuickJS module.\n");
	return;
    }

    state $td = File::Temp::tempdir( CLEANUP => !$config->{debug}->{abc} );
    my $cfg = { %{$config->{delegates}->{abc} } };

    # External tools usually process a default.abc.
    warn("ABC: Using config \"default.abc\".\n")
      if index( $abc2svg->{method}, QUICKJSXS ) < 0 && fs_test( s => "default.abc" );

    my $prep = make_preprocessor( $cfg->{preprocess} );

    # Prepare names for temporary files.
    state $imgcnt = 0;
    $imgcnt++;
    my $src  = fn_catfile( $td, "tmp${imgcnt}.abc" );
    my $svg  = fn_catfile( $td, "tmp${imgcnt}.svg" );
    my $out  = fn_catfile( $td, "tmp${imgcnt}.out" );
    my $err  = fn_catfile( $td, "tmp${imgcnt}.err" );

    # Get rid of as much space as possible.
    # Jean-François Moine:
    # If you have both "%%stretchstaff 1" and "%%trimsvg 1", and
    # "%%stretchlast 0", only the final line is shorter.
    # Otherwise, you can have "%%trimsvg 1" as the last line of the tune.
    my @preamble =
      ( "%%topspace 0",
	"%%titlespace 0",
	"%%musicspace 0",
	"%%composerspace 0",
	"%%infospace 0",
	"%%textspace 0",
	"%%leftmargin 0cm",
	"%%rightmargin 0cm",
	"%%stretchstaff 1",
	"%%stretchlast 0",
	"%%trimsvg 1",
	"%%staffsep 0",
	@{ $cfg->{preamble}//[] } );

    for ( keys(%{$elt->{opts}}) ) {
	next if $_ ne "transpose";
	my $x = $elt->{opts}->{$_};
	next unless $x;
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
    my $kv = {};
    $kv = parse_kvm( @pre ) if @pre;
    $kv = { %$kv, %{$elt->{opts}} };
    $kv->{split} //= 1;		# less overhead. really.
    $kv->{scale} ||= 1;		# with id: design scale
    $kv->{align} //= ($kv->{center}//0) ? "center" : "left";
    if ( $kv->{width} ) {
	$pw = $kv->{width};
    }

    unshift( @preamble,
	     grep { /^%%/ } @pre,
	     $pw ? sprintf("%%%%pagewidth %dpx", $pw) : (),
	   );

    # Create the temp file for the ABC source.
    my $fd;
    unless ( $fd = fs_open( $src, '>:utf8' ) ) {
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
    for ( @{ $cfg->{postamble}//[] } ) {
	print $fd $_, "\n";
	warn($_, "\n") if DEBUG > 1;
    }

    unless ( close($fd) ) {
	warn("Error in ABC embedding: $src: $!\n");
	return;
    }

    my @lines;
    my $ret;

    if ( $abc2svg->{method} eq QUICKJSXS ) {

	# QuickJS with embedded interpreter.

	my $js = JavaScript::QuickJS->new;
	my $base = $abc2svg->{abclib} . "/abc2svg";
	$js->set_module_base($base);

	my $qjsdata =
	  {
	   print     => sub { push( @lines, split(/\n/, $_) ) for @_ },
	   printErr  => sub { print STDERR @_ },
	   quit      => sub { exit 66 },
	   readFile  => sub { slurp($_[0]) },
	   get_mtime => sub {
	       my @stat = stat($_[0]);
	       return @stat ? 1000*$stat[9] : undef;
	   },
	   loadjs    => sub {
	       my ( $fn, $relay, $onerror ) = @_;
	       if ( fs_test( sr => "$base/$fn" ) ) {
		   $js->eval(slurp("$base/$_[0]"));
		   $relay->() if $relay;
	       }
	       elsif ( $onerror ) {
		   $onerror->();
	       }
	       else {
		   warn( qq{loadjs("$fn"): $!\n} );
	       }
	   },
	  };

	$js->set_globals
	  ( args    => [ $src ],
	    load    => sub { $js->eval(slurp("$base/$_[0]")) },
	    abc2svg => $qjsdata,
	    abc     => {},	# for backends
	  );

	warn( "+ QuickJS_XS[", CP->display($base), "] $src\n") if DEBUG;
	my $hooks = "$base/../hooks.js";
	undef $hooks unless fs_test( s => $hooks );

	eval {
	    $js->eval( slurp("$base/abc2svg-1.js") );
	    $js->eval( slurp($hooks) ) if $hooks;
	    if ( -r "$base/../cmd.js" ) {
		warn(" QuickJS_XS using ", CP->display("$base/../cmd.js"),
		     $hooks ? "+hooks" : "", "\n" )
		  if DEBUG;
		$js->eval( slurp("$base/../cmd.js") );
	    }
	    else {
		warn(" QuickJS_XS using ", CP->display("$base/cmdline.js"),
		     $hooks ? "+hooks" : "", "\n" )
		  if DEBUG;
		$js->eval( slurp("$base/cmdline.js") );
	    }
	    $js->eval( slurp("$base/tohtml.js") );
	    $js->eval( qq{abc_cmd("ChordPro", args, "QuickJS_XS")} );
	};
	warn($@) if $@;
	undef $js;

	if ( DEBUG ) {
	    my $fd = fs_open( $out, '>:utf8' );
	    print $fd join("\n", @lines), "\n";
	    close($fd);
	}
    }

    elsif ( $abc2svg->{method} eq QUICKJS ) {

	# QuickJS with external interpreter.

	my @cmd = @{ $abc2svg->{command} };

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

	my @cmd = @{ $abc2svg->{command} };

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
	my @cmd = @{ $abc2svg->{command} };
	push( @cmd, $src );
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
    my $staffbase;
    my $copy = 0;
    @data = ();
    my $lines = 1;
    while ( @lines ) {
	$_ = shift(@lines);
	if ( /\<!-- staffbase:(.*) --\>/ ) {
	    $staffbase = $1;
	    warn("ABC: staffbase = $staffbase\n") if DEBUG;
	    next;
	}
	if ( /^<svg/ ) {
	    $copy++;
	}
	push( @data, $_ ), $lines++ if $copy;
	if ( /^<\/svg/ && @lines && $lines[0] =~ /^<\/div/ ) {
	    last;
	}
    }
    if ( @data ) {
	unshift( @data, "<div>" );
	push( @data, "</div>" );
    }

    if ( DEBUG ) {
	open( $fd, '>:utf8', $svg );
	print( $fd $_, "\n" ) for @data;
	close($fd);
	warn("SVG: ", 1+$lines, " lines (", fs_test( s => $svg ), " bytes)\n") if DEBUG > 1;
    }

    my $scale;
    my $design_scale;
    if ( $kv->{scale} != 1 ) {
	if ( $kv->{id} ) {
	    $design_scale = $kv->{scale};
	}
	else {
	    $scale = $kv->{scale};
	}
    }
    return
	  { type => "image",
	    line => $elt->{line},
	    subtype => "svg",
	    data => \@data,
	    opts => { maybe id           => $kv->{id},
		      maybe align        => $kv->{align},
		      maybe split        => $kv->{split},
		      maybe spread       => $kv->{spread},
		      maybe sep          => $kv->{staffsep},
		      maybe base         => $staffbase,
		      maybe scale        => $scale,
		      maybe design_scale => $design_scale,
		    } };
}

sub have_xs {
    local $SIG{__WARN__} = sub {};
    state $ok;
    $ok //= eval { require JavaScript::QuickJS };
}

sub slurp {
    my ( $fn ) = @_;
    my $opts = { split => 0, fail => "soft" };
    my $data = loadlines( $fn, $opts );
    warn("LOAD($fn): ", $opts->{error}, "\n")
      unless defined $data || $fn eq "default.abc";
    $data;
}

# Determine the method to process the abc, and much more.
sub info {
    state $info = { handler => "" };
    my $ctl = $::config->{delegates}->{abc};
    my $handler = $ctl->{handler} // "abc2svg";

    # Use cached info, but allow handler change between songs.
    return $info if $handler eq $info->{handler};

    my $exe;
    $info->{handler} = $handler;

    state $checked;
    unless ( $checked
	     || $handler eq "abc2svg"
	     || $handler =~ /^quickjs(?:_(?:xs|qjs))?$/
	   ) {
	warn("ABC: Please remove handler \"$handler\" from your ABC delegates config and use \"abc2svg\" instead.\n");
	$handler = "abc2svg";
	$checked++;
    }

    # Default handler "abc2svg" uses program (if set),
    # otherwise embedded QuickJS or external QuickJS (in that order).
    # Handler "quickjs_xs" uses embedded QuickJS only.
    # Handler "quickjs_qjs" uses external QuickJS only.
    # Handler "quickjs" uses internal or external QuickJS.

    if ( $handler eq "abc2svg" && !$ctl->{program} # QuickJS
	 || $handler eq "quickjs"		    # XS or QJS
	 || $handler eq "quickjs_xs"		    # XS only
	 || $handler eq "quickjs_qjs"		    # QJS only
       ) {
	if ( $handler ne "quickjs_qjs" && have_xs() ) {
	    $info->{method} = QUICKJSXS;
	}
	elsif ( $handler ne "quickjs_xs"
		&& ($exe = CP->findexe("qjs", silent => 1 )) ) {
	    $info->{method} = QUICKJS;
	}
	if ( $info->{method} ) {
	    my $dir = CP->findresdirs("abc")->[-1];
	    my $js = "$dir/abc2svg/abc2svg-1.js";
	    my @js = loadlines($js);
	    if ( $js[-1] =~ /abc2svg.version="(.*?)";abc2svg.vdate="(.*?)"/ ) {
		$info->{version} = "ABC2SVG version $1 of $2";
		$info->{abclib} = $dir;
	    }
	    $info->{info} = $info->{method} . " (" . $info->{version} . ")";
	    if ( $info->{method} eq QUICKJS ) {
		$info->{command} =
		  [ $exe, "--std", "${dir}/chordproabc.js",
		    "${dir}/abc2svg" ];
	    }
	}
    }

    elsif ( $handler eq "abc2svg" && $ctl->{program}
	    && ( $exe = CP->findexe($ctl->{program}, silent => 1 ) ) ) {
	$info->{handler} = $handler;
	$info->{method} = CP->display($exe);
	$info->{info} = $info->{method};
	$info->{command} = [ $exe ];
    }

    return $info;
}

# Pre-scan.
sub options( $data ) {

    my @pre;
    my @data = @$data;
    while ( @data ) {
	last if $data[0] =~ /^([A-Z]:|\%)/;
	push( @pre, shift(@data) );
    }
    @pre = () if @pre && !@data;	# no data found
    my $kv = {};
    $kv = parse_kvm( @pre ) if @pre;
    $kv->{align} //= ($kv->{center}//0) ? "center" : "left";
    $kv;
}

1;
