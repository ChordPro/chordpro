#! perl

use strict;
use warnings;
use utf8;

package ChordPro::Wx::RenderDialog;

use parent qw( ChordPro::Wx::RenderDialog_wxg );

use Wx qw[:everything];
use Wx::Locale gettext => '_T';
use ChordPro::Wx::Config;
use ChordPro::Wx::Utils;

sub new {
    my $self = shift->SUPER::new(@_);

    if ( %{$state{presets}{tasks}} ) {
	$self->{l_customtasks}->Show(1);
	my $index = 0;
	for my $task ( sort keys %{$state{presets}{tasks}} ) {
	    my $id = Wx::NewId();
	    $self->{sz_customtasks}->Add
	      ( $self->{"cb_customtask_$index"} = Wx::CheckBox->new
		($self, $id, $state{presets}{tasks}{$task}->{title} ),
		0, 0, 0 );
	    $index++;
	}
	$self->{sz_customtasks}->Layout;
	$self->{sz_prefs_inner}->Fit($self);
    }
    $state{"xpose_$_"} ||= 0
      for qw( enabled semitones accidentals );

    $self->refresh;
    $self;
}

sub refresh {
    my ( $self ) = @_;
    $self->{cb_xpose}->SetValue( $state{xpose_enabled} );
    $self->OnCbTranspose(undef);
}

################ Event handlers ################

sub OnAccept {
    my ( $self, $event ) = @_;
    $state{xpose_enabled}     = $self->{cb_xpose}->IsChecked;
    $state{xpose_semitones}   = $self->{sp_xpose}->GetValue
      * ( $self->{ch_xpose_dir}->GetSelection ? -1 : 1 );
    $state{xpose_accidentals} = $self->{ch_acc}->GetSelection;
    $event->Skip;
}

sub OnCancel {
    my ( $self, $event ) = @_;
    $event->Skip;
}

sub OnCbTranspose {
    my ( $self, $event ) = @_;
    my $n = $self->{cb_xpose}->IsChecked;
    $self->{$_}->Enable($n)
      for qw ( sp_xpose ch_xpose_dir ch_acc );
}

1;
