#! perl

use v5.26;
use feature 'signatures';
no warnings 'experimental::signatures';
use utf8;

################ Entry ################

our $options;
our $Wx_min = "3.004";

package ChordPro::Wx::WxChordPro;

use parent qw( Wx::App ChordPro::Wx::Main );

use ChordPro::Paths;
use ChordPro::Wx::Config;

use Wx qw( wxACCEL_CTRL WXK_CONTROL_Q wxID_EXIT );

sub run( $self, $opts ) {

    $options = $opts;

    #### Start ################

    ChordPro::Wx::WxChordPro->new->MainLoop();

}

sub OnInit( $self ) {

    $self->SetAppName("ChordPro");
    $self->SetVendorName("ChordPro.ORG");
    Wx::InitAllImageHandlers();
    ChordPro::Wx::Config->Setup($options);
    ChordPro::Wx::Config->Load($options);

    my $main = ChordPro::Wx::Main->new;
    return 0 unless $main->init($options);

    $self->SetTopWindow($main);
    $main->Show(1);

    if ( $options->{maximize} ) {
	$main->Maximize(1);
    }

    elsif ( $options->{geometry}
	    && $options->{geometry} =~ /^(?:(\d+)x(\d+))?(?:([+-]\d+)([+-]\d+))?$/ ) {
	$main->SetSize( $1, $2 )
	  if defined($1) && defined($2);
	$main->Move( $3+0, $4+0 )
	  if defined($3) && defined($4);
    }

    return 1;
}

################ Static & Overrides ################

use Wx qw[:everything];
use ChordPro::Wx::Utils;
use File::Basename;

# Synchronous system call. Used in ChordPro::Utils module.
sub ::sys { Wx::ExecuteArgs( \@_, wxEXEC_SYNC | wxEXEC_HIDE_CONSOLE ); }

use warnings 'redefine';

################ Main ################

use Object::Pad;

class ChordPro::Wx::Main :isa(ChordPro::Wx::Main_wxg);

use ChordPro;	our $VERSION = $ChordPro::VERSION;
use ChordPro::Paths;
use ChordPro::Output::Common;
use ChordPro::Utils qw( is_msw is_macos demarkup );

use Wx qw[:everything];
use Wx::Locale gettext => '_T';

use ChordPro::Wx::Config;
use ChordPro::Wx::Utils;

use Encode qw(decode_utf8);
use File::Basename;

method log( $level, $msg ) {
    $msg =~ s/\n+$//;

    #    $msg = "[$level] $msg";
    if ( $level eq 'I' ) {
	Wx::LogMessage( "%s", $msg);
    }
    if ( $level eq 'S' ) {
	Wx::LogMessage( "%s", $msg );
    }
    elsif ( $level eq 'W' ) {
	Wx::LogWarning( "%s", $msg);
    }
    elsif ( $level eq 'E' ) {
	Wx::LogError( "%s", $msg);
    }
    elsif ( $level eq 'F' ) {
	Wx::LogFatal( "%s", $msg);
    }
}

BUILD {

    Wx::Event::EVT_IDLE($self, $self->can('OnIdle'));
    Wx::Event::EVT_CLOSE($self, $self->can('OnClose'));

    # Later, the panels will take over logging.
    Wx::Log::SetActiveTarget( Wx::LogStderr->new );
    $self->SetTitle("ChordPro");
    $self->SetIcon( Wx::Icon->new(CP->findres( "chordpro-icon.png", class => "icons" ), wxBITMAP_TYPE_ANY) );

    $self->attach_events;

    # MacOS file dialogs always filters with all wildcards. So if there is
    # an "All files|*.*" at the end, all file will match.
    # So either remove the *.* or use the following code:
    Wx::SystemOptions::SetOption("osx.openfiledialog.always-show-types", 1)
	if 0 && is_macos;
}

