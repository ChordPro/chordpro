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

# Either Wx::StyledTextCtrl or Wx::TextCtrl.
field $stc;

# Style for annotations.
field $astyle;

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
    $self->{t_editor}->OSXDisableAllSmartSubstitutions
      if $self->{t_editor}->can("OSXDisableAllSmartSubstitutions");

    # Try Styled Text Control (Scintilla). This required an updated
    # version of Wx.
    $self->setup_scintilla if $::options->{stc}//1;

    # Setup WebView, if possible.
    $self->setup_webview if $::options->{webview}//1;

    # Single pane.
    $self->unsplit;

    $self;
}

################ ################

method name() { "Editor" }

################ wxStyledTextCtrl (Scintilla) ################

method setup_scintilla() {

    my $try;
    $stc = $self->{t_editor};
    if ( eval { use Wx::STC; 1 } ) {
	# Replace the placeholder Wx::TextCtrl.
	$try = Wx::StyledTextCtrl->new( $self->{p_left},
					wxID_ANY );
    }
    else {
	return;
    }

    # Check for updated STC.
    for ( qw( IsModified DiscardEdits MarkDirty ) ) {
	next if $try->can($_);
	# Pre 3.x wxPerl, missing methods.
	$try->Destroy;
	return;
    }
    $stc = $try;
    $state{have_stc} = 1;		# Note: too early!

    # Replace the wxTextCtrl by Scintilla.
    $self->{sz_editor}->Replace( $self->{t_editor}, $stc, 1 );
    $self->{t_editor}->Destroy;
    $self->{t_editor} = $stc;
    $self->{sz_editor}->Layout;

    $stc->SetLexer(wxSTC_LEX_CONTAINER);
    $stc->SetKeyWords(0,
		      [qw( album arranger artist capo chord chorus
			   column_break columns comment comment_box
			   comment_italic composer copyright define
			   diagrams duration end_of_bridge end_of_chorus
			   end_of_grid end_of_tab end_of_verse grid
			   highlight image key lyricist meta new_page
			   new_physical_page new_song no_grid pagesize
			   pagetype sorttitle start_of_bridge
			   start_of_chorus start_of_grid start_of_tab
			   start_of_verse subtitle tempo time title
			   titles transpose year )
		      ]);

    Wx::Event::EVT_STC_STYLENEEDED($self, -1, $self->can('OnStyleNeeded'));

    $stc->StyleClearAll;
    # 0 - basic
    # 1 - comments (grey)
    $stc->StyleSetSpec( 1, "fore:#b1b1b1" );
    # 2 - Keywords (grey)
    $stc->StyleSetSpec( 2, "fore:#b1b1b1" );
    # 3 - Brackets (grey)
    $stc->StyleSetSpec( 3, "fore:#b1b1b1" );
    # 4 - Chords (red)
    $stc->StyleSetSpec( 4, "fore:#ff3c31" );
    # 5 - Directives (blue, same as status label colour)
    $stc->StyleSetSpec( 5, "fore:#0068d9" );
    # 6 - Directive arguments (orange, same as toolbar icon colour)
    $stc->StyleSetSpec( 6, "fore:#ef6c2a" );

    # For linenumbers.
    $stc->SetMarginWidth( 0, 40 ); # TODO

    $stc->SetWrapMode(3); # wxSTC_WRAP_WHITESPACE );
    $stc->SetWrapStartIndent(2); # wxSTC_WRAP_WHITESPACE );
}

