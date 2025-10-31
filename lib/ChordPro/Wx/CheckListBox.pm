#! perl

# CheckListBox that displays tooltips.

use v5.26;
use Object::Pad;
use utf8;
use Wx qw[:everything];

class ChordPro::Wx::CheckListBox
  :repr(HASH)
  :isa(Wx::CheckListBox);

# Since macOS does not seem to generate LEAVE_WINDOW (and ENTER_WINDOW)
# events, we'll use a timer to clear the tips.

use Wx qw[:timer];
my $timer;

method show_tip( $item ) {	# undef means clear

    #                 Panel      Notebook   Main
    my $main = $self->GetParent->GetParent->GetParent;

    if ( ( $item // Wx::wxNOT_FOUND ) == Wx::wxNOT_FOUND ) {
	$main->{l_stylemods_tip}->SetLabel("");
	return;
    }

    my $data = $self->GetClientData($item);
    my $desc = "";
    $desc .= ucfirst($data->{src}) . ": " unless $data->{src} eq "std";
    $desc .= $data->{desc};
    $main->{l_stylemods_tip}->SetLabel($desc);

    # Create (once) and start timer.
    unless ( $timer ) {
	$timer = Wx::Timer->new($self);
	Wx::Event::EVT_TIMER( $self, $timer, $self->can("OnTimer") );
    }
    $timer->Start( 2000, wxTIMER_ONE_SHOT ); # 2 secs
}

#### Event Handlers ####

method OnTimer( $event ) {
    $self->show_tip(undef);
}

# For OnEnter and OnMotion, we show the description of the hovered choice.

# method OnEnter( $event ) {	# Not generated on macOS?
#     $self->show_tip( $self->HitTest($event->GetPosition()) );
# }

method OnMotion( $event ) {
    $self->show_tip( $self->HitTest($event->GetPosition()) );
}

# When leaving, clear the tip.

# method OnLeave( $event ) {	# Not generated on macOS?
#     $self->show_tip(undef);
# }


1;
