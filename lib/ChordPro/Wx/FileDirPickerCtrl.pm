#! perl

use v5.26;
use Object::Pad;
use utf8;

use Wx ':panel';

class ChordPro::Wx::FileDirPickerCtrl
  :repr(HASH)
  :isa(Wx::Panel);

use Wx ':everything';
use ChordPro::Wx::Utils;
use File::Basename;

field $parent;
field $id;
field $pos;
field $size;
field $style;

field $path     = "";
field $text     = "";
field $message  = "";
field $wildcard = "";

field $textctrl;
field $picker :accessor;
field $browse :accessor;
field $sizer;
field $widget :accessor;

my @args;

sub BUILDARGS {
    my $class = shift;

    my ( $parent, $id, $path, $message, $wildcard ) = @args = @_;

    # Args for SUPER::new.
    ( $parent, $id, wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL );
}

ADJUSTPARAMS ( $params ) {

    ( $parent, $id, $path, $message, $wildcard ) = @args;

    if ( $wildcard eq "" ) {
	$picker = Wx::DirDialog->new( $self, $message,
				      $path,
				      wxDD_DIR_MUST_EXIST
				    );
    }
    else {
	$picker = Wx::FileDialog->new( $self, $message,
				       basename($path),
				       $path,
				       $wildcard,
				       wxFD_OPEN|wxFD_FILE_MUST_EXIST
				     );
    }

    $textctrl = Wx::TextCtrl->new( $self, wxID_ANY,
				   "",
				   wxDefaultPosition,
				   wxDefaultSize,
				   0, # |wxTE_READONLY ?
				 );

    $browse = Wx::Button->new( $self, wxID_ANY, "Browse",
			       wxDefaultPosition, wxDefaultSize,
			       0 );

    $sizer = Wx::BoxSizer->new(wxHORIZONTAL);
    $sizer->Add( $textctrl, 1, wxEXPAND|wxRIGHT, 5 );
    $sizer->Add( $browse, 0, 5, wxLEFT|wxRIGHT );
    $sizer->Layout;

    Wx::Event::EVT_TEXT( $self, $textctrl->GetId,
			 sub { $self->OnTextChanged($_[1]) } );
    Wx::Event::EVT_SET_FOCUS( $textctrl,
			      sub { $self->OnTextFocusIn($_[1]) } );
    Wx::Event::EVT_KILL_FOCUS( $textctrl,
			      sub { $self->OnTextFocusOut($_[1]) } );

    Wx::Event::EVT_BUTTON( $self, $browse->GetId,
			   sub { $self->OnDialog($_[1]) } );

    $self->SetSizer($widget = $sizer);
    $sizer->Fit($self);
    $self->Layout;

    $self;
}

################

method GetPath() { $picker->GetPath }
method SetPath($p) {
    $picker->SetPath( $text = $p );
    ellipsize( $textctrl, text => $text,
	       type => wxELLIPSIZE_START );
}

################

method OnDialog($e) {
    my $ret = $picker->ShowModal;
    return unless $ret == wxID_OK;
    $text = $path = $picker->GetPath;
    ellipsize( $textctrl, text => $text,
	       type => wxELLIPSIZE_START );
}

method OnDirChanged($e) {
    warn("OnDirChanged not implemented\n");
}
method OnFileChanged($e) {
    warn("OnFileChanged not implemented\n");
}
method OnTextChanged($e) {
    $text = $textctrl->GetText;
    $picker->SetPath($text);
    ellipsize( $textctrl, text => $text,
	       type => wxELLIPSIZE_START );
}
method OnTextFocusIn($e) {
    $textctrl->ChangeValue($text);
}
method OnTextFocusOut($e) {
    $textctrl->SetValue($text);
}

1;