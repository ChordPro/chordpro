#!/usr/bin/perl

use Wx 0.9912 qw[:allclasses];

use strict;
use warnings;

package main;

use FindBin;
use lib "$FindBin::Bin/../CPAN";
use lib "$FindBin::Bin/../lib";
use App::Packager qw( :name App::Music::ChordPro );
use App::Music::ChordPro::Wx;
use App::Music::ChordPro::Utils qw(is_msw);
$ENV{PATH} = "$FindBin::Bin/.." . (is_msw() ? ";" : ":" ) . $ENV{PATH};

# Package name.
my $my_package = 'ChordPro';
# Program name and version.
my $my_name = 'WxChordPro';
my $my_version = $App::Music::ChordPro::Wx::VERSION;

# We need Wx::App for the mainloop.
# App::Music::ChordPro::Wx::Main is the main entry of the program.
use base qw(Wx::App App::Music::ChordPro::Wx::Main);

my $options = app_options();

sub OnInit {
    my ( $self ) = shift;

    $self->SetAppName("ChordPro");
    $self->SetVendorName("ChordPro.ORG");
    Wx::InitAllImageHandlers();

    my $main = App::Music::ChordPro::Wx::Main->new();
    exit unless $main->init($options);

    $self->SetTopWindow($main);
    $main->Show(1);

    return 1;
}

# No localisation yet.
# my $locale = Wx::Locale->new("English", "en", "en_US");
# $locale->AddCatalog("wxchordpro");

my $m = main->new();
$m->MainLoop();

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
}

sub app_usage {
    my ($exit) = @_;
    app_ident();
    print STDERR <<EndOfUsage;
Usage: $0 [options] [file ...]
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

For more information about the ChordPro file format, see
L<http://www.chordpro.org>.

For more information about ChordPro program, see L<App::Music::ChordPro>.

=head1 LICENSE

Copyright (C) 2010,2018 Johan Vromans,

This module is free software. You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

