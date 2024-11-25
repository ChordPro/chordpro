#! perl

use v5.26;
use Object::Pad;
use utf8;

class ChordPro::Wx::NewSongDialog
  :repr(HASH)
  :isa(ChordPro::Wx::NewSongDialog_wxg);

use Wx qw[:everything];
use Wx::Locale gettext => '_T';
use ChordPro::Wx::Config;
use ChordPro::Wx::Utils;
use ChordPro::Utils qw(demarkup);
use Encode qw(encode_utf8);

no warnings 'redefine';		# TODO
method new :common ( $parent, $id, $title ) {
    my $self = $class->SUPER::new($parent, $id, $title);
    $self->refresh;
    $self;
}
use warnings 'redefine';	# TODO

method refresh() {
    for ( qw(title subtitle artist key) ) {
	$self->{"t_$_"}->Clear;
    }
    my $sel = 8;
    for ( qw(dir1 dir2) ) {
	$self->{"t_$_"}->Clear;
	$self->{"ch_$_"}->SetSelection($sel++);
    }
}

method set_title($title) {
    $self->{t_title}->SetValue($title);
}

method get_title() {
    $self->{t_title}->GetValue;
}

method get_meta() {
    my $t = "";
    for ( qw(title subtitle artist key) ) {
	next unless my $v = $self->{"t_$_"}->GetValue;
	$t .= "{$_: $v}\n";
    }
    for ( qw(dir1 dir2) ) {
	next unless my $v = $self->{"t_$_"}->GetValue;
	my $k = $self->{"ch_$_"}->GetString($self->{"ch_$_"}->GetSelection);
	$t .= "{" . lc($k) . ": $v}\n";
    }
    return $t;
}

################ Event handlers ################

method OnAccept($event) {
    $event->Skip;
}

method OnCancel($event) {
    $event->Skip;
}

1;
