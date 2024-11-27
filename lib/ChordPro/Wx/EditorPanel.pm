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

use ChordPro::Utils qw( is_macos );
use ChordPro::Wx::Config;
use ChordPro::Wx::Utils;
use ChordPro::Utils qw( max demarkup is_macos is_msw plural );
use ChordPro::Paths;

use File::Basename;

# WhoamI
field $panel :accessor = "editor";

# Just fill in the defaults.
sub BUILDARGS( $class, $parent=undef, $id=wxID_ANY,
	   $pos=wxDefaultPosition, $size=wxDefaultSize,
	   $style=0, $name="" ) {
   return( $parent, $id, $pos, $size, $style, $name );
}

ADJUST {
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
    $self->{bmb_preview}->SetFocus;

    $self->refresh_messages;
}

method openfile( $file, $checked=0, $actual=undef ) {
    $actual //= $file;

    # File tests fail on Windows, so bypass when already checked.
    unless ( $checked || -f -r $file ) {
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
    unless ( $self->{t_editor}->LoadFile($file) ) {
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
	$stc->SetScrollWidthTracking(1);
    }
    else {
	$self->{t_editor}->ShowPosition(0); # doesn't work?
    }

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
	$self->{l_status}->SetLabel(basename($file));
	$self->{l_status}->SetToolTip($file);
	$self->log( 'S', "Loaded: $file (" . plural($n, " line") . ")");
    }
    $self->GetParent->SetTitle( $state{windowtitle} = $actual);

    # Default is no transposing.
    $preferences{xpose_from} = $preferences{xpose_to} = 0;
    $preferences{xpose_acc} = 0;
    $self->{sw_lr}->Unsplit(undef) if $self->{sw_lr}->IsSplit;
    $self->{sw_tb}->Unsplit(undef) if $self->{sw_tb}->IsSplit;

    return 1;
}

method newfile() {
    delete $state{currentfile};

    my $title = "New Song";
    $state{windowtitle} = $title;
    $self->{l_status}->SetLabel($title);
    my $content = "{title: New Song}\n";
    $self->{t_editor}->SetText($content);

    my $file = $preferences{tmplfile};
    if ( $file && $preferences{enable_tmplfile} ) {
	$self->log( 'I', "Loading template $file" );
	if ( -f -r $file && $self->{t_editor}->LoadFile($file) ) {
	    $content = "";
	}
	else {
	    $self->log( 'E', "Cannot open template $file: $!" );
	}
    }
    else {
	require ChordPro::Wx::NewSongDialog;
	unless ( $self->{d_newfile} ) {
	    $self->{d_newfile} = ChordPro::Wx::NewSongDialog->new
	      ( $self, wxID_ANY, "New Song" );
	    restorewinpos( $self->{d_newfile}, "newfile" );
	    $self->{d_newfile}->set_title($title);
	}
	$self->{d_newfile}->refresh;
	my $ret = $self->{d_newfile}->ShowModal;
	savewinpos( $self->{d_newfile}, "newfile" );
	if ( $ret == wxID_OK ) {
	    $title = $self->{d_newfile}->get_title;
	    $content = $self->{d_newfile}->get_meta;
	}
    }

    $self->{t_editor}->SetText($content) if length($content);
    $self->{t_editor}->EmptyUndoBuffer;

    $self->log( 'S', "New song: $title");
    $state{windowtitle} = $title;
    $self->{l_status}->SetLabel($title);
    $self->{l_status}->SetToolTip($state{currentfile});
    $preferences{xpose_from} = $preferences{xpose_to} = 0;
    $preferences{xpose_acc} = 0;
    $self->{sw_lr}->Unsplit(undef) if $self->{sw_lr}->IsSplit;
    $self->{sw_tb}->Unsplit(undef) if $self->{sw_tb}->IsSplit;
}

method check_source_saved() {
    # Do we need saving?
    return 1 unless ( $self->{t_editor} && $self->{t_editor}->IsModified );

    # Do we have a filename?
    if ( $state{currentfile} ) {
	my $md = Wx::MessageDialog->new
	  ( $self,
	    "File " . $state{currentfile} . " has been changed.\n".
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
	    my $fd = Wx::FileDialog->new
	      ($self, _T("Choose output file"),
	       "", $state{currentfile}//"",
	       "*.cho",
	       0|wxFD_SAVE|wxFD_OVERWRITE_PROMPT,
	       wxDefaultPosition);
	    my $ret = $fd->ShowModal;
	    if ( $ret == wxID_OK ) {
		$file = $fd->GetPath;
	    }
	    $fd->Destroy;
	}
	return unless defined $file;

	if ( $self->{t_editor}->SaveFile($file) ) {
	    $self->{t_editor}->SetModified(0);
	    $state{currentfile} = $file;
	    $state{windowtitle} = $file;
	    $self->log( 'S',  "Saved: $file" );
	    return;
	}

	my $md = Wx::MessageDialog->new
	  ( $self,
	    "Cannot save to $file",
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
    if ( open( $fd, '>:utf8', $preview_cho )
	 and print $fd ( $self->{t_editor}->GetText )
	 and close($fd) ) {
	$self->prv->preview( $args, %opts );
	$self->previewtooltip;
    }
    else {
	$self->log( 'E', "$preview_cho: $!" );
    }
}

method check_preview_saved() {
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

method embrace( $pre, $post ) {
    my $ctrl = $self->{t_editor};

    my ( $from, $to ) = $ctrl->GetSelection;
    my $have_selection = $from != $to;

    if ( $have_selection ) {
	my $text = $have_selection ? $ctrl->GetSelectedText : $ctrl->GetText;
	chomp($text);
	$text = $pre . $text . $post;
	$ctrl->Replace( $from, $to, $text );
	my $pos = $ctrl->GetInsertionPoint;
	$ctrl->SetSelection( $pos, $pos );
    }
    else {
	$ctrl->AddText($pre);
	my $pos = $ctrl->GetInsertionPoint;
	$ctrl->AddText($post);
	$ctrl->SetSelection( $pos, $pos );
    }
}

method embrace_directive($dir) {
    $self->embrace( "{$dir: ", "}\n" );
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

    $self->embrace( "{start_of_$section}\n",
		    "\n{end_of_$section}\n" );
}

method save_preferences() { 1 }

method update_preferences() {
    $self->refresh;
}

################ Event Handlers (alphabetic order) ################

method OnA2Crd($event) {

    my $ctrl = $self->{t_editor};
    my ( $from, $to ) = $ctrl->GetSelection;
    my $have_selection = $from != $to;
    my $text = $have_selection ? $ctrl->GetSelectedText : $ctrl->GetText;

    require ChordPro::A2Crd;
    $::options->{nosysconfig} = 1;
    $::options->{nouserconfig} = 1;
    $::options->{noconfig} = 1;

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
    $ctrl->SetInsertionPoint($from);
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
    my $pos = $e->GetInsertionPoint;
    my $mod = $e->IsModified;

    # Save in temp file and call editor.
    use File::Temp qw(tempfile);
    ( undef, my $file ) = tempfile( SUFFIX => ".cho", OPEN => 0 );
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

method OnPaste($event) {
    $self->{t_editor}->Paste;
}

method OnRedo($event) {
    $self->{t_editor}->CanRedo && $self->{t_editor}->Redo;
}

method OnSave($event) {
    return unless $self->{t_editor}->IsModified;
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

method OnInsertSection($event) {
    $self->embrace_section(undef);
}

1;

