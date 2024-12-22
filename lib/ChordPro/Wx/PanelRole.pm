#! perl

use v5.26;
use Object::Pad;
use utf8;

role ChordPro::Wx::PanelRole;

use Wx qw[:everything];
use Wx::Locale gettext => '_T';

use ChordPro::Wx::Config;
use ChordPro::Wx::Utils;
use ChordPro::Utils qw( demarkup is_macos is_msw plural );
use ChordPro::Paths;

use File::Basename;

# Either Wx::WebView or Wx::StaticText.
field $wv			:accessor;

# Wx::WebView.
field $prv			:mutator;

################ API Functions ################

# The logger is set up by the refresh call!

method setup_logger() {
    return if $state{logstderr};
    Wx::Log::SetActiveTarget( Wx::LogTextCtrl->new( $self->{t_messages} ) );
}

method log( $level, @msg ) {
    wxTheApp->GetTopWindow->log( $level, @msg );
    $self->alert(1) if $level =~ /WEF/;
}

method alert( $severity, $message = "Click Messages to see diagnostic information" ) {
    return if $self->{sw_tb}->IsSplit;
    state $id = wxID_ANY;
    if ( $id == wxID_ANY ) {
	$id = Wx::NewId;
	$self->{w_infobar}->AddButton( $id, "Messages");
	$self->{w_infobar}->AddButton( wxID_CLOSE );
	Wx::Event::EVT_BUTTON( $self->{w_infobar}, $id,
			       sub { $self->OnWindowMessages($_[1]) } );
    }
    $self->{w_infobar}->ShowMessage( $message, wxICON_INFORMATION);
}

method setup_webview() {

    my $try;
    $wv = $self->{webview};
    return unless eval { require Wx::WebView; 1 };

    # WebView can only handle PDF on Windows with Edge backend.
    # Wx::WebView::IsBackendAvailable requires Wx 3.002.
    return if is_msw
      && ( $Wx::VERSION < 3.002 || !Wx::WebView::IsBackendAvailable("wxWebViewEdge") );

    $state{have_webview} = 1;		# Note: too early
    my $default = CP->findres( "chordpro-icon.png",
			       class => "icons" );
    $default = "file://" . $default unless is_msw;
    $wv = Wx::WebView::New( $self->{p_right},
			    wxID_ANY, $default,
			    wxDefaultPosition, wxDefaultSize,
			    is_msw ? "wxWebViewEdge" : ()
			  );
    $self->{sz_preview}->Replace( $self->{webview}, $wv, 1 );
    $self->{webview}->Destroy;
    $self->{webview} = $wv;
    $self->{sz_preview}->Layout;
}

method setup_messages_ctxmenu() {

    # Context menu for message area.
    my $menu = Wx::Menu->new;
    my $id = Wx::NewId;
    $menu->Append( $id, "Clear the message area", "", Wx::wxITEM_NORMAL );
    Wx::Event::EVT_MENU( $self, $id, $self->can("OnMessagesClear") );
    $id = Wx::NewId;
    $menu->Append( $id, "Save the messages to a file", "", Wx::wxITEM_NORMAL );
    Wx::Event::EVT_MENU( $self, $id, $self->can("OnMessagesSave") );
    Wx::Event::EVT_CONTEXT_MENU( $self->{t_messages},
				 sub { $_[0]->PopupMenu( $menu,
							 Wx::wxDefaultPosition ) } );

}

method unsplit() {
    $self->{sw_lr}->Unsplit(undef);
    $self->{sw_tb}->Unsplit(undef);
}

method prepare_annotations() {
    return unless $state{have_stc};
    $self->{t_editor}->prepare_annotations;
}

method add_annotation( $line, $msg ) {
    return unless $state{have_stc};
    $self->{t_editor}->add_annotation( $line, $msg );
}

method refresh_messages {
    $self->{t_messages}->SetFont( Wx::Font->new($preferences{msgsfont}) );
}

################ Virtual Methods ################

