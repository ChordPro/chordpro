#!/usr/bin/perl

# Testing truesf and markup

use strict;
use warnings;
use utf8;
use App::Music::ChordPro::Testing;
use App::Music::ChordPro::Song;
use App::Music::ChordPro::Chords;

my @tbl;

while ( <DATA> ) {
    chomp;
    next if /^#/;
    next unless /\S/;
    my ( $chord, $disp, $info ) = split( /\t/, $_ );
    my $c = $chord;
    $c =~ s/[()]//g;
    push( @tbl, [ $c, $disp, $info ] );
}

plan tests => 1 + @tbl;

my $s = App::Music::ChordPro::Song->new;
ok( $s, "Got song");

App::Music::ChordPro::Chords::set_parser("common");
$::config->{settings}->{truesf} = 1;
$::config->{settings}->{chordnames} = "relaxed";
$::config->{settings}->{notenames} = 1;

foreach ( @tbl ) {
    my ( $c, $disp, $info ) = @$_;
    my $res = $s->chord($c);
    $res = $s->{chordsinfo}->{$res} // "FAIL";
    if ( UNIVERSAL::isa( $res, 'HASH' ) ) {
	$res->{display} = $disp if $disp;
	$res = $res->chord_display(0x3);
    }
    is( $res, $info, "parsing chord $c" . ( $disp ? " as $disp" : "") );
}

sub reformat {
    my ( $res ) = @_;
    delete($res->{parser});
    $res = {%$res};		# unbless
    use Data::Dumper qw();
    local $Data::Dumper::Sortkeys  = 1;
    local $Data::Dumper::Indent    = 1;
    local $Data::Dumper::Quotekeys = 0;
    local $Data::Dumper::Deparse   = 1;
    local $Data::Dumper::Terse     = 1;
    local $Data::Dumper::Trailingcomma = 1;
    local $Data::Dumper::Useperl = 1;
    local $Data::Dumper::Useqq     = 0; # I want unicode visible
    my $s = Data::Dumper::Dumper($res);
    $s =~ s/\s+/ /gs;
    $s =~ s/, \}/ }/gs;
    $s =~ s/\s+$//;
    return $s;
}

__DATA__
Bm7		Bm7
Bbm7		B♭m7
Bbm7b5		B♭m7♭5
C#m7		C♯m7
C#m7#5		C♯m7♯5
B		B
b		b
Bb		B♭
bb		b♭
<span color="blue">Bm7</span>		<span color="blue">Bm7</span>
<span color="blue">Bbm7</span>		<span color="blue">B♭m7</span>
Bm7	<span color="blue">Bm</span><sup>7</sup>	<span color="blue">Bm</span><sup>7</sup>
Bm7	<span color="blue">Bm<sup>7</sup></span>	<span color="blue">Bm<sup>7</sup></span>
Bm7	<span color="blue">Bbm7</span>	<span color="blue">B♭m7</span>
Bm7	<span color="blueberry">Bbm7</span>	<span color="blueberry">B♭m7</span>
Bm7	<span color="blueberry">Bm</span><sup>7</sup>	<span color="blueberry">Bm</span><sup>7</sup>
Bm7b5		Bm7♭5
Bbm7b5		B♭m7♭5
Bbm7b5	Bbm7<sup>b5<sup>	B♭m7<sup>♭5<sup>
