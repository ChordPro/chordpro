#! perl

use strict;
use warnings;
use utf8;
use Carp;

package App::Music::ChordPro::Chords::Appearance;

=for md

key      The bare chord name, e.g., "Am7".
         Also index in chordinfo.
	 Transposed/transcoded if applicable.

info     The chord info (chord props, diagram props, etc.)
         This should be chordsinfo->{key}

orig     The chord as it appeared in the song, e.g. "(<b>Am7</b>)"

format   The format for the chord, e.g. "%{root}%{qual}<sup>%{ext}</sup>",
         but more likely something like "(<b>%{formatted}</b>)".
         %{formatted} will be replaced by the result of applying the
         global config.chord-format.

raw      ????
         Key with parens if (%{formatted}).

=cut

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

    unless ( $info
	     && UNIVERSAL::isa( $info, 'App::Music::ChordPro::Chord::Base' ) ) {
	$Carp::Internal{ (__PACKAGE__) }++;
	local $Carp::RefArgFormatter =
	  sub { my $t = $_[0];
		$t =~ s/^App::Music::ChordPro::(.*)=HASH.*/<<$1>>/;
		$t };
	my $m = Carp::longmess();
	$m =~ s/App::Music::ChordPro::([^(]+)/$1/g;
	$m =~ s;( at )(?:.*?)(App/Music/ChordPro);$1$2;g;
	die("Missing info for " . $self->key . "$m");
    }

    local $info->{chordformat} = $self->format;
    $info->chord_display($cap);
}

sub raw {
    my ( $self ) = @_;
    return $self->key unless defined $self->format;
    if ( $self->format eq '(%{formatted})' ) {
	return '(' . $self->key . ')';
    }
    $self->key;
}

sub CARP_TRACE {
    my ( $self ) = @_;
    "<<Appearance(\"" . $self->key . "\")>>";
}

1;
