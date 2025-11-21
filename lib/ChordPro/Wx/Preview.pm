#! perl

use v5.26;
use Object::Pad;
use utf8;
use Carp;

class ChordPro::Wx::Preview;

use ChordPro;
use ChordPro::Files;
use ChordPro::Paths;
use ChordPro::Wx::Config;
use ChordPro::Utils qw( demarkup :xp );

use Wx ':everything';
use Wx::Locale gettext => '_T';
use File::Temp qw( tempfile tempdir );
use File::Basename qw(basename);
use Ref::Util qw( is_hashref );

field $panel			:param;
field $msgs;
field $fatal;
field $died;
field $tmpdir;
field $preview_cho		:accessor;
field $preview_file;
field $preview_tmp;
field $unsaved_preview		:mutator;

BUILD {
    $tmpdir = tempdir( CLEANUP => 1 );
    $preview_cho = fn_catfile( $tmpdir, "preview.cho" );
}

method _warn( @m ) {
    $self->log( 'W',  join("",@m) );
    $msgs++;
}

method _info( @m ) {
    $self->log( 'I',  join("",@m) );
}

method _die( @m ) {
    $self->log( 'E',  join("", @m) );
    $msgs++;
    $fatal++;
    $died++;
}

method log( $level, $msg ) {
    $panel->log( $level, $msg );
}

