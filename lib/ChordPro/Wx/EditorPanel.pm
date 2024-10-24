#! perl

use v5.26;
use Object::Pad;
use utf8;

class ChordPro::Wx::EditorPanel
  :does( ChordPro::Wx::PanelRole )
  :isa( ChordPro::Wx::EditorPanel_wxg );

use Wx qw[:everything];
use Wx::Locale gettext => '_T';

use ChordPro::Wx::Config;
use ChordPro::Wx::Utils;
use ChordPro::Utils qw( demarkup is_macos is_msw plural );
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
    $self->setup_scintilla;

    # Setup WebView, if possible.
    $self->setup_webview;

    # Single pane.
    $self->unsplit;

    $self;
}

################ ################

method setup_menubar() {

    my $mb =
    make_menubar( $self,
      [ [ wxID_FILE,
	  [ [ wxID_NEW, "", "Create another ChordPro document", "OnNew" ],
	    [ wxID_OPEN, "", "Open an existing ChordPro document", "OnOpen" ],
	    [],
	    [ wxID_SAVE, "", "Save the current ChordPro file", "OnSave" ],
	    [ wxID_SAVEAS, "", "Save under a different name", "OnSaveAs" ],
	    [],
	    [ wxID_ANY, "Hide/Show messages",
	      "Hide or show the messages pane", "OnWindowMessages" ],
	    [ wxID_ANY, "Save messages",
	      "Save the messages to a file", "OnMessagesSave" ],
	    [ wxID_ANY, "Clear messages",
	      "Clear the current messages", "OnMessagesClear" ],
	    [],
	    [ wxID_EXIT, "", "Close window and exit", "OnClose" ],
	  ]
	],
	[ wxID_EDIT,
	  [ [ wxID_UNDO,   "OnUndo" ],
	    [ wxID_REDO,   "OnRedo" ],
	    [],
	    [ wxID_CUT,    "OnCut" ],
	    [ wxID_COPY,   "OnCopy" ],
	    [ wxID_PASTE,  "OnPaste" ],
	    [ wxID_DELETE, "OnDelete" ],
	    [],
	    [ wxID_ANY, "Preferences...\tCtrl-R",
	      "Preferences", "OnPreferences" ],
	  ]
	],
	[ wxID_ANY, "Tasks",
	  [ [ wxID_ANY, "Default preview\tCtrl-P",
	      "Preview with default formatting", "OnPreview" ],
	    [ wxID_ANY, "No chord diagrams",
	      "Preview without chord diagrams", "OnPreviewNoDiagrams" ],
	    [ wxID_ANY, "Lyrics only",
	      "Preview just the lyrics", "OnPreviewLyricsOnly" ],
	    [ wxID_ANY, "More...",
	      "Transpose, transcode, and more", "OnPreviewMore" ],
	    [],
	    [ wxID_ANY, "Hide/Show Preview",
	      "Hide or show the preview pane", "OnWindowPreview" ],
	    [ wxID_ANY, "Save preview", "Save the preview to a PDF",
	      "OnPreviewSave" ],
	  ]
	],
	[ wxID_HELP,
	  [ [ wxID_ANY, "ChordPro file format",
	      "Help about the ChordPro file format", "OnHelp_ChordPro" ],
	    [ wxID_ANY, "ChordPro config files",
	      "Help about the config files", "OnHelp_Config" ],
	    [],
	    [ wxID_ANY, "Enable debug info in PDF",
	      "Add sources and configs to the PDF for debugging", 1,
	      "OnHelp_DebugInfo" ],
	    [ wxID_ANY, "Insert runtime info",
	      "Insert runtime info into the messages",
	      "OnMessagesRuntimeInfo" ],
	    [],
	    [ wxID_ABOUT, "", "About WxChordPro", "OnAbout" ],
	  ]
	]
      ] );
}

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
    # 1 - comments
    $stc->StyleSetSpec( 1, "bold,fore:grey" );
    # 2 - Keywords
    $stc->StyleSetSpec( 2, "bold,fore:grey" );
    # 3 - Brackets
    $stc->StyleSetSpec( 3, "bold,fore:blue" );
    # 4 - Chords
    $stc->StyleSetSpec( 4, "fore:red" );
    # 5 - Directives
    $stc->StyleSetSpec( 5, "bold,fore:indigo" );
    # 6 - Directive arguments
    $stc->StyleSetSpec( 6, "fore:orange" );

    # For linenumbers.
    $stc->SetMarginWidth( 0, 40 ); # TODO

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
    $style->( qr/^(\{)([-\w!]+)([: ]+)(.*)(\})/m, 3, 5, 3, 6, 3 );
    # Chords.
    $style->( qr/(\[)([^\[\]]*)(\])/m, 3, 4, 3 );
}

