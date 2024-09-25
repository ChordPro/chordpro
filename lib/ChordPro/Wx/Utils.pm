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

  );

no strict 'refs';

while ( my ( $sub, $value ) = each %const ) {
    *$sub = sub () { $value };
    push( @EXPORT, $sub );
}

use strict 'refs';

################ ################

sub panels {
    my @panels = qw( p_edit p_sbexport p_msg p_preview );
    wantarray ? @panels : \@panels;
}

push( @EXPORT, 'panels' );

################ ################

1;