method name();
method check_source_saved();
method check_preview_saved();
method save_preferences();
method update_preferences();

################ Event Handlers (alphabetic order) ################

method OnHelp_DebugInfo($event) {
    $state{debuginfo} = wxTheApp->GetTopWindow->GetMenuBar->FindItem($event->GetId)->IsChecked;
}

#method OnNew($event) {
#    return unless $self->GetParent->check_saved;
#    $self->GetParent->select_mode("initial");
#}

method OnOpen($event) {
    # Let the parent handle this one.
    # I would have expected a Skip to be sufficient, but then nothing happens.
    # Explicitly posting an event, e.g.
    # Wx::PostEvent( wxTheApp->GetTopWindow,
    # 		   Wx::CommandEvent->new( wxEVT_COMMAND_MENU_SELECTED,
    # 					  wxID_OPEN ) );
    # ends up here, not in the parent, so we have a nice loop.
    # This is the only place where we violate our principle to not call
    # event handlers explicitly...
    $self->GetParent->OnOpen($event);
}

method OnPreferences($event) {
    # Dispatch to Main.
    Wx::PostEvent( $self->GetParent,
		   Wx::CommandEvent->new
		   ( wxEVT_COMMAND_MENU_SELECTED, wxID_PREFERENCES) );
}

method OnPreview($event) {		# for menu
    $self->preview( [] );
    $self->previewtooltip;
}

method OnPreviewClose($event) {
    return unless $self->{sw_lr}->IsSplit;
    $self->{sw_lr}->Unsplit(undef);
    $self->previewtooltip;
}

method OnPreviewLyricsOnly($event) {
    $self->preview( [ '--lyrics-only' ] );
    $self->previewtooltip;
}

method OnPreviewMore($event) {

    #               C      D      E  F      G      A        B C
    state @xpmap = qw( 0 1  1 2 3  3 4  5 6  6 7 8  8 9 10 10 11 12 );
    state @sfmap = qw( 0 7 -5 2 9 -3 4 -1 6 -6 1 8 -4 3 10 -2  5 0  );

    unless ( $self->{d_render} ) {
	require ChordPro::Wx::RenderDialog;
	$self->{d_render} = ChordPro::Wx::RenderDialog->new
	  ( $self, wxID_ANY, "Tasks" );
	restorewinpos( $self->{d_render}, "render" );
    }
    else {
	$self->{d_render} ->refresh;
    }

    my $d = $self->{d_render};
    my $ret = $d->ShowModal;
    return unless $ret == wxID_OK;

    my @args;
    if ( $d->{cb_task_no_diagrams}->IsChecked ) {
	push( @args, "--no-chord-grids" );
    }
    if ( $d->{cb_task_lyrics_only}->IsChecked ) {
	push( @args, "--lyrics-only",
	      "--define=delegates.abc.omit=1",
	      "--define=delegates.ly.omit=1" );
    }
    if ( $d->{cb_task_decapo}->IsChecked ) {
	push( @args, "--decapo" );
    }

    # Transpose.
    my $xpose_from = $xpmap[$d->{ch_xpose_from}->GetSelection];
    my $xpose_to   = $xpmap[$d->{ch_xpose_to  }->GetSelection];
    my $xpose_acc  = $d->{ch_acc}->GetSelection;
    my $n = $xpose_to - $xpose_from;
    $n += 12 if $n < 0;
    $n += 12 if $xpose_acc == 1; # sharps
    $n -= 12 if $xpose_acc == 2; # flats

    push( @args, "--transpose=$n" );

    my $i = 0;
    for ( @{$state{tasks}} ) {
	if ( $d->{"cb_customtask_$i"}->IsChecked ) {
	    push( @args, "--config", $_->[1] );
	}
	$i++;
    }
    $self->preview( \@args  );
    $self->previewtooltip;
}

method OnPreviewNoDiagrams($event) {
    $self->preview( [ '--no-chord-grids' ] );
    $self->previewtooltip;
}