method prepare_annotations() {

    return unless $stc->isa('Wx::StyledTextCtrl');

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

    return unless $stc->isa('Wx::StyledTextCtrl');

    $stc->AnnotationSetText( $line, $message );
    $stc->AnnotationSetStyle( $line, $astyle );
}

################ API Functions ################

method refresh() {

    $self->setup_logger;

    $self->setup_menubar;

    $self->log( 'I', "Using " .
		( ref($self->{p_editor}{t_editor}) eq 'Wx::TextCtrl'
		  ? "basic" : "styled") . " text editor" );

    $self->log( 'I', "Using " .
		( ref($self->{p_editor}{webview}) eq 'Wx::WebView'
		  ? "embedded" : "external") . " PDF viewer" );


    my $font = $state{fonts}[$preferences{editfont}]{font};
    $font->SetPointSize($preferences{editsize});
    $self->{t_editor}->SetFont($font);
    $self->{t_editor}->SetBackgroundColour
      ( Wx::Colour->new($preferences{editcolour}) );

    $self->setup_messages_ctxmenu;

}

method openfile( $file, $checked=0 ) {

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
    $state{currentfile} = $file;
    use List::Util qw(uniq);
    @{$state{recents}} = uniq( $file, @{$state{recents}} );

    if ( $self->{t_editor}->GetText =~ /^\{\s*t(?:itle)?[: ]+([^\}]*)\}/m ) {
	my $title = demarkup($1);
	my $n = $self->{t_editor}->GetLineCount;
	$self->log( 'S', "Loaded: $title (" . plural($n, " line") . ")");
	$self->{l_status}->SetLabel($title);
    }
    else {
	my $n = $self->{t_editor}->GetLineCount;
	$self->{l_status}->SetLabel(basename($file));
	$self->log( 'S', "Loaded: $file (" . plural($n, " line") . ")");
    }
    $self->GetParent->SetTitle( $state{windowtitle} = $file);

    # Default is no transposing.
    $preferences{xpose_from} = $preferences{xpose_to} = 0;
    $preferences{xpose_acc} = 0;

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
    $self->{t_editor}->SetModified(0);
    $self->log( 'S', "New file");
    $preferences{xpose_from} = $preferences{xpose_to} = 0;
    $preferences{xpose_acc} = 0;
}

method checksaved() {
    return 1 unless ( $self->{t_editor} && $self->{t_editor}->IsModified );
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
	    $self->save_as( $state{currentfile} );
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
	    return if $self->OnSaveAs == wxID_CANCEL;
	}
    }
    return 1;
}

method saveas() {
    my $fd = Wx::FileDialog->new
      ($self, _T("Choose output file"),
       "", "",
       "*.cho",
       0|wxFD_SAVE|wxFD_OVERWRITE_PROMPT,
       wxDefaultPosition);
    my $ret = $fd->ShowModal;
    if ( $ret == wxID_OK ) {
	$self->save_as( $state{currentfile} = $fd->GetPath );
    }
    $fd->Destroy;
    return $ret;
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
    }
    else {
	$self->log( 'E', "$preview_cho: $!" );
    }
}

################ Event Handlers (alphabetic order) ################

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
    $state{currentfile}
      ? $self->save_as( $state{currentfile} )
      : $self->saveas;
}

sub OnSaveAs {
    my ( $self, $file ) = @_;
    $self->{t_editor}->SaveFile($file);
    $state{windowtitle} = $file;
    $self->log( 'S',  "Saved." );
}

method OnStyleNeeded($event) {		# scintilla
    $self->style_text;
}

method OnText($event) {
    $self->{t_editor}->SetModified(1);
}

method OnUndo($event) {
    $self->{t_editor}->CanUndo && $self->{t_editor}->Undo;
}

################ Compatibility ################

# This is to facilitate swapping between TextCtrl and Scintilla.

package Wx::StyledTextCtrl {

    sub SetFont {
	$_[0]->StyleSetFont( $_, $_[1] ) for 0..6;
    }

    sub GetFont {
	$_[0]->StyleGetFont(0, $_[1]);
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

