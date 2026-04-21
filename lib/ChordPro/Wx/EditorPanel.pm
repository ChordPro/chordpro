#! perl

use v5.26;
use Object::Pad;
use utf8;

class ChordPro::Wx::EditorPanel
  :repr(HASH)
  :does( ChordPro::Wx::PanelRole )
  :isa( ChordPro::Wx::EditorPanel_wxg );

use Wx qw[:everything];
use Wx::Locale gettext => '_T';

use ChordPro::Files;
use ChordPro::Wx::Config;
use ChordPro::Wx::Utils;
use ChordPro::Utils qw( max demarkup plural );
use ChordPro::Paths;

# WhoamI
field $panel :accessor = "editor";

# Just fill in the defaults.
sub BUILDARGS( $class, $parent=undef, $id=wxID_ANY,
	   $pos=wxDefaultPosition, $size=wxDefaultSize,
	   $style=0, $name="" ) {
   return( $parent, $id, $pos, $size, $style, $name );
}

BUILD {
    # By default the TextCtrl on MacOS substitutes smart quotes and dashes.
    # Note that OSXDisableAllSmartSubstitutions requires an augmented
    # version of wxPerl.
    $self->{t_editor}->OSXDisableAllSmartSubstitutions;

    # Setup WebView, if possible.
    $self->setup_webview if $::options->{webview}//1;

    # Single pane.
    $self->unsplit;

    $self;
}

################ ################

method name() { "Editor" }

################ API Functions ################

method refresh() {

    $self->setup_logger;

    $self->update_menubar( M_EDITOR );

    # Flush pending messages.
    if ( $state{msgs} ) {
	$self->log( 'I', $_ ) for @{$state{msgs}};
	$state{msgs} = [];
    }
    $self->log( 'I', "Using " .
		( $state{have_stc}
		  ? "styled" : "basic") . " text editor" );

    $state{have_webview} = ref($self->{webview}) eq 'Wx::WebView';
    $self->log( 'I', "Using " .
		( $state{have_webview}
		  ? "embedded" : "external") . " PDF viewer" );

    if ( $state{from_songbook} ) {
	$self->{bmp_songbook}->Show(1);
    }
    else {
	$self->{bmp_songbook}->Show(0);
    }
    $self->{sz_toolbar}->Layout;

    my $mod = $self->{t_editor}->IsModified;
    $self->{t_editor}->refresh;

    $self->setup_messages_ctxmenu;
    $self->previewtooltip;
    $self->messagestooltip;
    $self->{t_editor}->SetModified($mod);

    $self->refresh_messages;

    if ( $state{have_stc} ) {
	Wx::Event::EVT_STC_CHARADDED( $self, $self->{t_editor}->GetId,
				      $self->can("OnCharAdded") );
	Wx::Event::EVT_STC_CLIPBOARD_PASTE( $self, $self->{t_editor}->GetId,
					    $self->can("OnClipBoardPaste") );
    }
    $self->set_focus;
}

