#! perl

use v5.26;
use Object::Pad;
use utf8;

class ChordPro::Wx::SettingsDialog
  :repr(HASH)
  :isa(ChordPro::Wx::SettingsDialog_wxg);

use Wx qw[:everything];
use Wx::Locale gettext => '_T';
use ChordPro::Files;
use ChordPro::Paths;
use ChordPro::Wx::Config;
use ChordPro::Wx::Utils;
use File::Basename;

BUILD ( $parent, $id, $title ) {
    $self->refresh;
    $self->{sz_prefs_outer}->Fit($self);
    $self->Layout;
    Wx::Event::EVT_SYS_COLOUR_CHANGED( $self,
				       $self->can("OnSysColourChanged") );
    # Do not DeletePage until we're sure none of the widgets are referenced.
    $self->{nb_preferences}->RemovePage(5)
      unless $preferences{expert};
    $self->{nb_preferences}->RemovePage(4)
      unless $preferences{pdfviewer};

    unless ( has_appearance() ) {
	$self->{ch_theme}->Delete(2); # Follow System
    }

    $self;
}

# BUilt-in descriptions for some notation systems.
my $notdesc =
  { "common"	   => "C, D, E, F, G, A, B",
    "dutch"	   => "C, D, E, F, G, A, B",
    "german"	   => "C, ... A, Ais/B, H",
    "latin"	   => "Do, Re, Mi, Fa, Sol, ...",
    "scandinavian" => "C, ... A, A#/Bb, H",
    "solfege"	   => "Do, Re, Mi, Fa, So, ...",
    "solfège"	   => "Do, Re, Mi, Fa, So, ...",
    "nashville"	   => "1, 2, 3, ...",
    "roman"	   => "I, II, III, ...",
  };

method get_configfile() {
    $preferences{configfile} || ""
}

method refresh() {
    $self->fetch_prefs;
    $self->{t_editor}->refresh;
    $self->{t_editor}->SetText(<<EOD);
{title: St. James Infirmary Blues}
{subtitle: Traditional}

# Song starts here.
I went [Em]down to the [Am]St James In[Em]firmary
I found my [Am]baby [B7]there
EOD
}

method enablecustom() {
    my $n = $self->{cb_configfile}->IsChecked;
    $self->{fp_customconfig}->Enable($n);
    $self->{b_createconfig}->Enable($n);

    $n = $self->{cb_customlib}->IsChecked;
    $self->{dp_customlibrary}->Enable($n);

    $n = $self->{cb_tmplfile}->IsChecked;
    $self->{fp_tmplfile}->Enable($n);
}

method all_styles( $userpostfix = "" ) {
    sort
      map { lc } @{ $state{styles} },
                 map { lc "$_$userpostfix" } @{ $state{userstyles} };
}

