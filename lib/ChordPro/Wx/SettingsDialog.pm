#! perl

use v5.26;
use Object::Pad;
use utf8;

class ChordPro::Wx::SettingsDialog
  :repr(HASH)
  :isa(ChordPro::Wx::SettingsDialog_wxg);

use Wx qw[:everything];
use Wx::Locale gettext => '_T';
use ChordPro::Wx::Config;
use ChordPro::Wx::Utils;
use Encode qw(encode_utf8);

no warnings 'redefine';		# TODO
method new :common ( $parent, $id, $title ) {
    my $self = $class->SUPER::new($parent, $id, $title);
    $self->refresh;
    $self->{sz_prefs_outer}->Fit($self);
    $self->Layout;
    $self;
}
use warnings 'redefine';	# TODO

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
    $self->SetColours( $preferences{editcolours} );
}

method enablecustom() {
    my $n = $self->{cb_configfile}->IsChecked;
    $self->{fp_customconfig}->Enable($n);

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
    my $ctl = $self->{ch_presets};
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
    $self->{cb_presets}->SetValue($preferences{enable_presets});
    $self->{ch_presets}->Enable($preferences{enable_presets});

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

    # Editor.
    $self->{fp_editor}->SetSelectedFont
      ( Wx::Font->new($preferences{editfont}) );
    $self->{cp_bg}->SetColour($preferences{editbgcolour});
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
    $preferences{enable_presets} = $self->{cb_presets}->IsChecked;
    my $ctl = $self->{ch_presets};
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

    # Editor.
    $preferences{editfont} = $self->{fp_editor}->GetSelectedFont->GetNativeFontInfoDesc;
    $preferences{editbgcolour} = $self->{cp_bg}->GetAsHTML;
    $preferences{editcolours} = [ map { $self->{"cp_$_"}->GetAsHTML } 0..7 ];
    $preferences{editorwrap} = $self->{cb_editorwrap}->IsChecked;
    $preferences{editorwrapindent} = $self->{sp_editorwrap}->GetValue;
    $self->{t_editor}->refresh;

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
	$self->{w_infobar}->AddButton( $id, "Understood");
	Wx::Event::EVT_BUTTON( $self->{w_infobar}, $id,
			       sub { $self->OnIBDismiss($_[1]) } );
    }

    # Showing the InfoBar leads to a resize, which may cause
    # unwanted width change.
    my ( $w, $h ) = $self->GetSizeWH;
    $self->{w_infobar}->ShowMessage("Changing the custom library requires restart",
				    wxICON_INFORMATION);
    $self->{sz_prefs_outer}->Fit($self);
    $self->SetSize([$w,-1]);
}

sub GetColours {
    my ( $self ) = @_;
    [ map  { $self->{"cp_$_"}->GetAsHTML } 0..6 ];
}

sub SetColours {
    my ( $self, $colours ) = @_;
    my @c = @$colours;
    my $stc = $self->{t_editor};
    if ( $state{have_stc} ) {
	$stc->StyleSetSpec( $_, "fore:".$c[$_] ) for 0..6;
	$self->{"cp_$_"}->Enable(1) for 0..7;
	$self->{"cp_bg"}->Enable(0);
	$self->{"cp_bg"}->SetColour(wxWHITE);
	$self->{"l_$_"}->Enable(1) for 0..7;
	$self->{"l_bg"}->Enable(0);
	$self->{"cp_$_"}->SetColour($c[$_]) for 0..7;
    }
    else {
	$self->{"cp_$_"}->Enable(0) for 1..7;
	$self->{"cp_$_"}->SetColour("#e0e0e0") for 1..7;
	$self->{"l_$_"}->Enable(0) for 1..7;
	$self->{"cp_0"}->Enable(1);
	$self->{"l_0"}->Enable(1);
	$self->{"cp_bg"}->Enable(1);
	$self->{"cp_bg"}->SetColour($preferences{editbgcolour});
	$self->{"l_bg"}->Enable(1);
    }
    $stc->refresh;
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

method OnIBDismiss($e) {
    $self->{w_infobar}->Dismiss;
}

#### Configs etc.

method OnConfigFile($event) {
    my $n = $self->{cb_configfile}->IsChecked;
    $self->{fp_customconfig}->Enable($n);
}

method OnCustomConfigChanged($event) {
    my $path = $self->{fp_customconfig}->GetPath;
    my $fn = encode_utf8($path);
    return if -s $fn;		# existing config

    my $md = Wx::MessageDialog->new
      ( $self,
	"Create new config $path?",
	"Creating a config file",
	wxYES_NO | wxICON_INFORMATION );
    my $ret = $md->ShowModal;
    $md->Destroy;
    if ( $ret == wxID_YES ) {
	my $fd;
	if ( open( $fd, ">:utf8", $fn )
	     and print $fd ChordPro::Config::config_final( default => 1 )
	     and close($fd) ) {
	    $self->{fp_customconfig}->SetPath($path);
	}
	else {
	    my $md = Wx::MessageDialog->new
	      ( $self,
		"Error creating $path: $!",
		"File open error",
		wxOK | wxICON_ERROR );
	    $md->ShowModal;
	    $md->Destroy;
	}
    }
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
    $self->{ch_presets}->Enable( $self->{cb_presets}->GetValue );
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

method OnColour0Changed( $event ) {
    $self->colourchanged(0);
}

method OnColour1Changed( $event ) {
    $self->colourchanged(1);
}

method OnColour2Changed( $event ) {
    $self->colourchanged(2);
}

method OnColour3Changed( $event ) {
    $self->colourchanged(3);
}

method OnColour4Changed( $event ) {
    $self->colourchanged(4);
}

method OnColour5Changed( $event ) {
    $self->colourchanged(5);
}

method OnColour6Changed( $event ) {
    $self->colourchanged(6);
}

method OnColour7Changed( $event ) {
    $self->colourchanged(7);
}

method OnBgColourChanged( $event ) {
    $self->colourchanged(-1);
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
    $event->Skip;
}

################ Helpers ################

method colourchanged($index) {
    if ( $index < 0 ) {
	$preferences{editbgcolour} = $self->{cp_bg}->GetAsHTML;
    }
    else {
	$preferences{editcolours}->[$index] = $self->{"cp_$index"}->GetAsHTML;
    }
    $self->{t_editor}->refresh;
}

method setnomod( $ctl, $code ) {
    Carp::confess("WHOAH!") unless $ctl;
    my $mod = $ctl->IsModified;
    $code->($self, $ctl);
    $ctl->SetModified($mod);
}

1;