#! perl

package ChordPro::Wx::Utils;

use v5.26;
use utf8;
use Carp;
use feature qw( signatures );
no warnings "experimental::signatures";

use Exporter 'import';
our @EXPORT;

################ Constants ################

# Constants not (yet) in this version of Wx.

my %const =
  ( wxEXEC_HIDE_CONSOLE            => 0x0010,
    wxDIRP_SMALL                   => 0x8000, # wxPB_SMALL
    wxFLP_SMALL                    => 0x8000, # wxPB_SMALL
    wxRESERVE_SPACE_EVEN_IF_HIDDEN => 0x0002,
    wxID_EXECUTE		   => 0x1417,

    wxART_CLOSE			   => "wxART_CLOSE",
  );

no strict 'refs';

while ( my ( $sub, $value ) = each %const ) {
    *$sub = sub () { $value };
    push( @EXPORT, $sub );
}

use strict 'refs';

################ ################

sub panels {
    my @panels = qw( p_editor p_sbexport );
    wantarray ? @panels : \@panels;
}

push( @EXPORT, 'panels' );

# Create a menu bar.
#
# This is intended to be called by a panel, but the actual menu bar is
# attached to the top level frame. The callbacks are routed to the
# methods in the panel, if possible.

sub make_menubar {
    my ( $self, $ctl ) = @_;

    use Wx::Locale gettext => '_T';
    my $target = $Wx::wxTheApp->GetTopWindow;

    my $mb = Wx::MenuBar->new;

    for ( @$ctl ) {

	# [ wxID_FILE, [ ... ] ]

	my @data = @$_;
	my $id   = shift(@data);
	my $menu = pop(@data);
	my $text = shift(@data);

	$id = Wx::NewId if $id < 0;

	my $m = Wx::Menu->new;
	for my $item ( @$menu ) {

	    if ( !@$item ) {
		# []
		$m->AppendSeparator;
		next;
	    }

	    # [ wxID_NEW, "", "Create new", ..., "OnNew" ],

	    my @data = @$item;
	    my $id   = shift(@data);
	    my $cb   = pop(@data);
	    my $text = shift(@data);
	    my $tip  = shift(@data);

	    $id = Wx::NewId if $id < 0;

	    $m->Append( $id,
			_T($text // Wx::GetStockLabel($id)),
			$tip ? _T($tip) : "", @data );

	    my $code;
	    if ( $code = $self->can($cb) ) {
		# Reroute callbacks.
		Wx::Event::EVT_MENU( $target, $id,
				     sub { &$code( $self, $_[1] ) } );
	    }
	    elsif ( $code = $target->can($cb) ) {
		# Use parent callbacks.
		Wx::Event::EVT_MENU( $target, $id, $code );
	    }
	    else {
		$self->log("w", "No callback for $cb" );
	    }
	}

	# Add menu to menu bar.
	$mb->Append( $m, _T($text // Wx::GetStockLabel($id)) );
    }

    # Add menu bar.
    $target->SetMenuBar($mb);

    return $mb;
}

push( @EXPORT, 'make_menubar' );

################ ################

use ChordPro::Utils qw( is_msw is_macos );

sub savewinpos {
    my ( $win, $name ) = @_;
    $ChordPro::Wx::Config::state{windows}->{$name} =
      join( " ", $win->GetPositionXY, $win->GetSizeWH );
}

sub restorewinpos {
    my ( $win, $name ) = @_;
    $win = $Wx::wxTheApp->GetTopWindow if $name eq "main";

    my $t = $ChordPro::Wx::Config::state{windows}->{$name};
    if ( $t ) {
	my @a = split( ' ', $t );
	if ( is_msw || is_macos ) {
	    $win->SetSizeXYWHF( $a[0],$a[1],$a[2],$a[3], 0 );
	}
	else {
	    # Linux WM usually prevent placement.
	    $win->SetSize( $a[2],$a[3] );
	}
    }
}

push( @EXPORT, 'savewinpos', 'restorewinpos' );

################ ################

1;
