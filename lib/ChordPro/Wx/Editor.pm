#! perl

use v5.26;
use feature 'signatures';
no warnings 'experimental::signatures';
use utf8;

use Wx ':everything';

package ChordPro::Wx::Editor;

use ChordPro::Wx::Config;
use ChordPro::Wx::Utils;

sub new( $class, $parent, $id ) {

    my $widget;
    if ( $::options->{stc}//1 && eval { use Wx::STC; 1 } ) {
	$widget  = Wx::StyledTextCtrl->new($parent);
	# Check for updated STC.
	for ( qw( IsModified DiscardEdits ) ) {
	    next if $widget->can($_);
	    # Pre 3.x wxPerl, missing methods.
	    $widget->Destroy;
	    undef $widget;
	    last;
	}
    }

    if ( defined($widget) ) {
	$state{have_stc} = 1;
	return bless $widget => 'ChordPro::Wx::STCEditor';
    }
    $state{have_stc} = 0;
    ChordPro::Wx::TextEditor->new($parent);
}

package ChordPro::Wx::STCEditor;

use parent qw( -norequire Wx::StyledTextCtrl );

use Wx ':everything';
use ChordPro::Wx::Config;
use ChordPro::Wx::Utils;


sub refresh( $self, $prefs = undef ) {
    my $stc = $self;
    $prefs //= \%preferences;

    $stc->SetLexer(wxSTC_LEX_CONTAINER);
    $stc->SetKeyWords(0,
		      [qw( album arranger artist capo chord chorus
			   column_break columns comment comment_box
			   comment_italic composer copyright define
			   diagrams duration end_of_bridge end_of_chorus
			   end_of_grid end_of_tab end_of_verse grid
			   highlight image key lyricist meta new_page
			   new_physical_page new_song no_grid pagesize
			   pagetype sorttitle start_of_bridge
			   start_of_chorus start_of_grid start_of_tab
			   start_of_verse subtitle tempo time title
			   titles transpose year )
		      ]);

    Wx::Event::EVT_STC_STYLENEEDED( $stc, wxID_ANY,
				    sub { OnStyleNeeded($self, $_[1]) } );

    $stc->StyleClearAll;

    my @c = @{$prefs->{editcolours}};
    # 0 - basic
    $stc->StyleSetSpec( 0, "fore:" . shift(@c) );
    # 1 - comments (grey)
    $stc->StyleSetSpec( 1, "fore:" . shift(@c) );
    # 2 - Keywords (grey)
    $stc->StyleSetSpec( 2, "fore:" . shift(@c) );
    # 3 - Brackets (grey)
    $stc->StyleSetSpec( 3, "fore:" . shift(@c) );
    # 4 - Chords (red)
    $stc->StyleSetSpec( 4, "fore:" . shift(@c) );
    # 5 - Directives (blue, same as status label colour)
    $stc->StyleSetSpec( 5, "fore:" . shift(@c) );
    # 6 - Directive arguments (orange, same as toolbar icon colour)
    $stc->StyleSetSpec( 6, "fore:" . shift(@c));

    # For linenumbers.
    $stc->SetMarginWidth( 0, 40 ); # TODO

    # For annotations.
    $self->{astyle} //= 1 + wxSTC_STYLE_LASTPREDEFINED;
    $stc->StyleSetBackground( $self->{astyle},
			      Wx::Colour->new($prefs->{editcolours}->[-1]) );
    $stc->StyleSetForeground( $self->{astyle}, wxRED );

    $stc->SetFont( Wx::Font->new($prefs->{editfont}) );

    # Wrapping.
    if ( $prefs->{editorwrap} ) {
	$stc->SetWrapMode(3); # wxSTC_WRAP_WHITESPACE );
	$stc->SetWrapStartIndent( $prefs->{editorwrapindent} );
    }
    else {
	$stc->SetWrapMode(0); # wxSTC_WRAP_NONE );
    }
    $self->style_text;
}

