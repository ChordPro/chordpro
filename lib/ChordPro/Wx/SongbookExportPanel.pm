#! perl

use v5.26;
use Object::Pad;
use utf8;

class ChordPro::Wx::SongbookExportPanel
  :does( ChordPro::Wx::PanelRole )
  :isa( ChordPro::Wx::SongbookExportPanel_wxg );

use Wx qw[:everything];

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
    $self->setup_webview;

    # Single pane.
    $self->unsplit;

    return $self;
}

################ ################

method setup_menubar() {

    my $mb =
    make_menubar( $self,
      [ [ wxID_FILE,
	  [ [ wxID_NEW, "", "Create or open a ChordPro document", "OnNew" ],
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
	  [ [ wxID_ANY, "Preferences...\tCtrl-R",
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

################ API Functions ################

method refresh() {

    setup_logger($self);

    $self->setup_menubar;

    $self->log( 'I', "Using " .
		( ref($self->{p_editor}{webview}) eq 'Wx::WebView'
		  ? "embedded" : "external") . " PDF viewer" );

    my $c = $state{songbookexport};
    $self->{dp_folder}->SetPath( $state{sbefolder} // $c->{folder} // "");
    $self->{t_exporttitle}->SetValue($c->{title} // "");
    $self->{t_exportstitle}->SetValue($c->{subtitle} // "");
    $self->{fp_cover}->SetPath($c->{cover} // "");
    $self->{cb_stdcover}->SetValue($c->{stdcover} // 0);
    $self->OnStdCoverChecked();

    # Not handled yet by wxGlade.
    Wx::Event::EVT_DIRPICKER_CHANGED( $self, $self->{dp_folder}->GetId,
				      $self->can("OnDirPickerChanged") );


    $state{sbefiles} = [];

    if ( $state{sbefolder} && -d $state{sbefolder} ) {
	$self->{dp_folder}->SetPath($state{sbefolder});
	$self->log( 'I', "Using folder " . $state{sbefolder} );
	$self->OnDirPickerChanged(undef);
    }

    setup_messages_ctxmenu($self);
}

method save_prefs() {
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

    $self->save_prefs();

    my $filelist = "";
    my @o = $self->{w_rearrange}->GetList->GetCurrentOrder;
    for ( $self->{w_rearrange}->GetList->GetCurrentOrder ) {
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

method checksaved() {
    return 1 unless $state{unsavedpreview};
    my $md = Wx::MessageDialog->new
      ( $self,
	"The preview has not yet been saved.\n".
	"Do you want to save your changes?",
	"Preview has changed",
	0 | wxCANCEL | wxYES_NO | wxYES_DEFAULT | wxICON_QUESTION );
    my $ret = $md->ShowModal;
    $md->Destroy;
    return if $ret == wxID_CANCEL;
    if ( $ret == wxID_YES ) {
	$self->prv->save;
    }
    return 1;
}

################ Event handlers ################

sub OnDirPickerChanged {
    my ( $self, $event ) = @_;

    my $folder = $self->{dp_folder}->GetPath;
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
    my $src = "filelist.txt";
    if ( -s "$folder/$src" ) {
	$self->{cb_filelist}->Enable;
	$self->{cb_recursive}->Disable;
    }
    else {
	$self->{cb_filelist}->Disable;
    }
    if ( -s "$folder/$src" && !$self->{cb_filelist}->IsChecked ) {
	@files = loadlines("$folder/$src");
    }
    else {
	$src = "folder";
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
    }

    my $n = scalar(@files);
    my $msg = "Found $n ChordPro file" . ( $n == 1 ? "" : "s" ) . " in $src" .
      ( $self->{cb_recursive}->IsChecked ? "s" : "" );
    $self->{l_info}->SetLabel($msg);
    $self->log( 'S', $msg );

    if ( $Wx::wxVERSION < 3.001 ) {
	# Due to bugs in the implementation of the wxRearrangeCtrl widget
	# we cannot update it, so we must recreate the widget.
	# https://github.com/wxWidgets/Phoenix/issues/1052#issuecomment-434388084
	my @order = ( 0 .. $#files );
	my $w = Wx::RearrangeCtrl->new($self->{sz_export_outer}->GetStaticBox(), wxID_ANY, wxDefaultPosition, wxDefaultSize, \@order, \@files );
	$self->{sz_export_outer}->Replace( $self->{w_rearrange}, $w, 1 );
	$self->{w_rearrange}->Destroy;
	$self->{w_rearrange} = $w;
    }
    else {
	$self->{w_rearrange}->GetList->Set(\@files);
	$self->{w_rearrange}->GetList->Check($_,1) for 0..$#files;
    }
    unless ( $self->{w_rearrange}->IsShown ) {
	$self->{sl_rearrange}->Show;
	$self->{l_rearrange}->Show;
	$self->{w_rearrange}->Show;
	$self->{sz_export_inner}->Layout;
    }
    $self->{sz_ep}->Layout;
    $state{sbefiles} = \@files;
}

sub OnFilelistIgnore {
    my ( $self, $event ) = @_;
    $self->OnDirPickerChanged($event);
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
