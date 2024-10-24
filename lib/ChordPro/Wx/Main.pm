#! perl

use v5.26;
use feature 'signatures';
no warnings 'experimental::signatures';
use utf8;

################ Entry ################

our $options;

package ChordPro::Wx::WxChordPro;

use parent qw( Wx::App ChordPro::Wx::Main );

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
    ChordPro::Wx::Config::Setup;

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

# Override Wx::Bitmap to use resource search.
my $wxbitmapnew = \&Wx::Bitmap::new;
no warnings 'redefine';
*Wx::Bitmap::new = sub {
    # Only handle Wx::Bitmap->new(file, type) case.
    goto &$wxbitmapnew if @_ != 3 || -f $_[1];
    my ($self, @rest) = @_;
    $rest[0] = ChordPro::Paths->get->findres( basename($rest[0]), class => "icons" );
    $rest[0] ||= ChordPro::Paths->get->findres( "missing.png", class => "icons" );
    $wxbitmapnew->($self, @rest);
};

# Synchronous system call. Used in ChordPro::Utils module.
sub ::sys { Wx::ExecuteArgs( \@_, wxEXEC_SYNC | wxEXEC_HIDE_CONSOLE ); }

use warnings 'redefine';

################ Main ################

use Object::Pad;

class ChordPro::Wx::Main :isa(ChordPro::Wx::Main_wxg);

use ChordPro;	our $VERSION = $ChordPro::VERSION;
use ChordPro::Paths;
use ChordPro::Output::Common;
use ChordPro::Utils qw( is_msw is_macos );

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

ADJUST {

    Wx::Event::EVT_IDLE($self, $self->can('OnIdle'));
    Wx::Event::EVT_CLOSE($self, $self->can('OnClose'));

    # Later, the panels will take over logging.
    Wx::Log::SetActiveTarget( Wx::LogStderr->new );
    $self->SetTitle("ChordPro");
    $self->SetIcon( Wx::Icon->new(CP->findres( "chordpro-icon.png", class => "icons" ), wxBITMAP_TYPE_ANY) );

    # For the initial panel, suppress the menubar by providing an empty one.
    # On Windows this causes a problem with the layout, so we'll provide
    # a dummy menubar.
    my $menu = Wx::MenuBar->new;
    if ( is_msw ) {
	my $tmp_menu;
	$tmp_menu = Wx::Menu->new();
	$tmp_menu->Append(wxID_EXIT, _T("Exit"), _T("Close window and exit"));
	$menu->Append($tmp_menu, _T("File"));
    }
    $self->SetMenuBar($menu);

    $self->attach_events;

    # MacOS file dialogs always filters with all wildcards. So if there is
    # an "All files|*.*" at the end, all file will match.
    # So either remove the *.* or use the following code:
    Wx::SystemOptions::SetOption("osx.openfiledialog.always-show-types", 1)
	if 0 && is_macos;

    $self;
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
	exit      => "OnClose",
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
}

method select_mode( $mode ) {
    my @panels = panels;

    if ( $mode eq "initial" ) {
	$self->{$_}->Show(0) for @panels;
	$self->{p_initial}->Show(1);
	$self->refresh;
    }
    else {
	$self->{p_initial}->Show(0);
	$self->{$_}->Show( $_ eq "p_$mode" ) for @panels;
	$self->{"p_$mode"}->refresh;
    }
    $self->{sz_main}->Layout;
    return $self->{"p_$mode"};
}

# Explicit (re)initialisation of this class.
method init( $options ) {

    ChordPro::Wx::Config::Load;

    $state{logstderr} = $options->{logstderr};
    $state{verbose}   = $options->{verbose};
    $state{trace}     = $options->{trace};
    $state{debug}     = $options->{debug};
    $state{customlib} = delete $ENV{CHORDPRO_LIB};

    $self->SetStatusBar(undef);
    $self->get_preferences;

    if ( @ARGV ) {
	my $arg = decode_utf8(shift(@ARGV));
	if ( -d $arg && $self->{p_sbexport}->open_dir($arg) ) {
	    $self->select_mode("sbexport");
	    return 1;
	}
	elsif ( $self->{p_editor}->openfile($arg) ) {
	    $self->select_mode("editor");
	    return 1;
	}
	return 0;
    }
    else {
	$self->select_mode("initial");
    }
    return 1;
}

method refresh() {
    $self->init_recents;
    $self->SetMenuBar(undef);
}

method init_recents() {

    my $r = $state{recents};

    if ( defined $r->[0] ) {
	my $ctl = $self->{lb_recent};
	$ctl->Clear;
	$ctl->Enable(1);
	my $i = 0;
	for my $file ( @$r ) {
	    last unless defined $file;
	    $ctl->Append( basename($file) );
	    $ctl->SetClientData( $i, $file );
	    $i++;
	}
    }
    $self->{rb_createrecent}->SetSelection(0);
    $self->create_or_recent;
}

