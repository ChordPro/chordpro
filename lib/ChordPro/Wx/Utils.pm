#! perl

package ChordPro::Wx::Utils;

use v5.26;
use utf8;
use Carp;
use feature qw( signatures );
no warnings "experimental::signatures";

use Exporter 'import';
our @EXPORT;

use Wx ':everything';
use Wx::Locale gettext => '_T';
use ChordPro::Utils qw( is_msw is_macos );

################ Constants ################

# Constants not (yet) in this version of Wx, and constants specific to us.

my %const =
  ( wxID_FULLSCREEN		=> Wx::NewId(),
    wxICON_NONE			=> 0x00040000,

    $Wx::VERSION < $::Wx_tng ?
    ( wxEXEC_HIDE_CONSOLE		=> 0x00000020,
      wxELLIPSIZE_FLAGS_DEFAULT		=> 3,
      wxELLIPSIZE_NONE			=> 0,
      wxELLIPSIZE_START			=> 1,
      wxELLIPSIZE_MIDDLE		=> 2,
      wxELLIPSIZE_END			=> 3,
      wxEVT_COMMAND_FILEPICKER_CHANGED	=> 0x000027b8,
      wxEVT_COMMAND_DIRPICKER_CHANGED	=> 0x000027b9,
    ) : () );

no strict 'refs';

while ( my ( $sub, $value ) = each %const ) {
    *$sub = sub () { $value };
    push( @EXPORT, $sub );
}

use strict 'refs';

{ no feature 'signatures';
  sub Wx::Event::EVT_STC_CLIPBOARD_PASTE($$$) {
    $_[0]->Connect( $_[1], -1, Wx::wxEVT_STC_AUTOCOMP_CHAR_DELETED()+3, $_[2] );
  }
}

################ ################

# Create / update menu bar.
#
# setup_menubar is called by main ctor, update_menubar by the refresh
# methods of main and panels.
# This is intended to be called by a panel, but the actual menu bar is
# attached to the top level frame. The callbacks are routed to the
# methods in the panel, if possible.

use constant
  { M_ALL	=> 0xff,
    M_MAIN	=> 0x01,
    M_EDITOR	=> 0x02,
    M_SONGBOOK	=> 0x04,
  };

push( @EXPORT, qw( M_MAIN M_EDITOR M_SONGBOOK ) );

my @swingers;

sub update_menubar( $self, $sel ) {
    die unless @swingers;

    for ( @swingers ) {
	my ( $mi, $mask ) = @$_;
	$mi->Enable( $mask & $sel );
    }
}