method fetch_prefs() {

    # Transfer preferences to the dialog.

    # Skip default (system, user, song) configs.
    $self->{cb_skipstdcfg}->SetValue($preferences{skipstdcfg});

    # Add the styles to the presets.
    my $ctl = $self->{ch_extra2};
    $ctl->Clear;
    my $neat = sub {
	my ($t ) = @_;
	$t = ucfirst(lc($t));
	$t =~ s/_/ /g;
	$t =~ s/ (.)/" ".uc($1)/eg;
	$t;
    };
    my $i = 0;
    for ( $self->all_styles( " (user)" ) ) {
	$ctl->Append( $neat->($_) );
    }
    $ctl = $self->{ch_style};
    $ctl->Clear;
    $ctl->Append( "Default",
		  { desc => "Default ChordPro look." } );
    for ( sort keys %{$state{style_presets}} ) {
	$ctl->Append( $state{style_presets}->{$_}->{title},
		      $state{style_presets}->{$_},
		    );
    }
    $ctl->SetSelection(0);
    $self->set_style_desc("Default ChordPro look.");

    # Check the presets that were selected.
    my $p = $preferences{cfgpreset};
    foreach ( @$p ) {
	next if $_ eq "custom";	# legacy
	my $t = $neat->($_);
	my $n = $ctl->FindString($t);
	$n = $ctl->FindString( $t = "$t (user)" ) if $n == wxNOT_FOUND;
	unless ( $n == wxNOT_FOUND ) {
	    $ctl->Check( $n, 1 );
	}
    }
#    $self->{cb_presets}->SetValue($preferences{enable_presets});
    $self->{ch_extra2}->Enable($preferences{enable_presets});

    # Custom config file.
    $self->{cb_configfile}->SetValue($preferences{enable_configfile});
    $self->{fp_customconfig}->SetPath($preferences{configfile})
      if $preferences{configfile};

    # Custom library.
    $self->{cb_customlib}->SetValue($preferences{enable_customlib});
    $self->{dp_customlibrary}->SetPath($preferences{customlib})
      if $preferences{customlib};

    # New song template.
    $self->{cb_tmplfile}->SetValue($preferences{enable_tmplfile});
    $self->{fp_tmplfile}->SetPath($preferences{tmplfile})
      if $preferences{tmplfile};

    # Preferred filename extension.
    $self->{t_prefext}->SetValue( $preferences{chordproext} );

    # Editor.
    $self->{fp_editor}->SetSelectedFont( Wx::Font->new($preferences{editfont}) );
    $self->prefs2colours;
    $self->{cb_editorlines}->SetValue($preferences{editorlines});
    $self->{cb_editorwrap}->SetValue($preferences{editorwrap});
    $self->{sp_editorwrap}->SetValue($preferences{editorwrapindent});

    # Messages.
    $self->{fp_messages}->SetSelectedFont( Wx::Font->new($preferences{msgsfont}) );

    # Notation.
    $ctl = $self->{ch_notation};
    $ctl->Clear;
    my $n = 0;
    my $check = 0;
    for ( @{ $state{notations} } ) {
	my $s = ucfirst($_);
	$check = $n if $_ eq lc $preferences{notation};
	$s .= " (" . $notdesc->{lc($s)} .")" if $notdesc->{lc($s)};
	$ctl->Append($s);
	$ctl->SetClientData( $n, $_);
	$n++;
    }
    $ctl->SetSelection($check);

    # Transpose.
    $self->{cb_xpose}->SetValue( $preferences{enable_xpose} );
    $self->OnCbTranspose(undef);

    # Transcode.
    $ctl = $self->{ch_xcode};
    $ctl->Clear;
    $n = 0;
    for ( @{ $state{notations} } ) {
	my $s = ucfirst($_);
	$check = $n if $_ eq lc $preferences{xcode};
	$s .= " (" . $notdesc->{lc($s)} .")" if $notdesc->{lc($s)};
	$ctl->Append($s);
	$ctl->SetClientData( $n, $_);
	$n++;
    }
    $ctl->SetSelection($check);
    $self->{cb_xcode}->SetValue( $preferences{enable_xcode} );
    $self->OnCbTranscode(undef);

    # PDF Viewer.
    $self->{cb_pdfviewer}->SetValue($preferences{enable_pdfviewer});
    $self->{t_pdfviewer}->SetValue($preferences{pdfviewer})
      if $preferences{pdfviewer};
    $self->{t_pdfviewer}->Enable($self->{cb_pdfviewer}->IsChecked);

    # HTML Viewer.
    $self->{cb_htmlviewer}->SetValue($preferences{enable_htmlviewer});

    $self->enablecustom;
    $state{_prefs} = clone(\%preferences);

    # use DDP; p %preferences, as => "Fetched";
}

#               C      D      E  F      G      A        B C
my @xpmap = qw( 0 1  1 2 3  3 4  5 6  6 7 8  8 9 10 10 11 12 );
my @sfmap = qw( 0 7 -5 2 9 -3 4 -1 6 -6 1 8 -4 3 10 -2  5 0  );