method style_text() {

    # Scintilla uses byte indices.
    use Encode;
    my $text  = Encode::encode_utf8($stc->GetText);

    my $style = sub {
	my ( $re, @styles ) = @_;
	pos($text) = 0;
	while ( $text =~ m/$re/g ) {
	    my @s = @styles;
	    die("!!! ", scalar(@{^CAPTURE}), ' ', scalar(@s)) unless @s == @{^CAPTURE};
	    my $end = pos($text);
	    my $start = $end - length($&);
	    my $group = 0;
	    while ( $start < $end ) {
		my $l = length(${^CAPTURE[$group++]});
		$stc->StartStyling( $start, 0 );
		$stc->SetStyling( $l, shift(@s) );
		$start += $l;
	    }
	}
    };

    # Comments/
    $style->( qr/^(#.*)/m, 1 );
    # Directives.
    $style->( qr/^(\{)([-\w!]+)(.*)(\})/m, 3, 5, 6, 3 );
    $style->( qr/^(\{)([-\w!]+)([: ])(.*)(\})/m, 3, 5, 3, 6, 3 );
    # Chords.
    $style->( qr/(\[)([^\[\]]*)(\])/m, 3, 4, 3 );
}

method prepare_annotations() {

    return unless $state{have_stc};

    $astyle = 1 + wxSTC_STYLE_LASTPREDEFINED;
    $stc->AnnotationClearAll;
    $stc->AnnotationSetVisible(wxSTC_ANNOTATION_BOXED);
    $stc->StyleSetBackground( $astyle, Wx::Colour->new(255, 255, 160) );
    $stc->StyleSetForeground( $astyle, wxRED );

    if ( $stc->can("StyleGetSizeFractional") ) { # Wx 3.002
	$stc->StyleSetSizeFractional	# size * 100
	  ( $astyle,
	    ( $stc->StyleGetSizeFractional
	      ( wxSTC_STYLE_DEFAULT ) * 4 ) / 5 );
    }
    return 1;
}

method add_annotation( $line, $message ) {

    return unless $state{have_stc};

    $stc->AnnotationSetText( $line, $message );
    $stc->AnnotationSetStyle( $line, $astyle );
}

################ API Functions ################

method refresh() {

    $self->setup_logger;

    $self->update_menubar( M_EDITOR );

    $state{have_stc} = $self->{t_editor}->isa('Wx::StyledTextCtrl');
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
    my $font = Wx::Font->new($preferences{editfont});
    $self->{t_editor}->SetFont($font);
    $font = Wx::Font->new($preferences{msgsfont});
    $self->{t_messages}->SetFont($font);
    if ( $state{have_stc} ) {
#	$stc->StyleSetBackground(wxSTC_STYLE_DEFAULT,
#				 Wx::Colour->new($preferences{editcolour}));
#	$stc->StyleClearAll;
    }
    else {
	$self->{t_editor}->SetBackgroundColour
	  ( Wx::Colour->new($preferences{editcolour}) );
    }

    $self->setup_messages_ctxmenu;
    $self->previewtooltip;
    $self->messagestooltip;
    $self->{t_editor}->SetModified($mod);
    $self->{bmb_preview}->SetFocus;
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

    if ( $stc ) {
	my @t = split( /\n/, $self->{t_editor}->GetText );
	my $max = -1;
	for ( @t ) {
	    $max = max( $max, length($_) );
	}
	if ( $stc->can("SetScrollWidthTracking") ) {
	    $stc->SetScrollWidth($max);
	    $stc->SetScrollWidthTracking(1);
	}
	else {
	    $stc->SetScrollWidth($max+10);
	}
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

    my $file = $preferences{tmplfile};
    my $content = "{title: New Song}\n\n";
    if ( $file ) {
	$self->log( 'I', "Loading template $file" );
	if ( -f -r $file ) {
	    if ( $self->{t_editor}->LoadFile($file) ) {
		$content = "";
	    }
	    else {
		$self->log( 'E', "Cannot open template $file: $!" );
	    }
	}
	else {
	    $self->log( 'E', "Cannot open template $file: $!" );
	}
     }
    $self->{t_editor}->SetText($content) unless $content eq "";
    $self->{t_editor}->EmptyUndoBuffer
      if $self->{t_editor}->can("EmptyUndoBuffer");
    $self->log( 'S', "New file");
    $state{windowtitle} = "New Song";
    $self->{l_status}->SetLabel("New Song");
    $self->{l_status}->SetToolTip("");
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
	unless ( defined $file ) {
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

method save_preferences() { 1 }

################ Event Handlers (alphabetic order) ################

method OnA2Crd($event) {

    my $ctrl = $self->{t_editor};
    my ( $from, $to ) = $ctrl->GetSelection;
    my $have_selection = $from != $to;

    my $text = $have_selection
      ? $state{have_stc}
        ? $ctrl->GetSelectedText
        : $ctrl->GetStringSelection
      : $ctrl->GetText;

    require ChordPro::A2Crd;
    $::options->{nosysconfig} = 1;
    $::options->{nouserconfig} = 1;
    $::options->{noconfig} = 1;
    my $cho = join
      ( "\n",
	@{ ChordPro::A2Crd::a2crd
	    ( { lines => [ split( /\n/, $text ) ] } ) } ) . "\n";


    if ( $have_selection ) {
	if ( $state{have_stc} ) {
	    $ctrl->ReplaceSelection($cho );
	}
	else {
	    $ctrl->Replace( $from, $to, $cho );
	}
    }
    else {
	$ctrl->Clear;
	$ctrl->SetText($cho);
    }
    $ctrl->SetInsertionPoint($from) unless $state{have_stc};
}

method OnCut($event) {
    $self->{t_editor}->Cut;
}

method OnDelete($event) {
    my ( $from, $to ) = $self->{t_editor}->GetSelection;
    $self->{t_editor}->Remove( $from, $to ) if $from < $to;
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

method OnStyleNeeded($event) {		# scintilla
    $self->style_text;
}

method OnText($event) {
    $self->{t_editor}->SetModified(1);
}

method OnUndo($event) {
    $self->{t_editor}->Undo;
}

################ Compatibility ################

# This is to facilitate swapping between TextCtrl and Scintilla.

package Wx::StyledTextCtrl {

    # wxPerl doesn't provide calls (yet) to fetch the fonts, so keep track.
    my $_font;
    sub SetFont {
	$_[0]->StyleSetFont( $_, $_[1] ) for 0..6;
	$_font = $_[1];
    }

    sub GetFont {
	$_font // $_[0]->StyleGetFont(0);
    }

    # IsModified, MarkDirty and DiscardEdits need custom patches.
    sub SetModified {
	$_[1] ? $_[0]->MarkDirty : $_[0]->DiscardEdits;
    }
}

package Wx::TextCtrl {

    sub GetText {
	$_[0]->GetValue;
    }

    sub SetText {
	$_[0]->SetValue($_[1]);
    }

    sub GetLineCount {
	$_[0]->GetNumberOfLines;
    }
}

1;

