#! perl

use strict;
use warnings;
use utf8;

package ChordPro::Wx::PreferencesDialog;

use parent qw( ChordPro::Wx::PreferencesDialog_wxg );

use Wx qw[:everything];
use Wx::Locale gettext => '_T';
use ChordPro::Wx::Config;
use ChordPro::Wx::Utils;
use Encode qw(encode_utf8);

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

sub get_configfile {
    my ( $self ) = @_;
    # warn("CF: ", $self->GetParent->{prefs_configfile} || "");
    $preferences{configfile} || ""
}

sub new {
    my $self = shift->SUPER::new(@_);
    $self->refresh;
    $self;
}

sub refresh {
    my ( $self ) = @_;
    $self->fetch_prefs;
}

sub _enablecustom {
    my ( $self ) = @_;
    my $n = $self->{cb_configfile}->IsChecked;
    $self->{fp_customconfig}->Enable($n);

    $n = $self->{cb_customlib}->IsChecked;
    $self->{dp_customlibrary}->Enable($n);

    $n = $self->{cb_tmplfile}->IsChecked;
    $self->{fp_tmplfile}->Enable($n);
}

sub fetch_prefs {
    my ( $self ) = @_;

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
    for ( sort @{ $state{styles} }, map { "$_ (user)" } @{ $state{userstyles} } ) {
	$ctl->Append( $neat->($_) );
    }

    # Check the presets that were selected.
    my $p = $preferences{cfgpreset};
    foreach ( @$p ) {
	next if $_ eq "custom";	# legacy
	my $t = $neat->($_);
	my $n = $ctl->FindString($t);
	$n = $ctl->FindString("$t (user)") if $n == wxNOT_FOUND;
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
    if ( $self->GetParent->{t_editor} ) {
	$self->{l_editor}->Show(1);
	$self->{sl_editor}->Show(1);
	$self->{fp_editor}->Show(1);
	$self->{cp_editor}->Show(!$state{have_stc});
	$self->{sz_editor}->Layout;
	$self->{fp_editor}->SetSelectedFont
	  ( Wx::Font->new($preferences{editfont}) );
#	$self->{ch_editfont}->SetSelection( $preferences{editfont} );
#	$self->{sp_editfont}->SetValue( $preferences{editsize} );
	$self->{cp_editor}->SetColour(Wx::Colour->new($preferences{editcolour}));
    }
    else {
	$self->{fp_editor}->Show(0);
	$self->{cp_editor}->Show(0);
	$self->{l_editor}->Show(0);
	$self->{sl_editor}->Show(0);
	$self->{sz_editor}->Layout;
    }

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

    # Transcode.
    $ctl = $self->{ch_transcode};
    $ctl->Clear;
    $ctl->Append("-----");
    $n = 1;
    for ( @{ $state{notations} } ) {
	my $s = ucfirst($_);
	$check = $n if $_ eq lc $preferences{xcode};
	$s .= " (" . $notdesc->{lc($s)} .")" if $notdesc->{lc($s)};
	$ctl->Append($s);
	$ctl->SetClientData( $n, $_);
	$n++;
    }
    $ctl->SetSelection($check);

    # PDF Viewer.
    $self->{cb_pdfviewer}->SetValue($preferences{enable_pdfviewer});
    $self->{t_pdfviewer}->SetValue($preferences{pdfviewer})
      if $preferences{pdfviewer};
    $self->{t_pdfviewer}->Enable($self->{cb_pdfviewer}->IsChecked);

    $self->_enablecustom;

}

#               C      D      E  F      G      A        B C
my @xpmap = qw( 0 1  1 2 3  3 4  5 6  6 7 8  8 9 10 10 11 12 );
my @sfmap = qw( 0 7 -5 2 9 -3 4 -1 6 -6 1 8 -4 3 10 -2  5 0  );

sub store_prefs {
    my ( $self ) = @_;

    # Transfer all preferences to the state.

    my $parent = $self->GetParent;

    # Skip default (system, user, song) configs.
    $preferences{skipstdcfg}  = $self->{cb_skipstdcfg}->IsChecked;

    # Presets.
    $preferences{enable_presets} = $self->{cb_presets}->IsChecked;
    my $ctl = $self->{ch_presets};
    my $cnt = $ctl->GetCount;
    my @p;
    my $styles = $state{styles};
    for ( my $n = 0; $n < $cnt; $n++ ) {
	next unless $ctl->IsChecked($n);
	push( @p, $styles->[$n] );
	if ( $n == $cnt - 1 ) {
	    my $c = $self->{fp_customconfig}->GetPath;
	    $parent->{_cfgpresetfile} =
	      $preferences{configfile} = $c;
	}
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
    $preferences{editcolour} = $self->{cp_editor}->GetColour->GetAsString(wxC2S_HTML_SYNTAX);

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
    $preferences{xpose_from} = $xpmap[$self->{ch_xpose_from}->GetSelection];
    $preferences{xpose_to  } = $xpmap[$self->{ch_xpose_to  }->GetSelection];
    $preferences{xpose_acc}  = $self->{ch_acc}->GetSelection;
    $n = $preferences{xpose_to} - $preferences{xpose_from};
    $n += 12 if $n < 0;
    $n += 12 if $preferences{xpose_acc} == 1; # sharps
    $n -= 12 if $preferences{xpose_acc} == 2; # flats
    $state{xpose} = $n;

    # Transcode.
    $n = $self->{ch_transcode}->GetSelection;
    if ( $n > 0 ) {
	$preferences{xcode} =
	  $self->{ch_transcode}->GetClientData($n);
    }
    else {
       	$preferences{xcode} = "";
    }

    # PDF Viewer.
    $preferences{enable_pdfviewer} = $self->{cb_pdfviewer}->IsChecked;
    $preferences{pdfviewer} = $self->{t_pdfviewer}->GetValue;

}

sub restore_prefs {
    my ( $self ) = @_;

    # Editor (changed are applied live).
    my $ctl = $self->GetParent->{t_editor};
    return unless $ctl;

    my $font = Wx::Font->new($preferences{editfont});
    $self->setnomod( $ctl, sub { $ctl->SetFont($font) } );
    $self->setnomod( $ctl,
		     sub { $ctl->SetBackgroundColour
			     ( Wx::Colour->new($preferences{editcolour}) ) } )
      if $ctl->can("SetBackgroundColour");
}

sub need_restart {
    my ( $self ) = @_;
    my $infobar = Wx::InfoBar->new($self);
    $self->{sz_prefs_inner}->Add($infobar, 0, wxEXPAND|wxALL, 0);
    $infobar->ShowMessage("Changing the custom library requires restart",
			  wxICON_INFORMATION);
}

################ Event handlers ################

# Event handlers override the subs generated by wxGlade in the _wxg class.

sub OnConfigFile {
    my ( $self, $event ) = @_;
    my $n = $self->{cb_configfile}->IsChecked;
    $self->{fp_customconfig}->Enable($n);
}

sub OnCustomConfigChanged {
    my ( $self, $event ) = @_;
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

sub OnCustomLib {
    my ( $self, $event ) = @_;
    my $n = $self->{cb_customlib}->IsChecked;
    $self->{dp_customlibrary}->Enable($n);
    $self->need_restart;
}

sub OnCustomLibChanged {
    my ( $self, $event ) = @_;
    $self->need_restart;
}

sub OnTmplFile {
    my ( $self, $event ) = @_;
    my $n = $self->{cb_tmplfile}->IsChecked;
    $self->{fp_tmplfile}->Enable($n);
}

sub OnTmplFileDialog {
    my ( $self, $event ) = @_;
    my $fd = Wx::FileDialog->new
      ($self, _T("Choose template for new songs"),
       "", $self->GetParent->{prefs_tmplfile} || "",
       $state{ffilter},
       0|wxFD_OPEN|wxFD_FILE_MUST_EXIST,
       wxDefaultPosition);
    my $ret = $fd->ShowModal;
    if ( $ret == wxID_OK ) {
	my $file = $fd->GetPath;
	$self->{t_tmplfiledialog}->SetValue($file);
    }
    $fd->Destroy;
}

sub OnAccept {
    my ( $self, $event ) = @_;
    $self->store_prefs;
    $event->Skip;
}

sub OnCancel {
    my ( $self, $event ) = @_;
    $self->restore_prefs;
    $event->Skip;
}

sub OnSkipStdCfg {
    my ( $self, $event ) = @_;
    $event->Skip;
}

sub OnPresets {
    my ( $self, $event ) = @_;
    $self->{ch_presets}->Enable( $self->{cb_presets}->GetValue );
    $event->Skip;
}

sub OnPDFViewer {
    my ( $self, $event ) = @_;
    $self->{t_pdfviewer}->Enable( $self->{cb_pdfviewer}->GetValue );
    $event->Skip;
}

sub OnXposeFrom {
    my ( $self, $event ) = @_;
    $self->OnXposeTo($event);
}

sub OnXposeTo {
    my ( $self, $event ) = @_;
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

sub OnChNotation {
    my ( $self, $event ) = @_;
    my $n = $self->{ch_notation}->GetSelection;
    $event->Skip;
}

sub OnChTranscode {
    my ( $self, $event ) = @_;
    my $n = $self->{ch_transcode}->GetSelection;
    $event->Skip;
}

sub OnChEditFont {
    my ($self, $event) = @_;
    my $parent = $self->GetParent;
    my $ctl = $parent->{t_editor};
    return unless $ctl;
    my $n = $self->{ch_editfont}->GetSelection;
    my $font = $state{fonts}->[$n]->{font};
    $font->SetPointSize($preferences{editsize});
    $self->setnomod( $ctl, sub { $ctl->SetFont($font) } );
}

sub OnFontPickerChanged {
    my ($self, $event) = @_;
    my $parent = $self->GetParent;
    my $ctl = $parent->{t_editor};
    return unless $ctl;
    my $font = $self->{fp_editor}->GetSelectedFont;
    $self->setnomod( $ctl, sub { $ctl->SetFont($font) } );
}

sub OnSpEditFont {
    my ($self, $event) = @_;
    my $parent = $self->GetParent;
    my $ctl = $parent->{t_editor};
    return unless $ctl;
    my $n = $self->{sp_editfont}->GetValue;
    my $font = $ctl->GetFont;
    $font->SetPointSize($n);
    $self->setnomod( $ctl, sub { $ctl->SetFont($font) } );
}

sub OnChEditColour {
    my ($self, $event) = @_;
    my $parent = $self->GetParent;
    my $ctl = $parent->{t_editor};
    return unless $ctl;
    my $n = $self->{cp_editor}->GetColour;
    return unless $n && $n->IsOk;
    $self->setnomod( $ctl, sub { $ctl->SetBackgroundColour($n) } )
      if $ctl->can("SetBackgroundColour");
}

################ Helpers ################

sub setnomod {
    my ( $self, $ctl, $code ) = @_;
    Carp::confess("WHOAH!") unless $ctl;
    my $mod = $ctl->IsModified;
    $code->($self, $ctl);
    $ctl->SetModified($mod);
}

1;
