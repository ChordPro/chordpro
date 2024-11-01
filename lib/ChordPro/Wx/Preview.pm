#! perl

use v5.26;
use Object::Pad;
use utf8;
use Carp;

class ChordPro::Wx::Preview;

use ChordPro;
use ChordPro::Paths;
use ChordPro::Wx::Config;
use ChordPro::Utils qw( demarkup );

use Wx ':everything';
use Wx::Locale gettext => '_T';

use File::Temp qw( tempfile );
use File::Basename qw(basename);

field $panel			:param;
field $msgs;
field $fatal;
field $died;
field $preview_cho		:accessor;
field $preview_pdf;
field $preview_tmp;
field $unsaved_preview		:mutator;

ADJUST {
    ( undef, $preview_cho ) = tempfile( OPEN => 0 );
    $preview_pdf = $preview_cho . ".pdf";
    $preview_cho .= ".cho";
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

    unlink($preview_pdf);

    my $annotate = eval { $panel->prepare_annotations };

    #### ChordPro

    @ARGV = ();			# just to make sure

    $msgs = $fatal = $died = 0;
    local $SIG{__WARN__} = sub {
	$self->_warn(@_);
	$panel->add_annotation( $1-1, $2 )
	  if $annotate && "@_" =~ /^Line (\d+),\s+(.*)/;

    };

    #    $SIG{__DIE__}  = \&_die;

    my $haveconfig = List::Util::any { $_ eq "--config" } @$args;
    if ( $preferences{skipstdcfg} ) {
	push( @ARGV, '--nodefaultconfigs' );
    }
    if ( $preferences{enable_presets} && $preferences{cfgpreset} ) {
	# Only include the ones we have.
	my %s = ( map { $_ => 1 } @{$state{styles}}, @{$state{userstyles}} );
	foreach ( @{ $preferences{cfgpreset} } ) {
	    next unless exists($s{$_});
	    push( @ARGV, '--config', $_ );
	    $haveconfig++;
	}
    }
    if ( $preferences{enable_configfile} ) {
	$haveconfig++;
	push( @ARGV, '--config', $preferences{configfile} );

    }
    delete $ENV{CHORDPRO_LIB};
    if ( $preferences{enable_customlib} ) {
	$ENV{CHORDPRO_LIB} = $preferences{customlib};
    }
    CP->setup_resdirs;
    if ( $preferences{xcode} ) {
	$haveconfig++;
	push( @ARGV, '--transcode', $preferences{xcode} );
    }

    if ( $preferences{notation} ) {
	$haveconfig++;
	push( @ARGV, '--config', 'notes:' . $preferences{notation} );
    }

    push( @ARGV, '--noconfig' ) unless $haveconfig;

    push( @ARGV, '--output', $preview_pdf );
    push( @ARGV, '--generate', "PDF" );

    push( @ARGV, '--transpose', $state{xpose} ) if $state{xpose};

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
    goto ERROR unless -e $preview_pdf;

    $unsaved_preview = 1;
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
					       $_->{$panel->panel."_lr"} // 0.5 );
	    }
	}

	Wx::Event::EVT_WEBVIEW_LOADED
	    ( $panel, $panel->{webview}, $self->can("OnWebViewLoaded") );
	Wx::Event::EVT_WEBVIEW_ERROR
	    ( $panel, $panel->{webview}, $self->can("OnWebViewError") );

	use URI::file;
	my $wf = URI::file->new($preview_pdf);
	$wf =~ s;///([A-Z]):/;///$1|/;;
	$self->log( 'I', "Preview " . substr($wf,0,128) );
	$panel->{webview}->LoadURL($wf);
    }
    else {
	$self->log( 'S', "Output generated, starting previewer");

	if ( my $cmd = $preferences{pdfviewer} ) {
	    if ( $cmd =~ s/\%f/$preview_pdf/g ) {
	    }
	    elsif ( $cmd =~ /\%u/ ) {
		my $u = _makeurl($preview_pdf);
		$cmd =~ s/\%u/$u/g;
	    }
	    else {
		$cmd .= " \"$preview_pdf\"";
	    }
	    Wx::ExecuteCommand($cmd);
	}
	else {
	    my $wxTheMimeTypesManager = Wx::MimeTypesManager->new;
	    my $ft = $wxTheMimeTypesManager->GetFileTypeFromExtension("pdf");
	    if ( $ft && ( my $cmd = $ft->GetOpenCommand($preview_pdf) ) ) {
		Wx::ExecuteCommand($cmd);
	    }
	    else {
		Wx::LaunchDefaultBrowser($preview_pdf);
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
    return unless -s $preview_pdf;
    my $fd = Wx::FileDialog->new
      ( $panel,
	_T("Choose output file"),
	"", "",
	"*.pdf",
	0|wxFD_SAVE|wxFD_OVERWRITE_PROMPT );
    my $ret = $fd->ShowModal;
    if ( $ret == wxID_OK ) {
	use File::Copy;
	copy( $preview_pdf, $fd->GetPath );
	$self->discard;
    }
    $fd->Destroy;
    return $ret;
}

method discard {
    $unsaved_preview = 0;
}

1;
