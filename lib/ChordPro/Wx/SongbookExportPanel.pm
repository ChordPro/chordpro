#! perl

use v5.26;
use Object::Pad;
use utf8;

class ChordPro::Wx::SongbookExportPanel
  :repr(HASH)
  :does( ChordPro::Wx::PanelRole )
  :isa( ChordPro::Wx::SongbookExportPanel_wxg );

use Wx qw[:everything];
use Wx::Locale gettext => "_T";

use ChordPro::Wx::Config;
use ChordPro::Wx::Utils;

use Encode qw( decode_utf8 encode_utf8 );
use File::LoadLines;

# WhoamI
field $panel :accessor = "sbexport";

# Just fill in the defaults.
sub BUILDARGS( $class, $parent=undef, $id=wxID_ANY,
	   $pos=wxDefaultPosition, $size=wxDefaultSize,
	   $style=0, $name="" ) {
   return( $parent, $id, $pos, $size, $style, $name );
}

ADJUST {

    # Setup logger.
    $self->setup_logger;

    # Setup WebView, if possible.
    $self->setup_webview if $::options->{webview}//1;

    # Single pane.
    $self->unsplit;

}

################ ################

method name() { "Export Songbook" }

################ ################

method setup_menubar() {

    my $mb =
    make_menubar( $self,
      [ [ wxID_FILE,
	  [ [ wxID_NEW, "", "Create or open a ChordPro document", "OnNew" ],
	    [],
	    [ wxID_ANY, "Export to PDF...", "Save the preview to a PDF",
	      "OnPreviewSave" ],
	    [],
	    [ wxID_ANY, "Show messages",
	      "Hide or show the messages pane", 1, "OnWindowMessages" ],
	    [ wxID_ANY, "Save messages",
	      "Save the messages to a file", "OnMessagesSave" ],
	    [ wxID_ANY, "Clear messages",
	      "Clear the current messages", "OnMessagesClear" ],
	    [],
	    [ wxID_EXIT, "", "Close window and exit", "OnClose" ],
	  ]
	],
	[ wxID_EDIT,
	  [ [ wxID_PREFERENCES, "Preferences...\tCtrl-R",
	      "Preferences", "OnPreferences" ],
	  ]
	],
	[ wxID_ANY, "Tasks",
	  [ [ wxID_ANY, "Default preview\tCtrl-P",
	      "Preview with default formatting", "OnPreview" ],
	    [ wxID_ANY, "No chord diagrams",
	      "Preview without chord diagrams", "OnPreviewNoDiagrams" ],
	    [ wxID_ANY, "Lyrics only",
	      "Preview just the lyrics". "OnPreviewLyricsOnly" ],
	    [ wxID_ANY, "More...",
	      "Transpose, transcode, and more", "OnPreviewMore" ],
	    [],
	    [ wxID_ANY, "Show Preview",
	      "Hide or show the preview pane", 1, "OnWindowPreview" ],
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
	    [ wxID_ABOUT, "About ChordPro", "About WxChordPro", "OnAbout" ],
	  ]
	]
      ] );
}

################ API Functions ################

