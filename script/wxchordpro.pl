#!/usr/bin/perl

# WxChordPro -- Successor of Chord/Chordii

# Author          : Johan Vromans
# Created On      : Fri Jul  9 14:32:34 2010
# Last Modified On: Fri Sep 12 22:52:50 2025
# Update Count    : 338
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;

use utf8;
binmode(STDERR, ':utf8');
binmode(STDOUT, ':utf8');

use FindBin;

# @INC construction...
# Standard paths are lib and lib/ChordPro/lib relative to the parent
# of the script directory.
# Directories in CHORDPRO_XLIBS follow, to augment the path.
# For example, to add custom delegates.
# Directories in CHORDPRO_XXLIBS are put in front, these can be used
# to overrule standard modules. For example, to provide a patches
# module to an installed kit. Caveat emptor.
my @xlibs;
BEGIN {
    for ( $ENV{CHORDPRO_XXLIBS} ) {
	push( @xlibs, split( $^O =~ /msw/ ? ";" : ":", $_ ) ) if $_;
    }
    push( @xlibs, "$FindBin::Bin/../lib", "$FindBin::Bin/../lib/ChordPro/lib",  );
    for ( $ENV{CHORDPRO_XLIBS} ) {
	push( @xlibs, split( $^O =~ /msw/ ? ";" : ":", $_ ) ) if $_;
    }
};
use lib @xlibs;

use ChordPro;
use ChordPro::Paths;
CP->pathprepend( "$FindBin::Bin", "$FindBin::Bin/.." );

# Package name.
my $my_package = 'ChordPro';
# Program name and version.
my $my_name = 'WxChordPro';
my $my_version = $ChordPro::VERSION;

my $options = app_options();

# Verify that we have an appropriate Wx version.
our $Wx_tng = 3.004;
our $Wx_min = $options->{wxtng} ? $Wx_tng : 0.9932;
unless ( eval { Wx->VERSION($Wx_min) } ) {
    my $md = ChordPro::Wx::WxUpdateRequired->new;
    $md->ShowModal;
    $md->Destroy;
    exit 1;
}
# Now it is safe to proceed.

# ChordPro::Wx::Main is the main entry of the program.
require ChordPro::Wx::Main;

if ( $Wx::VERSION < $Wx_tng) {
    # Cannot do Scintilla without Wx_tng;
    # $options->{stc} //= 0;
    # Cannot do WebView without Wx_tng;
    # $options->{webview} //= 0;
}

ChordPro::Wx::WxChordPro->run($options);

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
		      "logstderr",
		      'maximize',
		      'geometry=s',
		      'config=s',
		      'stc!',
		      'webview!',
		      'wxtng!',
		      'dark!',
		      'new',
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

package ChordPro::Wx::WxUpdateRequired;

# Dialog to be shown if Wx is not up to date.

use Wx qw[:everything];
use base qw(Wx::Dialog);
use strict;

sub new {
    my $self = shift->SUPER::new( undef, wxID_ANY,
				  "Update Required",
				  wxDefaultPosition, wxDefaultSize,
				  wxDEFAULT_DIALOG_STYLE|wxRESIZE_BORDER );

    # Main sizer.
    my $sz = Wx::BoxSizer->new(wxVERTICAL);
    # sz3: Icon (left), info lines (right side).
    my $sz3 = Wx::BoxSizer->new(wxHORIZONTAL);
    # sz4: Information lines, right side,
    my $sz4 = Wx::BoxSizer->new(wxVERTICAL);

    $sz->Add( $sz3, 0, wxEXPAND, 0 );
    $sz3->Add( $sz4, 0, wxBOTTOM|wxEXPAND|wxRIGHT|wxTOP, 20 );

    my $icon = ChordPro::Paths->get->findres( "chordpro-splash.png",
					      class => "icons" )
      || ChordPro::Paths->get->findres( "missing.png",
					class => "icons" );
    Wx::Image::AddHandler(Wx::PNGHandler->new);
    $sz3->Insert( 0,
		  Wx::StaticBitmap->new( $self, wxID_ANY,
					 Wx::Bitmap->new( $icon, wxBITMAP_TYPE_PNG) ),
		  0, 0, 0 );


    for ( Wx::StaticText->new( $self, wxID_ANY,
			       "Software Update Required" ) ) {
	$_->SetForegroundColour( Wx::Colour->new(0, 104, 217) );
	$_->SetFont( Wx::Font->new( 20, wxFONTFAMILY_DEFAULT,
				    wxFONTSTYLE_NORMAL, wxFONTWEIGHT_NORMAL,
				    0, "" ) );
	$sz4->Add( $_, 0, wxBOTTOM|wxTOP, 20 );
    }

    $sz4->Add( Wx::StaticText->new( $self, wxID_ANY,
				    "ChordPro requires Wx (wxPerl) ".
				    "version $::Wx_min or later." ),
	       0, wxTOP, 20 );

    $sz4->Add( Wx::StaticText->new( $self, wxID_ANY,
				    "You currently have Wx ".
				    "version $Wx::VERSION." ),
	       0, wxBOTTOM|wxTOP, 10 );

    # Bottom line (with hyperlink).
    for ( Wx::BoxSizer->new(wxHORIZONTAL) ) {
	$_->Add( Wx::StaticText->new( $self, wxID_ANY,
				      "Please consult the "),
		 0, wxALIGN_CENTER_VERTICAL, 0 );
	$_->Add( Wx::HyperlinkCtrl->new( $self, wxID_ANY,
					 " installation instructions ",
					 "https://www.chordpro.org/chordpro/chordpro-installation/",
					 wxDefaultPosition,
					 wxDefaultSize,
					 wxHL_DEFAULT_STYLE ),
		 0, wxALIGN_CENTER_VERTICAL, 0 );
	$_->Add( Wx::StaticText->new( $self, wxID_ANY,
				      " on the ChordPro web site." ),
		 0, wxALIGN_CENTER_VERTICAL, 0 );
	$sz4->Add( $_, 0, wxEXPAND, 0 );
    }

    # Dialog close button.
    for ( Wx::StdDialogButtonSizer->new() ) {
	for my $b ( Wx::Button->new( $self, wxID_EXIT, "" ) ) {
	    $b->SetDefault();
	    $_->Add( $b, 0, wxEXPAND, 0 );
	    $self->SetAffirmativeId( $b->GetId );
	}
	$_->Realize();
	$sz->Add( $_, 0, wxALIGN_RIGHT|wxALL, 20 );
    }

    $self->SetSizer($sz);
    $sz->Fit($self);
    $self->Layout();

    return $self;
}

=head1 NAME

wxchordpro - Wx-based GUI for ChordPro

=head1 SYNOPSIS

  wxchordpro [ options ] [ file ]

=head1 DESCRIPTION

B<wxchordpro> is the GUI for the ChordPro program. It allows
opening of files, make changes, and preview (optionally print) the
formatted result.

Visit the web site L<https://chordpro.org> for complete documentation.

=cut