method openfile( $file, $checked=0, $actual=undef ) {
    $actual //= $file;

    # Bypass test when already checked. TODO?
    unless ( $checked || fs_test( 'fr', $file ) ) {
	$self->log( 'W',  "Error opening $file: $!",);
	my $md = Wx::MessageDialog->new
	  ( $self,
	    "Error opening $file: $!",
	    "File open error",
	    wxOK | wxICON_ERROR );
	my $ret = $md->ShowModal;
	$md->Destroy;
	return;
    }
    if ( my $f = fs_load($file) ) {

	# Check for filelist.
	if ( $f->[0] =~ m;^//\s*chordpro\s+songbook;i ) {
	    $f->[0] = $file;
	    return $self->GetParent->select_mode("sbexport")->load_filelist($f)
	}

	# This has the (desired) sideeffect that all newlines
	# are now \n .
	$self->{t_editor}->SetText(join("\n",@$f)."\n");
	$self->{t_editor}->DiscardEdits;
    }
    else {
	$self->log( 'W',  "Error opening $file: $!",);
	my $md = Wx::MessageDialog->new
	  ( $self,
	    "Error opening $file: $!",
	    "File load error",
	    wxOK | wxICON_ERROR );
	$md->ShowModal;
	$md->Destroy;
	return;
    }
    #### TODO: Get rid of selection on Windows

    if ( $state{have_stc} ) {
	my $stc = $self->{t_editor};
	my @t = split( /\n/, $stc->GetText );
	my $max = -1;
	for ( @t ) {
	    $max = max( $max, length($_) );
	}
	$stc->SetScrollWidth($max);
	$stc->SetScrollWidthTracking(1)
	  if $stc->can("SetScrollWidthTracking");
    }
    else {
	$self->{t_editor}->ShowPosition(0); # doesn't work?
    }
    $self->{t_editor}->SetFocus;

    if ( $actual =~ /^\s+.*\s+$/ ) {
	$state{currentfile} = undef;
    }
    else {
	$state{currentfile} = $actual;
	use List::Util qw(uniq);
	@{$state{recents}} = uniq( $file, @{$state{recents}} );
    }
    if ( $self->{t_editor}->GetText =~ /^\{\s*t(?:itle)?[: ]+([^\}]*)\}/m ) {
	my $title = demarkup($1);
	my $n = $self->{t_editor}->GetLineCount;
	$self->log( 'S', "Loaded: $title (" . plural($n, " line") . ")");
	$self->{l_status}->SetLabel($title);
	$self->{l_status}->SetToolTip($file);
    }
    else {
	my $n = $self->{t_editor}->GetLineCount;
	$self->{l_status}->SetLabel(fn_basename($file));
	$self->{l_status}->SetToolTip($file);
	$self->log( 'S', "Loaded: $file (" . plural($n, " line") . ")");
    }
    if ( $state{have_stc} && $preferences{expert} ) {
	$self->log( 'S', "Line endings: " .
		    (qw(CRLF CR LF))[$self->{t_editor}->GetEOLMode] );
    }
    $self->GetParent->SetTitle( $state{windowtitle} = $actual);

    if ( $self->{sw_lr}->IsSplit ) {
	$self->{sw_lr}->Unsplit(undef);
	$self->previewtooltip;
    }
    if ( $self->{sw_tb}->IsSplit ) {
	$self->{sw_tb}->Unsplit(undef);
	$self->messagestooltip;
    }
    $self->prv->discard if $self->prv;

    return 1;
}

method newfile( $file = undef ) {
    my $title = "New Song";

    if ( defined($file) ) {
	my $t = $file;
	$t =~ s/\.\w+//;
	$t =~ s/_/ /g;
	$t =~ s/\s+/ /g;
	$t =~ s/^\s+//;
	$t =~ s/\s+$//;
	$title = join( " ", map { ucfirst($_) } split( ' ', $t ) );
    }
    else {
	delete $state{currentfile};
    }

    $state{windowtitle} = $title;
    $self->{l_status}->SetLabel($title);
    my $content = "{title: $title}";
    $self->{t_editor}->SetText($content);

    my $file = $preferences{tmplfile};
    if ( $file && $preferences{enable_tmplfile} ) {
	$self->log( 'I', "Loading template $file" );
	if ( fs_test( fr => $file ) && $self->{t_editor}->LoadFile($file) ) {
	    $content = "";
	}
	else {
	    $self->log( 'E', "Cannot open template $file: $!" );
	}
    }
    else {
	$content = "{title: $title}";
    }

    for ( $self->{t_editor} ) {
	$content =~ s/[\n\r]*\Z//;
	$_->SetText($content) if length($content);
	$_->DocumentEnd;
	$_->NewLine;
	$_->SetSelection(0,0);
	$_->SetFocus;
    }

    $self->log( 'S', "New song: $title");
    if ( $state{have_stc} && $preferences{expert} ) {
	$self->log( 'S', "Line endings: " .
		    (qw(CRLF CR LF))[$self->{t_editor}->GetEOLMode] );
    }
    $state{windowtitle} = $title;
    $self->{l_status}->SetLabel($title);
    $self->{l_status}->SetToolTip($state{currentfile});
    if ( $self->{sw_lr}->IsSplit ) {
	$self->{sw_lr}->Unsplit(undef);
	$self->previewtooltip;
    }
    if ( $self->{sw_tb}->IsSplit ) {
	$self->{sw_tb}->Unsplit(undef);
	$self->messagestooltip;
    }
    $self->prv->discard if $self->prv;

    1;
}

