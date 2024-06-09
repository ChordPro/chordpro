#! perl

use strict;
use warnings;
use Alien::wxWidgets;

my $prefix = Alien::wxWidgets->prefix;

my $perltype = "Generic";
$perltype = "Citrus Perl" if $^X =~ /citrusperl/;
$perltype = "HomeBrew Perl" if $^X =~ /Cellar/;

print <<EOD;
# Packager settings for WxChordPro.

# $perltype + wxWidgets 3.2.

@../common/wxchordpro.pp
--gui

# Explicit libraries.
--link=/usr/local/lib/libpng16.16.dylib
--link=/usr/local/lib/libjpeg.8.dylib
--link=/usr/local/lib/libtiff.6.dylib
--link=/usr/local/Cellar/zlib/1.3.1/lib/libz.1.3.1.dylib
--link=/usr/local/opt/zstd/lib/libzstd.1.dylib
--link=/usr/local/opt/pcre2/lib/libpcre2-32.0.dylib

# Explicitly link the wx libraries.
EOD

for ( sort Alien::wxWidgets->shared_libraries ) {
    my $lib = "$prefix/lib/$_";
    warn("Skipped: $_\n"),next unless -f $lib;
    print( "--link=$lib\n");
    if ( /_webview-/ ) {
	print( "--module=Wx::WebView\n" );
    }
}