method store_prefs() {

    # Transfer all preferences to the state.

    my $parent = $self->GetParent;

    # Skip default (system, user, song) configs.
    $preferences{skipstdcfg}  = $self->{cb_skipstdcfg}->IsChecked;

    # Presets.
#    $preferences{enable_presets} = $self->{cb_presets}->IsChecked;
    my $ctl = $self->{ch_extra2};
    my $cnt = $ctl->GetCount;
    my @p;
    my @styles = $self->all_styles;
    for ( my $n = 0; $n < $cnt; $n++ ) {
	next unless $ctl->IsChecked($n);
	push( @p, $styles[$n] );
    }
    $preferences{cfgpreset} = \@p;

    # Custom config file.
    $preferences{enable_configfile} = $self->{cb_configfile}->IsChecked;
    $preferences{configfile}        = $self->{fp_customconfig}->GetPath;

    # Custom library.
    $preferences{enable_customlib} = $self->{cb_customlib}->IsChecked;
    $preferences{customlib}        = $self->{dp_customlibrary}->GetPath;

    # New song template.
    $preferences{enable_tmplfile} = $self->{cb_tmplfile}->IsChecked;
    $preferences{tmplfile}        = $self->{fp_tmplfile}->GetPath;

    # Preferred filename extension.
    $preferences{chordproext} = $self->{t_prefext}->GetValue;

    # Editor.
    $preferences{editfont} = $self->{fp_editor}->GetSelectedFont->GetNativeFontInfoDesc;
    $self->colours2prefs;
    $preferences{editorwrap} = $self->{cb_editorwrap}->IsChecked;
    $preferences{editorwrapindent} = $self->{sp_editorwrap}->GetValue;

    # Messages.
    $preferences{msgsfont} = $self->{fp_messages}->GetSelectedFont->GetNativeFontInfoDesc;

    # Notation.
    my $n = $self->{ch_notation}->GetSelection;
    if ( $n > 0 ) {
	$preferences{notation} =
	  $self->{ch_notation}->GetClientData($n);
    }
    else {
       	$preferences{notation} = "";
    }

    # Transpose.
    $preferences{enable_xpose} = $self->{cb_xpose}->IsChecked;
    $preferences{xpose_from} = $xpmap[$self->{ch_xpose_from}->GetSelection];
    $preferences{xpose_to  } = $xpmap[$self->{ch_xpose_to  }->GetSelection];
    $preferences{xpose_acc}  = $self->{ch_acc}->GetSelection;
    $n = $preferences{xpose_to} - $preferences{xpose_from};
    $n += 12 if $n < 0;
    $n += 12 if $preferences{xpose_acc} == 1; # sharps
    $n -= 12 if $preferences{xpose_acc} == 2; # flats
    $state{xpose} = $n;

    # Transcode.
    $preferences{enable_xcode} = $self->{cb_xcode}->IsChecked;
    $n = $self->{ch_xcode}->GetSelection;
    if ( $n > 0 ) {
	$preferences{xcode} =
	  $self->{ch_xcode}->GetClientData($n);
    }
    else {
       	$preferences{xcode} = "";
    }

    # PDF Viewer.
    $preferences{enable_pdfviewer} = $self->{cb_pdfviewer}->IsChecked;
    $preferences{pdfviewer} = $self->{t_pdfviewer}->GetValue;

    # HTML Viewer.
    $preferences{enable_htmlviewer} = $self->{cb_htmlviewer}->IsChecked;

    # use DDP; p %preferences, as => "Stored";
}

method restore_prefs() {
    %preferences = %{ $state{_prefs} };
    # use DDP; p %preferences, as => "Restored";
}

method need_restart() {
    state $id = wxID_ANY;
    if ( $id == wxID_ANY ) {
	$id = Wx::NewId;
    }

    # Showing the InfoBar leads to a resize, which may cause
    # unwanted width change.
    my ( $w, $h ) = $self->GetSizeWH;
    $self->{w_infobar}->ShowMessage("    Changing the custom library requires restart",
				    wxICON_INFORMATION);
    $self->{sz_prefs_outer}->Fit($self);
    $self->SetSize([$w,-1]);
}

