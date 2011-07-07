#!/usr/bin/perl

# pChord -- perl version of Chord/Chordii

# Author          : Johan Vromans
# Created On      : Fri Jul  9 14:32:34 2010
# Last Modified By: Johan Vromans
# Last Modified On: Thu Jul  7 13:43:36 2011
# Update Count    : 141
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Data::Dumper;

################ Setup  ################

# Process command line options, config files, and such.
my $options = app_setup("pchord", "0.10");

################ Presets ################

$options->{trace} = 1   if $options->{debug};
$options->{verbose} = 1 if $options->{trace};

################ Activate ################

main($options);

################ The Process ################

sub main {
    my ($options) = @_;
    print Dumper($options) if $options->{debug};
    binmode( STDOUT, ':utf8' );

    use Music::ChordPro::Songbook;

    my $s = Music::ChordPro::Songbook->new;

    $s->parsefile( $ARGV[0] );
    #$s->transpose(-2);		# NYI

    warn(Dumper($s), "\n") if $options->{debug};

    $options->{generate} ||= "ChordPro";
    my $pkg = "Music::ChordPro::Output::".$options->{generate};
    eval "require $pkg;";
    die("No backend for ", $options->{generate}, "\n") if $@;

    my $backend = $pkg . "::generate_songbook";
    print( join( "\n",
		 @{ $pkg->generate_songbook( $s, $options ) } ) );
}

################ Options and Configuration ################

use Getopt::Long 2.13;
use File::Spec;
use Carp;

# Package name.
my $my_package;
# Program name and version.
my ($my_name, $my_version);
my %configs;

sub app_setup {
    my ($appname, $appversion, %args) = @_;
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally

    # Package name.
    $my_package = $args{package};
    # Program name and version.
    if ( defined $appname ) {
	($my_name, $my_version) = ($appname, $appversion);
    }
    else {
	($my_name, $my_version) = qw( MyProg 0.01 );
    }

    %configs =
      ( sysconfig  => File::Spec->catfile ("/", "etc", lc($my_name) . ".conf"),
	userconfig => File::Spec->catfile($ENV{HOME}, ".".lc($my_name), "conf"),
	config     => "." . lc($my_name) .".conf",
#	config     => lc($my_name) .".conf",
      );

    my $options =
      {
       verbose		=> 0,		# verbose processing
       ### ADD OPTIONS HERE ###

       # Development options (not shown with -help).
       debug		=> 0,		# debugging
       trace		=> 0,		# trace (show process)

       # Service.
       _package		=> $my_package,
       _name		=> $my_name,
       _version		=> $my_version,
       _stdin		=> \*STDIN,
       _stdout		=> \*STDOUT,
       _stderr		=> \*STDERR,
       _argv		=> [ @ARGV ],
      };

    # Colled command line options in a hash, for they will be needed
    # later.
    my $clo = {};

    # Sorry, layout is a bit ugly...
    if ( !GetOptions
	 ($clo,

	  ### ADD OPTIONS HERE ###
	  'generate=s',

	  # Configuration handling.
	  'config=s',
	  'noconfig',
	  'sysconfig=s',
	  'nosysconfig',
	  'userconfig=s',
	  'nouserconfig',
	  'define|D=s%' => sub { $clo->{$_[1]} = $_[2] },

	  # Standard options.
	  'ident'		=> \$ident,
	  'help|?'		=> \$help,
	  'verbose',
	  'trace',
	  'debug',
	 ) )
    {
	# GNU convention: message to STDERR upon failure.
	app_usage(\*STDERR, 2);
    }
    # GNU convention: message to STDOUT upon request.
    app_usage(\*STDOUT, 0) if $help;
    app_ident(\*STDOUT) if $ident;

    # If the user specified a config, it must exist.
    # Otherwise, set to a default.
    for my $config ( qw(sysconfig userconfig config) ) {
	for ( $clo->{$config} ) {
	    if ( defined($_) ) {
		croak("$_: $!\n") if ! -r $_;
		next;
	    }
	    $_ = $configs{$config};
	    undef($_) unless -r $_;
	}
	app_config($options, $clo, $config);
    }

    # Plug in command-line options.
    @{$options}{keys %$clo} = values %$clo;

    $options;
}

sub app_ident {
    my ($fh) = @_;
    print {$fh} ("This is ",
		 $my_package
		 ? "$my_package [$my_name $my_version]"
		 : "$my_name version $my_version",
		 "\n");
}

sub app_usage {
    my ($fh, $exit) = @_;
    app_ident($fh);
    print ${fh} <<EndOfUsage;
Usage: $0 [options]
    ### ADD OPTIONS HERE ###

Configuration options:
    --config=CFG	project specific config file ($configs{config})
    --noconfig		don't use a project specific config file
    --userconfig=CFG	user specific config file ($configs{userconfig})
    --nouserconfig	don't use a user specific config file
    --sysconfig=CFG	system specific config file ($configs{sysconfig})
    --nosysconfig	don't use a system specific config file
    --define key=value  define or override a configuration option
Missing default configuration files are silently ignored.

Miscellaneous options:
    --help		this message
    --ident		show identification
    --verbose		verbose information
EndOfUsage
    exit $exit if defined $exit;
}

sub app_config {
    my ($options, $opts, $config) = @_;
    return if $opts->{"no$config"};
    my $cfg = $opts->{$config};
    return unless defined $cfg && -s $cfg;
    my $verbose = $opts->{verbose} || $opts->{trace} || $opts->{debug};
    warn("Loading $config: $cfg\n") if $verbose;

    # Process config data, filling $options ...
}