method create_or_recent( $sel=0 ) {
    if ( $sel ) {
	$self->{p_create}->Show(0);
	$self->{p_recent}->Show(1);
	$self->{p_recent}->SetSize( $self->{p_create}->GetSize );
    }
    else {
	$self->{p_create}->Show(1);
	$self->{p_recent}->Show(0);
    }
    $self->{sz_recent}->Layout;
    $self->{sz_createrecentpanels}->Layout;
}

method get_preferences() {

    # Find config setting.
    my $p = lc( $preferences{cfgpreset} );
    if ( ",$p" =~ quotemeta( "," . _T("Custom") ) ) {
	$state{cfgpresetfile} = $preferences{configfile};
    }
    my @presets;
    foreach ( @{$state{styles}} ) {
	if ( ",$p" =~ quotemeta( "," . lc($_) ) ) {
	    push( @presets, $_ );
	}
    }
    $preferences{cfgpreset} = \@presets;
    use DDP; Wx::LogMessage("%s",np(@presets));

    # Find transcode setting.
    $p = lc $preferences{xcode};
    if ( $p ) {
	if ( $p eq lc(_T("-----")) ) {
####????	    $p = $prefctl->{xcode};

	}
	else {
	    my $n = "";
	    for ( @{ $self->notationlist } ) {
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

    my $t = $preferences{cfgpreset};
    $preferences{cfgpreset} = join( ",", @{$preferences{cfgpreset}} ) if $t;
    ChordPro::Wx::Config::Store;
    $preferences{cfgpreset} = $t;
}

method aboutmsg() {
    my $firstyear = 2016;
    my $year = 1900 + (localtime(time))[5];
    if ( $year != $firstyear ) {
	$year = "$firstyear,$year";
    }

    # Sometimes version numbers are localized...
    my $dd = sub { my $v = $_[0]; $v =~ s/,/./g; $v };

    my $msg = join
      ( "",
	"ChordPro Preview Editor version ",
	$dd->($ChordPro::VERSION),
	"\n",
	"https://www.chordpro.org\n",
	"Copyright $year Johan Vromans <jvromans\@squirrel.nl>\n",
	"\n",
	"GUI designed with wxGlade\n\n",
	"Run-time information:\n",
	$::config->{settings}
	? ::runtimeinfo()
	: "  Not yet available (try again later)\n"
      );

    return $msg;
}

################ Event handlers (alphabetic order) ################

# This method is called from the helper panels.
method OnAbout($event) {

    my $info = Wx::AboutDialogInfo->new;
    my $year = 1900 + (localtime(time))[5];
    $info->SetName("ChordPro");
    $info->SetVersion( $VERSION .
		       ( $VERSION =~ /_/ ? " (unsupported development snapshot)" : "" ) );
    $info->SetDescription("ChordPro Preview Editor");
    $info->SetCopyright("Ⓒ 2016-$year Johan Vromans");
    $info->SetWebSite("https://www.chordpro.org",
		     "Visit the ChordPro web site");
    my $icon = Wx::Icon->new;
    $info->SetIcon($icon)
      if $icon->LoadFile( CP->findres("chordpro-splash.png",class=>"icons"),wxBITMAP_TYPE_PNG );
    Wx::AboutBox($info);
}

method OnClose($event) {
    $self->save_preferences;
    for ( panels ) {
	return unless $self->{$_}->checksaved;
    }
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
	_T("Choose folder to export"),
	$state{songbookexport}{folder}//"",
	wxDD_DIR_MUST_EXIST );
    my $ret = $fd->ShowModal;
    if ( $ret == wxID_OK ) {
	$self->select_mode("sbexport")->open_dir( $fd->GetPath );
    }
    $fd->Destroy;
}

method OnIdle($event) {
    return if $self->{p_initial}->IsShown;
    my $f = $state{windowtitle} // "ChordPro";
    $f = "*$f" if $self->{p_editor}->{t_editor}->IsModified;
    $self->SetTitle($f);
}

method OnHelp_ChordPro($event) {
    Wx::LaunchDefaultBrowser("https://www.chordpro.org/chordpro/");
}

method OnHelp_Config($event) {
    Wx::LaunchDefaultBrowser("https://www.chordpro.org/chordpro/chordpro-configuration/");
}

method OnHelp_Example($event) {
    $self->select_mode("editor");
    $self->{p_editor}->openfile( CP->findres( "swinglow.cho", class => "examples" ) );
}

method OnHelp_Site($event) {
    Wx::LaunchDefaultBrowser("https://www.chordpro.org/");
}

method OnNew($event) {
    $self->select_mode("editor");
    $self->{p_editor}->newfile;
}

method OnOpen($event) {

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

################ End of Event handlers ################

1;
