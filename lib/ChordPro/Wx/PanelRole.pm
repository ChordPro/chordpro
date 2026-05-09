#! perl

use v5.26;
use Object::Pad;
use utf8;

role ChordPro::Wx::PanelRole;

use Wx qw[:everything];
use Wx::Locale gettext => '_T';

use ChordPro::Files;
use ChordPro::Paths;
use ChordPro::Utils qw( demarkup plural :xp );
use ChordPro::Wx::Config;
use ChordPro::Wx::Utils;

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
    $wv = Wx::WebView::New( $self->{p_right},
			    wxID_ANY, "",
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
    $self->preview( [ $self->preview_tasks_args ] );
    $self->previewtooltip;
}

method OnPreviewClose($event) {
    return unless $self->{sw_lr}->IsSplit;
    $self->{sw_lr}->Unsplit(undef);
    $self->previewtooltip;
}

method OnPreviewLyricsOnly($event) {
    # Legacy menu shortcut: toggle the toolbar checkbox and preview.
    $self->{cb_task_lyrics_only}->SetValue(1)
      if $self->{cb_task_lyrics_only};
    $self->preview( [ $self->preview_tasks_args ] );
    $self->previewtooltip;
}

method OnPreviewNoDiagrams($event) {
    # Legacy menu shortcut: toggle the toolbar checkbox and preview.
    $self->{cb_task_no_diagrams}->SetValue(1)
      if $self->{cb_task_no_diagrams};
    $self->preview( [ $self->preview_tasks_args ] );
    $self->previewtooltip;
}

