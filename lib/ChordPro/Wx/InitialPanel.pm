#! perl

use strict;
use warnings;
use utf8;

# Implementation of ChordPro::Wx::InitialPanel_wxg details.

package ChordPro::Wx::InitialPanel;

# ChordPro::Wx::SoongbookExport_wxg is generated by wxGlade and contains
# all UI associated code.

use parent qw( ChordPro::Wx::InitialPanel_wxg );

use Wx qw[:everything];
use Wx::Locale gettext => '_T';
use ChordPro::Wx::Utils;

sub new {
    my( $self, $parent, $id, $pos, $size, $style, $name ) = @_;
    $parent = undef              unless defined $parent;
    $id     = -1                 unless defined $id;
    $pos    = wxDefaultPosition  unless defined $pos;
    $size   = wxDefaultSize      unless defined $size;
    $name   = ""                 unless defined $name;

    $self = $self->SUPER::new( $parent, $id, $pos, $size, $style, $name );
    $self->Layout();
    return $self;

}

sub OnInitialNew {
    my ( $self, $event ) = @_;
    Wx::PostEvent( $self->GetParent,
		   Wx::CommandEvent->new( wxEVT_COMMAND_MENU_SELECTED,
					  wxID_NEW ) );
}

sub OnInitialOpen {
    my ( $self, $event ) = @_;
    Wx::PostEvent( $self->GetParent,
		   Wx::CommandEvent->new( wxEVT_COMMAND_MENU_SELECTED,
					  wxID_OPEN ) );
}

sub OnInitialExample {
    my ( $self, $event ) = @_;
    Wx::PostEvent( $self->GetParent,
		   Wx::CommandEvent->new( wxEVT_COMMAND_MENU_SELECTED,
					  $self->GetParent->wxID_HELP_EXAMPLE ) );
}

sub OnInitialSBexp {
    my ( $self, $event ) = @_;
    Wx::PostEvent( $self->GetParent,
		   Wx::CommandEvent->new( wxEVT_COMMAND_MENU_SELECTED,
					  $self->GetParent->wxID_EXPORT_FOLDER ) );
}

sub OnInitialSite {
    my ( $self, $event ) = @_;
    Wx::LaunchDefaultBrowser("https://www.chordpro.org/");
    $event->Skip;
}

sub OnInitialDocs {
    my ( $self, $event ) = @_;
    $self->OnHelp_ChordPro($event);
    $event->Skip;
}

1;