method check_source_saved() {
    # Do we need saving?
    return 1 unless ( $self->{t_editor} && $self->{t_editor}->IsModified );

    # Do we have a filename?
    if ( $state{currentfile} ) {
	my $md = Wx::MessageDialog->new
	  ( $self,
	    "File " . fn_basename($state{currentfile}) . " has been changed.\n".
	    "Do you want to save your changes?",
	    "File has changed",
	    0 | wxCANCEL | wxYES_NO | wxYES_DEFAULT | wxICON_QUESTION );
	my $ret = $md->ShowModal;
	$md->Destroy;
	return if $ret == wxID_CANCEL;
	if ( $ret == wxID_YES ) {
	    $self->save_file( $state{currentfile} );
	}
	else {
	    $self->{t_editor}->SetModified(0);
	}
    }
    else {
	my $md = Wx::MessageDialog->new
	  ( $self,
	    "Do you want to save your changes?",
	    "Contents has changed",
	    0 | wxCANCEL | wxYES_NO | wxYES_DEFAULT | wxICON_QUESTION );
	my $ret = $md->ShowModal;
	$md->Destroy;
	return if $ret == wxID_CANCEL;
	if ( $ret == wxID_YES ) {
	    $self->save_file;
	}
	else {
	    $self->{t_editor}->SetModified(0);
	}
    }
    return 1;
}

method save_file( $file = undef ) {
    while ( 1 ) {
	unless ( defined $file && $file ne "" ) {
	    my $cf = $state{currentfile} // "Untitled";
	    my $fd = Wx::FileDialog->new
	      ($self, _T("Choose output file"),
	       fn_dirname($cf), fn_basename($cf),
	       "*".$preferences{chordproext},
	       0|wxFD_SAVE|wxFD_OVERWRITE_PROMPT,
	       wxDefaultPosition);
	    my $ret = $fd->ShowModal;
	    if ( $ret == wxID_OK ) {
		$file = $fd->GetPath;
	    }
	    $fd->Destroy;
	}
	return unless defined $file;

	# On macOS Catalina DMG STC seems to have problems saving.
	my $fd = fs_open( $file, '>:utf8' );
	$self->{t_editor}->ConvertEOLs(wxSTC_EOL_LF);
	my $t = $self->{t_editor}->GetText;
	# $self->log( 'I', ChordPro::Utils::as($t));
	$t .= "\n" unless $t =~ /\n$/;
	if ( $fd
	     and print $fd $t
	     and $fd->close ) {
	    $self->{t_editor}->SetModified(0);
	    $state{currentfile} = $file;
	    $state{windowtitle} = $file;
	    $self->log( 'S',  "Saved: $file" );
	    use List::Util qw(uniq);
	    @{$state{recents}} = uniq( $file, @{$state{recents}} );
	    return;
	}

	my $md = Wx::MessageDialog->new
	  ( $self,
	    "Cannot save to $file\n$!",
	    "Error saving file",
	    0 | wxOK | wxICON_ERROR);
	$md->ShowModal;
	$md->Destroy;
	undef $file;
    }
}