method attach_events() {

    # To select actions, we use a panel with a bitmap and a text.
    # We need to attach a mouse click (EVT_LEFT_UP) to the panel and
    # all of its children.

    my %panels =
      ( new	  => "OnNew",
	open      => "OnOpen",
	sbexport  => "OnExportFolder",
	example   => "OnHelp_Example",
	site      => "OnHelp_Site",
	help      => "OnHelp_ChordPro",
      );
    while ( my ( $p, $handler ) = each %panels ) {
	my $panel = $self->{"pn_$p"};
	#$handler = "OnI".ucfirst($p);
	my $h = $self->can($handler);
	warn("Missing pn handler $handler") unless $h;
	$handler = sub { &$h( $self, undef ) };
	Wx::Event::EVT_LEFT_UP( $panel, $handler );
	foreach my $n ( $panel->GetChildren ) {
	    Wx::Event::EVT_LEFT_UP( $n, $handler );
	}
    }

    Wx::Event::EVT_MAXIMIZE( $self, $self->can("OnMaximized") );
}

method select_mode( $mode ) {
    my @panels = panels;

    if ( $mode eq "initial" ) {
	$self->{$_}->Show(0) for @panels;
	$self->{p_initial}->Show(1);
	$self->refresh;
	$self->SetTitle("ChordPro");
    }
    else {
	$self->{p_initial}->Show(0);
	$self->{$_}->Show( $_ eq "p_$mode" ) for @panels;
	$self->{"p_$mode"}->refresh;
    }
    $self->{sz_main}->Layout;
    $state{mode} = $mode;
    return $state{panel} = $self->{"p_$mode"};
}

# Explicit (re)initialisation of this class.
method init( $options ) {

    $state{mode} = "initial";

    # General runtime options.
    $state{verbose}   = $options->{verbose};
    $state{trace}     = $options->{trace};
    $state{debug}     = $options->{debug};

    # For development/debugging.
    $state{logstderr} = $options->{logstderr};

    $self->SetStatusBar(undef);
    $self->get_preferences;
    $self->setup_menubar;
    Wx::Event::EVT_SYS_COLOUR_CHANGED( $self,
				       $self->can("OnSysColourChanged") );
    $self->init_theme;

    if ( @ARGV ) {
	my $arg = decode_utf8(shift(@ARGV));
	if ( -d $arg ) {
	    # This won't work on macOS packaged app.
	    return 1 if $self->select_mode("sbexport")->open_dir($arg);
	}
	elsif ( ! -r $arg ) {
	    Wx::MessageDialog->new( $self, "Error opening $arg",
				    "File Open Error",
				    wxOK | wxICON_ERROR )->ShowModal;
	}
	elsif ( 0 && is_macos ) {
	    # Somehow the macOS app crashes when it is started with
	    # a filename argument. So instead of opening the file
	    # here, we queue an Open menu command.
	    my $e = Wx::CommandEvent->new
	      ( wxEVT_COMMAND_MENU_SELECTED, wxID_OPEN );
	    $e->SetClientData($arg);
	    $self->GetEventHandler->AddPendingEvent($e);
	    return 1;
	    # The strange thing is that it does work on macOS when
	    # ChordPro is run as an ordinary program.
	    # And it also works on all other platforms.
	}
	else {
	    return $self->select_mode("editor")->openfile($arg);
	}
    }
    $self->select_mode("initial");
    return 1;
}

method refresh() {
    $self->init_recents;
    $self->update_menubar(M_MAIN);
}

method init_recents() {

    my $r = $state{recents};

    if ( defined $r->[0] ) {
	my $ctl = $self->{lb_recent};
	$ctl->Clear;
	$ctl->Enable(1);
	my $i = 0;
	for my $file ( @$r ) {
	    next unless -s $file;
	    last unless defined $file;
	    $ctl->Append( basename($file) );
	    $ctl->SetClientData( $i, $file );
	    $i++;
	}
    }
}

method init_theme() {
    # Command line always overrides. Once.
    if ( !defined $state{editortheme} && defined $options->{dark} ) {
	$state{editortheme} = $options->{dark} ? "dark" : "light";
    }
    elsif ( $preferences{editortheme} eq "auto"
	    && Wx::SystemSettings->can("GetAppearance") ) {
	my $a = Wx::SystemSettings::GetAppearance();
	if ( $a->IsDark ) {
	    $state{editortheme} = "dark";
	}
	else {
	    $state{editortheme} = "light";
	}
    }
    else {
	$state{editortheme} = $preferences{editortheme};
    }
    $self->log( 'I', "Using $state{editortheme} theme" );
}