method get_selected_theme() {
    (qw(light dark auto))[$self->{ch_theme}->GetSelection];
}

method set_selected_theme($theme) {
    $self->{ch_theme}->SetSelection
      ( $theme eq "light" ? 0 : $theme eq "dark" ? 1 : 2 );
}

method colours2prefs {
    my $theme = $state{editortheme};
    $self->GetParent->init_theme;
    die("INTERNAL ERROR: invalid theme1\n")
      unless $theme eq "light" || $theme eq "dark";
    $preferences{editcolour}{$theme}{fg} = $self->{cp_fg}->GetAsHTML;
    $preferences{editcolour}{$theme}{bg} = $self->{cp_bg}->GetAsHTML;
    if ( $state{have_stc} ) {
	$preferences{editcolour}{$theme}{"s$_"} = $self->{"cp_s$_"}->GetAsHTML for 1..6;
	$preferences{editcolour}{$theme}{annfg} = $self->{cp_annfg}->GetAsHTML;
	$preferences{editcolour}{$theme}{annbg} = $self->{cp_annbg}->GetAsHTML;
    }
    $self->{t_editor}->refresh;
}

method prefs2colours() {

    $self->set_selected_theme( $preferences{editortheme} );
    if ( $preferences{editortheme} eq "auto" ) {
	$self->GetParent->init_theme;
	$self->{l_theme}->SetLabel( ucfirst $state{editortheme} );
    }
    else {
	$state{editortheme} = $preferences{editortheme};
	$self->{l_theme}->SetLabel("");
    }

    my $theme = $state{editortheme};
    die("INTERNAL ERROR: invalid theme2\n")
      unless $theme eq "light" || $theme eq "dark";

    $self->{cp_fg}->SetColour($preferences{editcolour}{$theme}{fg});
    $self->{cp_bg}->SetColour($preferences{editcolour}{$theme}{bg});
    if ( $state{have_stc} ) {
	for my $c ( "annfg", "annbg", map { "s$_" } 1..6 ) {
	    $self->{"cp_$c"}->Enable(1);
	    $self->{"l_$c"}->Enable(1);
	}
	$self->{"cp_s$_"}->SetColour($preferences{editcolour}{$theme}{"s$_"})
	  for 1..6;
	$self->{cp_annfg}->SetColour($preferences{editcolour}{$theme}{annfg});
	$self->{cp_annbg}->SetColour($preferences{editcolour}{$theme}{annbg});
    }
    else {
	my $grey = "#e0e0e0";
	for my $c ( "annfg", "annbg", map { "s$_" } 1..6 ) {
	    $self->{"cp_$c"}->SetColour($grey);
	    $self->{"cp_$c"}->Enable(0);
	    $self->{"l_$c"}->Enable(0);
	}
    }
    $self->{t_editor}->refresh;
}

################ Event handlers ################

#### General.

method OnAccept($event) {
    $self->store_prefs;
    $event->Skip;
}

method OnCancel($event) {
    $self->restore_prefs;
    $event->Skip;
}

# Only required for custom button.
# method OnIBDismiss($e) {
#     $self->{w_infobar}->Dismiss;
# }

#### Configs etc.

method OnConfigFile($event) {
    my $n = $self->{cb_configfile}->IsChecked;
    $self->{fp_customconfig}->Enable($n);
    $self->{b_createconfig}->Enable($n);
}

method OnCreateConfig($event) {
    $self->_OnCreateConfig( $event );
}