method preview( $args, %opts ) {
    use ChordPro::Wx::Preview;
    $self->prv //= ChordPro::Wx::Preview->new( panel => $self );

    my $mod = $self->{t_editor}->IsModified;
    my $preview_cho = $self->prv->preview_cho;
    unlink($preview_cho);
    my $fd;
    # The text that we get from the editor can have CRLF line endings,
    # that on Windows will result in double line ends. Write with
    # 'raw' layer.
    require Encode;
    if ( $fd = fs_open( $preview_cho, '>:raw' )
	 and print $fd ( Encode::encode_utf8($self->{t_editor}->GetText) )
	 and close($fd) ) {
	$self->prv->preview( $args, %opts );
	$self->previewtooltip;
    }
    else {
	$self->log( 'E', "$preview_cho: $!" );
    }
}

method check_preview_saved() {
    # Do not ask for preview save. It's regenerated easily.
    return 1;

    return 1 unless $self->prv && $self->prv->unsaved_preview;

    my $md = Wx::MessageDialog->new
      ( $self,
	"Do you want to save the preview as PDF?",
	"Preview",
	0 | wxCANCEL | wxYES_NO | wxYES_DEFAULT | wxICON_QUESTION );
    my $ret = $md->ShowModal;
    $md->Destroy;

    return 0 if $ret == wxID_CANCEL;
    $self->prv->discard, return 1 if $ret == wxID_NO; # don't save
    return $self->prv->save;
    1;
}

method embrace( $pre, $post, $nl = 1 ) {
    my $ctrl = $self->{t_editor};

    my ( $from, $to ) = $ctrl->GetSelection;
    my $have_selection = $from != $to;

    if ( $have_selection ) {
	my $text = $ctrl->GetSelectedText;
	chomp($text);
	$text = $pre . $text . $post;
	$ctrl->Replace( $from, $to, $text );
	my $pos = $ctrl->GetCurrentPos;
	$ctrl->SetSelection( $pos, $pos );
    }
    else {
	if ( $nl ) {
	    $nl = $self->nl;
	    my $ln = $ctrl->GetCurrentLine;
	    my $line = $ctrl->GetLine($ln);
	    #warn("LINE[$ln]: »$line«\n");
	    if ( $line =~ /\R\z/ ) {
		# Terminated
		#warn("LINE[$ln]: terminated\n");
	    }
	    else {
		$ctrl->LineEnd;
		$ctrl->NewLine;
		$ctrl->CharLeft;
		$ln = $ctrl->GetCurrentLine;
		$line = $ctrl->GetLine($ln);
		#warn("LINE[$ln]: »$line«\n");
	    }
	    if ( $line eq $nl ) {
		#warn("LINE[$ln]: empty\n");
		# Empty line
	    }
	    else {
		$ctrl->LineEnd;
		$ctrl->NewLine;
		$ln = $ctrl->GetCurrentLine;
		$line = $ctrl->GetLine($ln);
		#warn("LINE[$ln]: »$line«\n");
	    }
	}
	$ctrl->AddText($pre);
	my $pos = $ctrl->GetCurrentPos;
	$ctrl->AddText($post);
	$ctrl->SetSelection( $pos, $pos );
    }
}

method nl() {
    ("\r\n","\r","\n")[ $self->{t_editor}->GetEOLMode ];
}

method embrace_directive($dir) {
    $self->embrace( "{$dir: ", "}" );
}

method embrace_section($section) {

    unless ( defined($section) ) {
	my $dialog = Wx::TextEntryDialog->new
	  ( $self, "Enter section name",
	    "",
	    "tab" );

	return if $dialog->ShowModal != wxID_OK;
	$section = $dialog->GetValue;
    }

    my $nl = $self->nl;
    $self->embrace( "{start_of_$section}$nl",
		    $nl."{end_of_$section}" );
}

method save_preferences() { 1 }

method update_preferences() {
    $self->refresh;
}

method set_focus {
    $self->{t_editor}->SetFocus;
}

################ Event Handlers (alphabetic order) ################

