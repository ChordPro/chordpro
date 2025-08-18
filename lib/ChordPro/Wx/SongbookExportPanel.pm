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

use ChordPro::Files;
use ChordPro::Wx::Config;
use ChordPro::Wx::Utils;

use File::LoadLines;
use File::Basename;

# WhoamI
field $panel :accessor = "sbexport";

# Just fill in the defaults.
sub BUILDARGS( $class, $parent=undef, $id=wxID_ANY,
	   $pos=wxDefaultPosition, $size=wxDefaultSize,
	   $style=0, $name="" ) {
   return( $parent, $id, $pos, $size, $style, $name );
}

BUILD {
    # Setup logger.
    $self->setup_logger;

    # Setup WebView, if possible.
    $self->setup_webview if $::options->{webview}//1;

    # Single pane.
    $self->unsplit;
}

################ ################

method name() { "Export Songbook" }

################ API Functions ################

method refresh() {

    setup_logger($self);

    $self->update_menubar( M_SONGBOOK );

    $state{have_webview} = ref($self->{webview}) eq 'Wx::WebView';

    # Flush pending messages.
    if ( $state{msgs} ) {
	$self->log( 'I', $_ ) for @{$state{msgs}};
	$state{msgs} = [];
    }
    $self->log( 'I', "Using " .
		( $state{have_webview}
		  ? "embedded" : "external") . " PDF viewer" );

    $self->{cb_recursive}->SetValue(1);

    $self->{dp_folder}->SetPath( $state{sbe_folder} // "");
    $self->{t_exporttitle}->SetValue($state{sbe_title} // basename($state{sbe_folder}//""));
    $self->{t_exportstitle}->SetValue($state{sbe_subtitle} // "");
    $self->{fp_cover}->SetPath($state{sbe_cover} // "");
    $self->{cb_stdcover}->SetValue($state{sbe_stdcover} // 1);
    $self->OnStdCoverChecked();

    if ( $state{sbe_folder} && fs_test( d => $state{sbe_folder} ) ) {
	$self->{dp_folder}->SetPath($state{sbe_folder});
	$self->log( 'I', "Using folder " . $state{sbe_folder} );
	$self->OnDirPickerChanged(undef);
    }

    $self->{w_rearrange}->SetSelection($state{from_songbook}-1)
      if $state{from_songbook};
    $state{from_songbook} = 0;
    my $font = Wx::Font->new($preferences{msgsfont});
    $self->{t_messages}->SetFont($font);
    setup_messages_ctxmenu($self);
    $self->previewtooltip;
    $self->messagestooltip;
    $self->set_focus;
}

method save_preferences() {
    # Volatile (this run only).
    $state{sbe_folder}   = $self->{dp_folder}->GetPath       // "";
    $state{sbe_title}    = $self->{t_exporttitle}->GetValue  // "";
    $state{sbe_subtitle} = $self->{t_exportstitle}->GetValue // "";
    $state{sbe_cover}    = $self->{fp_cover}->GetPath        // "";
    $state{sbe_stdcover} = $self->{cb_stdcover}->IsChecked   // 0;
    # Persistent.
    $state{songbookexport}{folder} = $state{sbe_folder};
}

method update_preferences() {
}

method open_dir($dir) {
    $dir =~ s/[\\\/]$//;
    $self->{dp_folder}->SetPath( $state{sbe_folder} = $dir );
    $state{sbe_title} //= basename( $state{sbe_folder} );
    $state{sbe_subtitle} //= "";
    $self->{t_exporttitle}->SetValue( $state{sbe_title} );
    $self->{t_exportstitle}->SetValue( $state{sbe_subtitle} );
    $self->OnDirPickerChanged;
}

method load_filelist($files) {
    my $file = shift( @$files );
    my @files;
    my $dir = fn_dirname( fn_rel2abs( $file ) );
    for ( @$files ) {
	next unless $_;
	next if m;^(#|//);;
	if ( /--title(?:=|\s+)(.*)/ ) {
	    $self->{t_exporttitle}->SetValue($1);
	    $self->{cb_stdcover}->SetValue(1);
	}
	elsif ( /--subtitle(?:=|\s+)(.*)/ ) {
	    $self->{t_exportstitle}->SetValue($1);
	}
	elsif ( /--cover(?:=|\s+)(.*)/ ) {
	    $self->{fp_cover}->SetPath($1);
	    $self->{cb_stdcover}->SetValue(0);
	}
	else {
	    push( @files, $_ );
	}
    }
    $self->{dp_folder}->SetPath($dir);
    $self->{w_rearrange}->Set(\@files);
    $self->{w_rearrange}->Check($_,1) for 0..$#files;
    $self->{sz_rearrange}->Layout;
    $state{sbe_folder} = $dir;
    $state{sbe_files} = \@files;
    $self->OnStdCoverChecked(undef);
    $self->log( 'I', "Loaded file list from $file" );
    return 1;
}

method preview( $args, %opts ) {
    use ChordPro::Wx::Preview;
    $self->prv //= ChordPro::Wx::Preview->new( panel => $self );
    $args //= [];

    my $folder = $self->{dp_folder}->GetPath;
    my @files = @{ $state{sbe_files} };
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
	      $self->{t_exporttitle}->GetValue // "" );
	if ( my $stitle = $self->{t_exportstitle}->GetValue ) {
	    push( @args, "--subtitle", $stitle );
	}
    }
    elsif ( my $cover = $self->{fp_cover}->GetPath ) {
	push( @args, "--cover", $cover );
    }
    $self->prv->preview( \@args, %opts );
    $self->previewtooltip;

}

method check_source_saved() { 1 }

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

method set_focus {
    $self->{dp_folder}->SetFocus;
}

################ Event handlers ################

sub OnDirPickerChanged {
    my ( $self, $event ) = @_;

    my $folder = $state{sbe_folder} = $self->{dp_folder}->GetPath;
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

    my $recurse = $self->{cb_recursive}->IsChecked;
    my $opts =
      { filter => qr/^[^.].*\.(cho|crd|chopro|chord|chordpro|pro)$/i,
	recurse => $recurse };
    my $files = fs_find( $folder, $opts );

    my $src = "folder";
    my $n = scalar(@$files);
    my $msg = "Found $n ChordPro file" . ( $n == 1 ? "" : "s" ) . " in $src" .
      ( $self->{cb_recursive}->IsChecked ? "s" : "" );
    $self->{l_info}->SetLabel($msg);
    $self->log( 'S', $msg );
    $self->{cb_recursive}->Enable( $opts->{subfolders} );

    my @files = sort
      map { $_->{name} =~ s;^\Q$folder\E/?;;; $_->{name} }
      @$files;

    $self->{w_rearrange}->Set(\@files);
    $self->{w_rearrange}->Check($_,1) for 0..$#files;
    $self->{sz_rearrange}->Layout;
    $self->{sz_left}->Layout;
    $self->{b_down}->Enable(0);
    $self->{b_up}->Enable(0);
    $state{sbe_files} = \@files;
    $state{windowtitle} = $folder;
}

sub OnFilelistDeselectAll {
    my ($self, $event) = @_;
    $self->{w_rearrange}->Check($_,0) for 0..$#{$state{sbe_files}};
}

sub OnFilelistOpen {
    my ($self, $event) = @_;
    my $md = Wx::FileDialog->new
      ($self, _T("Choose file list"),
       $state{sbe_folder}, "filelist.txt",
       "Text files (*.txt)|*.txt",
       0|wxFD_OPEN|wxFD_FILE_MUST_EXIST,
       wxDefaultPosition);
    my $ret = $md->ShowModal;
    if ( $ret == wxID_OK ) {
	$self->load_filelist( $md->GetPath );
    }
    $md->Destroy;
}

sub OnFilelistSave {
    my ($self, $event) = @_;
    my $md = Wx::FileDialog->new
      ($self, _T("Choose file to store the current file list"),
       $state{sbe_folder}, "filelist.txt",
       "Text files (*.txt)|*.txt",
       0|wxFD_SAVE|wxFD_OVERWRITE_PROMPT,
       wxDefaultPosition);
    my $ret = $md->ShowModal;
    if ( $ret == wxID_OK ) {
	my $file = $md->GetPath;
	open( my $fd, '>:utf8', $file );
	my $filelist = "";
	my @files = @{$state{sbe_files}};
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
    $self->{w_rearrange}->Check($_,1) for 0..$#{$state{sbe_files}};
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
    my $file = fn_catfile( $state{sbe_folder},
			   $state{sbe_files}->[$self->{w_rearrange}->GetSelection] );
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
