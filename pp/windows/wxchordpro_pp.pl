#! perl

use strict;
use warnings;
use Alien::wxWidgets;
use constant is_msw => $^O =~ /win/i;
use constant is_macos => $^O =~ /darwin/i;

if ( @ARGV == 2 && $ARGV[0] eq "-o" ) {
    open( STDOUT, '>:utf8', $ARGV[1] ) or die("$ARGV[1]: $!\n");
}

my $prefix = Alien::wxWidgets->prefix;
my $version = Alien::wxWidgets->version;
$version =~ s/(\d+)\.(\d\d\d)(\d\d\d)/sprintf("v%d.%d.%d", $1, $2, $3)/e;

my $perltype = "Generic";
$perltype = "Citrus Perl" if $^X =~ /citrusperl/i;
$perltype = "HomeBrew Perl" if $^X =~ /cellar/i;
$perltype = "Strawberry Perl" if $^X =~ /strawberry/i;

print <<EOD;
# Packager settings for WxChordPro.

# $perltype $^V + wxWidgets $version.

@../common/wxchordpro.pp
EOD

print("--gui\n") if is_msw;

print("\n");

print("# Explicitly link the wxWidgets libraries.\n");

for ( sort Alien::wxWidgets->shared_libraries ) {
    my $lib = "$prefix/lib/$_";
    warn("Skipped: $_\n"),next unless -f $lib;
    warn("Not needed: $_\n"),next
      if $lib =~ /[-_](gl|xrc|stc)[-_]/;
    $lib =~ s/\\/\//g if is_msw;
    print( "--link=$lib\n");
    if ( /_webview[-_]/ ) {
	print( "--module=Wx::WebView\n" );
    }
}