# Build the inline "Preview Tasks" section in the panel toolbar,
# inserted left of the Settings button. The section is enabled
# only while the preview pane is showing.
method setup_preview_tasks_bar() {
    my $sz = $self->{sz_toolbar};
    return unless $sz;

    # Outer (vertical) sizer: title on top, controls row below.
    my $outer = $self->{sz_preview_tasks} = Wx::BoxSizer->new(wxVERTICAL);

    # ---- Section title ----
    $self->{l_preview_tasks} = Wx::StaticText->new
      ( $self, wxID_ANY, _T("Preview Tasks"),
	wxDefaultPosition, wxDefaultSize, wxALIGN_CENTER_HORIZONTAL );
    $self->{l_preview_tasks}->SetForegroundColour(Wx::Colour->new(0, 104, 217));
    $self->{l_preview_tasks}->SetFont
      ( Wx::Font->new( 10, wxFONTFAMILY_DEFAULT,
		       wxFONTSTYLE_NORMAL, wxFONTWEIGHT_BOLD, 0, "" ) );
    $self->{l_preview_tasks}->SetToolTip
      (_T("Options that apply to the preview"));
    $outer->Add( $self->{l_preview_tasks}, 0,
		 wxALIGN_CENTER_HORIZONTAL|wxBOTTOM, 2 );

    # Inner (horizontal) sizer holds the actual task widgets.
    my $tb = Wx::BoxSizer->new(wxHORIZONTAL);
    $outer->Add( $tb, 0, wxEXPAND, 0 );

    # ---- Transpose ----
    $self->{l_xpose} = Wx::StaticText->new( $self, wxID_ANY, _T("Transpose") );
    $self->{l_xpose}->SetToolTip
      (_T("Transpose the song. Negative values transpose down."));
    $tb->Add( $self->{l_xpose}, 0,
	      wxALIGN_CENTER_VERTICAL|wxLEFT|wxRIGHT, 3 );

    $self->{sp_xpose} = Wx::SpinCtrl->new
      ( $self, wxID_ANY, "0", wxDefaultPosition, [ 65, -1 ],
	wxSP_ARROW_KEYS, -12, 12, 0 );
    $self->{sp_xpose}->SetToolTip
      (_T("Number of semitones to transpose. Negative is down."));
    $tb->Add( $self->{sp_xpose}, 0, wxALIGN_CENTER_VERTICAL, 0 );
    Wx::Event::EVT_SPINCTRL( $self, $self->{sp_xpose}->GetId,
			     $self->can("OnPreviewTaskChanged") );
    Wx::Event::EVT_TEXT( $self, $self->{sp_xpose}->GetId,
			 $self->can("OnPreviewTaskChanged") );

    $self->{ch_acc} = Wx::Choice->new
      ( $self, wxID_ANY, wxDefaultPosition, wxDefaultSize,
	[ _T("Auto"), _T("Sharps"), _T("Flats"), _T("Key") ] );
    $self->{ch_acc}->SetSelection(0);
    $self->{ch_acc}->SetToolTip(_T("Accidentals after transposing.\n".
				   "Auto: sharps when up, flats when down.\n".
				   "Key: use the song's transposed key."));
    $tb->Add( $self->{ch_acc}, 0, wxALIGN_CENTER_VERTICAL|wxLEFT, 3 );
    Wx::Event::EVT_CHOICE( $self, $self->{ch_acc}->GetId,
			   $self->can("OnPreviewTaskChanged") );

    $tb->Add( Wx::StaticLine->new( $self, wxID_ANY,
				   wxDefaultPosition, [ -1, 22 ],
				   wxLI_VERTICAL ),
	      0, wxALIGN_CENTER_VERTICAL|wxLEFT|wxRIGHT, 6 );

    # ---- Task checkboxes ----
    $self->{cb_task_no_diagrams} = Wx::CheckBox->new
      ( $self, wxID_ANY, _T("No diagrams") );
    $self->{cb_task_no_diagrams}->SetToolTip(_T("Suppress the chord diagrams"));
    $tb->Add( $self->{cb_task_no_diagrams}, 0,
	      wxALIGN_CENTER_VERTICAL|wxRIGHT, 5 );
    Wx::Event::EVT_CHECKBOX( $self, $self->{cb_task_no_diagrams}->GetId,
			     $self->can("OnPreviewTaskChanged") );

    $self->{cb_task_lyrics_only} = Wx::CheckBox->new
      ( $self, wxID_ANY, _T("Lyrics only") );
    $self->{cb_task_lyrics_only}->SetToolTip
      (_T("Only lyrics (no chords, ABC, LilyPond, ...)"));
    $tb->Add( $self->{cb_task_lyrics_only}, 0,
	      wxALIGN_CENTER_VERTICAL|wxRIGHT, 5 );
    Wx::Event::EVT_CHECKBOX( $self, $self->{cb_task_lyrics_only}->GetId,
			     $self->can("OnPreviewTaskChanged") );

    $self->{cb_task_decapo} = Wx::CheckBox->new
      ( $self, wxID_ANY, _T("Decapo") );
    $self->{cb_task_decapo}->SetToolTip
      (_T("Show the chords as they sound, eliminating the need for a capo setting"));
    $tb->Add( $self->{cb_task_decapo}, 0,
	      wxALIGN_CENTER_VERTICAL|wxRIGHT, 5 );
    Wx::Event::EVT_CHECKBOX( $self, $self->{cb_task_decapo}->GetId,
			     $self->can("OnPreviewTaskChanged") );

    # Placeholder for custom tasks; populated in refresh_preview_tasks_bar.
    $self->{sz_customtasks_bar} = Wx::BoxSizer->new(wxHORIZONTAL);
    $tb->Add( $self->{sz_customtasks_bar}, 0,
	      wxALIGN_CENTER_VERTICAL, 0 );

    # Final separator before the existing buttons.
    $tb->Add( Wx::StaticLine->new( $self, wxID_ANY,
				   wxDefaultPosition, [ -1, 22 ],
				   wxLI_VERTICAL ),
	      0, wxALIGN_CENTER_VERTICAL|wxLEFT|wxRIGHT, 6 );

    # Insert the section in front of the Settings button.
    # GetItemCount/GetItem aren't exposed on Wx::BoxSizer in this wxPerl;
    # GetChildren returns a list (not an arrayref) of Wx::SizerItem, so
    # collect it in list context.
    my @items = $sz->GetChildren;
    my $idx = scalar @items;	# default: append at end
    for ( my $i = 0; $i < @items; $i++ ) {
	my $w = eval { $items[$i]->GetWindow };
	if ( $w && $w == $self->{bmp_preferences} ) {
	    $idx = $i;
	    last;
	}
    }
    $sz->Insert( $idx, $outer, 0, wxALIGN_CENTER_VERTICAL, 0 );

    # Initialize from saved state.
    $state{"xpose_$_"} ||= 0
      for qw( enabled semitones accidentals );
    $self->{sp_xpose}->SetValue( $state{xpose_semitones} || 0 );
    $self->{ch_acc}->SetSelection( $state{xpose_accidentals} || 0 );

    $self->update_preview_tasks_state;
}

