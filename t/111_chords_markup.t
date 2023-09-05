#!/usr/bin/perl

# Testing truesf and markup

use strict;
use warnings;
use utf8;
use ChordPro::Testing;
use ChordPro::Song;
use ChordPro::Chords;

my @tbl1;
my @tbl2;
my $tbl = \@tbl1;
my $line = 0;
while ( <DATA> ) {
    chomp;
    $line++;
    last if /^#END/;
    next if /^#/;
    next unless /\S/;
    $tbl = \@tbl2, next if /^--/;
    my ( $chord, $disp, $info ) = split( /\t/, $_ );
    my $c = $chord;
    push( @$tbl, [ $line, $c, $disp, $info ] );
}

plan tests => 2 + @tbl1 + @tbl2;

my $s = ChordPro::Song->new;
ok( $s, "Got song");
$s->_diag( format => '<DATA>, line %n, %m' );

ChordPro::Chords::set_parser("common");
$::config->{settings}->{truesf} = 1;
$::config->{settings}->{chordnames} = "relaxed";
$::config->{settings}->{notenames} = 1;

my $msg = "";
foreach ( @tbl1 ) {
    local $SIG{__WARN__} = sub { $msg .= "@_" };
    doit($_);
}
ok( $msg =~ /<DATA>, line (\d+), Invalid markup in chord: "Bbm7<sup>b5<sup>"/
    && $1 == 16,
    "Warning given at line $1" );

$::config->{"chord-formats"}->{common} = "%{root}%{qual|%{}}%{ext|<sup>%{}</sup>}%{bass|/%{}}";
foreach ( @tbl2 ) {
    doit($_);
}

sub doit {
    my ( $line, $c, $info ) = @{$_[0]};
    $s->_diag( line => $line );
    my $ap = $s->chord($c);
    my $key = $ap->key;
    my $res = $s->{chordsinfo}->{$key};
    unless ( $res ) {
	warn( "XXX |", join("|",keys %{$s->{chordsinfo}}), "|\n");
	$res = "FAIL";
    }
    $res = $ap->chord_display(0x3);
    is( $res, $info, "parsing chord $c" );
}

__DATA__
Bm7	Bm7
(Bm7)	(Bm7)
(Besm7)	(Besm7)
Bbm7	B♭m7
Bbm7b5	B♭m7♭5
C#m7	C♯m7
C#m7#5	C♯m7♯5
B	B
b	b
Bb	B♭
bb	b♭
<span color="blue">Bm7</span>	<span color="blue">Bm7</span>
<span color="blue">Bbm7</span>	<span color="blue">B♭m7</span>
Bm7b5	Bm7♭5
Bbm7b5	B♭m7♭5
Bbm7<sup>b5<sup>	B♭m7<sup>♭5<sup>
<b>(Bes)</b>	<b>(Bes)</b>
(<b>Bes</b>)	(<b>Bes</b>)
--
Bbm7b5	B♭m<sup>7♭5</sup>
<b>Bbm7b5</b>	<b>B♭m<sup>7♭5</sup></b>
(Bbm7b5)	(B♭m<sup>7♭5</sup>)
<b>(Bbm7b5)</b>	<b>(B♭m<sup>7♭5</sup>)</b>
