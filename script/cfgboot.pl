#!/usr/bin/perl

# Bootstrapper for ChordPro config.

# Author          : Johan Vromans
# Created On      : Mon Jun  3 08:14:35 2024
# Last Modified By: 
# Last Modified On: Mon Jun  3 14:06:25 2024
# Update Count    : 53
# Status          : Unknown, Use with caution!

################ Common stuff ################

use v5.26;
use feature 'signatures';
no warnings 'experimental::signatures';
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../lib/ChordPro/lib";

# Package name.
my $my_package = 'ChordPro';
# Program name and version.
my ($my_name, $my_version) = qw( cfgboot 0.01 );

################ Command line parameters ################

use Getopt::Long 2.13;

# Command line options.
my $output;
my $verbose = 1;		# verbose processing

my $debug = 0;			# debugging
my $trace = 0;			# trace (show process)
my $test = 0;			# test mode.

# Process command line options.
app_options();

$trace |= ($debug || $test);

################ The Process ################

use JSON::Relaxed qw();
use JSON::XS qw();
use File::LoadLines;
use Encode qw(decode_utf8);
binmode STDOUT => ':utf8';
binmode STDERR => ':utf8';

my $parser = JSON::Relaxed::Parser->new
  ( booleans => [ $Types::Serialiser::false, $Types::Serialiser::true ] );

my $file = shift;

my $opts = { split => 0, fail => "soft" };
my $json = loadlines( $file, $opts );
die( "$file: $opts->{error}\n") if $opts->{error};
my $data = $parser->decode($json);
if ( $parser->is_error ) {
    warn( "$file: JSON error: ", $parser->err_msg, "\n" );
    next;
}

my $writer = JSON::XS->new->canonical->utf8(0)->pretty($test)->convert_blessed;
if ( $output && $output ne "-" ) {
    open( my $fd, '>:utf8', $output )
      or die("$output: $!\n");
    select $fd;
}

print <<'EOD';
#! perl		#### THIS IS A GENERATED FILE. DO NO MODIFY

package ChordPro::Config::Data;

use JSON::XS qw();
use JSON::Relaxed::Parser qw();
use feature qw(state);
EOD

print "\nour \$VERSION = ", $data->{meta}->{_configversion}->[0], ";\n\n";

print <<'EOD';
sub config {
    state $pp = JSON::XS->new->utf8
	->boolean_values( $JSON::Boolean::false, $JSON::Boolean::true );

    $pp->decode( <<'EndOfJSON' );
EOD

print ( $writer->encode($data), "\n" );

print <<EOD;
EndOfJSON
}

1;
EOD

################ Subroutines ################

sub app_options() {
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally

    # Process options, if any.
    if ( !GetOptions(
	 'output=s'	=> \$output,
	 'ident'	=> \$ident,
	 'verbose+'	=> \$verbose,
	 'quiet'	=> sub { $verbose = 0 },
	 'trace'	=> \$trace,
	 'help|?'	=> \$help,
	 'debug'	=> \$debug
       ) or $help) {
	app_usage(2);
    }
    app_ident() if $ident;
    app_usage(2) unless @ARGV == 1;
}

sub app_ident() {
    print STDERR ("This is $my_package [$my_name $my_version]\n");
    print STDERR ("JSON::Relaxed version $JSON::Relaxed::VERSION\n");
}

sub app_usage( $exit ) {
    app_ident();
    print STDERR <<EndOfUsage;
Usage: $0 [options] config.json

   --output=XXX		optional output file
   --ident		shows identification
   --help		shows a brief help message and exits
   --verbose		provides more verbose information
   --quiet		runs as silently as possible
EndOfUsage
    exit $exit if defined $exit && $exit != 0;
}