method get_preferences() {

    # Find transcode setting.
    my $p = lc $preferences{xcode};
    if ( $p ) {
	if ( $p eq "-----" ) {
	    $preferences{enable_xcode} = 0;
	}
	else {
	    my $n = "";
	    for ( @{ $state{notations} } ) {
		next unless $_ eq $p;
		$n = $p;
		last;
	    }
	    $p = $n;
	}
    }
    $preferences{xcode} = $p;
    restorewinpos( $self, "main" );
    $self->Show(1);
}

method save_preferences() {
    savewinpos( $self, "main" );
    ChordPro::Wx::Config->Store;
}

method aboutmsg() {
    my $firstyear = 2016;
    my $year = 1900 + (localtime(time))[5];
    if ( $year != $firstyear ) {
	$year = "$firstyear,$year";
    }

    # Sometimes version numbers are localized...
    my $dd = sub { my $v = $_[0]; $v =~ s/,/./g; $v };

    local $ENV{CHORDPRO_LIB} =
      $preferences{enable_customlib} ? $preferences{customlib} : "";
    CP->setup_resdirs;
    my $msg = join
      ( "",
	"ChordPro version ",
	$dd->($ChordPro::VERSION),
	"\n",
	"https://www.chordpro.org\n",
	"Copyright $year Johan Vromans <jvromans\@squirrel.nl>\n",
	"\n",
	"GUI designed with wxGlade by the ChordPro Team\n\n",
	"Run-time information:\n",
	::runtimeinfo() =~ s/CHORDPRO_LIB/Custom lib  /rm
      );

    return $msg;
}

method check_saved() {
    for ( panels ) {
	return unless $self->{$_}->check_source_saved;
	return unless $self->{$_}->check_preview_saved;
    }
    # Panels may save prefs to preferences.
    $self->{$_}->save_preferences for panels;
    1;
}

################ Event handlers (alphabetic order) ################

# This method is called from the helper panels.
method OnAbout($event) {

    my $info = Wx::AboutDialogInfo->new;
    my $year = 1900 + (localtime(time))[5];
    $info->SetName("ChordPro");
    $info->SetVersion( $VERSION .
		       ( $VERSION =~ /_/ ? " (unsupported development snapshot)" : "" ) );
    $info->SetDescription("ChordPro is free software");
    $info->SetCopyright("Ⓒ 2016-$year Johan Vromans\nThe ChordPro Team");
    $info->SetWebSite( "https://www.chordpro.org",
		       "Visit the ChordPro web site");
    my $icon = Wx::Icon->new;
    $info->SetIcon($icon)
      if $icon->LoadFile( CP->findres("chordpro-splash.png",class=>"icons"),wxBITMAP_TYPE_PNG );
    Wx::AboutBox($info);
}

method OnClose($event) {
    return unless $self->check_saved;
    # Save preferences to persistent storage.
    $self->save_preferences;
    $self->Destroy;
}

# SHow the create buttons, or the recents list.
method OnCreateRecent($event) {
    $self->create_or_recent( $self->{rb_createrecent}->GetSelection );
}

method OnExportFolder($event) {

    # We handle this here for the same reasons as OnOpen.
    my $fd = Wx::DirDialog->new
      ( $self,
	_T("Select the folder with the songs"),
	$state{sbe_folder} // $state{songbookexport}{folder} // "",
	wxDD_DIR_MUST_EXIST );
    my $ret = $fd->ShowModal;
    if ( $ret == wxID_OK ) {
	$self->select_mode("sbexport")->open_dir( $fd->GetPath );
    }
    $fd->Destroy;
}

method OnIdle($event) {
    return if $self->{p_initial}->IsShown;
    my $mod = $self->{p_editor}->{t_editor}->IsModified;
    my $f = basename($state{windowtitle} // "ChordPro");
    if ( is_macos ) {
	wxTheApp->GetTopWindow->OSXSetModified($mod);
    }
    else {
	$f .= " (modified)" if $mod;
    }
    $f = "ChordPro — $f" if $state{windowtitle};
    $self->SetTitle($f);

    if ( $state{mode} eq "editor") {
	my $t = $self->{p_editor}->{t_editor}->GetText;
	if ( $t =~ /^\{\s*t(?:itle)?[: ]+([^\}]*)\}/m ) {
	    $self->{p_editor}->{l_status}->SetLabel(demarkup($1));
	}
    }

}

