#!/usr/bin/perl

# Author          : Johan Vromans
# Created On      : Sun Mar 10 18:02:02 2024
# Last Modified By: 
# Last Modified On: Tue Apr  2 22:46:16 2024
# Update Count    : 35
# Status          : Unknown, Use with caution!

################ Common stuff ################

use v5.26;
use feature 'signatures';
no warnings 'experimental::signatures';

# Package or program libraries, if appropriate.
# $LIBDIR = $ENV{'LIBDIR'} || '/usr/local/lib/sample';
# use lib qw($LIBDIR);
# require 'common.pl';

# Package name.
my $my_package = 'ChordPro';
# Program name and version.
my ($my_name, $my_version) = qw( rrjson 0.02 );

################ Command line parameters ################

use Getopt::Long 2.13;

# Command line options.
my $mode = "json";
my $verbose = 1;		# verbose processing

# Development options (not shown with -help).
my $debug = 0;			# debugging
my $trace = 0;			# trace (show process)
my $test = 0;			# test mode.

# Process command line options.
app_options();

# Post-processing.
$trace |= ($debug || $test);

################ Presets ################

my $TMPDIR = $ENV{TMPDIR} || $ENV{TEMP} || '/usr/tmp';

################ The Process ################

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../lib/ChordPro/lib";
use JSON::Relaxed;
use File::LoadLines;
binmode STDOUT => ':utf8';
binmode STDERR => ':utf8';

for my $file ( @ARGV ) {
    my $opts = { split => 0, fail => "soft" };
    my $json = loadlines( $file, $opts );
    die( "$file: $opts->{error}\n") if $opts->{error};
    my $data = JSON::Relaxed::Parser->new->parse($json);
    if ( $JSON::Relaxed::err_id ) {
	die("$file: JSON error: $JSON::Relaxed::err_msg\n");
    }
    if ( $mode eq "dump" ) {
	my %opts = ( fulldump => 1 );
	require Data::Printer;
	if ( -t STDOUT ) {
	    Data::Printer::p( $data, %opts );
	}
	else {
	    print( Data::Printer::np( $data, %opts ) );
	}
    }
    elsif ( $mode eq "dumper" ) {
	local $Data::Dumper::Sortkeys  = 1;
	local $Data::Dumper::Indent    = 1;
	local $Data::Dumper::Quotekeys = 0;
	local $Data::Dumper::Deparse   = 1;
	local $Data::Dumper::Terse     = 1;
	local $Data::Dumper::Trailingcomma = 1;
	local $Data::Dumper::Useperl = 1;
	local $Data::Dumper::Useqq     = 0; # I want unicode visible
	require Data::Dumper;
	print( Data::Dumper->Dump( [$data] ) );
    }
    elsif ( $mode eq "json_xs" ) {
	require JSON::XS;
	print ( JSON::XS->new->canonical->utf8->pretty->encode($data), "\n" );
    }
    else {			# default JSON
	require JSON::PP;
	print ( JSON::PP->new->canonical->utf8->pretty->encode($data), "\n" );
    }
}

################ Subroutines ################

sub app_options() {
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally

    # Process options, if any.
    # Make sure defaults are set before returning!
    return unless @ARGV > 0;

    if ( !GetOptions(
		     'json|json_pp'	=> sub { $mode = "json" },
		     'json_xs'	=> sub { $mode = "json_xs" },
		     'dump'	=> sub { $mode = "dump" },
		     'dumper'	=> sub { $mode = "dumper" },
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

sub app_ident() {
    print STDERR ("This is $my_package [$my_name $my_version]\n");
    print STDERR ("JSON::Relaxed version $JSON::Relaxed::VERSION\n");
}

sub app_usage( $exit ) {
    app_ident();
    print STDERR <<EndOfUsage;
Usage: $0 [options] [file ...]
   --json		JSON output (default)
   --dump		dump structure
   --ident		shows identification
   --help		shows a brief help message and exits
   --verbose		provides more verbose information
   --quiet		runs as silently as possible
EndOfUsage
    exit $exit if defined $exit && $exit != 0;
}
