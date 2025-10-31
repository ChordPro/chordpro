#! perl

# Generic wxchorpro.pp generator.

# Author          : Johan Vromans
# Last Modified By: Johan Vromans
# Last Modified On: Wed Oct 29 15:38:14 2025
# Update Count    : 105
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;

# Package name.
my $my_package = 'ChordPro';
# Program name and version.
my ($my_name, $my_version) = qw( wxpp.pl 0.02 );

use Alien::wxWidgets;
use constant is_msw   => $^O =~ /msw/i;
use constant is_macos => $^O =~ /darwin/i;

################ Command line parameters ################

use Getopt::Long 2.13;

# Command line options.
my $output;
my $verbose = 1;		# verbose processing

# Development options (not shown with -help).
my $debug = 0;			# debugging
my $trace = 0;			# trace (show process)
my $test = 0;			# test mode.

# Process command line options.
app_options();

# Post-processing.
$trace |= ($debug || $test);

# Output redirection, if requested.
if ( $output && $output ne "-" ) {
    close(STDOUT);
    open( STDOUT, '>:utf8', $output )
      or die("$output: $!\n");
}

################ The Process ################

my $prefix = Alien::wxWidgets->prefix;
my $version = Alien::wxWidgets->version;
$version =~ s/(\d+)\.(\d\d\d)(\d\d\d)/sprintf("v%d.%d.%d", $1, $2, $3)/e;

my $perltype = "Generic";
$perltype = "HomeBrew Perl"   if is_macos && $^X =~ /cellar/i;
$perltype = "Strawberry Perl" if is_msw && $^X =~ /strawberry/i;

# Get path for wxWidgets shared libraries.
my @slp;
if ( is_msw ) {
    push( @slp, Alien::wxWidgets->shared_library_path );
}
elsif ( is_macos ) {
    # Until we find a better way.
    push( @slp, Alien::wxWidgets->prefix . "/lib" );
}
else {
    my $ld = qx/ld --verbose/;
    while ( $ld =~ /SEARCH_DIR\("=(.*?)"\)/g ) {
	push( @slp, $1 ) if -d $1;
    }
}

print <<EOD;
# Packager settings for WxChordPro.

# $perltype $^V + wxWidgets $version.
# prefix = $prefix
# Shared libs: @slp

@../common/wxchordpro.pp
EOD

print("--gui\n") if is_msw;

print("\n");
print( "--module=Wx::$_\n" ) for qw( WebView STC );
print("\n");

print("# Explicitly link the wxWidgets libraries.\n");

my $fail = 0;
my %need = ( map { $_ => 1 } qw( media webview stc ) );

for my $lib ( sort Alien::wxWidgets->shared_libraries ) {
    my $found;
    for my $path ( @slp ) {
	my $lib = "$path/$lib";
	if ( -f $lib ) {
	    $found = $lib;
	    last;
	}
    }
    unless ( $found ) {
	warn("Not found: $lib\n");
	$fail++;
	next;
    }

    # We do not need (use) gl and xrc, so skip then.
    print("# Not needed: $lib\n"),next
      if $lib =~ /[-_](gl|xrc)[-_]/;

    $lib = $found if is_msw;
    $lib =~ s/\\/\//g if is_msw;

    print( "--link=$lib\n");

    # Verify we have the required libs.
    delete $need{$1} if $lib =~ /_(media|stc|webview)[-_]/;
}

for ( sort keys %need ) {
    warn( "No lib found for $_\n" );
    $fail++;
}

# Supporting libs. pp will complain if not found.
my @aux;
if ( is_msw ) {
    # None?
}
elsif ( is_macos ) {
    @aux = qw( jpeg libpng16 tiff lzma zstd pcre2-32 );
}
else {
    @aux = qw( deflate jbig jpeg libpng16.so.16 SDL2-2.0 tiff webp );
}
print("\n# Supporting libs\n");
print("-l $_\n") for @aux;

exit( $fail > 0 );

################ Subroutines ################

sub app_options {
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally

    # Process options, if any.
    # Make sure defaults are set before returning!
    return unless @ARGV > 0;

    if ( !GetOptions(
		     'output=s' => \$output,
		     'ident'	=> \$ident,
		     'verbose+'	=> \$verbose,
		     'quiet'	=> sub { $verbose = 0 },
		     'trace'	=> \$trace,
		     'help|?'	=> \$help,
		     'debug'	=> \$debug,
		    ) or $help )
    {
	app_usage(2);
    }
    app_ident() if $ident;
}

sub app_ident {
    print STDERR ("This is $my_package [$my_name $my_version]\n");
}

sub app_usage {
    my ($exit) = @_;
    app_ident();
    print STDERR <<EndOfUsage;
Usage: $0 [options]
   --output=XXX		output file
   --ident		shows identification
   --help		shows a brief help message and exits
   --verbose		provides more verbose information
   --quiet		runs as silently as possible

Supported platforms:
    Fedora 42, Rawhide
    Ubuntu 22.04 LTS, perl 5.34.0, custom wxWidgets 3.2.4
    Ubuntu 24.04 LTS, perl 5.38.2, wxWidgets 3.2.4
    Microsoft Windows 10, Strawberry perl, wxWidgets 3.x
    macOS Catalina, Homebrew Perl 5.34, Homebrew wxWidgets 3.2.2
EndOfUsage
    exit $exit if defined $exit && $exit != 0;
}
