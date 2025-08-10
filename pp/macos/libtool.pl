#!/usr/bin/perl

# Author          : Johan Vromans
# Created On      : Tue Sep 15 15:59:04 1992
# Last Modified By: Johan Vromans
# Last Modified On: Sun Aug 10 17:06:48 2025
# Update Count    : 26
# Status          : Unknown, Use with caution!

################ Common stuff ################

use v5.26;
use feature 'signatures';
no warnings qw(experimental::signatures);
use utf8;

# Package name.
my $my_package = 'ChordPro';
# Program name and version.
my ($my_name, $my_version) = qw( libtool 0.01 );

################ Command line parameters ################

use Getopt::Long 2.13;

# Command line options.
my $checklibs;			# check libs
my $writepp;			# write pp
my $pkgconfig = "pkg-config";	# tool
my $verbose = 1;		# verbose processing

# Development options (not shown with -help).
my $debug = 0;			# debugging
my $trace = 0;			# trace (show process)
my $test = 0;			# test mode.

# Process command line options.
app_options();

$checklibs++ unless $writepp;

# Post-processing.
$trace |= ($debug || $test);

################ Presets ################

binmode STDERR => ':utf8';
binmode STDOUT => ':utf8';

################ The Process ################

die("Perl must be brewed!\n") unless $^X =~ /Cellar/;

`$pkgconfig --version` =~ /\d+\.\d+/
  or die("Missing '$pkgconfig' tool\n");

# libtiff uses liblzma.
# libz seems to be standard.
my @libs = qw( libpng16 libjpeg libtiff-4 liblzma
	       libzstd libpcre2-32 );
my %libs;

if ( $checklibs ) {
    checklibs() || exit(1);
}

if ( $writepp ) {
    writepp($writepp);
}

################ Subroutines ################

sub checklibs() {
    my $fail = 0;
    for my $lib ( @libs ) {
	my $res = `pkg-config --silence-errors --libs $lib`;
	if ( $res =~ /-l/ && $res =~ /-L(.+)\s+-l(.+)/ ) {
	    my $path = $1 . "/lib" . $2 . ".dylib";
	    $libs{$2} = $path;
	    if ( -s $path ) {
		print("$path\n") if $verbose;
	    }
	    else {
		warn("$path: NOT FOUND\n");
		$fail++;
	    }
	}
	else {
	    warn( "NO LIBRARY FOR $lib\n");
	    $fail++;
	}
    }
    exit($fail);
}

sub writepp($pp) {
    require Alien::wxWidgets;
    Alien::wxWidgets->import;

    my $fd;
    unless ( $pp eq "-" ) {
	open( $fd, '>:utf8', $pp )
	  or die("$pp: $!\n");
	select($fd);
    }

    chomp( my $arch = `uname -m` );
    my $prefix = Alien::wxWidgets->prefix;
    my $wxversion = Alien::wxWidgets->version;
    $wxversion = sprintf("%d.%d", $wxversion =~ /^(\d+)\.(\d\d\d)/ );
    my $perlversion = sprintf("%d.%d", $] =~ /^(\d+)\.(\d\d\d)/ );
    my $perltype = "Generic";
    $perltype = "Citrus Perl" if $^X =~ /citrusperl/;
    $perltype = "HomeBrew Perl" if $^X =~ /Cellar/;

    print <<EOD;
# Packager settings for WxChordPro.

# macOS ($arch) + $perltype $perlversion + wxWidgets $wxversion.

@../common/wxchordpro.pp
--gui

# Explicit libraries.
EOD

    my $fail = 0;
    for my $lib ( @libs ) {
	my $res = `pkg-config --silence-errors --libs $lib`;
	if ( $res =~ /-l/ && $res =~ /-L(.+)\s+-l(.+)/ ) {
	    my $path = $1 . "/lib" . $2 . ".dylib";
	    if ( -s $path ) {
		print( "--link=$path\n");
	    }
	    else {
		print("# $path: NOT FOUND\n");
		$fail++;
	    }
	}
	else {
	    print( "# Library for $lib NOT FOUND\n");
	    $fail++;
	}
    }

    exit($fail) if $fail;

    print <<EOD;

# Explicitly link the wx libraries.
EOD

    for ( sort Alien::wxWidgets->shared_libraries ) {
	my $lib = "$prefix/lib/$_";
	warn("Skipped: $_\n"),next unless -f $lib;
	print( "--link=$lib\n");
	if ( /_webview-/ ) {
	    print( "--module=Wx::WebView\n" );
	}
	elsif ( /_stc[-_]/ ) {
	    print( "--module=Wx::STC\n" );
	}
    }

    # File will be closed automatically.
}

################ Subroutines ################

sub app_options() {
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally

    # Process options, if any.
    # Make sure defaults are set before returning!
    return unless @ARGV > 0;

    if ( !GetOptions( 'checklibs'	=> \$checklibs,
		      'pp=s'		=> \$writepp,
		      'pkgconfig=s'	=> \$pkgconfig,
		      'ident'		=> \$ident,
		      'verbose+'	=> \$verbose,
		      'quiet'		=> sub { $verbose = 0 },
		      'trace'		=> \$trace,
		      'help|?'		=> \$help,
		      'debug'		=> \$debug,
		    ) or $help )
    {
	app_usage(2);
    }
    app_ident() if $ident;
}

sub app_ident() {
    print STDERR ("This is $my_package [$my_name $my_version]\n");
}

sub app_usage($exit) {
    app_ident();
    print STDERR <<EndOfUsage;
Usage: $0 [options] [file ...]
   --checklibs		check presence of libraries
   --pp=XXX		write wxchordpro.pp
   --ident		shows identification
   --help		shows a brief help message and exits
   --verbose		provides more verbose information
   --quiet		runs as silently as possible
EndOfUsage
    exit $exit if defined $exit && $exit != 0;
}