method refresh() {

    setup_logger($self);

    $self->setup_menubar;

    $state{have_webview} = ref($self->{webview}) eq 'Wx::WebView';
    $self->log( 'I', "Using " .
		( $state{have_webview}
		  ? "embedded" : "external") . " PDF viewer" );

    $self->{cb_recursive}->SetValue(1);

    my $c = $state{songbookexport};
    $self->{dp_folder}->SetPath( $state{sbefolder} // $c->{folder} // "");
    $self->{t_exporttitle}->SetValue($c->{title} // "");
    $self->{t_exportstitle}->SetValue($c->{subtitle} // "");
    $self->{fp_cover}->SetPath($c->{cover} // "");
    $self->{cb_stdcover}->SetValue($c->{stdcover} // 0);
    $self->OnStdCoverChecked();

    if ( $state{sbefolder} && -d $state{sbefolder} ) {
	$self->{dp_folder}->SetPath($state{sbefolder});
	$self->log( 'I', "Using folder " . $state{sbefolder} );
	$self->OnDirPickerChanged(undef);
    }
    $self->{w_rearrange}->SetSelection($state{from_songbook}-1);
    $state{from_songbook} = 0;
    setup_messages_ctxmenu($self);
}

method save_preferences() {
    my $c = $state{songbookexport};
    $c->{folder}   = $self->{dp_folder}->GetPath       // "";
    $c->{title}    = $self->{t_exporttitle}->GetValue  // "";
    $c->{subtitle} = $self->{t_exportstitle}->GetValue // "";
    $c->{cover}    = $self->{fp_cover}->GetPath        // "";
    $c->{stdcover} = $self->{cb_stdcover}->IsChecked   // 0;
}

method open_dir($dir) {
    $dir =~ s/[\\\/]$//;
    $self->{dp_folder}->SetPath($dir);
    $self->OnDirPickerChanged;
}

method preview( $args, %opts ) {
    use ChordPro::Wx::Preview;
    $self->prv //= ChordPro::Wx::Preview->new( panel => $self );
    $args //= [];

    my $folder = $self->{dp_folder}->GetPath;
    my @files = @{ $state{sbefiles} };
    unless ( $folder && @files ) {
	my $md = Wx::MessageDialog->new
	  ( $self,
	    "Please select a folder!",
	    "No folder selected",
	    wxOK | wxICON_ERROR );
	my $ret = $md->ShowModal;
	$md->Destroy;
	return;
    }

    $self->save_preferences;

    my $filelist = "";
    my @o = $self->{w_rearrange}->GetCurrentOrder;
    for ( $self->{w_rearrange}->GetCurrentOrder ) {
	$filelist .= "$folder/$files[$_]\n" unless $_ < 0;
    }
    if ( $filelist eq "" ) {
	my $md = Wx::MessageDialog->new
	  ( $self,
	    "Please select one or more song files.",
	    "No songs selected",
	    wxOK | wxICON_ERROR );
	my $ret = $md->ShowModal;
	$md->Destroy;
	return;
    }

    my @args = ( @$args, "--filelist", \$filelist );
    my %opts = ( target => $self, filelist => 1 );

    if ( $self->{cb_stdcover}->IsChecked ) {
	push( @args, "--title",
	      encode_utf8($self->{t_exporttitle}->GetValue // "") );
	if ( my $stitle = $self->{t_exportstitle}->GetValue ) {
	    push( @args, "--subtitle", encode_utf8($stitle) );
	}
    }
    elsif ( my $cover = $self->{fp_cover}->GetPath ) {
	push( @args, "--cover", encode_utf8($cover) );
    }
    $self->prv->preview( \@args, %opts );
    $self->previewtooltip;

}

method check_source_saved() { 1 }

method check_preview_saved() {
    return 1 unless $self->prv && $self->prv->unsaved_preview;

    my $md = Wx::MessageDialog->new
      ( $self,
	"The preview for the songbook has not yet been saved.\n".
	"Do you want to save your changes?",
	"Preview has changed",
	0 | wxCANCEL | wxYES_NO | wxYES_DEFAULT | wxICON_QUESTION );
    my $ret = $md->ShowModal;
    $md->Destroy;

    return 0 if $ret == wxID_CANCEL;
    $self->prv->discard, return 1 if $ret == wxID_NO; # don't save
    return $self->prv->save;
    1;
}

################ Event handlers ################

sub OnDirPickerChanged {
    my ( $self, $event ) = @_;

    my $folder = $state{sbefolder} = $self->{dp_folder}->GetPath;
    opendir( my $dir, $folder )
      or do {
	$self->GetParent->log( 'W', "Error opening folder $folder: $!");
	my $md = Wx::MessageDialog->new
	  ( $self,
	    "Error opening folder $folder: $!",
	    "Error",
	    wxOK | wxICON_ERROR );
	my $ret = $md->ShowModal;
	$md->Destroy;
	return;
    };

    my @files;
    my $src = "folder";
    use File::Find qw(find);
    my $recurse = $self->{cb_recursive}->IsChecked;
    find sub {
	if ( -s && m/^[^.].*\.(cho|crd|chopro|chord|chordpro|pro)$/ ) {
	    push( @files, $File::Find::name );
	}
	if ( -d && $File::Find::name ne $folder ) {
	    $File::Find::prune = !$recurse;
	    $self->{cb_recursive}->Enable;
	}
    }, $folder;
    @files = map { decode_utf8( s;^\Q$folder\E/?;;r) } sort @files;

    my $n = scalar(@files);
    my $msg = "Found $n ChordPro file" . ( $n == 1 ? "" : "s" ) . " in $src" .
      ( $self->{cb_recursive}->IsChecked ? "s" : "" );
    $self->{l_info}->SetLabel($msg);
    $self->log( 'S', $msg );

    $self->{w_rearrange}->Set(\@files);
    $self->{w_rearrange}->Check($_,1) for 0..$#files;
    $self->{sz_rearrange}->Layout;
    $self->{b_down}->Enable(0);
    $self->{b_up}->Enable(0);
    $state{sbefiles} = \@files;
    $state{windowtitle} = $folder;
}

sub OnFilelistDeselectAll {
    my ($self, $event) = @_;
    $self->{w_rearrange}->Check($_,0) for 0..$#{$state{sbefiles}};
}

sub OnFilelistOpen {
    my ($self, $event) = @_;
    my $md = Wx::FileDialog->new
      ($self, _T("Choose file list"),
       $state{sbefolder}, "filelist.txt",
       "Text files (*.txt)|*.txt",
       0|wxFD_OPEN|wxFD_FILE_MUST_EXIST,
       wxDefaultPosition);
    my $ret = $md->ShowModal;
    if ( $ret == wxID_OK ) {
	my $file = $md->GetPath;
	my @files = loadlines($file);
	$self->{w_rearrange}->Set(\@files);
	$self->{w_rearrange}->Check($_,1) for 0..$#files;
	$self->{sz_rearrange}->Layout;
	$state{sbefiles} = \@files;
	$self->log( 'I', "Loaded file list from $file" );
    }
    $md->Destroy;
}

sub OnFilelistSave {
    my ($self, $event) = @_;
    my $md = Wx::FileDialog->new
      ($self, _T("Choose file to store the current file list"),
       $state{sbefolder}, "filelist.txt",
       "Text files (*.txt)|*.txt",
       0|wxFD_SAVE|wxFD_OVERWRITE_PROMPT,
       wxDefaultPosition);
    my $ret = $md->ShowModal;
    if ( $ret == wxID_OK ) {
	my $file = $md->GetPath;
	open( my $fd, '>:utf8', $file );
	my $filelist = "";
	my @files = @{$state{sbefiles}};
	for ( $self->{w_rearrange}->GetCurrentOrder ) {
	    $filelist .= "$files[$_]\n" unless $_ < 0;
	}
	print $fd $filelist;
	$self->log( 'I', "Saved file list to $file" );
	close($fd);
    }
    $md->Destroy;
}

sub OnFilelistSelectAll {
    my ($self, $event) = @_;
    $self->{w_rearrange}->Check($_,1) for 0..$#{$state{sbefiles}};
}

sub OnFilelistUse {
    my ( $self, $event ) = @_;
    $self->OnDirPickerChanged($event);
}

sub OnRearrangeDown {
    my ($self, $event) = @_;
    for ( $self->{w_rearrange} ) {
	$_->MoveCurrentDown if $_->CanMoveCurrentDown;
	$self->{b_down}->Enable($_->CanMoveCurrentDown);
	$self->{b_up}->Enable($_->CanMoveCurrentUp);
    }
}

sub OnRearrangeDSelect {
    my ($self, $event) = @_;
    my $file = join( "/", $state{sbefolder},
		     $state{sbefiles}->[$self->{w_rearrange}->GetSelection] );
    return unless $self->GetParent->{p_editor}->openfile($file);
    $self->prv and $self->prv->discard;
    $state{from_songbook} = 1 + $self->{w_rearrange}->GetSelection;
    $self->GetParent->select_mode("editor");
}

sub OnRearrangeSelect {
    my ($self, $event) = @_;
    for ( $self->{w_rearrange} ) {
	$self->{b_down}->Enable($_->CanMoveCurrentDown);
	$self->{b_up}->Enable($_->CanMoveCurrentUp);
    }
}

sub OnRearrangeUp {
    my ($self, $event) = @_;
    for ( $self->{w_rearrange} ) {
	$_->MoveCurrentUp if $_->CanMoveCurrentUp;
	$self->{b_down}->Enable($_->CanMoveCurrentDown);
	$self->{b_up}->Enable($_->CanMoveCurrentUp);
    }
}

sub OnRecursive {
    my ( $self, $event ) = @_;
    $self->OnDirPickerChanged($event);
}

sub OnStdCoverChecked {
    my ( $self, $event ) = @_;
    $self->{l_cover}->Enable( !$self->{cb_stdcover}->IsChecked );
    $self->{fp_cover}->Enable( !$self->{cb_stdcover}->IsChecked );
    $self->{l_exporttitle}->Enable( $self->{cb_stdcover}->IsChecked );
    $self->{t_exporttitle}->Enable( $self->{cb_stdcover}->IsChecked );
    $self->{l_exportstitle}->Enable( $self->{cb_stdcover}->IsChecked );
    $self->{t_exportstitle}->Enable( $self->{cb_stdcover}->IsChecked );
}

1;
