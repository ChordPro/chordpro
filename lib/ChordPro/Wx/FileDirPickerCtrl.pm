#! perl

use v5.26;
use Object::Pad;
use utf8;

use Wx ':panel';

class ChordPro::Wx::FileDirPickerCtrl
  :repr(HASH)
  :isa(Wx::Panel);

use Wx ':everything';
use ChordPro::Wx::Config;
use ChordPro::Wx::Utils;
use File::Basename;

field $text     = "";
field $textctrl;
field $picker;
field $picker_event;

my @args;

sub BUILDARGS {
    my $class = shift;

    my ( $parent, $id, $path, $message, $wildcard, $new ) = @args = @_;

    # Args for SUPER::new.
    ( $parent, $id, wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL );
}

BUILD {
    my ( $parent, $id, $path, $message, $wildcard, $new ) = @args;

    if ( $wildcard eq "" && !$new ) {
	$picker = Wx::DirDialog->new( $self, $message,
				      $path,
				      wxDD_DIR_MUST_EXIST
				    );
	$picker_event = Wx::FileDirPickerEvent->new
	  ( wxEVT_COMMAND_DIRPICKER_CHANGED, $self->GetId );
    }
    else {
	$picker = Wx::FileDialog->new( $self, $message,
				       dirname($path), basename($path),
				       $wildcard || $state{ffilters},
				       $new
				       ? (wxFD_SAVE|wxFD_OVERWRITE_PROMPT)
				       : (wxFD_OPEN|wxFD_FILE_MUST_EXIST)
				     );
	$picker_event = Wx::FileDirPickerEvent->new
	  ( wxEVT_COMMAND_FILEPICKER_CHANGED, $self->GetId );
    }

    $picker_event->SetEventObject($self);

    $textctrl = Wx::TextCtrl->new( $self, wxID_ANY,
				   "",
				   wxDefaultPosition,
				   wxDefaultSize,
				   0|wxTE_READONLY
				 );

    my $browse = Wx::Button->new( $self, wxID_ANY, "Browse",
				  wxDefaultPosition, wxDefaultSize,
				  0 );

    my $sizer = Wx::BoxSizer->new(wxHORIZONTAL);
    $sizer->Add( $textctrl, 1, wxEXPAND|wxRIGHT, 5 );
    $sizer->Add( $browse, 0, wxLEFT|wxRIGHT, 5 );
    $sizer->Layout;

    Wx::Event::EVT_TEXT( $self, $textctrl->GetId,
			 sub { $self->OnTextChanged($_[1]) } );
    Wx::Event::EVT_SET_FOCUS( $textctrl,
			      sub { $self->OnTextFocusIn($_[1]) } );
    Wx::Event::EVT_KILL_FOCUS( $textctrl,
			      sub { $self->OnTextFocusOut($_[1]) } );

    Wx::Event::EVT_BUTTON( $self, $browse->GetId,
			   sub { $self->OnDialog($_[1]) } );

    $self->SetSizer($sizer);
    $sizer->Fit($self);
    $self->Layout;
}

################ Widget Accessors ################

method GetPath() {
    $text;
}

method SetPath($p) {
    $picker->SetPath( $text = $p );
    ellipsize( $textctrl, text => $text,
	       type => wxELLIPSIZE_START );
}

################ Event Handlers ################

method OnDialog($e) {
    my $ret = $picker->ShowModal;
    return unless $ret == wxID_OK;
    $text = $picker->GetPath;
    ellipsize( $textctrl, text => $text,
	       type => wxELLIPSIZE_START );
    $self->ProcessEvent($picker_event);
}

method OnTextChanged($e) {
    $text = $textctrl->GetValue;
    $picker->SetPath($text);
    ellipsize( $textctrl, text => $text,
	       type => wxELLIPSIZE_START );
}

field $t;
method OnTextFocusIn($e) {
    $textctrl->ChangeValue( $t = $text );
}
method OnTextFocusOut($e) {
    $textctrl->SetValue($text);
    $self->ProcessEvent($picker_event) unless $t eq $text;
}

################

1;