method _OnCreateConfig( $event, $fn = undef ) {
    unless ( defined $fn ) {
	my $fd = Wx::FileDialog->new( $self,
				      "Select a new configuration file",
				      "", "customconfig",
				      "*.json",
				      wxFD_SAVE|wxFD_OVERWRITE_PROMPT
				    );
	my $ret = $fd->ShowModal;
	return unless $ret == wxID_OK;
	$fn = $fd->GetPath;
	$fd->Destroy;
    }
    use File::Copy;
    my $cfg = fn_catfile( CP->findresdirs("config")->[-1],
			  $state{expert}
			  ? "chordpro.json"
			  : "config.tmpl" );
    if ( fs_copy( $cfg, $fn ) ) {
	$self->{fp_customconfig}->SetPath( fn_rel2abs($fn) );
    }
    else {
	my $md = Wx::MessageDialog->new
	  ( $self,
	    "Error creating $fn: $!",
	    "File open error",
	    wxOK | wxICON_ERROR );
	$md->ShowModal;
	$md->Destroy;
    }
}

method OnCustomConfigChanged($event) {
    my $path = $self->{fp_customconfig}->GetPath;

    unless ( $path =~ /\.\w+$/ ) {
	$self->{fp_customconfig}->SetPath( $path .= ".json" );
    }
    return if fs_test( s => $path );		# existing config

    my $md = Wx::MessageDialog->new
      ( $self,
	"The configuration file ".basename($path)." does not exist.".
	"Create it?",
	"Missing Configuration",
	wxYES | wxICON_QUESTION );
    my $ret = $md->ShowModal;
    $md->Destroy;
    return unless $ret == wxID_YES;
    $self->_OnCreateConfig( $event, $path );
}

method OnCustomLib($event) {
    my $n = $self->{cb_customlib}->IsChecked;
    $self->{dp_customlibrary}->Enable($n);
    $self->need_restart;
}

method OnCustomLibChanged($event) {
    $self->need_restart;
}


method OnSkipStdCfg($event) {
    $event->Skip;
}

method OnPresets($event) {
#    $self->{ch_presets}->Enable( $self->{cb_presets}->GetValue );
    $event->Skip;
}

