#! perl

use strict;
use warnings;
use utf8;
use Carp;

package App::Music::ChordPro::Chords::Appearance;

sub new {
    my ( $pkg, %args ) = @_;
    bless { %args } => $pkg;
}

sub key :lvalue {
    my ( $self ) = @_;
    $self->{key};
}

sub format :lvalue {
    my ( $self ) = @_;
    $self->{format};
}

sub info :lvalue {
    my ( $self ) = @_;
    $self->{info};
}

# use overload '""' => sub { %_[0]->key }, fallback => 1;

# For convenience.
sub chord_display {
    my ( $self, $cap ) = @_;
    my $info = $self->info;
    Carp::confess("Missing info for " . $self->key)
	unless $info
	&& UNIVERSAL::isa( $info, 'App::Music::ChordPro::Chord::Base' );

    local $info->{chordformat} = $info->{display} // $self->format;
    $info->chord_display($cap);
}

sub raw {
    my ( $self ) = @_;
    return $self->{key} unless defined $self->{format};
    if ( $self->{format} eq '(%{formatted})' ) {
	return '(' . $self->key . ')';
    }
    $self->key;
}

1;
