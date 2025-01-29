#! perl

use strict;
use warnings;
use Alien::wxWidgets;

my $arch = `uname -m`;
my $prefix = Alien::wxWidgets->prefix;
my $wxversion = Alien::wxWidgets->version;
$wxversion = sprintf("%d.%d", $wxversion =~ /^(\d+)\.(\d\d\d)/ );

my $perltype = "Generic";
$perltype = "Citrus Perl" if $^X =~ /citrusperl/;
$perltype = "HomeBrew Perl" if $^X =~ /Cellar/;
die("Perl must be brewed!\n") unless $perltype =~ /brew/i;

print <<EOD;
# Packager settings for WxChordPro.

# $perltype + wxWidgets $wxversion.

@../common/wxchordpro.pp
--gui

# Explicit libraries.
EOD

# No idea who used liblzma.
# libz seems to be standard.

my $fail = 0;
for my $lib ( qw( libpng16 libjpeg libtiff-4 liblzma
		  libzstd libpcre2-32 ) ) {
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