method OnInsertSymbol($event) {
    unless ( $preferences{enable_insert_symbols} ) {
	my $md = Wx::MessageDialog->new
	  ( undef,
	    "Note: some symbols might not display properly in PDF".
	    " output, even if visible in the Editor. Make sure that".
	    " the symbols you use are supported by your output fonts.\n".
	    "\n".
	    "Continue and suppress future warnings?",
	    "Advanced operation warning",
	    wxYES_NO|wxNO_DEFAULT|wxICON_WARNING|wxDIALOG_NO_PARENT );
	return unless $md->ShowModal == wxID_YES;
	$preferences{enable_insert_symbols} = 1;

    }
    my $ctrl = $self->{t_editor};
    state $sym = "\x{2665}";
    my $d = Wx::SymbolPickerDialog->new( $sym, "", "", $self );
    if ( $d->ShowModal == wxID_OK ) {
	$ctrl->AddText( $sym = $d->GetSymbol );
    }
}

method OnA2Crd($event) {

    my $ctrl = $self->{t_editor};
    my ( $from, $to ) = $ctrl->GetSelection;
    my $have_selection = $from != $to;
    $ctrl->ConvertEOLs(wxSTC_EOL_LF);
    my $text = $have_selection ? $ctrl->GetSelectedText : $ctrl->GetText;

    require ChordPro::A2Crd;
    $::options->{nosysconfig} = 1;
    $::options->{nouserconfig} = 1;
    $::options->{noconfig} = 1;
    $::options->{fragment} = $have_selection;

    # Often text that is pasted from web has additional newlines.
    $text =~ s/^\n+//;
    if ( $text =~ m/(.+\n\n)+/ ) {
	$text =~ s/(.+\n)\n/$1/g;
    }

    my $cho = join
      ( "\n",
	@{ ChordPro::A2Crd::a2crd
	    ( { lines => [ split( /\n/, $text ) ] } ) } ) . "\n";

    if ( $have_selection ) {
	$ctrl->Replace( $from, $to, $cho );
    }
    else {
	$ctrl->Clear;
	$ctrl->SetText($cho);
    }
    $ctrl->SetCurrentPos($from);
}

method OnCharAdded( $event ) {
    my $stc = $self->{t_editor};
    my $key = $event->GetKey;
    return unless chr($key) =~ /[\]\n :\}]/;

    #warn("KEY: ", sprintf("%d 0x%x (%c)\n", $key, $key, $key ));
    my $ln = $stc->GetCurrentLine;
    my $line = $stc->GetLine($ln);
    #$stc->CallTipShow( $stc->GetCurrentPos, "LINE: »$line«");
    if ( $key eq ord("]") ) {
	# Complete a chord.
	my $pos = $stc->PositionBefore($stc->GetCurrentPos);
	my $p0 = $stc->BraceMatch($pos);
	return if $p0 < $stc->PositionFromLine($ln);
	$p0 = $stc->PositionAfter($p0);
	my $t = $stc->GetTextRange( $p0, $pos );
	return if $t =~ /\s/;
	if ( $t =~ s/(^|\/)([a-hu])/sprintf("%s%s", $1, uc($2))/ge ) {
	    $stc->SetSelection( $p0, $pos );
	    $stc->ReplaceSelection($t);
	    $stc->CharRight;
	}
    }

    elsif ( $key eq ord("\n") ) {
	# Move newline before trailing } to next line.
	if ( $line =~ /^\}(\r\n|\r|\n)?\Z/ ) {
	    my $nl = $self->nl;
	    my $pos = $stc->GetCurrentPos;
	    $stc->SetSelection( $stc->PositionBefore($pos),
				$stc->PositionAfter($pos) );
	    $stc->CharRightExtend if length($nl) == 2;
	    $stc->ReplaceSelection("}" . $nl);
	}
	elsif ( $ln > 1 && $stc->GetLine($ln-1) =~ /^\{\s*start_of_(\w+).*\}$/ ) {
	    $stc->InsertText( -1, "\n{end_of_$1}" );
	}
    }

    elsif ( $key eq ord(" ") || $key eq ord(":") || $key eq ord("}") ) {
	my $pos0 = $stc->PositionFromLine($ln);
	my $pos = $stc->GetCurrentPos;
	my $txt = $stc->GetTextRange( $pos0, $pos );
	if ( $txt =~ /^\s*(\{\s*)(\w+)(-\w+!?)?([ :\}])$/
	     &&
	     ( my $c = $state{rti}{directive_abbrevs}{$2} ) ) {
	    $stc->SetSelection( $pos0, $pos );
	    $stc->ReplaceSelection( $1.$c.($3//"").
				    ($4 eq "}" ? "}" : ": " ) );
	}
    }
}