sub setup_menubar( $self ) {

    state $ctl =
      [ [ wxID_FILE,
	  [ [ wxID_NEW, M_ALL, "",
	      "Create another ChordPro document", "OnNew" ],
	    [ wxID_OPEN, M_ALL, "",
	      "Open an existing ChordPro document", "OnOpen" ],
	    [],
	    [ wxID_SAVE, M_EDITOR, "",
	      "Save the current ChordPro file", "OnSave" ],
	    [ wxID_SAVEAS, M_EDITOR, "Save &As...\tShift-Ctrl-S",
	      "Save under a different name", "OnSaveAs" ],
	    [],
	    [ wxID_ANY, M_EDITOR|M_SONGBOOK, "Export to PDF...",
	      "Save the preview to a PDF", "OnPreviewSave" ],
	    [],
	    [ wxID_ANY, M_EDITOR|M_SONGBOOK, "Save Messages",
	      "Save the messages to a file", "OnMessagesSave" ],
	    [ wxID_ANY, M_EDITOR|M_SONGBOOK, "Clear Messages",
	      "Clear the current messages", "OnMessagesClear" ],
	    [],
	    [ wxID_EXIT, M_ALL, "",
	      "Close Window and Exit", "OnClose" ],
	  ]
	],
	[ wxID_EDIT,
	  [ [ wxID_UNDO,   M_EDITOR, "",
	      "Undo edits", "OnUndo" ],
	    [ wxID_REDO,   M_EDITOR, "",
	      "Redo edits", "OnRedo" ],
	    [],
	    [ wxID_CUT,    M_EDITOR|M_SONGBOOK, "", "OnCut" ],
	    [ wxID_COPY,   M_EDITOR|M_SONGBOOK, "", "OnCopy" ],
	    [ wxID_PASTE,  M_EDITOR|M_SONGBOOK, "", "OnPaste" ],
	    [ wxID_DELETE, M_EDITOR|M_SONGBOOK, "", "OnDelete" ],
	    [],
	    [ wxID_ANY,    M_EDITOR,
	      "Convert Text to ChordPro format\tShift-Ctrl-A",
	      "Convert a text document (chords above the lyrics) to ChordPro format",
	      "OnA2Crd" ],
	    $ENV{VISUAL} ?
	    [ wxID_ANY,    M_EDITOR,
	      "Use external editor\tShift-Ctrl-X",
	      "Use an external editing program to modify the song",
	      "OnExternalEditor" ] : (),
	    [],
	    [ wxID_PREFERENCES, M_ALL, "Settings...\tCtrl-R",
	      "Open the Settings dialog", "OnPreferences" ],
	  ]
	],
	[ wxID_ANY, M_EDITOR|M_SONGBOOK, "View",
	  [ [ wxID_ANY, M_EDITOR|M_SONGBOOK, "Show Preview",
	      "Hide or show the preview pane", 1, "OnWindowPreview" ],
	    [ wxID_ANY, M_EDITOR|M_SONGBOOK, "Show Messages",
	      "Hide or show the messages pane", 1, "OnWindowMessages" ],
	    [],
	    [ wxID_FULLSCREEN(), M_ALL, "Zoom\tShift-Ctrl-Z",
	      "OnMaximize" ],
	  ]
	],
	[ wxID_ANY, M_EDITOR, "&Insert",
	  [ [ wxID_ANY, M_EDITOR, "Insert {&title}",
	      "Insert a {title} directive", "OnInsertTitle" ],
	    [ wxID_ANY, M_EDITOR, "Insert {&subtitle}",
	      "Insert a {subtitle} directive", "OnInsertSubtitle" ],
	    [ wxID_ANY, M_EDITOR, "Insert {&key}",
	      "Insert a {key} directive", "OnInsertKey" ],
	    [ wxID_ANY, M_EDITOR, "Insert {&artist}",
	      "Insert a {artist} directive", "OnInsertArtist" ],
	    [],
	    [ wxID_ANY, M_EDITOR, "Insert &Chorus section",
	      "Insert start/end of chorus directive.", "OnInsertChorus" ],
	    [ wxID_ANY, M_EDITOR, "Insert &Verse section",
	      "Insert start/end of verse directive.", "OnInsertVerse" ],
	    [ wxID_ANY, M_EDITOR, "Insert &Grid section",
	      "Insert start/end of grid directive.", "OnInsertGrid" ],
	    [ wxID_ANY, M_EDITOR, "Insert &arbitrary section",
	      "Insert start/end of section directive.", "OnInsertSection" ],
	    [ wxID_ANY, M_EDITOR, "Clos&e section",
	      "Insert end directive for current section.", "OnCloseSection" ],
	  ]
	],
	[ wxID_ANY, M_EDITOR|M_SONGBOOK, "Tasks",
	  [ [ wxID_ANY, M_EDITOR|M_SONGBOOK, "Default Preview\tCtrl-P",
	      "Preview with default formatting", "OnPreview" ],
	    [ wxID_ANY, M_EDITOR|M_SONGBOOK, "No Chord Diagrams",
	      "Preview without chord diagrams", "OnPreviewNoDiagrams" ],
	    [ wxID_ANY, M_EDITOR|M_SONGBOOK, "Lyrics Only",
	      "Preview with just the lyrics", "OnPreviewLyricsOnly" ],
	    [ wxID_ANY, M_EDITOR|M_SONGBOOK, "More...",
	      "Transpose, transcode, and more", "OnPreviewMore" ],
	    [],
	  ]
	],
	[ wxID_HELP,
	  [ [ wxID_ANY, M_ALL, "ChordPro File Format",
	      "Help about the ChordPro file format", "OnHelp_ChordPro" ],
	    [ wxID_ANY, M_ALL, "ChordPro Configuration Files",
	      "Help about the configuration files", "OnHelp_Config" ],
	    [],
	    [ wxID_ANY, M_ALL, "Enable Debugging Info in PDF",
	      "Add sources and configuration files to the PDF for debugging", 1,
	      "OnHelp_DebugInfo" ],
	    [],
	    [ wxID_ABOUT, M_ALL, "About ChordPro",
	      "About WxChordPro", "OnAbout" ],
	  ]
	]
      ];

    my $target = $Wx::wxTheApp->GetTopWindow;

    my $mb = Wx::MenuBar->new;

    for ( @$ctl ) {

	# [ wxID_FILE, [ ... ] ]

	my @data = @$_;
	my $id   = shift(@data);
	my $menu = pop(@data);
	my $sels = shift(@data) // M_ALL;
	my $text = shift(@data);

	$id = Wx::NewId if $id < 0;

	my $m = Wx::Menu->new;
	for my $item ( @$menu ) {

	    if ( !@$item ) {
		# []
		$m->AppendSeparator;
		next;
	    }

	    # [ wxID_NEW, "", "Create new", ..., "OnNew" ],

	    my @data = @$item;
	    my $id   = shift(@data);
	    my $cb   = pop(@data);
	    my $sels = shift(@data) // M_ALL;
	    my $text = shift(@data);
	    my $tip  = shift(@data);

	    $id = Wx::NewId if $id < 0;

	    my $mi = $m->Append( $id,
				 _T($text // Wx::GetStockLabel($id)),
				 $tip ? _T($tip) : "", @data );
	    push( @swingers, [ $mi, $sels ] ) unless $sels == M_ALL;

	    if ( my $code = $target->can($cb) ) {
		Wx::Event::EVT_MENU( $target, $id, $code );
	    }
	    else {
		# $self->log("W", "No callback for $cb" );
		Wx::Event::EVT_MENU
		    ( $target, $id,
		      sub {
			  if ( my $code = $ChordPro::Wx::Config::state{panel}->can($cb) ) {
			      &$code( $ChordPro::Wx::Config::state{panel}, $_[1] );
			  }
			  else {
			      $self->log("E", "No callback for $cb" );
			  }
		      } );
	    }
	}

	# Add menu to menu bar.
	$mb->Append( $m, _T($text // Wx::GetStockLabel($id)) );
    }

    # Append the tasks.
    my $menu = $mb->FindMenu("Tasks");
    $menu = $mb->GetMenu($menu);
    $menu->AppendSeparator if @{$ChordPro::Wx::Config::state{tasks}};

    for my $task ( @{$ChordPro::Wx::Config::state{tasks} } ) {
	my ( $desc, $file ) = @$task;
	my $id = Wx::NewId();
	# Append to the menu.
	my $mi = $menu->Append( $id, $desc, _T("Custom task: ").$desc );
	Wx::Event::EVT_MENU
	    ( $self, $id,
	      sub { $ChordPro::Wx::Config::state{panel}->preview( [ "--config", $file ] ) }
	    );
	push( @swingers, [ $mi, M_ALL & ~M_MAIN ] );
    }

    # Add menu bar.
    $target->SetMenuBar($mb);

    return $mb;
}

push( @EXPORT, "setup_menubar", "update_menubar" );

################ ################

sub savewinpos( $win, $name ) {
    return unless $name eq "main";
    $ChordPro::Wx::Config::state{windows}->{$name} =
      join( " ", $win->GetPositionXY, $win->GetSizeWH );
}

sub restorewinpos( $win, $name ) {
    return unless $name eq "main";
    $win = $Wx::wxTheApp->GetTopWindow;

    my $t = $ChordPro::Wx::Config::state{windows}->{$name};
    if ( $t ) {
	my @a = split( ' ', $t );
	if ( is_msw || is_macos ) {
	    $win->SetSizeXYWHF( $a[0],$a[1],$a[2],$a[3], 0 );
	}
	else {
	    # Linux WM usually prevent placement.
	    $win->SetSize( $a[2],$a[3] );
	}
    }
}

push( @EXPORT, 'savewinpos', 'restorewinpos' );

################ ################

sub panels() {
    my @panels = qw( p_editor p_sbexport );
    wantarray ? @panels : \@panels;
}

push( @EXPORT, 'panels' );

################ ################

sub ellipsize( $widget, %opts ) {
    my $text = $opts{text} // $widget->GetText;
    my $width = ($widget->GetSizeWH)[0];
    $text = Wx::Control::Ellipsize( $text, Wx::ClientDC->new($widget),
				    $opts{type} // wxELLIPSIZE_END(),
				    $width-10, wxELLIPSIZE_FLAGS_DEFAULT() )
      if Wx::Control->can("Ellipsize");

    # Change w/o triggering a EVT_TEXT event.
    $widget->ChangeValue($text);
}

push( @EXPORT, "ellipsize" );

################ ################

sub kbdkey( $key ) {
    $key =~ s/Shift-/⇧/;
    $key =~ s/Alt-/⎇/;
    $key =~ s/Option-/⌥/;
    my $c = is_macos ? "⌘" : "Ctrl-";
    $key =~ s/Ctrl-/$c/;
    return $key;
}

push( @EXPORT, "kbdkey" );

use Storable();

################ ################

sub clone( $struct ) { Storable::dclone($struct) }

push( @EXPORT, "clone" );

################ ################

sub Wx::ColourPickerCtrl::GetAsHTML( $self ) {
    $self->GetColour->GetAsString(wxC2S_HTML_SYNTAX);
}

################ ################

# Override Wx::Bitmap to use resource search.
unless ( $::wxbitmapnew ) {
    $::wxbitmapnew = \&Wx::Bitmap::new;
    no warnings 'redefine';
    use File::Basename;
    *Wx::Bitmap::new = sub {
	# Only handle Wx::Bitmap->new(file, type) case.
	goto &$::wxbitmapnew if @_ != 3 || -f $_[1];
	my ($self, @rest) = @_;
	$rest[0] = ChordPro::Paths->get->findres( basename($rest[0]),
						  class => "icons" );
	$rest[0] ||= ChordPro::Paths->get->findres( "missing.png",
						    class => "icons" );
	$::wxbitmapnew->($self, @rest);
    };
}

################ ################

