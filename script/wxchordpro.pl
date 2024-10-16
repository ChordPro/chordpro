#!/usr/bin/perl

# WxChordPro -- Successor of Chord/Chordii

# Author          : Johan Vromans
# Created On      : Fri Jul  9 14:32:34 2010
# Last Modified On: Wed Oct 16 10:52:43 2024
# Update Count    : 289
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;

use utf8;
binmode(STDERR, ':utf8');
binmode(STDOUT, ':utf8');

use FindBin;
use lib "$FindBin::Bin/../lib";

use ChordPro;
use ChordPro::Paths;
CP->pathprepend( "$FindBin::Bin", "$FindBin::Bin/.." );

# Package name.
my $my_package = 'ChordPro';
# Program name and version.
my $my_name = 'WxChordPro';
my $my_version = $ChordPro::VERSION;

# ChordPro::Wx::Main is the main entry of the program.
use ChordPro::Wx::Main;

my $options = app_options();

ChordPro::Wx::WxChordPro::run($options);

################ Subroutines ################

use Getopt::Long 2.13;

sub app_options {
    my $options = {};

    # Process options, if any.
    # Make sure defaults are set before returning!
    return unless @ARGV > 0;

    if ( !GetOptions( $options,
		      'ident',
		     'verbose|v+',
		      'version|V',
		      'maximize',
		      'geometry=s',
		     'quit',
		     'trace',
		     'help|?',
		     'debug',
		    ) or $options->{help} )
    {
	app_usage(2);
    }


    # This is to allow installers to fake an initial run.
    exit if $options->{quit};

    if ( $options->{version} ) {
	app_ident();
	exit(0);
    }
    app_ident() if $options->{ident};

    return $options;
}

sub app_ident {
    print STDERR ("This is $my_package [$my_name $my_version]\n");
    print STDERR ( ::runtimeinfo("short"), "\n");
}

sub app_usage {
    my ($exit) = @_;
    app_ident();
    print STDERR <<EndOfUsage;
Usage: $0 [options] [file ...]
    --maximize          show full screen
    --help		this message
    --ident		show identification
    --version -V	show identification and exit
    --verbose		verbose information
    --quit		don't do anything
EndOfUsage
    exit $exit if defined $exit && $exit != 0;
}

=head1 NAME

wxchordpro - a simple Wx-based GUI for ChordPro

=head1 SYNOPSIS

  wxchordpro [ options ] [ file ]

=head1 DESCRIPTION

B<wxchordpro> is a simple GUI for the ChordPro program. It allows
opening of files, make changes, and preview (optionally print) the
formatted result.

Visit the web site L<https://chordpro.org> for complete documentation.

=cut

