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
  );

no strict 'refs';

while ( my ( $sub, $value ) = each %const ) {
    *$sub = sub () { $value };
    push( @EXPORT, $sub );
}

use strict 'refs';

################ ################

# Create a menu bar.
#
# This is intended to be called by a panel, but the actual menu bar is
# attached to the top level frame. The callbacks are routed to the
# methods in the panel, if possible.

sub setup_menubar( $self, $sel) {

    my $pref = ChordPro::Utils::is_macos() ? "Settings" : "Preferences";
    my $ctl =
      [ [ wxID_FILE,
	  [ [ wxID_NEW, "MES", "", "Create another ChordPro document", "OnNew" ],
	    [ wxID_OPEN, "MES", "", "Open an existing ChordPro document", "OnOpen" ],
	    [],
	    [ wxID_SAVE, "E", "", "Save the current ChordPro file", "OnSave" ],
	    [ wxID_SAVEAS, "E", "", "Save under a different name", "OnSaveAs" ],
	    [],
	    [ wxID_ANY, "ES", "Export to PDF...", "Save the preview to a PDF",
	      "OnPreviewSave" ],
	    [],
	    [ wxID_ANY, "ES", "Save Messages",
	      "Save the messages to a file", "OnMessagesSave" ],
	    [ wxID_ANY, "ES", "Clear Messages",
	      "Clear the current messages", "OnMessagesClear" ],
	    [],
	    [ wxID_EXIT, "MES", "", "Close Window and Exit", "OnClose" ],
	  ]
	],
	[ wxID_EDIT,
	  [ [ wxID_UNDO,   "E", "OnUndo" ],
	    [ wxID_REDO,   "E", "OnRedo" ],
	    [],
	    [ wxID_CUT,    "ES", "OnCut" ],
	    [ wxID_COPY,   "ES", "OnCopy" ],
	    [ wxID_PASTE,  "ES", "OnPaste" ],
	    [ wxID_DELETE, "ES", "OnDelete" ],
	    [],
	    [ wxID_PREFERENCES, "MES", "$pref...\tCtrl-R",
	      $pref, "OnPreferences" ],
	  ]
	],
	[ wxID_ANY, "ES", "Tasks",
	  [ [ wxID_ANY, "ES", "Default Preview\tCtrl-P",
	      "Preview with default formatting", "OnPreview" ],
	    [ wxID_ANY, "ES", "No Chord Diagrams",
	      "Preview without chord diagrams", "OnPreviewNoDiagrams" ],
	    [ wxID_ANY, "ES", "Lyrics Only",
	      "Preview with just the lyrics", "OnPreviewLyricsOnly" ],
	    [ wxID_ANY, "ES", "More...",
	      "Transpose, transcode, and more", "OnPreviewMore" ],
	    [],
	  ]
	],
	[ wxID_ANY, "ES", "View",
	  [ [ wxID_ANY, "ES", "Show Preview",
	      "Hide or show the preview pane", 1, "OnWindowPreview" ],
	    [ wxID_ANY, "ES", "Show Messages",
	      "Hide or show the messages pane", 1, "OnWindowMessages" ],
	    [],
	    [ wxID_FULLSCREEN(), "MES", "Toggle Full Screen\tShift-Ctrl-Z",
	      "OnMaximize" ],
	  ]
	],
	[ wxID_HELP,
	  [ [ wxID_ANY, "MES", "ChordPro File Format",
	      "Help about the ChordPro file format", "OnHelp_ChordPro" ],
	    [ wxID_ANY, "MES", "ChordPro Configuration Files",
	      "Help about the configuration files", "OnHelp_Config" ],
	    [],
	    [ wxID_ANY, "MES", "Enable Debugging Info in PDF",
	      "Add sources and configuration files to the PDF for debugging", 1,
	      "OnHelp_DebugInfo" ],
	    [],
	    [ wxID_ABOUT, "MES", "About ChordPro",
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
	my $sels = shift(@data) // "MES";
	my $text = shift(@data);

	$id = Wx::NewId if $id < 0;
	my $enabled = index( $sels, $sel ) >= 0;

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
	    my $sels = shift(@data) // "MES";
	    my $text = shift(@data);
	    my $tip  = shift(@data);

	    my $enabled = index( $sels, $sel ) >= 0;
	    $id = Wx::NewId if $id < 0;

	    my $mi = $m->Append( $id,
				 _T($text // Wx::GetStockLabel($id)),
				 $tip ? _T($tip) : "", @data );
	    $mi->Enable($enabled);

	    my $code;
	    if ( $code = $self->can($cb) ) {
		# Reroute callbacks.
		Wx::Event::EVT_MENU( $target, $id,
				     sub { &$code( $self, $_[1] ) } );
	    }
	    elsif ( $code = $target->can($cb) ) {
		# Use parent callbacks.
		Wx::Event::EVT_MENU( $target, $id, $code );
	    }
	    else {
		$self->log("w", "No callback for $cb" );
	    }
	}

	# Add menu to menu bar.
	$mb->Append( $m, _T($text // Wx::GetStockLabel($id)) );
    }

    # Append the tasks.
    my $menu = $mb->FindMenu("Tasks");
    $menu = $mb->GetMenu($menu);
    # Append separator.
    $menu->AppendSeparator if @{$ChordPro::Wx::Config::state{tasks}};
    for my $task ( @{$ChordPro::Wx::Config::state{tasks} } ) {
	my ( $desc, $file ) = @$task;
	my $id = Wx::NewId();
	# Append to the menu.
	my $mi = $menu->Append( $id, $desc, _T("Custom task: ").$desc );
	if ( index( "SE", $sel ) >= 0 ) {
	    Wx::Event::EVT_MENU
		( $self->GetParent, $id,
		  sub { $self->preview( [ "--config", $file ] ) }
		);
	}
	else {
	    $mi->Enable(0);
	}
    }

    # Add menu bar.
    $target->SetMenuBar($mb);

    return $mb;
}

push( @EXPORT, "setup_menubar" );

################ ################

sub savewinpos {
    my ( $win, $name ) = @_;
    $ChordPro::Wx::Config::state{windows}->{$name} =
      join( " ", $win->GetPositionXY, $win->GetSizeWH );
}

sub restorewinpos {
    my ( $win, $name ) = @_;
    $win = $Wx::wxTheApp->GetTopWindow if $name eq "main";

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

sub panels {
    my @panels = qw( p_editor p_sbexport );
    wantarray ? @panels : \@panels;
}

push( @EXPORT, 'panels' );

################ ################

