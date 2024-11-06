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
  (
  );

no strict 'refs';

while ( my ( $sub, $value ) = each %const ) {
    *$sub = sub () { $value };
    push( @EXPORT, $sub );
}

use strict 'refs';

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

sub panels {
    my @panels = qw( p_editor p_sbexport );
    wantarray ? @panels : \@panels;
}

push( @EXPORT, 'panels' );

################ ################