sub style_text( $self ) {
    my $stc = $self;

    # Scintilla uses byte indices.
    use Encode;
    my $text  = Encode::encode_utf8($stc->GetText);

    my $style = sub {
	my ( $re, @styles ) = @_;
	pos($text) = 0;
	while ( $text =~ m/$re/g ) {
	    my @s = @styles;
	    die("!!! ", scalar(@{^CAPTURE}), ' ', scalar(@s)) unless @s == @{^CAPTURE};
	    my $end = pos($text);
	    my $start = $end - length($&);
	    my $group = 0;
	    while ( $start < $end ) {
		my $l = length(${^CAPTURE[$group++]});
		$stc->StartStyling( $start, 0 );
		$stc->SetStyling( $l, shift(@s) );
		$start += $l;
	    }
	}
    };

    # Comments/
    $style->( qr/^(#.*)/m, 1 );
    # Directives.
    $style->( qr/^(\{)([-\w!]+)(.*)(\})/m, 3, 5, 6, 3 );
    $style->( qr/^(\{)([-\w!]+)([: ])(.*)(\})/m, 3, 5, 3, 6, 3 );
    # Chords.
    $style->( qr/(\[)([^\[\]]*)(\])/m, 3, 4, 3 );
}

sub prepare_annotations( $self ) {

    return unless $state{have_stc};
    my $stc = $self;

    $stc->AnnotationClearAll;
    $stc->AnnotationSetVisible(wxSTC_ANNOTATION_BOXED);

    if ( $stc->can("StyleGetSizeFractional") ) { # Wx 3.002
	$stc->StyleSetSizeFractional	# size * 100
	  ( $self->{astyle},
	    ( $stc->StyleGetSizeFractional
	      ( wxSTC_STYLE_DEFAULT ) * 4 ) / 5 );
    }

    return 1;
}

sub add_annotation( $self, $line, $message ) {

    return unless $state{have_stc};
    my $stc = $self;

    $stc->AnnotationSetText( $line, $message );
    $stc->AnnotationSetStyle( $line, $self->{astyle} );
}

sub SetBGColour( $self, $colour ) {
}

sub SetModified( $self, $mod ) {
    if ( $mod ) {
	# $self->MarkDirty;	# NOT IMPLEMENTED
	my $pos = $self->GetInsertionPoint;
	$self->LineDuplicate;
	$self->LineDelete;
	$self->SetInsertionPoint($pos);
    }
    else {
	$self->DiscardEdits;
    }
}

sub SetFont( $self, $font ) {
    die("XXX\n") unless $font->IsOk;
    $self->StyleSetFont( $_, $font ) for 0..6;
    $self->{font} = $font;
}

sub GetFont( $self ) {
    $self->{font} // $self->StyleGetFont(0);
}

sub OSXDisableAllSmartSubstitutions( $self ) {
}

sub OnStyleNeeded( $self, $event ) {		# scintilla
    $self->style_text;
}

sub Replace( $self, $from=-1, $to=-1, $text="" ) {
    # We will only call this to replace the selection.
    $self->ReplaceSelection($text);
}

################ Methods ################

package ChordPro::Wx::TextEditor;

use parent qw( -norequire Wx::TextCtrl );

use Wx ':everything';
use ChordPro::Wx::Config;
use ChordPro::Wx::Utils;
use ChordPro::Utils qw( is_macos );

sub new( $class, $parent, $id=undef ) {

    my $self = $class->SUPER::new( $parent, wxID_ANY, "",
				   wxDefaultPosition, wxDefaultSize,
				   wxHSCROLL|wxTE_MULTILINE );

    return $self;
}

sub refresh( $self, $prefs = undef ) {
    my $ctrl = $self;
    $prefs //= \%preferences;

    my $mod = $self->IsModified;

    # TextCtrl only supports background colour and font.
    my $bgcol = Wx::Colour->new( $prefs->{editbgcolour} );
    my $fgcol = Wx::Colour->new( $prefs->{editcolours}->[0] );
    $ctrl->SetBackgroundColour($bgcol);
    $ctrl->SetStyle( 0, -1, Wx::TextAttr->new( $fgcol, $bgcol ) );
    $ctrl->SetFont( Wx::Font->new($prefs->{editfont}) );

    $ctrl->SetModified($mod);
}

sub AddText( $self, $text ) {
    $self->WriteText($text);
}

sub GetLineCount( $self ) {
    $self->GetNumberOfLines;
}

sub GetSelectedText( $self ) {
    $self->GetStringSelection;
}

sub GetText( $self ) {
    $self->GetValue;
}

sub SetText( $self, $text ) {
    $self->SetValue($text);
}

sub SetBGColour( $self, $colour ) {
    $self->SetBackgroundColour($colour);
    $self->SetStyle( 0, -1,
		     Wx::TextAttr->new
		     ( $self->GetDefaultStyle->GetTextColour,
		       Wx::Colour->new($colour) ) );
}

sub SetColour( $self, $colour ) {
    $self->SetStyle( 0, -1,
		     Wx::TextAttr->new( Wx::Colour->new($colour) ) );
}

sub EmptyUndoBuffer($self) {
}

sub OSXDisableAllSmartSubstitutions( $self ) {
    return unless is_macos;
    $self->SUPER::OSXDisableAllSmartSubstitutions;
}

################

1;