method OnPreviewSave($event) {
    return unless $self->prv;
    $self->prv->save;
}

method OnSashLRChanged($event) {
    $state{sash}{$self->panel."_lr"} = $self->{sw_lr}->GetSashPosition;
}

method OnSashTBChanged($event) {
    $state{sash}{$self->panel."_tb"} = $self->{sw_tb}->GetSashPosition;
}

method OnShowMessages($event) {
    $self->OnWindowMessages($event);
}

method OnShowPreview($event) {		# for button
    $self->{sw_lr}->IsSplit
      ? $self->OnPreviewClose($event)
      : $self->OnPreview($event);
}

method OnWindowMessages($event) {
    if ( $self->{sw_tb}->IsSplit ) {
	$state{sash}{$self->panel."_tb"} = $self->{sw_tb}->GetSashPosition;
	$self->{sw_tb}->Unsplit(undef);
    }
    else {
	$self->{bmb_messages}->SetBackgroundColour(wxNullColour);
	$self->{sw_tb}->SplitHorizontally( $self->{p_top},
					   $self->{p_bottom},
					   $state{sash}{$self->panel."_tb"} // 0 );
    }
    $self->messagestooltip;
}

method OnMessagesClear($event) {
    $self->{t_messages}->Clear;
}

method OnMessagesRuntimeInfo($event) {
    $self->log( 'I', "---- Runtime Information ----\n" . $self->GetParent->aboutmsg );
    $self->log( 'I', "---- End of Runtime Information ----\n" );
}

method OnMessagesSave($event) {
    my $conf = Wx::ConfigBase::Get;
    my $file = $state{messages}{savedas} // "";

    # Starting the dialog and cancel it is now the official way to get
    # the runtime info into the log messages :).
    $self->OnMessagesRuntimeInfo($event);

    my $fd = Wx::FileDialog->new
      ( $self,
	_T("Choose file to save in"),
	"",
	$file,
	"*",
	wxFD_SAVE|wxFD_OVERWRITE_PROMPT );

    my $ret = $fd->ShowModal;
    if ( $ret == wxID_OK ) {
	$file = $fd->GetPath;
	$self->{t_messages}->SaveFile($file);
	$self->log( 'S',  "Messages saved." );
	$state{messages}{savedas} = $file;
    }

    $fd->Destroy;
    return $ret;
}

method OnWindowPreview($event) {
    if ( $self->{sw_lr}->IsSplit ) {
	$state{sash}{$self->panel."_lr"} = $self->{sw_lr}->GetSashPosition;
	$self->{sw_lr}->Unsplit(undef);
    }
    else {
	$self->{sw_lr}->SplitVertically( $self->{p_left},
					 $self->{p_right},
					 $state{sash}{$self->panel."_lr"} // 0 );
    }
    $self->previewtooltip;
}

method previewtooltip() {
    my $mb = wxTheApp->GetTopWindow->GetMenuBar;
    my $mi = $mb->FindItem($mb->FindMenuItem("View","Preview Panel"));
    if ( $self->{sw_lr}->IsSplit ) {
	$self->{bmb_preview}->SetToolTip(_T("Hide the preview\nUse ".
					    kbdkey("Ctrl-P").
					    " to refresh the preview"));
	$mi->Check(1);
    }
    else {
	$self->{bmb_preview}->SetToolTip(_T("Generate and show a new preview"));
	$mi->Check(0);
    }
}

method messagestooltip() {
    my $mb = wxTheApp->GetTopWindow->GetMenuBar;
    my $mi = $mb->FindItem($mb->FindMenuItem("View","Messages Panel"));
    if ( $self->{sw_tb}->IsSplit ) {
	$self->{bmb_messages}->SetToolTip(_T("Hide the messages"));
	$mi->Check(1);
    }
    else {
	$self->{bmb_messages}->SetToolTip(_T("Show the messages"));
	$mi->Check(0);
    }
    $self->{w_infobar}->Dismiss if $self->{w_infobar}->IsShown;
}

1;

