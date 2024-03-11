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

presentation
         The presentation as defined in config->parser->chords.

=cut

field $key             :mutator :param = undef;
field $format          :mutator :param = undef;
field $info            :mutator :param = undef;
field $orig            :mutator :param = undef;
field $presentation    :mutator :param = "";

# For convenience.
method chord_display( $finalformat = undef ) {

    use String::Interpolate::Named;
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

    my $args = {};
    $info->flat_copy( $args, $info->{display} // $info );
    $args->{$presentation} = 1 if $presentation;
    my $res = $info->name;
    my $i = 0;		# debug
    warn("[$i] ", ::dump($args), "\n") if $::config->{debug}->{appearance};
    for my $fmt ( $::config->{'chord-formats'}->{common}, # $default,
		  $info->{format},
		  $info->{chordformat},
		  $format,
		  $finalformat
		) {
	$i++;
	next unless $fmt;
	$args->{root} = lc($args->{root}) if $info->is_note;
	$args->{formatted} = $res;
	$res = interpolate( { args => $args }, $fmt );
	warn("[$i] \"$res\" ← \"$fmt\" ← \"$args->{formatted}\"\n")
	   if $::config->{debug}->{appearance};
    }

    # Substitute musical symbols if wanted.
    return $::config->{settings}->{truesf} ? $info->fix_musicsyms($res) : $res;
}

method is_annotation {
    $presentation eq "annotation";
}

method is_parenthesised {
    $presentation eq "parenthesised";
}

method CARP_TRACE {
    "<<Appearance(\"$key\")>>";
}

method _data_printer($ddp) {
    my $ret = "'$orig'";
    $ret .= " ← '$key'" if $key ne $orig;
    $ret .=" @ '$format'" if $format;
    $ret .=" ($presentation)" if $presentation;
    return $ret;
}

1;
