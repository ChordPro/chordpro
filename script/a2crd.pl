#!/usr/bin/perl

# A2ChordPro -- perl version of Chord/A2Crd

# Author          : Johan Vromans
# Created On      : Mon Oct 29 10:45:24 2018
# Last Modified By: Johan Vromans
# Last Modified On: Tue Nov  6 16:43:04 2018
# Update Count    : 35
# Status          : Unknown, Use with caution!

################ Common stuff ################

=head1 NAME

a2crd - Convert ASCII Crd to ChordPro

=head1 DESCRIPTION

B<a2crd> will read a text file containing the lyrics of one or many
songs with chord information written visually above the lyrics. This
is often referred to as I<crd> data. B<a2crd> will then generate
equivalent ChordPro output.

Note that the output will generally need some additional editing to be
useful as input to ChordPro.

B<a2crd> is a wrapper around L<App::Music::ChordPro::A2Crd>, which
does all of the work. a2crd and App::Music::ChordPro::A2Crd do
not use any other modules of the ChordPro package.

=cut

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../CPAN";
use lib "$FindBin::Bin/../lib";
use App::Packager qw( :name App::Music::ChordPro );

use App::Music::ChordPro::A2Crd;
use File::LoadLines;

# Package or program libraries, if appropriate.
# $LIBDIR = $ENV{'LIBDIR'} || '/usr/local/lib/sample';
# use lib qw($LIBDIR);
# require 'common.pl';

# Package name.
my $my_package = 'ChordPro';
# Program name and version.
my ($my_name, $my_version) = qw( a2crd 0.972 );

################ Command line parameters ################

use Getopt::Long 2.13;

# Command line options.
my %options;
my $verbose = 0;		# verbose processing
my $output;

# Development options (not shown with -help).
my $debug = 0;			# debugging
my $trace = 0;			# trace (show process)
my $test = 0;			# test mode.

# Process command line options.
app_options();

# Post-processing.
$trace |= ($debug || $test);

$options{output} = $output;
$options{verbose} = $verbose;

################ Presets ################

my $TMPDIR = $ENV{TMPDIR} || $ENV{TEMP} || '/usr/tmp';

################ The Process ################

binmode( STDERR, ':utf8' );

my $lines = loadlines( @ARGV ? $ARGV[0] : \*DATA);

my $fd;
if ( $output && $output ne '-' ) {
    open( $fd, '>:utf8', $output )
      or croak("$output: $!\n");
}
else {
    binmode( STDOUT, ':utf8' );
    $fd = \*STDOUT;
}

print $fd "$_\n"
  foreach App::Music::ChordPro::A2Crd::a2cho($lines, \%options);

################ Subroutines ################

sub app_options {
    my $version = 0;		# handled locally
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally

    # Process options, if any.
    # Make sure defaults are set before returning!
    return unless @ARGV > 0;

    if ( !GetOptions(
		     'output=s' => \$output,
		     'ident'	=> \$ident,
		     'version'	=> \$version,
		     'verbose'	=> \$verbose,
		     'trace'	=> \$trace,
		     'help|?'	=> \$help,
		     'debug'	=> \$debug,
		    ) or $help )
    {
	app_usage(2);
    }
    app_ident() if $ident || $version;
    exit if $version;
}

sub app_ident {
    print STDERR ("This is $my_package [$my_name $my_version]\n");
}

sub app_usage {
    my ($exit) = @_;
    app_ident();
    print STDERR <<EndOfUsage;
Usage: $0 [options] [file ...]
    --output=XXX	output file (stdout)
    --help		this message
    --ident		show identification
    --verbose		verbose information
EndOfUsage
    exit $exit if defined $exit && $exit != 0;
}

__DATA__
Title: Swing Low Sweet Chariot

{soc}
      D          G    D
Swing low, sweet chariot,
                       A7
Comin’ for to carry me home.
      D7         G    D
Swing low, sweet chariot,
              A7       D
Comin’ for to carry me home.
{eoc}

  D                       G          D
I looked over Jordan, and what did I see,
                       A7
Comin’ for to carry me home.
  D              G            D
A band of angels comin’ after me,
              A7       D
Comin’ for to carry me home.

