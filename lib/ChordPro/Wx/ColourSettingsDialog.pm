#! perl

use strict;
use warnings;
use utf8;

package ChordPro::Wx::ColourSettingsDialog;

use parent qw( ChordPro::Wx::ColourSettingsDialog_wxg );

use Wx qw[:everything];
use Wx::Locale gettext => '_T';
use ChordPro::Wx::Config;
use ChordPro::Wx::Utils;

sub new {
    my $self = shift->SUPER::new(@_);
    return $self;
}

sub refresh {
    my ( $self ) = @_;
    $self->setup_scintilla($self);
    $self->style_text($self);
    $self->SetColours( $preferences{"editcolours"} );
}

sub setup_scintilla {
    my ( $self ) = @_;

    my $try;
    my $stc = $self->{t_editor};
    if ( eval { use Wx::STC; 1 } ) {
	# Replace the placeholder Wx::TextCtrl.
	$try = Wx::StyledTextCtrl->new( $self,
					wxID_ANY );
    }
    else {
	return;
    }

    # Check for updated STC.
    for ( qw( IsModified DiscardEdits MarkDirty ) ) {
	next if $try->can($_);
	# Pre 3.x wxPerl, missing methods.
	$try->Destroy;
	return;
    }
    $stc = $try;

    # Replace the wxTextCtrl by Scintilla.
    $self->{sz_editor}->Replace( $self->{t_editor}, $stc, 1 );
    my $text = $self->{t_editor}->GetText;
    $self->{t_editor}->Destroy;
    $self->{t_editor} = $stc;
    $stc->SetText($text);
    $self->{sz_editor}->Layout;

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

    Wx::Event::EVT_STC_STYLENEEDED($self, -1, $self->can('OnStyleNeeded'));


    # For linenumbers.
    $stc->SetMarginWidth( 0, 40 ); # TODO

    $stc->SetWrapMode(3); # wxSTC_WRAP_WHITESPACE );
    $stc->SetWrapStartIndent(2); # wxSTC_WRAP_WHITESPACE );
}

sub style_text {
    my ( $self ) = @_;
    my $stc = $self->{t_editor};
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

sub GetColours {
    my ( $self ) = @_;
    [ map  { $self->{"cp_$_"}->GetAsHTML } 0..6 ];
}

sub SetColours {
    my ( $self, $colours ) = @_;
    my @c = split( /,\s*/, $colours );
    my $stc = $self->{t_editor};
    $stc->StyleClearAll;
    $stc->StyleSetSpec( $_, "fore:".$c[$_] ) for 0..6;
    $self->{"cp_$_"}->SetColour($c[$_]) for 0..6;
}

################ Event handlers ################

sub OnColourChanged {
    my ( $self, $event, $n) = @_;
    $self->{t_editor}->StyleSetSpec( $n, "bold,fore:".
				     $self->{"cp_$n"}->GetAsHTML );
}

sub OnColourChanged_0 {
    push( @_, 0 );
    goto &OnColourChanged;
}

sub OnColourChanged_1 {
    push( @_, 1 );
    goto &OnColourChanged;
}

sub OnColourChanged_2 {
    push( @_, 2 );
    goto &OnColourChanged;
}

sub OnColourChanged_3 {
    push( @_, 3 );
    goto &OnColourChanged;
}

sub OnColourChanged_4 {
    push( @_, 4 );
    goto &OnColourChanged;
}

sub OnColourChanged_5 {
    push( @_, 5 );
    goto &OnColourChanged;
}

sub OnColourChanged_6 {
    push( @_, 6 );
    goto &OnColourChanged;
}

sub OnColourChanged_7 {
    push( @_, 7 );
    goto &OnColourChanged;
}

sub OnAccept {
    my ( $self, $event ) = @_;
    savewinpos( $self, "tasks" );
    $event->Skip;
}

sub OnCancel {
    my ( $self, $event ) = @_;
    $event->Skip;
}


1;
