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

method alert( $severity ) {
    $self->{bmb_messages}->SetBackgroundColour( $severity ? wxRED : wxGREEN )
      unless $self->{sw_tb}->IsSplit;
}

method setup_webview() {

    my $try;
    $wv = $self->{webview};
    return unless eval { use Wx::WebView; 1 };

    # WebView can only handle PDF on Windows with Edge backend.
    # Wx::WebView::IsBackendAvailable requires Wx 3.002.
    return if is_msw
      && ( $Wx::VERSION < 3.002 || !Wx::WebView::IsBackendAvailable("wxWebViewEdge") );

    $state{have_webview} = 1;		# Note: too early
    $wv = Wx::WebView::New( $self->{p_right},
			    wxID_ANY,
			    CP->findres( "chordpro-icon.png",
					 class => "icons" ),
			    wxDefaultPosition, wxDefaultSize,
			    is_msw ? "wxWebViewEdge" : ()
			  );
    $self->{sz_preview}->Replace( $self->{webview}, $wv, 1 );
    $self->{webview}->Destroy;
    $self->{webview} = $wv;
    $self->{sz_preview}->Layout;
}

# Create a menu bar.
#
# This is intended to be called by a panel, but the actual menu bar is
# attached to the top level frame. The callbacks are routed to the
# methods in the panel, if possible.

method make_menubar($ctl) {

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

    # Append the tasks.
    my $menu = $mb->FindMenu("Tasks");
    $menu = $mb->GetMenu($menu);
    # Append separator.
    $menu->AppendSeparator if @{$state{tasks}};
    for my $task ( @{$state{tasks} } ) {
	my ( $desc, $file ) = @$task;
	my $id = Wx::NewId();
	# Append to the menu.
	$menu->Append( $id, $desc, _T("Custom task: ").$desc );
	Wx::Event::EVT_MENU
	    ( $self->GetParent, $id,
	      sub { $self->preview( [ "--config", $file ] ) }
	    );
    }

    # Add menu bar.
    $target->SetMenuBar($mb);

    return $mb;
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
    $id = Wx::NewId;
    $menu->Append( $id, "Insert runtime information", "", Wx::wxITEM_NORMAL );
    Wx::Event::EVT_MENU( $self, $id, $self->can("OnMessagesRuntimeInfo") );
    Wx::Event::EVT_CONTEXT_MENU( $self->{t_messages},
				 sub { $_[0]->PopupMenu( $menu,
							 Wx::wxDefaultPosition ) } );

}

method unsplit() {
    $self->{sw_lr}->Unsplit(undef);
    $self->{sw_tb}->Unsplit(undef);
}

################ Virtual Methods ################

method name();
method check_source_saved();
method check_preview_saved();
method save_preferences();

################ Event Handlers (alphabetic order) ################

method OnHelp_DebugInfo($event) {
    $state{debuginfo} = wxTheApp->GetTopWindow->GetMenuBar->FindItem($event->GetId)->IsChecked;
}

method OnNew($event) {
    return unless $self->GetParent->check_saved;
    $self->GetParent->select_mode("initial");
}

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
    use ChordPro::Wx::PreferencesDialog;
    unless ( $self->{d_prefs} ) {
	$self->{d_prefs} = ChordPro::Wx::PreferencesDialog->new($self, -1, "Preferences");
	restorewinpos( $self->{d_prefs}, "prefs" );
    }
    else {
	$self->{d_prefs}->refresh;
    }
    my $ret = $self->{d_prefs}->ShowModal;
    savewinpos( $self->{d_prefs}, "prefs" );
    return unless $ret == wxID_OK;

    $self->GetParent->save_preferences;
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

    use ChordPro::Wx::RenderDialog;
    my $d = $self->{d_render} ||= ChordPro::Wx::RenderDialog->new($self, -1, "Tasks");
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
    $self->log( 'I', $self->GetParent->aboutmsg );
    $self->alert(0);
}

method OnMessagesSave($event) {
    my $conf = Wx::ConfigBase::Get;
    my $file = $state{messages}{savedas} // "";
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
	$self->log( 'S',  "Messages saved." );
	$self->{t_messages}->SaveFile($file);
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
    if ( $self->{sw_lr}->IsSplit ) {
	$self->{bmb_preview}->SetToolTip(_T("Hide preview"));
    }
    else {
	$self->{bmb_preview}->SetToolTip(_T("Generate and show preview"));
    }
}

method messagestooltip() {
    if ( $self->{sw_tb}->IsSplit ) {
	$self->{bmb_messages}->SetToolTip(_T("Hide messages"));
    }
    else {
	$self->{bmb_messages}->SetToolTip(_T("Show messages"));
    }
}

1;