method OnPrefExtChanged($event) {
    $preferences{chordproext} = $self->{t_prefext}->GetValue;
    $preferences{chordproext} =~ s;^\.*(\w+)?$;sprintf(".%s",$1//substr($state{_prefs}{chordproext},1));e
      && $self->{t_prefext}->ChangeValue($preferences{chordproext});
    ChordPro::Wx::Config::setup_filters();
    $event->Skip;
}

#### Notations, Transpose and Transcode.

method OnCbTranspose($event) {
    my $n = $self->{cb_xpose}->IsChecked;
    $self->{$_}->Enable($n)
      for qw( ch_xpose_from ch_xpose_to ch_acc );
}

method OnXposeFrom($event) {
    $self->OnXposeTo($event);
}

method OnXposeTo($event) {
    my $sel = $self->{ch_xpose_to}->GetSelection;
    my $sf = $sfmap[$sel];
    if ( $sf == 0 ) {
	$sf = $sel - $self->{ch_xpose_from}->GetSelection;
    }
    if ( $sf < 0 ) {
	$self->{ch_acc}->SetSelection(2);
    }
    elsif ( $sf > 0 ) {
	$self->{ch_acc}->SetSelection(1);
    }
    else {
	$self->{ch_acc}->SetSelection(0);
    }
    $event->Skip;
}

method OnChNotation($event) {
    my $n = $self->{ch_notation}->GetSelection;
    $event->Skip;
}

method OnChTranscode($event) {
    my $n = $self->{ch_xcode}->GetSelection;
    $event->Skip;
}

method OnCbTranscode($event) {
    $self->{ch_xcode}->Enable( $self->{cb_xcode}->IsChecked );
}

#### Editor.

method OnEditorFontPickerChanged($event) {
    my $ctl = $self->{t_editor};
    return unless $ctl;
    my $font = $self->{fp_editor}->GetSelectedFont;
    $preferences{editfont} = $font->GetNativeFontInfoDesc;
    $ctl->refresh;
}

method OnColourFGChanged( $event ) {
    $self->colourchanged("fg");
}

method OnColourBGChanged( $event ) {
    $self->colourchanged("bg");
}

method OnColourS1Changed( $event ) {
    $self->colourchanged("s1");
}

method OnColourS2Changed( $event ) {
    $self->colourchanged("s2");
}

method OnColourS3Changed( $event ) {
    $self->colourchanged("s3");
}

method OnColourS4Changed( $event ) {
    $self->colourchanged("s4");
}

method OnColourS5Changed( $event ) {
    $self->colourchanged("s5");
}

method OnColourS6Changed( $event ) {
    $self->colourchanged("s6");
}

method OnColourAnnFGChanged( $event ) {
    $self->colourchanged("annfg");
}

method OnColourAnnBGChanged( $event ) {
    $self->colourchanged("annbg");
}

method OnThemeChanged( $event ) {
    $preferences{editortheme} = $self->get_selected_theme;
    $self->prefs2colours;
}

method OnEditorLineNumbers( $event ) {
    $preferences{editorlines} = $self->{cb_editorlines}->IsChecked;
    $self->{t_editor}->refresh;
}

method OnEditorWrap( $event ) {
    $self->{$_}->Enable( $self->{cb_editorwrap}->IsChecked )
      for qw( l_editorwrap sp_editorwrap );
    $preferences{editorwrap} = $self->{cb_editorwrap}->IsChecked;
    $preferences{editorwrapindent} = $self->{sp_editorwrap}->GetValue;
    $self->{t_editor}->refresh;
}

method OnEditorWrapIndent( $event ) {
    $preferences{editorwrapindent} = $self->{sp_editorwrap}->GetValue;
    $self->{t_editor}->refresh;
}

method OnCbTmplFile($event) {
    my $n = $self->{cb_tmplfile}->IsChecked;
    $self->{fp_tmplfile}->Enable($n);
}

method OnTmplFileChanged($event) {
    # my $file = $self->{fp_tmplfile}->GetPath;
    # ellipsize( $self->{t_tmplfile}, text => $file );
}

#### Messages.

method OnMessagesFontPickerChanged($event) {
    my $parent = $self->GetParent;
    my $ctl = $parent->{t_messages};
    return unless $ctl;
    my $font = $self->{fp_messages}->GetSelectedFont;
    $ctl->SetFont($font);
    $preferences{msgsfont} = $font->GetString(wxC2S_HTML_SYNTAX);
}

# Previewer.

method OnPDFViewer($event) {
    $self->{t_pdfviewer}->Enable( $self->{cb_pdfviewer}->GetValue );
}
method OnHTMLViewer($event) {
}

# System

method OnSysColourChanged($event) {
    $self->GetParent->init_theme;
    $self->OnThemeChanged($event);
    $event->Skip;
}

method OnAdvancedMode( $event ) {
    my $st = $self->{cb_advanced}->IsChecked;
    $preferences{advanced} = $st;
    for ( qw( ch_extra2
	      cb_configfile fp_customconfig b_createconfig
	      cb_customlib dp_customlibrary
	      cb_skipstdcfg
	      sl_line
	   ) ) {
	$self->{$_}->Show($st);
    }
    for ( qw( ch_extra1 l_extra1_desc
	   ) ) {
	$self->{$_}->Show(!$st);
    }
    $self->{sz_extra}->Layout;
    $self->{sz_presets}->Layout;
}

method OnChangeStyle( $event ) {
    my $c = $event->GetClientData;
    $self->set_style_desc($c->{desc});
}

################ Helpers ################

method set_style_desc( $desc ) {
    $self->{l_style_desc}->SetLabel($desc);
    $self->{l_style_desc}->Wrap(($self->{ch_style}->GetSizeWH)[0]);
}

method colourchanged($index) {
    $self->colours2prefs;
}

method setnomod( $ctl, $code ) {
    Carp::confess("WHOAH!") unless $ctl;
    my $mod = $ctl->IsModified;
    $code->($self, $ctl);
    $ctl->SetModified($mod);
}

1;
