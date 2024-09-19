#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Alien::wxWidgets;

my $verbose = 1;

my $prefix = Alien::wxWidgets->prefix;
my @libs = Alien::wxWidgets->shared_libraries("core");
die("Cannot find libs version\n") unless $libs[0] =~ /-([0-9._]+)\.dylib/;
my $lv = $1;
my $srcpat = qr;($prefix.*?)/([-\w.]+\.(?:dylib|bundle));;
my $dst = '@executable_path';
my $arch = `uname -m`;
chomp($arch);

if ( @ARGV && $ARGV[0] =~ /^--?q(?:iet)?$/ ) {
    $verbose = 0;
    shift;
}

relocate($_) for @ARGV;

################ Subroutines ################

sub relocate {
    my ( $lib ) = @_;

    die("$lib: $!") unless -w $lib;

    my $odata = `otool -L "$lib"`;

    while ( $odata =~ m/$srcpat/g ) {
	my $orig = $1;
	my $name = $2;
	my $oname = $name;

	if ( $lib =~ m;/$name$; ) {
	    warn("+ install_name_tool -id \"$dst/$name\" \"$lib\"\n")
	      if $verbose;
	    system("install_name_tool", "-id", "$dst/$name", $lib);
	}
	else {
	    if ( $arch ne "arm64") {
	      $name =~ s/-[.0-9_]+\.dylib/-$lv.dylib/
	        unless $name =~ m;libpcre2;;
	    }
	    warn("+ install_name_tool -change \"$orig/$oname\" \"$dst/$name\" \"$lib\"\n")
	      if $verbose;
	    system("install_name_tool", "-change", "$orig/$oname", "$dst/$name", $lib);
	}
    }
}