method OnHelp_ChordPro($event) {
    Wx::LaunchDefaultBrowser("https://www.chordpro.org/chordpro/");
}

method OnHelp_Config($event) {
    Wx::LaunchDefaultBrowser("https://www.chordpro.org/chordpro/chordpro-configuration/");
}

method OnHelp_Example($event) {
    $self->select_mode("editor");
    $self->{p_editor}->openfile( CP->findres( "swinglow.cho",
					      class => "examples" ),
				 1, " example.cho " );
}

method OnExpertLineEndings($event) {
    $state{vieweol} = wxTheApp->GetTopWindow->GetMenuBar->FindItem($event->GetId)->IsChecked;
    if ( $state{mode} eq "editor" ) {
	$self->{p_editor}->{t_editor}->SetViewEOL($state{vieweol});
    }
}

method OnExpertWhiteSpace($event) {
    $state{viewws} = wxTheApp->GetTopWindow->GetMenuBar->FindItem($event->GetId)->IsChecked;
    if ( $state{mode} eq "editor" ) {
	$self->{p_editor}->{t_editor}->SetViewWhiteSpace($state{viewws});
    }
}

method OnHelp_Site($event) {
    Wx::LaunchDefaultBrowser("https://www.chordpro.org/");
}

method OnMaximize($event) {
    my $top = wxTheApp->GetTopWindow;
    # Note that ShowFullScreen on macOS isn't really Full Screen.
    # https://github.com/ChordPro/chordpro/issues/373#issuecomment-2501855028
    my $full = $top->IsMaximized;
    $top->Maximize( !$full );
}

method OnNew($event) {
    if ( $state{mode} eq "initial" ) {
	$self->select_mode("editor");
	$self->{p_editor}->newfile;
    }
    else {
	$state{panel}->OnNew($event);
    }
}

method OnOpen($event) {
    return unless $self->check_saved;

    # In case it is a synthetic event.
    if ( $event && ( my $arg = $event->GetClientData ) ) {
	$self->select_mode("editor")->openfile( $arg, 1 );
	return;
    }

    # We handle the dialog here, so we do not have to switch to the editor
    # unless there's real editing to do.

    my $fd = Wx::FileDialog->new
      ( $self,
	_T("Choose ChordPro file"),
	dirname($state{recents}[0]//""),
	"",
	$state{ffilters},
	wxFD_OPEN|wxFD_FILE_MUST_EXIST );
    my $ret = $fd->ShowModal;
    if ( $ret == wxID_OK ) {
	$self->select_mode("editor")->openfile( $fd->GetPath, 1 );
    }
    $fd->Destroy;
}

method OnPreferences($event) {
    unless ( $self->{d_prefs} ) {
	require ChordPro::Wx::SettingsDialog;
	$self->{d_prefs} = ChordPro::Wx::SettingsDialog->new
	  ( $self, wxID_ANY, "Settings" );
	restorewinpos( $self->{d_prefs}, "prefs" );
    }
    else {
	$self->{d_prefs}->refresh;
    }

    # The Settings dialog operates on the current $preferences.
    my $ret = $self->{d_prefs}->ShowModal;
    savewinpos( $self->{d_prefs}, "prefs" );
    return unless $ret == wxID_OK;

    # $preferences may have changed.
    $self->save_preferences;

    # Update the requestor.
    $state{panel}->update_preferences unless $state{mode} eq "initial";
}

# On the recents list, click selects and displays the file name.
# Double click selects the entry for processing.

method OnRecentDclick($event) {
    my $file = $self->{l_recent}->GetLabel;
    $self->select_mode("editor");
    $self->{p_editor}->openfile( $file, 0 );
}

method OnRecentSelect($event) {
    my $n = $self->{lb_recent}->GetSelection;
    my $file = $self->{lb_recent}->GetClientData($n);
    $self->{l_recent}->SetLabel($file);
    $self->{l_recent}->SetToolTip($file);
}

method OnSysColourChanged($event) {
    $self->init_theme;
    $state{panel}->{t_editor}->refresh unless $state{mode} eq "initial";
}

################ End of Event handlers ################

1;