# (Re)populate the custom-tasks checkboxes. Safe to call when the
# preset list has changed (e.g. on first refresh, or after Settings).
method refresh_preview_tasks_bar() {
    return unless $self->{sz_customtasks_bar};

    # Drop existing custom checkboxes.
    my $i = 0;
    while ( my $cb = delete $self->{"cb_customtask_$i"} ) {
	$self->{sz_customtasks_bar}->Detach($cb);
	$cb->Destroy;
	$i++;
    }

    my $tasks = $state{presets}{tasks};
    if ( $tasks && %$tasks ) {
	my $index = 0;
	for my $task ( sort keys %$tasks ) {
	    my $cb = Wx::CheckBox->new
	      ( $self, wxID_ANY, $tasks->{$task}->{title} );
	    $cb->SetToolTip(_T("Custom task: ").$tasks->{$task}->{title});
	    $self->{"cb_customtask_$index"} = $cb;
	    $self->{sz_customtasks_bar}->Add
	      ( $cb, 0, wxALIGN_CENTER_VERTICAL|wxRIGHT, 5 );
	    Wx::Event::EVT_CHECKBOX( $self, $cb->GetId,
				     $self->can("OnPreviewTaskChanged") );
	    $index++;
	}
    }
    $self->{sz_toolbar}->Layout if $self->{sz_toolbar};
    $self->update_preview_tasks_state;
}

# Enable/disable the entire preview-tasks section based on whether
# the preview pane is currently showing.
method update_preview_tasks_state() {
    my $shown = $self->{sw_lr} && $self->{sw_lr}->IsSplit;
    for my $name ( qw( l_preview_tasks
		       l_xpose
		       sp_xpose
		       ch_acc
		       cb_task_no_diagrams
		       cb_task_lyrics_only
		       cb_task_decapo ) ) {
	$self->{$name}->Enable($shown) if $self->{$name};
    }
    my $i = 0;
    while ( my $cb = $self->{"cb_customtask_$i"} ) {
	$cb->Enable($shown);
	$i++;
    }
}

# Collect arguments from the toolbar controls. Also syncs the
# transpose state into %state so Preview.pm picks it up.
method preview_tasks_args() {
    my @args;
    return @args unless $self->{cb_task_no_diagrams}; # bar not built

    push( @args, "--no-chord-grids" )
      if $self->{cb_task_no_diagrams}->IsChecked;
    push( @args, "--lyrics-only",
		 "--define=delegates.abc.omit=1",
		 "--define=delegates.ly.omit=1" )
      if $self->{cb_task_lyrics_only}->IsChecked;
    push( @args, "--decapo" )
      if $self->{cb_task_decapo}->IsChecked;

    my $i = 0;
    while ( my $cb = $self->{"cb_customtask_$i"} ) {
	if ( $cb->IsChecked ) {
	    my $info = $state{presets}{tasks}{ lc $cb->GetLabel };
	    push( @args, "--config", $info->{file} ) if $info;
	}
	$i++;
    }

    # Sync transpose state for Preview.pm. See also Preview.pm.
    # Transpose is "enabled" iff the user picked a non-zero offset.
    my $semi = $self->{sp_xpose}->GetValue;
    $state{xpose_enabled}     = $semi ? 1 : 0;
    $state{xpose_semitones}   = $semi;
    $state{xpose_accidentals} = $self->{ch_acc}->GetSelection;

    return @args;
}

# Bound to all Preview-Tasks toolbar widgets. Marks the preview as
# stale so OnIdle picks it up if Live Preview is enabled and the
# preview pane is open.
method OnPreviewTaskChanged($event) {
    $state{editchanged}++;
}

method OnPreviewSave($event) {
    unless ( $self->prv && $self->prv->have_preview ) {
	# Generate a preview on the fly, without launching a viewer.
	$self->preview( [], noviewer => 1 );
    }
    if ( $self->prv && $self->prv->have_preview ) {
	return $self->prv->save;
    }
    Wx::MessageDialog->new( $self,
			    "No preview to save",
			    "No Preview",
			    wxOK | wxICON_ERROR )->ShowModal;
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
	fn_dirname($file), fn_basename($file),
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
	return $self->OnPreview($event)
	  unless $self->prv && $self->prv->have_preview;
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
    $self->update_preview_tasks_state;
    $self->panel_focus;
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
    $self->panel_focus;
    $self->panel_linenums( $mi->IsChecked );
}

method panel_focus() {
    return unless UNIVERSAL::can( $state{panel}, "set_focus" );
    $state{panel}->set_focus;
}

method panel_linenums( $b ) {
    return unless UNIVERSAL::can( $state{panel}, "showlinenumbers" );
    $state{panel}->showlinenumbers($b);
}

1;

