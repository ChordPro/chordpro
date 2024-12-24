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
my $slp = Alien::wxWidgets->shared_library_path;

print <<EOD;
# Packager settings for WxChordPro.

# $perltype $^V + wxWidgets $version.
# prefix = $prefix
# Shared libs: $slp

@../common/wxchordpro.pp
EOD

print("--gui\n") if is_msw;

print("\n");

print("# Explicitly link the wxWidgets libraries.\n");

my $fail = 0;
for ( sort Alien::wxWidgets->shared_libraries ) {
    my $lib = "$slp/$_";
    unless ( -f $lib ) {
	warn("Skipped: $lib\n");
	$fail++;
	next;
    }
    warn("Not needed: $_\n"),next
      if $lib =~ /[-_](gl|xrc)[-_]/;
    $lib =~ s/\\/\//g if is_msw;
    print( "--link=$lib\n");
    if ( /_webview[-_]/ ) {
	print( "--module=Wx::WebView\n" );
    }
    elsif ( /_stc[-_]/ ) {
	print( "--module=Wx::STC\n" );
    }
}

exit( $fail > 0 );
