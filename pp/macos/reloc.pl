#!/usr/bin/perl

use strict;
use warnings;
use utf8;

my $verbose = 1;

my $prefix = $ENV{HOME} . "/lib/citrusperl";

my $srcpat = qr;($prefix.*?)/([-\w.]+\.(?:dylib|bundle));;
my $dst = '@executable_path';

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
	    $name =~ s/3\.0\.0\.2\.0/3.0/;
	    warn("+ install_name_tool -change \"$orig/$oname\" \"$dst/$name\" \"$lib\"\n")
	      if $verbose;
	    system("install_name_tool", "-change", "$orig/$oname", "$dst/$name", $lib);
	}
    }
}
