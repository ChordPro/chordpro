#! perl

use strict;
use warnings;

chomp( my $arch = `uname -m` );
die("Perl must be brewed!\n") unless $^X =~ /Cellar/;

my %libs;

# No idea who uses liblzma.
# libz seems to be standard.

my $fail = 0;
for my $lib ( qw( libpng16 libjpeg libtiff-4 liblzma
		  libzstd libpcre2-32 ) ) {
    my $res = `pkg-config --silence-errors --libs $lib`;
    if ( $res =~ /-l/ && $res =~ /-L(.+)\s+-l(.+)/ ) {
	my $path = $1 . "/lib" . $2 . ".dylib";
	$libs{$2} = $path;
	if ( -s $path ) {
	    print("$path\n");
	}
	else {
	    warn("$path: NOT FOUND\n");
	    $fail++;
	}
    }
    else {
	warn( "NO LIBRARY FOR $lib\n");
    }
}

exit($fail);