method OnClearDiagnosticFlags($event) {
    return unless $state{have_stc};
    $self->{t_editor}->AnnotationClearAll;
}

method OnClipBoardPaste($event) {
    my $text = $event->GetString;
    $text =~ s/^\n+//;
    if ( $text =~ m/(.+\n\n)+/ ) {
	$text =~ s/(.+\n)\n/$1/g;
    }
    $event->SetString($text);
}

method OnCloseSection($event) {
    my $stc = $self->{t_editor};
    my $ln = $stc->GetCurrentLine;
    my $closed = "";
    my $did;
    while ( $ln > 0 ) {
	$ln--;
	my $line = $stc->GetLine($ln);
	if ( $line =~ /^\{(\s*)start_of_(\w+(?:-\w*!?)?)/ ) {
	    if ( $2 eq $closed ) {
		$closed = "";
		next;
	    }
	    $stc->AddText( $self->nl )
	      if $stc->GetColumn($stc->GetCurrentPos);
	    $stc->AddText( "{$1end_of_$2}" . $self->nl );
	    $did++;
	    last;
	}
	elsif ( $line =~ /^\{(\s*)so(\w(?:-\w*!?)?)/ ) {
	    if ( $2 eq $closed ) {
		$closed = "";
		next;
	    }
	    $stc->AddText( $self->nl )
	      if $stc->GetColumn($stc->GetCurrentPos);
	    $stc->AddText( "{$1eo$2}" . $self->nl );
	    $did++;
	    last;
	}
	elsif ( $line =~ /^\{(\s*)end_of_(\w+(?:-\w*!?)?)/ ) {
	    $closed = $2;
	}
	elsif ( $line =~ /^\{(\s*)so(\w(?:-\w*!?)?)/ ) {
	    $closed = $2;
	}
    }
    return if $did;
    $stc->CallTipShow( $stc->GetCurrentPos, "No open section to close" );
}

method OnCopy($event) {
    $self->{t_editor}->Copy;
}

method OnCut($event) {
    $self->{t_editor}->Cut;
}

method OnDelete($event) {
    my ( $from, $to ) = $self->{t_editor}->GetSelection;
    $self->{t_editor}->Remove( $from, $to ) if $from < $to;
}

method OnExternalEditor($event) {
    my $editor = $ENV{VISUAL} // $ENV{EDITOR};
    $self->alert( 0, "No external editor specified" ), return unless $editor;
    my $e = $self->{t_editor};
    my $pos = $e->GetCurrentPos;
    my $mod = $e->IsModified;

    # Save in temp file and call editor.
    use File::Temp qw(tempfile);
    ( undef, my $file ) = tempfile( SUFFIX => $preferences{chordproext},
				    OPEN => 0 );
    $e->SaveFile($file);
    my @st = stat($file);
    $self->log( 'I', "Running $editor on $file (" .
		plural( $e->GetLineCount, " line" ) . ", " .
		plural( $st[7], " byte" ) . ")" );
    ::sys( $editor, $file );

    if ( (stat($file))[7] == $st[7] && (stat(_))[9] == $st[9] ) {
	$self->log( 'I', "Running $editor did not make changes" );
	$self->alert( 0, "No changes from external editor" );
    }
    else {
	$e->LoadFile($file);
	$self->log( 'I', "Updated editor from $file (" .
		    plural( $e->GetLineCount, " line" ) . ", " .
		    plural( (stat(_))[7], " byte" ) . ")" );
	$mod = 1;
	# Clear selection and set insertion point.
	$e->SetSelection( $pos, $pos );
	$e->EmptyUndoBuffer;
    }
    unlink($file);

    $e->SetModified($mod);
    $e->SetFocus;
}

# Experimental.
# This approach is a bit clumsy and prone to errors.
method OnExternalEditorSync($event) {
    my $editor = $ENV{VISUAL} // $ENV{EDITOR};
    $self->alert( 0, "No external editor specified" ), return unless $editor;
    my $e = $self->{t_editor};
    my $pos = $e->GetCurrentPos;
    my $mod = $e->IsModified;

    # Save in temp file and call editor.
    use File::Temp qw(tempfile);
    ( undef, my $file ) = tempfile( SUFFIX => $preferences{chordproext},
				    OPEN => 0 );
    $e->SaveFile($file);
    my @st = stat($file);
    $self->log( 'I', "Running $editor on $file (" .
		plural( $e->GetLineCount, " line" ) . ", " .
		plural( $st[7], " byte" ) . ")" );

    my $cmd = sprintf("%s %s", $editor, qquote($file) );
    my $edit = Wx::Process::Open( $cmd );

    unless ( $edit ) {
	$self->log( 'I', "Cannot start editor");
	return;
    }

    my $pid = $edit->GetPid;
    $self->log( 'I', "Editor pid = $pid");

    my $did;
    while ( Wx::Process::Exists($pid) ) {
	next if (stat($file))[7] == $st[7] && (stat(_))[9] == $st[9];
	@st = stat(_);
	$e->LoadFile($file);
	$self->log( 'I', "Updated editor from $file (" .
		    plural( $e->GetLineCount, " line" ) . ", " .
		    plural( $st[7], " byte" ) . ")" );
	$mod = 1;
	# Clear selection and set insertion point.
	$e->SetSelection( $pos, $pos );
	$e->EmptyUndoBuffer;
	$did++;
    }
    continue {
	wxTheApp->Yield;
	sleep(1);
    }

    if ( !$did && (stat($file))[7] == $st[7] && (stat(_))[9] == $st[9] ) {
	$self->log( 'I', "Running $editor did not make changes" );
	$self->alert( 0, "No changes from external editor" );
    }
    unlink($file);

    $e->SetModified($mod);
    $e->SetFocus;
}

method OnPaste($event) {
    $self->{t_editor}->Paste;
}

method OnRedo($event) {
    $self->{t_editor}->CanRedo && $self->{t_editor}->Redo;
}

method OnSave($event) {
    return unless $self->{t_editor}->IsModified
      || !defined $state{currentfile};
    $self->save_file( $state{currentfile} )
}

method OnSaveAs {
    $self->save_file;
}

method OnSongbook {
    return unless $self->check_source_saved;
    $self->GetParent->select_mode("sbexport");
}

method OnText($event) {
    $self->{t_editor}->SetModified(1);
}

method OnUndo($event) {
    $self->{t_editor}->Undo;
}

#### Insertions

method OnInsertTitle($event) {
    $self->embrace_directive("title");
}

method OnInsertSubtitle($event) {
    $self->embrace_directive("subtitle");
}

method OnInsertKey($event) {
    $self->embrace_directive("key");
}

method OnInsertArtist($event) {
    $self->embrace_directive("artist");
}

method OnInsertChorus($event) {
    $self->embrace_section("chorus");
}

method OnInsertVerse($event) {
    $self->embrace_section("verse");
}

method OnInsertGrid($event) {
    $self->embrace_section("grid");
}

method OnInsertTab($event) {
    $self->embrace_section("tab");
}

method OnInsertSection($event) {
    $self->embrace_section(undef);
}

1;

