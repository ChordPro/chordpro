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

# $perltype + wxWidgets 3.0.

@../common/wxchordpro.pp
--gui

# Explicit libraries.
--link=/usr/local/lib/libjpeg.8.dylib

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
