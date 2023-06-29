#! perl

use v5.26;
use Object::Pad;
use utf8;
use Carp;

class ChordPro::Chords::Appearance :strict(params);

=begin md

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

field $key             :mutator :param = undef;
field $format          :mutator :param = undef;
field $info            :mutator :param = undef;
field $orig            :mutator :param = undef;

# For convenience.
method chord_display {

    unless ( $info
	     && UNIVERSAL::isa( $info, 'ChordPro::Chord::Base' ) ) {
	$Carp::Internal{ (__PACKAGE__) }++;
	local $Carp::RefArgFormatter =
	  sub { my $t = $_[0];
		$t =~ s/^(ChordPro::.*)=HASH.*/<<$1>>/;
		$t };
	my $m = Carp::longmess();
	die("Missing info for $key$m");
    }

    local $info->{chordformat} = $format;
    $info->chord_display;
}

method raw {
    return $key unless defined $format;
    if ( $format eq '(%{formatted})' ) {
	return '(' . $key . ')';
    }
    $key;
}

method CARP_TRACE {
    "<<Appearance(\"$key\")>>";
}

1;
