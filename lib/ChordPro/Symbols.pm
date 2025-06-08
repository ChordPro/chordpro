#! perl

use v5.26;
use feature qw( signatures );
no warnings qw( experimental::signatures );
use utf8;
use Carp;

package ChordPro::Symbols;

use Exporter qw(import);

our @EXPORT;
our @EXPORT_OK;

my $symbols;

sub import {
    $symbols || _build();
    goto &Exporter::import;
}

sub _build {

    my @a = split( /\s+/, <<EOD );
u	\x{2190}	arrow-up
up	\x{2190}	arrow-up
ua	\x{2191}	arrow-up-with-arpeggio
us	\x{2192}	arrow-up-with-staccato
u+	\x{2193}	arrow-up-with-accent
up+	\x{2193}	arrow-up-with-accent
ua+	\x{2194}	arrow-up-with-accent-and-arpeggio
us+	\x{2195}	arrow-up-with-accent-and-staccato
ux	\x{2196}	arrow-up-muted
uxa	\x{2197}	arrow-up-muted-with-arpeggio
uxs	\x{2198}	arrow-up-muted-with-staccato
ux+	\x{2199}	arrow-up-muted-with-accent
uxa+	\x{219a}	arrow-up-muted-with-accent-and-arpeggio
uxs+	\x{219b}	arrow-up-muted-with-accent-and-staccato
uxa+	\x{219a}	arrow-up-muted-with-accent-and-arpeggio
uxs+	\x{219b}	arrow-up-muted-with-accent-and-staccato
d	\x{21a0}	arrow-down
dn	\x{21a0}	arrow-down
da	\x{21a1}	arrow-down-with-arpeggio
ds	\x{21a2}	arrow-down-with-staccato
d+	\x{21a3}	arrow-down-with-accent
dn+	\x{21a3}	arrow-down-with-accent
da+	\x{21a4}	arrow-down-with-accent-and-arpeggio
ds+	\x{21a5}	arrow-down-with-accent-and-staccato
dx	\x{21a6}	arrow-down-muted
dxa	\x{21a7}	arrow-down-muted-with-arpeggio
dxs	\x{21a8}	arrow-down-muted-with-staccato
dx+	\x{21a9}	arrow-down-muted-with-accent
dxa+	\x{21aa}	arrow-down-muted-with-accent-and-arpeggio
dxs+	\x{21ab}	arrow-down-muted-with-accent-and-staccato
dxa+	\x{21aa}	arrow-down-muted-with-accent-and-arpeggio
dxs+	\x{21ab}	arrow-down-muted-with-accent-and-staccato
x	\x{21b0}	arrow-mute
EOD

    while ( @a ) {
	my $code  = shift(@a);
	my $glyph = shift(@a);
	my $name  = shift(@a);
	$symbols->{"strum_$code"} = $glyph;
	$symbols->{$name} = $glyph;
	$name =~ s/muted/mut/;
	$name =~ s/accent/acc/;
	$name =~ s/arpeggio/arp/;
	$name =~ s/staccato/stc/;
	$name =~ s/-(and|with)-/-/g;
	$symbols->{$name} = $glyph;
    }

    @a = split( /\s+/, <<'EOD' );
flat              !
natural           "
sharp             #
repeat-start      $
repeat-end        %
repeat-end-start  &
repeat2           (
repeat1           )
delta             *
EOD

    while ( @a ) {
	my $name  = shift(@a);
	my $glyph = shift(@a);
	$symbols->{$name} = $glyph;
    }

    $symbols->{"circle-$_"} = $_ for "0".."9";
    $symbols->{"circle-$_"} = $_ for "A".."Z";

}

sub symbols() {
    $symbols;
}

push( @EXPORT_OK, qw( symbols ) );

sub symbol($sym) {
    $symbols->{$sym};
}

push( @EXPORT_OK, qw( symbol ) );

sub is_symbol( $name ) {
    exists( $symbols->{$name} );
}

push( @EXPORT, qw( is_symbol ) );

sub strum( $code ) {
    # Allow override by config.
    exists($::config->{gridstrum}->{symbols}->{$code})
      ? $::config->{gridstrum}->{symbols}->{$code}
      : $symbols->{"strum_$code"};
}

push( @EXPORT, qw( strum ) );

sub is_strum( $code ) {
    # In case of settings.notenames, prevent arrow codes from hiding
    # lowercase note names.
    return if $::config->{settings}->{notenames}
      && ChordPro::Chords::known_chord(uc $code);

    exists( $symbols->{"strum_$code"} );
}

push( @EXPORT, qw( is_strum ) );

sub as_json() {
    my $ret = "{\n";
    for ( sort keys %$symbols ) {
	$ret .= qq{  "$_" : };
	my $s = $symbols->{$_};
	if ( $s ge "0" && $s le "Z" ) {
	    $ret .= qq{"$s"};
	}
	else {
	    $ret .= sprintf(qq{"\\u%04x"}, ord($s) );
	}
	$ret .= ",\n";
    }
    $ret =~ s/,\n$/\n/;
    $ret .= "}\n";
}

push( @EXPORT_OK, qw( as_json ) );

1;