method preview( $args, %opts ) {

    unlink($preview_file) if $preview_file;

    my $annotate = eval { $panel->prepare_annotations };

    #### ChordPro

    @ARGV = ();			# just to make sure
    push( @ARGV, "--debug" ) if $state{debug};
    push( @ARGV, "--trace" ) if $state{trace};
    push( @ARGV, "--verbose" ) for 1..($state{verbose}//0);

    $msgs = $fatal = $died = 0;
    local $SIG{__WARN__} = sub {
	if ( $state{debuginfo} && $_[0] =~ /^ChordPro invoked/ ) {
	    $self->log( 'I', "@_" );
	}
	else {
	    $self->_warn(@_);
	    $panel->add_annotation( $1-1, $2 )
	      if $annotate && "@_" =~ /^Line (\d+),\s+(.*)/;
	}
    };

    #    $SIG{__DIE__}  = \&_die;

    my $haveconfig = List::Util::any { $_ eq "--config" } @$args;
    if ( $preferences{skipstdcfg} ) {
	push( @ARGV, '--nodefaultconfigs' );
    }

    for my $preset ( qw( instruments styles stylemods ) ) {
	for my $p ( @{$preferences{"preset_$preset"}} ) {
	    next if $p->{default};
	    next unless defined $p->{file};
	    push( @ARGV, "--config", $p->{file} );
	    $haveconfig++;
	}
    }

    if ( $preferences{enable_configfile} ) {
	$haveconfig++;
	push( @ARGV, '--config', $preferences{configfile} );

    }
    local $ENV{CHORDPRO_LIB};
    if ( $preferences{enable_customlib} ) {
	$ENV{CHORDPRO_LIB} = $preferences{customlib};
    }
    CP->setup_resdirs;

    if ( $preferences{enable_xcode} ) {
	my $c = $preferences{preset_xcodes}[0];
	unless ( $c->{default} ) {
	    $haveconfig++;
	    push( @ARGV, '--transcode', $c->{system} );
	}
    }

    if ( $preferences{preset_notations} ) {
	my $c = $preferences{preset_notations}[0];
	if ( $c && !$c->{default} ) {
	    $haveconfig++;
	    push( @ARGV, '--config', $c->{file} );
	}
    }

    push( @ARGV, '--noconfig' ) unless $haveconfig;

    if ( $preferences{enable_htmlviewer} ) {
	$preview_file = fn_catfile( $tmpdir, "preview.html" );
	push( @ARGV, '--generate', "HTML" );
    }
    else {
	$preview_file = fn_catfile( $tmpdir, "preview.pdf" );
	push( @ARGV, '--generate', "PDF" );
    }
    push( @ARGV, '--output', $preview_file );

    # Transpose. See also PanelRole.pm.
    $state{"xpose_$_"} ||= 0
      for qw( enabled semitones accidentals );
    if ( $state{xpose_enabled} ) {
	my $pfx;
	if ( $state{xpose_accidentals} == XP_SHARP ) {
	    $pfx = "s"
	}
	elsif ( $state{xpose_accidentals} == XP_FLAT ) {
	    $pfx = "f"
	}
	else {
	    $pfx = "";
	}
	push( @ARGV, '--transpose', $state{xpose_semitones} . $pfx );
    }

    push( @ARGV, '--define', 'diagnostics.format=Line %n, %m' );
    push( @ARGV, '--define', 'debug.runtimeinfo=0' ) unless $state{debuginfo};

    push( @ARGV, @$args ) if @$args;
    push( @ARGV, $preview_cho ) unless $opts{filelist};

    if ( $state{trace} || $state{debug}
	 || $state{verbose} && $state{verbose} > 1 ) {
	$self->log( 'I', "Command line: @ARGV\n" );
	$self->log( 'I', "CHORDPRO_LIB: $ENV{CHORDPRO_LIB}\n" ) if $ENV{CHORDPRO_LIB};
	#$self->log( 'I', "$_" ) for split( /\n+/, $panel->GetParent->aboutmsg() );
    }
    my $options;
    my $dialog;
    my $phase;
    push( @ARGV, "--progress_callback", sub {
	      my %ctl = @_;
	      $phase = $ctl{phase} if $ctl{phase};
	      $self->log( 'I', "Progress[$phase] " . $ctl{index} .
			  " of " . $ctl{total} . ": " .
			  demarkup($ctl{msg}) )
		if $ctl{index} && ($ctl{total}||0) > 1;

	      if ( $ctl{index} == 0 ) {
		  return 1 unless ($ctl{total}||0) > 1;
		  $dialog = Wx::ProgressDialog->new
		    ( "Processing...",
		      'Starting',
		      $ctl{total}, $panel,
		      wxPD_CAN_ABORT|wxPD_AUTO_HIDE|wxPD_APP_MODAL|
		      wxPD_ELAPSED_TIME|wxPD_ESTIMATED_TIME|wxPD_REMAINING_TIME );
	      }
	      elsif ( $dialog ) {
		  $dialog->Update( $ctl{index},
				   "Song " . $ctl{index} . " of " .
				   $ctl{total} . ": " .
				   demarkup($ctl{msg}) )
		    and return 1;
		  $self->log( 'I', "Processing cancelled." );
		  return;
	      }

	      return 1;
	  } );

    require Encode;
    for ( @ARGV ) {
	next if ref ne "";
#	$_ = Encode::encode_utf8($_);
    }

    eval {
	$options = ChordPro::app_setup( "ChordPro", $ChordPro::VERSION );
    };

    $self->_die($@), goto ERROR if $@ && !$died;

    $options->{verbose} = $state{verbose} || 0;
    $options->{trace} = $state{trace} || 0;
    $options->{debug} = $state{debug} || $state{debuginfo};
    $options->{diagformat} = 'Line %n, %m';
    # Actual file name.
    $options->{filesource} = $state{currentfile};
    $options->{silent} = 1;

    eval {
	ChordPro::main($options);
    };
    $dialog->Destroy if $dialog;
    $self->_die($@), goto ERROR if $@ && !$died;
    goto ERROR unless fs_test( e => $preview_file );

    $unsaved_preview = 1;
    if ( $preferences{enable_htmlviewer} ) {
	fs_copy( CP->findres( $_, class => "styles" ),
		 fn_catfile( $tmpdir, $_ ) )
	  for qw( chordpro.css chordpro_print.css );
    }

    if ( !$preferences{enable_pdfviewer}
	 && $panel->{webview}->isa('Wx::WebView') ) {

	for ( $panel ) {
	    my $top = wxTheApp->GetTopWindow;
	    my ($w,$h) = $top->GetSizeWH;
	    my $want = ref($panel) =~ /Editor/ ? 700 : 900;
	    $top->SetSize( $w+400, $h ) if $w < $want;
	    unless ( $_->{sw_lr}->IsSplit ) {
		$_->{sw_lr}->SplitVertically ( $_->{p_left},
					       $_->{p_right},
					       $state{sash}{$_->panel."_lr"} // 0.5 );
	    }
	}

	Wx::Event::EVT_WEBVIEW_LOADED
	    ( $panel, $panel->{webview}, $self->can("OnWebViewLoaded") );
	Wx::Event::EVT_WEBVIEW_ERROR
	    ( $panel, $panel->{webview}, $self->can("OnWebViewError") );

	use URI::file;
	my $wf = URI::file->new($preview_file);
	$wf =~ s;///([A-Z]):/;///$1|/;;
	$self->log( 'I', "Preview " . substr($wf,0,128) );
	$panel->{webview}->LoadURL($wf);
    }
    else {
	$self->log( 'S', "Output generated, starting previewer");

	if ( my $cmd = $preferences{pdfviewer} ) {
	    if ( $cmd =~ s/\%f/$preview_file/g ) {
	    }
	    elsif ( $cmd =~ /\%u/ ) {
		my $u = _makeurl($preview_file);
		$cmd =~ s/\%u/$u/g;
	    }
	    else {
		$cmd .= " \"$preview_file\"";
	    }
	    Wx::ExecuteCommand($cmd);
	}
	else {
	    my $wxTheMimeTypesManager = Wx::MimeTypesManager->new;
	    my $ft = $wxTheMimeTypesManager->GetFileTypeFromExtension
	      ( $preferences{enable_htmlviewer} ? "html" : "pdf");
	    if ( $ft && ( my $cmd = $ft->GetOpenCommand($preview_file) ) ) {
		Wx::ExecuteCommand($cmd);
	    }
	    else {
		Wx::LaunchDefaultBrowser($preview_file);
	    }
	}
    }

    $dialog->Destroy if $dialog;
    unlink( $preview_cho );

  ERROR:
    if ( $msgs ) {
	$panel->alert(1);
	$self->log( 'S',  $msgs . " message" .
		    ( $msgs == 1 ? "" : "s" ) );
	if ( $fatal ) {
	    $self->log( 'E',  "Fatal problems found." );
	    return;
	}
	else {
	    $self->log( 'W',  "Problems found." );
	}
    }
    elsif ( !fs_test( s => $preview_file ) ) {
	$panel->alert(1);
	$self->log( 'W',  "Nothing to view. Empty song?" );
    }
    return;
}

sub OnWebViewLoaded {
}

sub OnWebViewError {
    my ( $self, $event ) = @_;
    my $errorstring = $event->GetString;
    my $url = $event->GetURL;

    my $errormap =
      { wxWEBVIEW_NAV_ERR_CONNECTION()	    => 'wxWEB_NAV_ERR_CONNECTION',
	wxWEBVIEW_NAV_ERR_CERTIFICATE()	    => 'wxWEB_NAV_ERR_CERTIFICATE',
	wxWEBVIEW_NAV_ERR_AUTH()	    => 'wxWEB_NAV_ERR_AUTH',
	wxWEBVIEW_NAV_ERR_SECURITY()	    => 'wxWEB_NAV_ERR_SECURITY',
	wxWEBVIEW_NAV_ERR_NOT_FOUND()	    => 'wxWEB_NAV_ERR_NOT_FOUND',
	wxWEBVIEW_NAV_ERR_REQUEST()	    => 'wxWEB_NAV_ERR_REQUEST',
	wxWEBVIEW_NAV_ERR_USER_CANCELLED()  => 'wxWEB_NAV_ERR_USER_CANCELLED',
	wxWEBVIEW_NAV_ERR_OTHER()	    => 'wxWEB_NAV_ERR_OTHER',
      };

    my $errorid = $event->GetInt;
    my $errname = exists( $errormap->{$errorid} ) ? $errormap->{$errorid} : '<UNKNOWN ID>';

    $self->log( 'E',
		sprintf( 'Getting %s Webview reports the following error code and string : %s : %s',
			 $url, $errname, $errorstring ) );
}

sub _makeurl {
    my $u = shift;
    $u =~ s;\\;/;g;
    $u =~ s/([^a-z0-9---_\/.~])/sprintf("%%%02X", ord($1))/ieg;
    $u =~ s/^([a-z])%3a/\/$1:/i;	# Windows
    return "file://$u";
}

method save {
    return unless fs_test( s => $preview_file );

    if ( $preferences{enable_htmlviewer} ) {
	return $panel->{webview}->Print;
    }

    my $savefile = "preview";
    if ( $state{mode} eq "editor" && $state{currentfile} ) {
	$savefile = $state{currentfile} =~ s/\.\w+$//r;
    }
    if ( $state{mode} eq "sbexport" && $state{sbe_folder} ) {
	$savefile = $state{sbe_folder} . ".pdf";
    }

    my $fd = Wx::FileDialog->new
      ( $panel,
	_T("Choose output file"),
	fn_dirname($savefile), fn_basename($savefile),
	"*.pdf",
	0|wxFD_SAVE|wxFD_OVERWRITE_PROMPT );
    my $ret = $fd->ShowModal;
    my $fn = $fd->GetPath;
    $fd->Destroy;

    if ( $ret == wxID_OK ) {
	if ( fs_copy( $preview_file, $fn ) ) {
	    $unsaved_preview = 0;
	}
	else {
	    my $md = Wx::MessageDialog->new
	      ( $self,
		"Cannot save to $fn\n$!",
		"Error saving file",
		0 | wxOK | wxICON_ERROR);
	    $md->ShowModal;
	    $md->Destroy;
	}
    }
    return $ret;
}

method have_preview {
    fs_test( s => $preview_file );
}

method discard {
    $unsaved_preview = 0;
    unlink($preview_file);
}

1;
