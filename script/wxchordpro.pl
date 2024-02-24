#!/usr/bin/perl

# WxChordPro -- Successor of Chord/Chordii

# Author          : Johan Vromans
# Created On      : Fri Jul  9 14:32:34 2010
# Last Modified On: Mon Feb 12 22:12:02 2024
# Update Count    : 283
# Status          : Unknown, Use with caution!

################ Common stuff ################
use Wx 0.9912 qw[:allclasses];

use strict;
use warnings;
use utf8;

package main;

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

# We need Wx::App for the mainloop.
# ChordPro::Wx::Main is the main entry of the program.
use base qw(Wx::App ChordPro::Wx::Main);

my $options = app_options();

sub OnInit {
    my ( $self ) = shift;

    $self->SetAppName("ChordPro");
    $self->SetVendorName("ChordPro.ORG");
    Wx::InitAllImageHandlers();

    my $main = ChordPro::Wx::Main->new();
    exit unless $main->init($options);

    $self->SetTopWindow($main);
    $main->Show(1);

    if ( $options->{maximize} ) {
	$main->Maximize(1);
    }

#    elsif ( $options->{geometry}
#	    && $options->{geometry} =~ /^(?:(\d+)x(\d+))?(?:([+-]\d+)([+-]\d+))?$/ ) {
#	$main->SetSize( $1, $2 )
#	  if defined($1) && defined($2);
#	$main->Move( $3+0, $4+0 )
#	  if defined($3) && defined($4);
#    }

    return 1;
}

# No localisation yet.
# my $locale = Wx::Locale->new("English", "en", "en_US");
# $locale->AddCatalog("wxchordpro");

my $m = main->new();
$m->MainLoop();

################ Subroutines ################

use Wx qw( wxEXEC_SYNC );

# Not yet defined in this version of wxPerl.
use constant wxEXEC_HIDE_CONSOLE => 32;

# Synchronous system call. Used in Util module.
sub ::sys { Wx::ExecuteArgs( \@_, wxEXEC_SYNC | wxEXEC_HIDE_CONSOLE ); }

################ Subroutines ################

use Getopt::Long 2.13;

sub app_options {
    my $options = {};

    # Process options, if any.
    # Make sure defaults are set before returning!
    return unless @ARGV > 0;

    if ( !GetOptions( $options,
		      'ident',
		      'log',
		     'verbose|v+',
		      'version|V',
		      'maximize',
#		      'geometry=s',
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
    --version		show identification and exit
    --verbose		verbose information
    --quit		don't do anything
EndOfUsage
    exit $exit if defined $exit && $exit != 0;
}

=head1 NAME

wxchordpro - a simple Wx-based GUI wrapper for ChordPro

=head1 SYNOPSIS

  wxchordpro [ options ] [ file ]

=head1 DESCRIPTION

B<wxchordpro> is a GUI wrapper for the ChordPro program. It allows
opening of files, make changes, and preview (optionally print) the
formatted result.

Visit the web site L<https://chordpro.org> for complete documentation.

=cut

