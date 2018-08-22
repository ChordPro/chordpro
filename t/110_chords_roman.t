#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Test::More;

use App::Packager ( ':name', 'App::Music::ChordPro' );
use App::Music::ChordPro::Config;
use App::Music::ChordPro::Chords;

my %tbl;

#=for testing

while ( <DATA> ) {
    chomp;
    my ( $chord, $info ) = split( /\t/, $_ );
    my $c = $chord;
    $c =~ s/[()]//g;
    $tbl{$c} = $info;
}

#=cut

plan tests => 1 + keys(%tbl);

our $config =
  eval {
      App::Music::ChordPro::Config::configurator;
  };
ok( $config, "got config" );

use Data::Dumper qw();
local $Data::Dumper::Sortkeys  = 1;
local $Data::Dumper::Indent    = 1;
local $Data::Dumper::Quotekeys = 0;
local $Data::Dumper::Deparse   = 1;
local $Data::Dumper::Terse     = 1;
local $Data::Dumper::Trailingcomma = 1;
local $Data::Dumper::Useperl = 1;
local $Data::Dumper::Useqq     = 0; # I want unicode visible

=for generating

for my $r ( 'I', '#I', 'bII', 'II', '#II', 'bIII', 'III', 'IV',
	    '#IV', 'bV', 'V', '#V', 'bVI', 'VI', '#VI', 'bVII', 'VII' ) {
    for my $q ( '', '0', '+' ) {
	for my $e ( '', '7', '^', 'h', 'h7', '^7' ) {
	    my $chord = "$r$q$e";
	    my $res = App::Music::ChordPro::Chords::parse_chord_roman($chord);
	    unless ( $res ) {
		print( "$chord\tFAIL\n");
		next;
	    }
	    my $s = Data::Dumper::Dumper($res);
	    $s =~ s/\s+/ /gs;
	    $s =~ s/, \}/ }/gs;
	    $s =~ s/\s+$//;
	    print("$chord\t$s\n");
	    my $chord = lc($r)."$q$e";
	    my $res = App::Music::ChordPro::Chords::parse_chord_roman($chord);
	    unless ( $res ) {
		print( "$chord\tFAIL\n");
		next;
	    }
	    my $s = Data::Dumper::Dumper($res);
	    $s =~ s/\s+/ /gs;
	    $s =~ s/, \}/ }/gs;
	    $s =~ s/\s+$//;
	    print("$chord\t$s\n");
	}
    }
}

exit;

=cut

while ( my ( $c, $info ) = each %tbl ) {
    my $res = App::Music::ChordPro::Chords::parse_chord($c);
    $res //= "FAIL";
    if ( UNIVERSAL::isa( $res, 'HASH' ) ) {
        my $s = Data::Dumper::Dumper($res);
	$s =~ s/\s+/ /gs;
	$s =~ s/, \}/ }/gs;
	$s =~ s/\s+$//;
	$res = $s;
    }
    is( $res, $info, "parsing chord $c");
}

__DATA__
I	{ ext => '', name => 'I', qual => '', root => 'I', root_canon => 'I', root_ord => 0, system => 'roman' }
i	{ ext => '', name => 'i', qual => '-', root => 'i', root_canon => 'i', root_ord => 0, system => 'roman' }
I7	{ ext => 7, name => 'I7', qual => '', root => 'I', root_canon => 'I', root_ord => 0, system => 'roman' }
i7	{ ext => 7, name => 'i7', qual => '-', root => 'i', root_canon => 'i', root_ord => 0, system => 'roman' }
I^	{ ext => '^', name => 'I^', qual => '', root => 'I', root_canon => 'I', root_ord => 0, system => 'roman' }
i^	{ ext => '^', name => 'i^', qual => '-', root => 'i', root_canon => 'i', root_ord => 0, system => 'roman' }
Ih	{ ext => 'h', name => 'Ih', qual => '', root => 'I', root_canon => 'I', root_ord => 0, system => 'roman' }
ih	{ ext => 'h', name => 'ih', qual => '-', root => 'i', root_canon => 'i', root_ord => 0, system => 'roman' }
Ih7	{ ext => 'h7', name => 'Ih7', qual => '', root => 'I', root_canon => 'I', root_ord => 0, system => 'roman' }
ih7	{ ext => 'h7', name => 'ih7', qual => '-', root => 'i', root_canon => 'i', root_ord => 0, system => 'roman' }
I^7	{ ext => '^7', name => 'I^7', qual => '', root => 'I', root_canon => 'I', root_ord => 0, system => 'roman' }
i^7	{ ext => '^7', name => 'i^7', qual => '-', root => 'i', root_canon => 'i', root_ord => 0, system => 'roman' }
I0	{ ext => '', name => 'I0', qual => 0, root => 'I', root_canon => 'I', root_ord => 0, system => 'roman' }
i0	{ ext => '', name => 'i0', qual => '-', root => 'i', root_canon => 'i', root_ord => 0, system => 'roman' }
I07	{ ext => 7, name => 'I07', qual => 0, root => 'I', root_canon => 'I', root_ord => 0, system => 'roman' }
i07	{ ext => 7, name => 'i07', qual => '-', root => 'i', root_canon => 'i', root_ord => 0, system => 'roman' }
I0^	{ ext => '^', name => 'I0^', qual => 0, root => 'I', root_canon => 'I', root_ord => 0, system => 'roman' }
i0^	{ ext => '^', name => 'i0^', qual => '-', root => 'i', root_canon => 'i', root_ord => 0, system => 'roman' }
I0h	{ ext => 'h', name => 'I0h', qual => 0, root => 'I', root_canon => 'I', root_ord => 0, system => 'roman' }
i0h	{ ext => 'h', name => 'i0h', qual => '-', root => 'i', root_canon => 'i', root_ord => 0, system => 'roman' }
I0h7	{ ext => 'h7', name => 'I0h7', qual => 0, root => 'I', root_canon => 'I', root_ord => 0, system => 'roman' }
i0h7	{ ext => 'h7', name => 'i0h7', qual => '-', root => 'i', root_canon => 'i', root_ord => 0, system => 'roman' }
I0^7	{ ext => '^7', name => 'I0^7', qual => 0, root => 'I', root_canon => 'I', root_ord => 0, system => 'roman' }
i0^7	{ ext => '^7', name => 'i0^7', qual => '-', root => 'i', root_canon => 'i', root_ord => 0, system => 'roman' }
I+	{ ext => '', name => 'I+', qual => '+', root => 'I', root_canon => 'I', root_ord => 0, system => 'roman' }
i+	{ ext => '', name => 'i+', qual => '-', root => 'i', root_canon => 'i', root_ord => 0, system => 'roman' }
I+7	{ ext => 7, name => 'I+7', qual => '+', root => 'I', root_canon => 'I', root_ord => 0, system => 'roman' }
i+7	{ ext => 7, name => 'i+7', qual => '-', root => 'i', root_canon => 'i', root_ord => 0, system => 'roman' }
I+^	{ ext => '^', name => 'I+^', qual => '+', root => 'I', root_canon => 'I', root_ord => 0, system => 'roman' }
i+^	{ ext => '^', name => 'i+^', qual => '-', root => 'i', root_canon => 'i', root_ord => 0, system => 'roman' }
I+h	{ ext => 'h', name => 'I+h', qual => '+', root => 'I', root_canon => 'I', root_ord => 0, system => 'roman' }
i+h	{ ext => 'h', name => 'i+h', qual => '-', root => 'i', root_canon => 'i', root_ord => 0, system => 'roman' }
I+h7	{ ext => 'h7', name => 'I+h7', qual => '+', root => 'I', root_canon => 'I', root_ord => 0, system => 'roman' }
i+h7	{ ext => 'h7', name => 'i+h7', qual => '-', root => 'i', root_canon => 'i', root_ord => 0, system => 'roman' }
I+^7	{ ext => '^7', name => 'I+^7', qual => '+', root => 'I', root_canon => 'I', root_ord => 0, system => 'roman' }
i+^7	{ ext => '^7', name => 'i+^7', qual => '-', root => 'i', root_canon => 'i', root_ord => 0, system => 'roman' }
#I	{ ext => '', name => '#I', qual => '', root => 'I', root_canon => 'I', root_mod => 1, root_ord => 1, system => 'roman' }
#i	{ ext => '', name => '#i', qual => '-', root => 'i', root_canon => 'i', root_mod => 1, root_ord => 1, system => 'roman' }
#I7	{ ext => 7, name => '#I7', qual => '', root => 'I', root_canon => 'I', root_mod => 1, root_ord => 1, system => 'roman' }
#i7	{ ext => 7, name => '#i7', qual => '-', root => 'i', root_canon => 'i', root_mod => 1, root_ord => 1, system => 'roman' }
#I^	{ ext => '^', name => '#I^', qual => '', root => 'I', root_canon => 'I', root_mod => 1, root_ord => 1, system => 'roman' }
#i^	{ ext => '^', name => '#i^', qual => '-', root => 'i', root_canon => 'i', root_mod => 1, root_ord => 1, system => 'roman' }
#Ih	{ ext => 'h', name => '#Ih', qual => '', root => 'I', root_canon => 'I', root_mod => 1, root_ord => 1, system => 'roman' }
#ih	{ ext => 'h', name => '#ih', qual => '-', root => 'i', root_canon => 'i', root_mod => 1, root_ord => 1, system => 'roman' }
#Ih7	{ ext => 'h7', name => '#Ih7', qual => '', root => 'I', root_canon => 'I', root_mod => 1, root_ord => 1, system => 'roman' }
#ih7	{ ext => 'h7', name => '#ih7', qual => '-', root => 'i', root_canon => 'i', root_mod => 1, root_ord => 1, system => 'roman' }
#I^7	{ ext => '^7', name => '#I^7', qual => '', root => 'I', root_canon => 'I', root_mod => 1, root_ord => 1, system => 'roman' }
#i^7	{ ext => '^7', name => '#i^7', qual => '-', root => 'i', root_canon => 'i', root_mod => 1, root_ord => 1, system => 'roman' }
#I0	{ ext => '', name => '#I0', qual => 0, root => 'I', root_canon => 'I', root_mod => 1, root_ord => 1, system => 'roman' }
#i0	{ ext => '', name => '#i0', qual => '-', root => 'i', root_canon => 'i', root_mod => 1, root_ord => 1, system => 'roman' }
#I07	{ ext => 7, name => '#I07', qual => 0, root => 'I', root_canon => 'I', root_mod => 1, root_ord => 1, system => 'roman' }
#i07	{ ext => 7, name => '#i07', qual => '-', root => 'i', root_canon => 'i', root_mod => 1, root_ord => 1, system => 'roman' }
#I0^	{ ext => '^', name => '#I0^', qual => 0, root => 'I', root_canon => 'I', root_mod => 1, root_ord => 1, system => 'roman' }
#i0^	{ ext => '^', name => '#i0^', qual => '-', root => 'i', root_canon => 'i', root_mod => 1, root_ord => 1, system => 'roman' }
#I0h	{ ext => 'h', name => '#I0h', qual => 0, root => 'I', root_canon => 'I', root_mod => 1, root_ord => 1, system => 'roman' }
#i0h	{ ext => 'h', name => '#i0h', qual => '-', root => 'i', root_canon => 'i', root_mod => 1, root_ord => 1, system => 'roman' }
#I0h7	{ ext => 'h7', name => '#I0h7', qual => 0, root => 'I', root_canon => 'I', root_mod => 1, root_ord => 1, system => 'roman' }
#i0h7	{ ext => 'h7', name => '#i0h7', qual => '-', root => 'i', root_canon => 'i', root_mod => 1, root_ord => 1, system => 'roman' }
#I0^7	{ ext => '^7', name => '#I0^7', qual => 0, root => 'I', root_canon => 'I', root_mod => 1, root_ord => 1, system => 'roman' }
#i0^7	{ ext => '^7', name => '#i0^7', qual => '-', root => 'i', root_canon => 'i', root_mod => 1, root_ord => 1, system => 'roman' }
#I+	{ ext => '', name => '#I+', qual => '+', root => 'I', root_canon => 'I', root_mod => 1, root_ord => 1, system => 'roman' }
#i+	{ ext => '', name => '#i+', qual => '-', root => 'i', root_canon => 'i', root_mod => 1, root_ord => 1, system => 'roman' }
#I+7	{ ext => 7, name => '#I+7', qual => '+', root => 'I', root_canon => 'I', root_mod => 1, root_ord => 1, system => 'roman' }
#i+7	{ ext => 7, name => '#i+7', qual => '-', root => 'i', root_canon => 'i', root_mod => 1, root_ord => 1, system => 'roman' }
#I+^	{ ext => '^', name => '#I+^', qual => '+', root => 'I', root_canon => 'I', root_mod => 1, root_ord => 1, system => 'roman' }
#i+^	{ ext => '^', name => '#i+^', qual => '-', root => 'i', root_canon => 'i', root_mod => 1, root_ord => 1, system => 'roman' }
#I+h	{ ext => 'h', name => '#I+h', qual => '+', root => 'I', root_canon => 'I', root_mod => 1, root_ord => 1, system => 'roman' }
#i+h	{ ext => 'h', name => '#i+h', qual => '-', root => 'i', root_canon => 'i', root_mod => 1, root_ord => 1, system => 'roman' }
#I+h7	{ ext => 'h7', name => '#I+h7', qual => '+', root => 'I', root_canon => 'I', root_mod => 1, root_ord => 1, system => 'roman' }
#i+h7	{ ext => 'h7', name => '#i+h7', qual => '-', root => 'i', root_canon => 'i', root_mod => 1, root_ord => 1, system => 'roman' }
#I+^7	{ ext => '^7', name => '#I+^7', qual => '+', root => 'I', root_canon => 'I', root_mod => 1, root_ord => 1, system => 'roman' }
#i+^7	{ ext => '^7', name => '#i+^7', qual => '-', root => 'i', root_canon => 'i', root_mod => 1, root_ord => 1, system => 'roman' }
bII	{ ext => '', name => 'bII', qual => '', root => 'II', root_canon => 'II', root_mod => -1, root_ord => 1, system => 'roman' }
bii	{ ext => '', name => 'bii', qual => '-', root => 'ii', root_canon => 'ii', root_mod => -1, root_ord => 1, system => 'roman' }
bII7	{ ext => 7, name => 'bII7', qual => '', root => 'II', root_canon => 'II', root_mod => -1, root_ord => 1, system => 'roman' }
bii7	{ ext => 7, name => 'bii7', qual => '-', root => 'ii', root_canon => 'ii', root_mod => -1, root_ord => 1, system => 'roman' }
bII^	{ ext => '^', name => 'bII^', qual => '', root => 'II', root_canon => 'II', root_mod => -1, root_ord => 1, system => 'roman' }
bii^	{ ext => '^', name => 'bii^', qual => '-', root => 'ii', root_canon => 'ii', root_mod => -1, root_ord => 1, system => 'roman' }
bIIh	{ ext => 'h', name => 'bIIh', qual => '', root => 'II', root_canon => 'II', root_mod => -1, root_ord => 1, system => 'roman' }
biih	{ ext => 'h', name => 'biih', qual => '-', root => 'ii', root_canon => 'ii', root_mod => -1, root_ord => 1, system => 'roman' }
bIIh7	{ ext => 'h7', name => 'bIIh7', qual => '', root => 'II', root_canon => 'II', root_mod => -1, root_ord => 1, system => 'roman' }
biih7	{ ext => 'h7', name => 'biih7', qual => '-', root => 'ii', root_canon => 'ii', root_mod => -1, root_ord => 1, system => 'roman' }
bII^7	{ ext => '^7', name => 'bII^7', qual => '', root => 'II', root_canon => 'II', root_mod => -1, root_ord => 1, system => 'roman' }
bii^7	{ ext => '^7', name => 'bii^7', qual => '-', root => 'ii', root_canon => 'ii', root_mod => -1, root_ord => 1, system => 'roman' }
bII0	{ ext => '', name => 'bII0', qual => 0, root => 'II', root_canon => 'II', root_mod => -1, root_ord => 1, system => 'roman' }
bii0	{ ext => '', name => 'bii0', qual => '-', root => 'ii', root_canon => 'ii', root_mod => -1, root_ord => 1, system => 'roman' }
bII07	{ ext => 7, name => 'bII07', qual => 0, root => 'II', root_canon => 'II', root_mod => -1, root_ord => 1, system => 'roman' }
bii07	{ ext => 7, name => 'bii07', qual => '-', root => 'ii', root_canon => 'ii', root_mod => -1, root_ord => 1, system => 'roman' }
bII0^	{ ext => '^', name => 'bII0^', qual => 0, root => 'II', root_canon => 'II', root_mod => -1, root_ord => 1, system => 'roman' }
bii0^	{ ext => '^', name => 'bii0^', qual => '-', root => 'ii', root_canon => 'ii', root_mod => -1, root_ord => 1, system => 'roman' }
bII0h	{ ext => 'h', name => 'bII0h', qual => 0, root => 'II', root_canon => 'II', root_mod => -1, root_ord => 1, system => 'roman' }
bii0h	{ ext => 'h', name => 'bii0h', qual => '-', root => 'ii', root_canon => 'ii', root_mod => -1, root_ord => 1, system => 'roman' }
bII0h7	{ ext => 'h7', name => 'bII0h7', qual => 0, root => 'II', root_canon => 'II', root_mod => -1, root_ord => 1, system => 'roman' }
bii0h7	{ ext => 'h7', name => 'bii0h7', qual => '-', root => 'ii', root_canon => 'ii', root_mod => -1, root_ord => 1, system => 'roman' }
bII0^7	{ ext => '^7', name => 'bII0^7', qual => 0, root => 'II', root_canon => 'II', root_mod => -1, root_ord => 1, system => 'roman' }
bii0^7	{ ext => '^7', name => 'bii0^7', qual => '-', root => 'ii', root_canon => 'ii', root_mod => -1, root_ord => 1, system => 'roman' }
bII+	{ ext => '', name => 'bII+', qual => '+', root => 'II', root_canon => 'II', root_mod => -1, root_ord => 1, system => 'roman' }
bii+	{ ext => '', name => 'bii+', qual => '-', root => 'ii', root_canon => 'ii', root_mod => -1, root_ord => 1, system => 'roman' }
bII+7	{ ext => 7, name => 'bII+7', qual => '+', root => 'II', root_canon => 'II', root_mod => -1, root_ord => 1, system => 'roman' }
bii+7	{ ext => 7, name => 'bii+7', qual => '-', root => 'ii', root_canon => 'ii', root_mod => -1, root_ord => 1, system => 'roman' }
bII+^	{ ext => '^', name => 'bII+^', qual => '+', root => 'II', root_canon => 'II', root_mod => -1, root_ord => 1, system => 'roman' }
bii+^	{ ext => '^', name => 'bii+^', qual => '-', root => 'ii', root_canon => 'ii', root_mod => -1, root_ord => 1, system => 'roman' }
bII+h	{ ext => 'h', name => 'bII+h', qual => '+', root => 'II', root_canon => 'II', root_mod => -1, root_ord => 1, system => 'roman' }
bii+h	{ ext => 'h', name => 'bii+h', qual => '-', root => 'ii', root_canon => 'ii', root_mod => -1, root_ord => 1, system => 'roman' }
bII+h7	{ ext => 'h7', name => 'bII+h7', qual => '+', root => 'II', root_canon => 'II', root_mod => -1, root_ord => 1, system => 'roman' }
bii+h7	{ ext => 'h7', name => 'bii+h7', qual => '-', root => 'ii', root_canon => 'ii', root_mod => -1, root_ord => 1, system => 'roman' }
bII+^7	{ ext => '^7', name => 'bII+^7', qual => '+', root => 'II', root_canon => 'II', root_mod => -1, root_ord => 1, system => 'roman' }
bii+^7	{ ext => '^7', name => 'bii+^7', qual => '-', root => 'ii', root_canon => 'ii', root_mod => -1, root_ord => 1, system => 'roman' }
II	{ ext => '', name => 'II', qual => '', root => 'II', root_canon => 'II', root_ord => 2, system => 'roman' }
ii	{ ext => '', name => 'ii', qual => '-', root => 'ii', root_canon => 'ii', root_ord => 2, system => 'roman' }
II7	{ ext => 7, name => 'II7', qual => '', root => 'II', root_canon => 'II', root_ord => 2, system => 'roman' }
ii7	{ ext => 7, name => 'ii7', qual => '-', root => 'ii', root_canon => 'ii', root_ord => 2, system => 'roman' }
II^	{ ext => '^', name => 'II^', qual => '', root => 'II', root_canon => 'II', root_ord => 2, system => 'roman' }
ii^	{ ext => '^', name => 'ii^', qual => '-', root => 'ii', root_canon => 'ii', root_ord => 2, system => 'roman' }
IIh	{ ext => 'h', name => 'IIh', qual => '', root => 'II', root_canon => 'II', root_ord => 2, system => 'roman' }
iih	{ ext => 'h', name => 'iih', qual => '-', root => 'ii', root_canon => 'ii', root_ord => 2, system => 'roman' }
IIh7	{ ext => 'h7', name => 'IIh7', qual => '', root => 'II', root_canon => 'II', root_ord => 2, system => 'roman' }
iih7	{ ext => 'h7', name => 'iih7', qual => '-', root => 'ii', root_canon => 'ii', root_ord => 2, system => 'roman' }
II^7	{ ext => '^7', name => 'II^7', qual => '', root => 'II', root_canon => 'II', root_ord => 2, system => 'roman' }
ii^7	{ ext => '^7', name => 'ii^7', qual => '-', root => 'ii', root_canon => 'ii', root_ord => 2, system => 'roman' }
II0	{ ext => '', name => 'II0', qual => 0, root => 'II', root_canon => 'II', root_ord => 2, system => 'roman' }
ii0	{ ext => '', name => 'ii0', qual => '-', root => 'ii', root_canon => 'ii', root_ord => 2, system => 'roman' }
II07	{ ext => 7, name => 'II07', qual => 0, root => 'II', root_canon => 'II', root_ord => 2, system => 'roman' }
ii07	{ ext => 7, name => 'ii07', qual => '-', root => 'ii', root_canon => 'ii', root_ord => 2, system => 'roman' }
II0^	{ ext => '^', name => 'II0^', qual => 0, root => 'II', root_canon => 'II', root_ord => 2, system => 'roman' }
ii0^	{ ext => '^', name => 'ii0^', qual => '-', root => 'ii', root_canon => 'ii', root_ord => 2, system => 'roman' }
II0h	{ ext => 'h', name => 'II0h', qual => 0, root => 'II', root_canon => 'II', root_ord => 2, system => 'roman' }
ii0h	{ ext => 'h', name => 'ii0h', qual => '-', root => 'ii', root_canon => 'ii', root_ord => 2, system => 'roman' }
II0h7	{ ext => 'h7', name => 'II0h7', qual => 0, root => 'II', root_canon => 'II', root_ord => 2, system => 'roman' }
ii0h7	{ ext => 'h7', name => 'ii0h7', qual => '-', root => 'ii', root_canon => 'ii', root_ord => 2, system => 'roman' }
II0^7	{ ext => '^7', name => 'II0^7', qual => 0, root => 'II', root_canon => 'II', root_ord => 2, system => 'roman' }
ii0^7	{ ext => '^7', name => 'ii0^7', qual => '-', root => 'ii', root_canon => 'ii', root_ord => 2, system => 'roman' }
II+	{ ext => '', name => 'II+', qual => '+', root => 'II', root_canon => 'II', root_ord => 2, system => 'roman' }
ii+	{ ext => '', name => 'ii+', qual => '-', root => 'ii', root_canon => 'ii', root_ord => 2, system => 'roman' }
II+7	{ ext => 7, name => 'II+7', qual => '+', root => 'II', root_canon => 'II', root_ord => 2, system => 'roman' }
ii+7	{ ext => 7, name => 'ii+7', qual => '-', root => 'ii', root_canon => 'ii', root_ord => 2, system => 'roman' }
II+^	{ ext => '^', name => 'II+^', qual => '+', root => 'II', root_canon => 'II', root_ord => 2, system => 'roman' }
ii+^	{ ext => '^', name => 'ii+^', qual => '-', root => 'ii', root_canon => 'ii', root_ord => 2, system => 'roman' }
II+h	{ ext => 'h', name => 'II+h', qual => '+', root => 'II', root_canon => 'II', root_ord => 2, system => 'roman' }
ii+h	{ ext => 'h', name => 'ii+h', qual => '-', root => 'ii', root_canon => 'ii', root_ord => 2, system => 'roman' }
II+h7	{ ext => 'h7', name => 'II+h7', qual => '+', root => 'II', root_canon => 'II', root_ord => 2, system => 'roman' }
ii+h7	{ ext => 'h7', name => 'ii+h7', qual => '-', root => 'ii', root_canon => 'ii', root_ord => 2, system => 'roman' }
II+^7	{ ext => '^7', name => 'II+^7', qual => '+', root => 'II', root_canon => 'II', root_ord => 2, system => 'roman' }
ii+^7	{ ext => '^7', name => 'ii+^7', qual => '-', root => 'ii', root_canon => 'ii', root_ord => 2, system => 'roman' }
#II	{ ext => '', name => '#II', qual => '', root => 'II', root_canon => 'II', root_mod => 1, root_ord => 3, system => 'roman' }
#ii	{ ext => '', name => '#ii', qual => '-', root => 'ii', root_canon => 'ii', root_mod => 1, root_ord => 3, system => 'roman' }
#II7	{ ext => 7, name => '#II7', qual => '', root => 'II', root_canon => 'II', root_mod => 1, root_ord => 3, system => 'roman' }
#ii7	{ ext => 7, name => '#ii7', qual => '-', root => 'ii', root_canon => 'ii', root_mod => 1, root_ord => 3, system => 'roman' }
#II^	{ ext => '^', name => '#II^', qual => '', root => 'II', root_canon => 'II', root_mod => 1, root_ord => 3, system => 'roman' }
#ii^	{ ext => '^', name => '#ii^', qual => '-', root => 'ii', root_canon => 'ii', root_mod => 1, root_ord => 3, system => 'roman' }
#IIh	{ ext => 'h', name => '#IIh', qual => '', root => 'II', root_canon => 'II', root_mod => 1, root_ord => 3, system => 'roman' }
#iih	{ ext => 'h', name => '#iih', qual => '-', root => 'ii', root_canon => 'ii', root_mod => 1, root_ord => 3, system => 'roman' }
#IIh7	{ ext => 'h7', name => '#IIh7', qual => '', root => 'II', root_canon => 'II', root_mod => 1, root_ord => 3, system => 'roman' }
#iih7	{ ext => 'h7', name => '#iih7', qual => '-', root => 'ii', root_canon => 'ii', root_mod => 1, root_ord => 3, system => 'roman' }
#II^7	{ ext => '^7', name => '#II^7', qual => '', root => 'II', root_canon => 'II', root_mod => 1, root_ord => 3, system => 'roman' }
#ii^7	{ ext => '^7', name => '#ii^7', qual => '-', root => 'ii', root_canon => 'ii', root_mod => 1, root_ord => 3, system => 'roman' }
#II0	{ ext => '', name => '#II0', qual => 0, root => 'II', root_canon => 'II', root_mod => 1, root_ord => 3, system => 'roman' }
#ii0	{ ext => '', name => '#ii0', qual => '-', root => 'ii', root_canon => 'ii', root_mod => 1, root_ord => 3, system => 'roman' }
#II07	{ ext => 7, name => '#II07', qual => 0, root => 'II', root_canon => 'II', root_mod => 1, root_ord => 3, system => 'roman' }
#ii07	{ ext => 7, name => '#ii07', qual => '-', root => 'ii', root_canon => 'ii', root_mod => 1, root_ord => 3, system => 'roman' }
#II0^	{ ext => '^', name => '#II0^', qual => 0, root => 'II', root_canon => 'II', root_mod => 1, root_ord => 3, system => 'roman' }
#ii0^	{ ext => '^', name => '#ii0^', qual => '-', root => 'ii', root_canon => 'ii', root_mod => 1, root_ord => 3, system => 'roman' }
#II0h	{ ext => 'h', name => '#II0h', qual => 0, root => 'II', root_canon => 'II', root_mod => 1, root_ord => 3, system => 'roman' }
#ii0h	{ ext => 'h', name => '#ii0h', qual => '-', root => 'ii', root_canon => 'ii', root_mod => 1, root_ord => 3, system => 'roman' }
#II0h7	{ ext => 'h7', name => '#II0h7', qual => 0, root => 'II', root_canon => 'II', root_mod => 1, root_ord => 3, system => 'roman' }
#ii0h7	{ ext => 'h7', name => '#ii0h7', qual => '-', root => 'ii', root_canon => 'ii', root_mod => 1, root_ord => 3, system => 'roman' }
#II0^7	{ ext => '^7', name => '#II0^7', qual => 0, root => 'II', root_canon => 'II', root_mod => 1, root_ord => 3, system => 'roman' }
#ii0^7	{ ext => '^7', name => '#ii0^7', qual => '-', root => 'ii', root_canon => 'ii', root_mod => 1, root_ord => 3, system => 'roman' }
#II+	{ ext => '', name => '#II+', qual => '+', root => 'II', root_canon => 'II', root_mod => 1, root_ord => 3, system => 'roman' }
#ii+	{ ext => '', name => '#ii+', qual => '-', root => 'ii', root_canon => 'ii', root_mod => 1, root_ord => 3, system => 'roman' }
#II+7	{ ext => 7, name => '#II+7', qual => '+', root => 'II', root_canon => 'II', root_mod => 1, root_ord => 3, system => 'roman' }
#ii+7	{ ext => 7, name => '#ii+7', qual => '-', root => 'ii', root_canon => 'ii', root_mod => 1, root_ord => 3, system => 'roman' }
#II+^	{ ext => '^', name => '#II+^', qual => '+', root => 'II', root_canon => 'II', root_mod => 1, root_ord => 3, system => 'roman' }
#ii+^	{ ext => '^', name => '#ii+^', qual => '-', root => 'ii', root_canon => 'ii', root_mod => 1, root_ord => 3, system => 'roman' }
#II+h	{ ext => 'h', name => '#II+h', qual => '+', root => 'II', root_canon => 'II', root_mod => 1, root_ord => 3, system => 'roman' }
#ii+h	{ ext => 'h', name => '#ii+h', qual => '-', root => 'ii', root_canon => 'ii', root_mod => 1, root_ord => 3, system => 'roman' }
#II+h7	{ ext => 'h7', name => '#II+h7', qual => '+', root => 'II', root_canon => 'II', root_mod => 1, root_ord => 3, system => 'roman' }
#ii+h7	{ ext => 'h7', name => '#ii+h7', qual => '-', root => 'ii', root_canon => 'ii', root_mod => 1, root_ord => 3, system => 'roman' }
#II+^7	{ ext => '^7', name => '#II+^7', qual => '+', root => 'II', root_canon => 'II', root_mod => 1, root_ord => 3, system => 'roman' }
#ii+^7	{ ext => '^7', name => '#ii+^7', qual => '-', root => 'ii', root_canon => 'ii', root_mod => 1, root_ord => 3, system => 'roman' }
bIII	{ ext => '', name => 'bIII', qual => '', root => 'III', root_canon => 'III', root_mod => -1, root_ord => 3, system => 'roman' }
biii	{ ext => '', name => 'biii', qual => '-', root => 'iii', root_canon => 'iii', root_mod => -1, root_ord => 3, system => 'roman' }
bIII7	{ ext => 7, name => 'bIII7', qual => '', root => 'III', root_canon => 'III', root_mod => -1, root_ord => 3, system => 'roman' }
biii7	{ ext => 7, name => 'biii7', qual => '-', root => 'iii', root_canon => 'iii', root_mod => -1, root_ord => 3, system => 'roman' }
bIII^	{ ext => '^', name => 'bIII^', qual => '', root => 'III', root_canon => 'III', root_mod => -1, root_ord => 3, system => 'roman' }
biii^	{ ext => '^', name => 'biii^', qual => '-', root => 'iii', root_canon => 'iii', root_mod => -1, root_ord => 3, system => 'roman' }
bIIIh	{ ext => 'h', name => 'bIIIh', qual => '', root => 'III', root_canon => 'III', root_mod => -1, root_ord => 3, system => 'roman' }
biiih	{ ext => 'h', name => 'biiih', qual => '-', root => 'iii', root_canon => 'iii', root_mod => -1, root_ord => 3, system => 'roman' }
bIIIh7	{ ext => 'h7', name => 'bIIIh7', qual => '', root => 'III', root_canon => 'III', root_mod => -1, root_ord => 3, system => 'roman' }
biiih7	{ ext => 'h7', name => 'biiih7', qual => '-', root => 'iii', root_canon => 'iii', root_mod => -1, root_ord => 3, system => 'roman' }
bIII^7	{ ext => '^7', name => 'bIII^7', qual => '', root => 'III', root_canon => 'III', root_mod => -1, root_ord => 3, system => 'roman' }
biii^7	{ ext => '^7', name => 'biii^7', qual => '-', root => 'iii', root_canon => 'iii', root_mod => -1, root_ord => 3, system => 'roman' }
bIII0	{ ext => '', name => 'bIII0', qual => 0, root => 'III', root_canon => 'III', root_mod => -1, root_ord => 3, system => 'roman' }
biii0	{ ext => '', name => 'biii0', qual => '-', root => 'iii', root_canon => 'iii', root_mod => -1, root_ord => 3, system => 'roman' }
bIII07	{ ext => 7, name => 'bIII07', qual => 0, root => 'III', root_canon => 'III', root_mod => -1, root_ord => 3, system => 'roman' }
biii07	{ ext => 7, name => 'biii07', qual => '-', root => 'iii', root_canon => 'iii', root_mod => -1, root_ord => 3, system => 'roman' }
bIII0^	{ ext => '^', name => 'bIII0^', qual => 0, root => 'III', root_canon => 'III', root_mod => -1, root_ord => 3, system => 'roman' }
biii0^	{ ext => '^', name => 'biii0^', qual => '-', root => 'iii', root_canon => 'iii', root_mod => -1, root_ord => 3, system => 'roman' }
bIII0h	{ ext => 'h', name => 'bIII0h', qual => 0, root => 'III', root_canon => 'III', root_mod => -1, root_ord => 3, system => 'roman' }
biii0h	{ ext => 'h', name => 'biii0h', qual => '-', root => 'iii', root_canon => 'iii', root_mod => -1, root_ord => 3, system => 'roman' }
bIII0h7	{ ext => 'h7', name => 'bIII0h7', qual => 0, root => 'III', root_canon => 'III', root_mod => -1, root_ord => 3, system => 'roman' }
biii0h7	{ ext => 'h7', name => 'biii0h7', qual => '-', root => 'iii', root_canon => 'iii', root_mod => -1, root_ord => 3, system => 'roman' }
bIII0^7	{ ext => '^7', name => 'bIII0^7', qual => 0, root => 'III', root_canon => 'III', root_mod => -1, root_ord => 3, system => 'roman' }
biii0^7	{ ext => '^7', name => 'biii0^7', qual => '-', root => 'iii', root_canon => 'iii', root_mod => -1, root_ord => 3, system => 'roman' }
bIII+	{ ext => '', name => 'bIII+', qual => '+', root => 'III', root_canon => 'III', root_mod => -1, root_ord => 3, system => 'roman' }
biii+	{ ext => '', name => 'biii+', qual => '-', root => 'iii', root_canon => 'iii', root_mod => -1, root_ord => 3, system => 'roman' }
bIII+7	{ ext => 7, name => 'bIII+7', qual => '+', root => 'III', root_canon => 'III', root_mod => -1, root_ord => 3, system => 'roman' }
biii+7	{ ext => 7, name => 'biii+7', qual => '-', root => 'iii', root_canon => 'iii', root_mod => -1, root_ord => 3, system => 'roman' }
bIII+^	{ ext => '^', name => 'bIII+^', qual => '+', root => 'III', root_canon => 'III', root_mod => -1, root_ord => 3, system => 'roman' }
biii+^	{ ext => '^', name => 'biii+^', qual => '-', root => 'iii', root_canon => 'iii', root_mod => -1, root_ord => 3, system => 'roman' }
bIII+h	{ ext => 'h', name => 'bIII+h', qual => '+', root => 'III', root_canon => 'III', root_mod => -1, root_ord => 3, system => 'roman' }
biii+h	{ ext => 'h', name => 'biii+h', qual => '-', root => 'iii', root_canon => 'iii', root_mod => -1, root_ord => 3, system => 'roman' }
bIII+h7	{ ext => 'h7', name => 'bIII+h7', qual => '+', root => 'III', root_canon => 'III', root_mod => -1, root_ord => 3, system => 'roman' }
biii+h7	{ ext => 'h7', name => 'biii+h7', qual => '-', root => 'iii', root_canon => 'iii', root_mod => -1, root_ord => 3, system => 'roman' }
bIII+^7	{ ext => '^7', name => 'bIII+^7', qual => '+', root => 'III', root_canon => 'III', root_mod => -1, root_ord => 3, system => 'roman' }
biii+^7	{ ext => '^7', name => 'biii+^7', qual => '-', root => 'iii', root_canon => 'iii', root_mod => -1, root_ord => 3, system => 'roman' }
III	{ ext => '', name => 'III', qual => '', root => 'III', root_canon => 'III', root_ord => 4, system => 'roman' }
iii	{ ext => '', name => 'iii', qual => '-', root => 'iii', root_canon => 'iii', root_ord => 4, system => 'roman' }
III7	{ ext => 7, name => 'III7', qual => '', root => 'III', root_canon => 'III', root_ord => 4, system => 'roman' }
iii7	{ ext => 7, name => 'iii7', qual => '-', root => 'iii', root_canon => 'iii', root_ord => 4, system => 'roman' }
III^	{ ext => '^', name => 'III^', qual => '', root => 'III', root_canon => 'III', root_ord => 4, system => 'roman' }
iii^	{ ext => '^', name => 'iii^', qual => '-', root => 'iii', root_canon => 'iii', root_ord => 4, system => 'roman' }
IIIh	{ ext => 'h', name => 'IIIh', qual => '', root => 'III', root_canon => 'III', root_ord => 4, system => 'roman' }
iiih	{ ext => 'h', name => 'iiih', qual => '-', root => 'iii', root_canon => 'iii', root_ord => 4, system => 'roman' }
IIIh7	{ ext => 'h7', name => 'IIIh7', qual => '', root => 'III', root_canon => 'III', root_ord => 4, system => 'roman' }
iiih7	{ ext => 'h7', name => 'iiih7', qual => '-', root => 'iii', root_canon => 'iii', root_ord => 4, system => 'roman' }
III^7	{ ext => '^7', name => 'III^7', qual => '', root => 'III', root_canon => 'III', root_ord => 4, system => 'roman' }
iii^7	{ ext => '^7', name => 'iii^7', qual => '-', root => 'iii', root_canon => 'iii', root_ord => 4, system => 'roman' }
III0	{ ext => '', name => 'III0', qual => 0, root => 'III', root_canon => 'III', root_ord => 4, system => 'roman' }
iii0	{ ext => '', name => 'iii0', qual => '-', root => 'iii', root_canon => 'iii', root_ord => 4, system => 'roman' }
III07	{ ext => 7, name => 'III07', qual => 0, root => 'III', root_canon => 'III', root_ord => 4, system => 'roman' }
iii07	{ ext => 7, name => 'iii07', qual => '-', root => 'iii', root_canon => 'iii', root_ord => 4, system => 'roman' }
III0^	{ ext => '^', name => 'III0^', qual => 0, root => 'III', root_canon => 'III', root_ord => 4, system => 'roman' }
iii0^	{ ext => '^', name => 'iii0^', qual => '-', root => 'iii', root_canon => 'iii', root_ord => 4, system => 'roman' }
III0h	{ ext => 'h', name => 'III0h', qual => 0, root => 'III', root_canon => 'III', root_ord => 4, system => 'roman' }
iii0h	{ ext => 'h', name => 'iii0h', qual => '-', root => 'iii', root_canon => 'iii', root_ord => 4, system => 'roman' }
III0h7	{ ext => 'h7', name => 'III0h7', qual => 0, root => 'III', root_canon => 'III', root_ord => 4, system => 'roman' }
iii0h7	{ ext => 'h7', name => 'iii0h7', qual => '-', root => 'iii', root_canon => 'iii', root_ord => 4, system => 'roman' }
III0^7	{ ext => '^7', name => 'III0^7', qual => 0, root => 'III', root_canon => 'III', root_ord => 4, system => 'roman' }
iii0^7	{ ext => '^7', name => 'iii0^7', qual => '-', root => 'iii', root_canon => 'iii', root_ord => 4, system => 'roman' }
III+	{ ext => '', name => 'III+', qual => '+', root => 'III', root_canon => 'III', root_ord => 4, system => 'roman' }
iii+	{ ext => '', name => 'iii+', qual => '-', root => 'iii', root_canon => 'iii', root_ord => 4, system => 'roman' }
III+7	{ ext => 7, name => 'III+7', qual => '+', root => 'III', root_canon => 'III', root_ord => 4, system => 'roman' }
iii+7	{ ext => 7, name => 'iii+7', qual => '-', root => 'iii', root_canon => 'iii', root_ord => 4, system => 'roman' }
III+^	{ ext => '^', name => 'III+^', qual => '+', root => 'III', root_canon => 'III', root_ord => 4, system => 'roman' }
iii+^	{ ext => '^', name => 'iii+^', qual => '-', root => 'iii', root_canon => 'iii', root_ord => 4, system => 'roman' }
III+h	{ ext => 'h', name => 'III+h', qual => '+', root => 'III', root_canon => 'III', root_ord => 4, system => 'roman' }
iii+h	{ ext => 'h', name => 'iii+h', qual => '-', root => 'iii', root_canon => 'iii', root_ord => 4, system => 'roman' }
III+h7	{ ext => 'h7', name => 'III+h7', qual => '+', root => 'III', root_canon => 'III', root_ord => 4, system => 'roman' }
iii+h7	{ ext => 'h7', name => 'iii+h7', qual => '-', root => 'iii', root_canon => 'iii', root_ord => 4, system => 'roman' }
III+^7	{ ext => '^7', name => 'III+^7', qual => '+', root => 'III', root_canon => 'III', root_ord => 4, system => 'roman' }
iii+^7	{ ext => '^7', name => 'iii+^7', qual => '-', root => 'iii', root_canon => 'iii', root_ord => 4, system => 'roman' }
IV	{ ext => '', name => 'IV', qual => '', root => 'IV', root_canon => 'IV', root_ord => 5, system => 'roman' }
iv	{ ext => '', name => 'iv', qual => '-', root => 'iv', root_canon => 'iv', root_ord => 5, system => 'roman' }
IV7	{ ext => 7, name => 'IV7', qual => '', root => 'IV', root_canon => 'IV', root_ord => 5, system => 'roman' }
iv7	{ ext => 7, name => 'iv7', qual => '-', root => 'iv', root_canon => 'iv', root_ord => 5, system => 'roman' }
IV^	{ ext => '^', name => 'IV^', qual => '', root => 'IV', root_canon => 'IV', root_ord => 5, system => 'roman' }
iv^	{ ext => '^', name => 'iv^', qual => '-', root => 'iv', root_canon => 'iv', root_ord => 5, system => 'roman' }
IVh	{ ext => 'h', name => 'IVh', qual => '', root => 'IV', root_canon => 'IV', root_ord => 5, system => 'roman' }
ivh	{ ext => 'h', name => 'ivh', qual => '-', root => 'iv', root_canon => 'iv', root_ord => 5, system => 'roman' }
IVh7	{ ext => 'h7', name => 'IVh7', qual => '', root => 'IV', root_canon => 'IV', root_ord => 5, system => 'roman' }
ivh7	{ ext => 'h7', name => 'ivh7', qual => '-', root => 'iv', root_canon => 'iv', root_ord => 5, system => 'roman' }
IV^7	{ ext => '^7', name => 'IV^7', qual => '', root => 'IV', root_canon => 'IV', root_ord => 5, system => 'roman' }
iv^7	{ ext => '^7', name => 'iv^7', qual => '-', root => 'iv', root_canon => 'iv', root_ord => 5, system => 'roman' }
IV0	{ ext => '', name => 'IV0', qual => 0, root => 'IV', root_canon => 'IV', root_ord => 5, system => 'roman' }
iv0	{ ext => '', name => 'iv0', qual => '-', root => 'iv', root_canon => 'iv', root_ord => 5, system => 'roman' }
IV07	{ ext => 7, name => 'IV07', qual => 0, root => 'IV', root_canon => 'IV', root_ord => 5, system => 'roman' }
iv07	{ ext => 7, name => 'iv07', qual => '-', root => 'iv', root_canon => 'iv', root_ord => 5, system => 'roman' }
IV0^	{ ext => '^', name => 'IV0^', qual => 0, root => 'IV', root_canon => 'IV', root_ord => 5, system => 'roman' }
iv0^	{ ext => '^', name => 'iv0^', qual => '-', root => 'iv', root_canon => 'iv', root_ord => 5, system => 'roman' }
IV0h	{ ext => 'h', name => 'IV0h', qual => 0, root => 'IV', root_canon => 'IV', root_ord => 5, system => 'roman' }
iv0h	{ ext => 'h', name => 'iv0h', qual => '-', root => 'iv', root_canon => 'iv', root_ord => 5, system => 'roman' }
IV0h7	{ ext => 'h7', name => 'IV0h7', qual => 0, root => 'IV', root_canon => 'IV', root_ord => 5, system => 'roman' }
iv0h7	{ ext => 'h7', name => 'iv0h7', qual => '-', root => 'iv', root_canon => 'iv', root_ord => 5, system => 'roman' }
IV0^7	{ ext => '^7', name => 'IV0^7', qual => 0, root => 'IV', root_canon => 'IV', root_ord => 5, system => 'roman' }
iv0^7	{ ext => '^7', name => 'iv0^7', qual => '-', root => 'iv', root_canon => 'iv', root_ord => 5, system => 'roman' }
IV+	{ ext => '', name => 'IV+', qual => '+', root => 'IV', root_canon => 'IV', root_ord => 5, system => 'roman' }
iv+	{ ext => '', name => 'iv+', qual => '-', root => 'iv', root_canon => 'iv', root_ord => 5, system => 'roman' }
IV+7	{ ext => 7, name => 'IV+7', qual => '+', root => 'IV', root_canon => 'IV', root_ord => 5, system => 'roman' }
iv+7	{ ext => 7, name => 'iv+7', qual => '-', root => 'iv', root_canon => 'iv', root_ord => 5, system => 'roman' }
IV+^	{ ext => '^', name => 'IV+^', qual => '+', root => 'IV', root_canon => 'IV', root_ord => 5, system => 'roman' }
iv+^	{ ext => '^', name => 'iv+^', qual => '-', root => 'iv', root_canon => 'iv', root_ord => 5, system => 'roman' }
IV+h	{ ext => 'h', name => 'IV+h', qual => '+', root => 'IV', root_canon => 'IV', root_ord => 5, system => 'roman' }
iv+h	{ ext => 'h', name => 'iv+h', qual => '-', root => 'iv', root_canon => 'iv', root_ord => 5, system => 'roman' }
IV+h7	{ ext => 'h7', name => 'IV+h7', qual => '+', root => 'IV', root_canon => 'IV', root_ord => 5, system => 'roman' }
iv+h7	{ ext => 'h7', name => 'iv+h7', qual => '-', root => 'iv', root_canon => 'iv', root_ord => 5, system => 'roman' }
IV+^7	{ ext => '^7', name => 'IV+^7', qual => '+', root => 'IV', root_canon => 'IV', root_ord => 5, system => 'roman' }
iv+^7	{ ext => '^7', name => 'iv+^7', qual => '-', root => 'iv', root_canon => 'iv', root_ord => 5, system => 'roman' }
#IV	{ ext => '', name => '#IV', qual => '', root => 'IV', root_canon => 'IV', root_mod => 1, root_ord => 6, system => 'roman' }
#iv	{ ext => '', name => '#iv', qual => '-', root => 'iv', root_canon => 'iv', root_mod => 1, root_ord => 6, system => 'roman' }
#IV7	{ ext => 7, name => '#IV7', qual => '', root => 'IV', root_canon => 'IV', root_mod => 1, root_ord => 6, system => 'roman' }
#iv7	{ ext => 7, name => '#iv7', qual => '-', root => 'iv', root_canon => 'iv', root_mod => 1, root_ord => 6, system => 'roman' }
#IV^	{ ext => '^', name => '#IV^', qual => '', root => 'IV', root_canon => 'IV', root_mod => 1, root_ord => 6, system => 'roman' }
#iv^	{ ext => '^', name => '#iv^', qual => '-', root => 'iv', root_canon => 'iv', root_mod => 1, root_ord => 6, system => 'roman' }
#IVh	{ ext => 'h', name => '#IVh', qual => '', root => 'IV', root_canon => 'IV', root_mod => 1, root_ord => 6, system => 'roman' }
#ivh	{ ext => 'h', name => '#ivh', qual => '-', root => 'iv', root_canon => 'iv', root_mod => 1, root_ord => 6, system => 'roman' }
#IVh7	{ ext => 'h7', name => '#IVh7', qual => '', root => 'IV', root_canon => 'IV', root_mod => 1, root_ord => 6, system => 'roman' }
#ivh7	{ ext => 'h7', name => '#ivh7', qual => '-', root => 'iv', root_canon => 'iv', root_mod => 1, root_ord => 6, system => 'roman' }
#IV^7	{ ext => '^7', name => '#IV^7', qual => '', root => 'IV', root_canon => 'IV', root_mod => 1, root_ord => 6, system => 'roman' }
#iv^7	{ ext => '^7', name => '#iv^7', qual => '-', root => 'iv', root_canon => 'iv', root_mod => 1, root_ord => 6, system => 'roman' }
#IV0	{ ext => '', name => '#IV0', qual => 0, root => 'IV', root_canon => 'IV', root_mod => 1, root_ord => 6, system => 'roman' }
#iv0	{ ext => '', name => '#iv0', qual => '-', root => 'iv', root_canon => 'iv', root_mod => 1, root_ord => 6, system => 'roman' }
#IV07	{ ext => 7, name => '#IV07', qual => 0, root => 'IV', root_canon => 'IV', root_mod => 1, root_ord => 6, system => 'roman' }
#iv07	{ ext => 7, name => '#iv07', qual => '-', root => 'iv', root_canon => 'iv', root_mod => 1, root_ord => 6, system => 'roman' }
#IV0^	{ ext => '^', name => '#IV0^', qual => 0, root => 'IV', root_canon => 'IV', root_mod => 1, root_ord => 6, system => 'roman' }
#iv0^	{ ext => '^', name => '#iv0^', qual => '-', root => 'iv', root_canon => 'iv', root_mod => 1, root_ord => 6, system => 'roman' }
#IV0h	{ ext => 'h', name => '#IV0h', qual => 0, root => 'IV', root_canon => 'IV', root_mod => 1, root_ord => 6, system => 'roman' }
#iv0h	{ ext => 'h', name => '#iv0h', qual => '-', root => 'iv', root_canon => 'iv', root_mod => 1, root_ord => 6, system => 'roman' }
#IV0h7	{ ext => 'h7', name => '#IV0h7', qual => 0, root => 'IV', root_canon => 'IV', root_mod => 1, root_ord => 6, system => 'roman' }
#iv0h7	{ ext => 'h7', name => '#iv0h7', qual => '-', root => 'iv', root_canon => 'iv', root_mod => 1, root_ord => 6, system => 'roman' }
#IV0^7	{ ext => '^7', name => '#IV0^7', qual => 0, root => 'IV', root_canon => 'IV', root_mod => 1, root_ord => 6, system => 'roman' }
#iv0^7	{ ext => '^7', name => '#iv0^7', qual => '-', root => 'iv', root_canon => 'iv', root_mod => 1, root_ord => 6, system => 'roman' }
#IV+	{ ext => '', name => '#IV+', qual => '+', root => 'IV', root_canon => 'IV', root_mod => 1, root_ord => 6, system => 'roman' }
#iv+	{ ext => '', name => '#iv+', qual => '-', root => 'iv', root_canon => 'iv', root_mod => 1, root_ord => 6, system => 'roman' }
#IV+7	{ ext => 7, name => '#IV+7', qual => '+', root => 'IV', root_canon => 'IV', root_mod => 1, root_ord => 6, system => 'roman' }
#iv+7	{ ext => 7, name => '#iv+7', qual => '-', root => 'iv', root_canon => 'iv', root_mod => 1, root_ord => 6, system => 'roman' }
#IV+^	{ ext => '^', name => '#IV+^', qual => '+', root => 'IV', root_canon => 'IV', root_mod => 1, root_ord => 6, system => 'roman' }
#iv+^	{ ext => '^', name => '#iv+^', qual => '-', root => 'iv', root_canon => 'iv', root_mod => 1, root_ord => 6, system => 'roman' }
#IV+h	{ ext => 'h', name => '#IV+h', qual => '+', root => 'IV', root_canon => 'IV', root_mod => 1, root_ord => 6, system => 'roman' }
#iv+h	{ ext => 'h', name => '#iv+h', qual => '-', root => 'iv', root_canon => 'iv', root_mod => 1, root_ord => 6, system => 'roman' }
#IV+h7	{ ext => 'h7', name => '#IV+h7', qual => '+', root => 'IV', root_canon => 'IV', root_mod => 1, root_ord => 6, system => 'roman' }
#iv+h7	{ ext => 'h7', name => '#iv+h7', qual => '-', root => 'iv', root_canon => 'iv', root_mod => 1, root_ord => 6, system => 'roman' }
#IV+^7	{ ext => '^7', name => '#IV+^7', qual => '+', root => 'IV', root_canon => 'IV', root_mod => 1, root_ord => 6, system => 'roman' }
#iv+^7	{ ext => '^7', name => '#iv+^7', qual => '-', root => 'iv', root_canon => 'iv', root_mod => 1, root_ord => 6, system => 'roman' }
bV	{ ext => '', name => 'bV', qual => '', root => 'V', root_canon => 'V', root_mod => -1, root_ord => 6, system => 'roman' }
bv	{ ext => '', name => 'bv', qual => '-', root => 'v', root_canon => 'v', root_mod => -1, root_ord => 6, system => 'roman' }
bV7	{ ext => 7, name => 'bV7', qual => '', root => 'V', root_canon => 'V', root_mod => -1, root_ord => 6, system => 'roman' }
bv7	{ ext => 7, name => 'bv7', qual => '-', root => 'v', root_canon => 'v', root_mod => -1, root_ord => 6, system => 'roman' }
bV^	{ ext => '^', name => 'bV^', qual => '', root => 'V', root_canon => 'V', root_mod => -1, root_ord => 6, system => 'roman' }
bv^	{ ext => '^', name => 'bv^', qual => '-', root => 'v', root_canon => 'v', root_mod => -1, root_ord => 6, system => 'roman' }
bVh	{ ext => 'h', name => 'bVh', qual => '', root => 'V', root_canon => 'V', root_mod => -1, root_ord => 6, system => 'roman' }
bvh	{ ext => 'h', name => 'bvh', qual => '-', root => 'v', root_canon => 'v', root_mod => -1, root_ord => 6, system => 'roman' }
bVh7	{ ext => 'h7', name => 'bVh7', qual => '', root => 'V', root_canon => 'V', root_mod => -1, root_ord => 6, system => 'roman' }
bvh7	{ ext => 'h7', name => 'bvh7', qual => '-', root => 'v', root_canon => 'v', root_mod => -1, root_ord => 6, system => 'roman' }
bV^7	{ ext => '^7', name => 'bV^7', qual => '', root => 'V', root_canon => 'V', root_mod => -1, root_ord => 6, system => 'roman' }
bv^7	{ ext => '^7', name => 'bv^7', qual => '-', root => 'v', root_canon => 'v', root_mod => -1, root_ord => 6, system => 'roman' }
bV0	{ ext => '', name => 'bV0', qual => 0, root => 'V', root_canon => 'V', root_mod => -1, root_ord => 6, system => 'roman' }
bv0	{ ext => '', name => 'bv0', qual => '-', root => 'v', root_canon => 'v', root_mod => -1, root_ord => 6, system => 'roman' }
bV07	{ ext => 7, name => 'bV07', qual => 0, root => 'V', root_canon => 'V', root_mod => -1, root_ord => 6, system => 'roman' }
bv07	{ ext => 7, name => 'bv07', qual => '-', root => 'v', root_canon => 'v', root_mod => -1, root_ord => 6, system => 'roman' }
bV0^	{ ext => '^', name => 'bV0^', qual => 0, root => 'V', root_canon => 'V', root_mod => -1, root_ord => 6, system => 'roman' }
bv0^	{ ext => '^', name => 'bv0^', qual => '-', root => 'v', root_canon => 'v', root_mod => -1, root_ord => 6, system => 'roman' }
bV0h	{ ext => 'h', name => 'bV0h', qual => 0, root => 'V', root_canon => 'V', root_mod => -1, root_ord => 6, system => 'roman' }
bv0h	{ ext => 'h', name => 'bv0h', qual => '-', root => 'v', root_canon => 'v', root_mod => -1, root_ord => 6, system => 'roman' }
bV0h7	{ ext => 'h7', name => 'bV0h7', qual => 0, root => 'V', root_canon => 'V', root_mod => -1, root_ord => 6, system => 'roman' }
bv0h7	{ ext => 'h7', name => 'bv0h7', qual => '-', root => 'v', root_canon => 'v', root_mod => -1, root_ord => 6, system => 'roman' }
bV0^7	{ ext => '^7', name => 'bV0^7', qual => 0, root => 'V', root_canon => 'V', root_mod => -1, root_ord => 6, system => 'roman' }
bv0^7	{ ext => '^7', name => 'bv0^7', qual => '-', root => 'v', root_canon => 'v', root_mod => -1, root_ord => 6, system => 'roman' }
bV+	{ ext => '', name => 'bV+', qual => '+', root => 'V', root_canon => 'V', root_mod => -1, root_ord => 6, system => 'roman' }
bv+	{ ext => '', name => 'bv+', qual => '-', root => 'v', root_canon => 'v', root_mod => -1, root_ord => 6, system => 'roman' }
bV+7	{ ext => 7, name => 'bV+7', qual => '+', root => 'V', root_canon => 'V', root_mod => -1, root_ord => 6, system => 'roman' }
bv+7	{ ext => 7, name => 'bv+7', qual => '-', root => 'v', root_canon => 'v', root_mod => -1, root_ord => 6, system => 'roman' }
bV+^	{ ext => '^', name => 'bV+^', qual => '+', root => 'V', root_canon => 'V', root_mod => -1, root_ord => 6, system => 'roman' }
bv+^	{ ext => '^', name => 'bv+^', qual => '-', root => 'v', root_canon => 'v', root_mod => -1, root_ord => 6, system => 'roman' }
bV+h	{ ext => 'h', name => 'bV+h', qual => '+', root => 'V', root_canon => 'V', root_mod => -1, root_ord => 6, system => 'roman' }
bv+h	{ ext => 'h', name => 'bv+h', qual => '-', root => 'v', root_canon => 'v', root_mod => -1, root_ord => 6, system => 'roman' }
bV+h7	{ ext => 'h7', name => 'bV+h7', qual => '+', root => 'V', root_canon => 'V', root_mod => -1, root_ord => 6, system => 'roman' }
bv+h7	{ ext => 'h7', name => 'bv+h7', qual => '-', root => 'v', root_canon => 'v', root_mod => -1, root_ord => 6, system => 'roman' }
bV+^7	{ ext => '^7', name => 'bV+^7', qual => '+', root => 'V', root_canon => 'V', root_mod => -1, root_ord => 6, system => 'roman' }
bv+^7	{ ext => '^7', name => 'bv+^7', qual => '-', root => 'v', root_canon => 'v', root_mod => -1, root_ord => 6, system => 'roman' }
V	{ ext => '', name => 'V', qual => '', root => 'V', root_canon => 'V', root_ord => 7, system => 'roman' }
v	{ ext => '', name => 'v', qual => '-', root => 'v', root_canon => 'v', root_ord => 7, system => 'roman' }
V7	{ ext => 7, name => 'V7', qual => '', root => 'V', root_canon => 'V', root_ord => 7, system => 'roman' }
v7	{ ext => 7, name => 'v7', qual => '-', root => 'v', root_canon => 'v', root_ord => 7, system => 'roman' }
V^	{ ext => '^', name => 'V^', qual => '', root => 'V', root_canon => 'V', root_ord => 7, system => 'roman' }
v^	{ ext => '^', name => 'v^', qual => '-', root => 'v', root_canon => 'v', root_ord => 7, system => 'roman' }
Vh	{ ext => 'h', name => 'Vh', qual => '', root => 'V', root_canon => 'V', root_ord => 7, system => 'roman' }
vh	{ ext => 'h', name => 'vh', qual => '-', root => 'v', root_canon => 'v', root_ord => 7, system => 'roman' }
Vh7	{ ext => 'h7', name => 'Vh7', qual => '', root => 'V', root_canon => 'V', root_ord => 7, system => 'roman' }
vh7	{ ext => 'h7', name => 'vh7', qual => '-', root => 'v', root_canon => 'v', root_ord => 7, system => 'roman' }
V^7	{ ext => '^7', name => 'V^7', qual => '', root => 'V', root_canon => 'V', root_ord => 7, system => 'roman' }
v^7	{ ext => '^7', name => 'v^7', qual => '-', root => 'v', root_canon => 'v', root_ord => 7, system => 'roman' }
V0	{ ext => '', name => 'V0', qual => 0, root => 'V', root_canon => 'V', root_ord => 7, system => 'roman' }
v0	{ ext => '', name => 'v0', qual => '-', root => 'v', root_canon => 'v', root_ord => 7, system => 'roman' }
V07	{ ext => 7, name => 'V07', qual => 0, root => 'V', root_canon => 'V', root_ord => 7, system => 'roman' }
v07	{ ext => 7, name => 'v07', qual => '-', root => 'v', root_canon => 'v', root_ord => 7, system => 'roman' }
V0^	{ ext => '^', name => 'V0^', qual => 0, root => 'V', root_canon => 'V', root_ord => 7, system => 'roman' }
v0^	{ ext => '^', name => 'v0^', qual => '-', root => 'v', root_canon => 'v', root_ord => 7, system => 'roman' }
V0h	{ ext => 'h', name => 'V0h', qual => 0, root => 'V', root_canon => 'V', root_ord => 7, system => 'roman' }
v0h	{ ext => 'h', name => 'v0h', qual => '-', root => 'v', root_canon => 'v', root_ord => 7, system => 'roman' }
V0h7	{ ext => 'h7', name => 'V0h7', qual => 0, root => 'V', root_canon => 'V', root_ord => 7, system => 'roman' }
v0h7	{ ext => 'h7', name => 'v0h7', qual => '-', root => 'v', root_canon => 'v', root_ord => 7, system => 'roman' }
V0^7	{ ext => '^7', name => 'V0^7', qual => 0, root => 'V', root_canon => 'V', root_ord => 7, system => 'roman' }
v0^7	{ ext => '^7', name => 'v0^7', qual => '-', root => 'v', root_canon => 'v', root_ord => 7, system => 'roman' }
V+	{ ext => '', name => 'V+', qual => '+', root => 'V', root_canon => 'V', root_ord => 7, system => 'roman' }
v+	{ ext => '', name => 'v+', qual => '-', root => 'v', root_canon => 'v', root_ord => 7, system => 'roman' }
V+7	{ ext => 7, name => 'V+7', qual => '+', root => 'V', root_canon => 'V', root_ord => 7, system => 'roman' }
v+7	{ ext => 7, name => 'v+7', qual => '-', root => 'v', root_canon => 'v', root_ord => 7, system => 'roman' }
V+^	{ ext => '^', name => 'V+^', qual => '+', root => 'V', root_canon => 'V', root_ord => 7, system => 'roman' }
v+^	{ ext => '^', name => 'v+^', qual => '-', root => 'v', root_canon => 'v', root_ord => 7, system => 'roman' }
V+h	{ ext => 'h', name => 'V+h', qual => '+', root => 'V', root_canon => 'V', root_ord => 7, system => 'roman' }
v+h	{ ext => 'h', name => 'v+h', qual => '-', root => 'v', root_canon => 'v', root_ord => 7, system => 'roman' }
V+h7	{ ext => 'h7', name => 'V+h7', qual => '+', root => 'V', root_canon => 'V', root_ord => 7, system => 'roman' }
v+h7	{ ext => 'h7', name => 'v+h7', qual => '-', root => 'v', root_canon => 'v', root_ord => 7, system => 'roman' }
V+^7	{ ext => '^7', name => 'V+^7', qual => '+', root => 'V', root_canon => 'V', root_ord => 7, system => 'roman' }
v+^7	{ ext => '^7', name => 'v+^7', qual => '-', root => 'v', root_canon => 'v', root_ord => 7, system => 'roman' }
#V	{ ext => '', name => '#V', qual => '', root => 'V', root_canon => 'V', root_mod => 1, root_ord => 8, system => 'roman' }
#v	{ ext => '', name => '#v', qual => '-', root => 'v', root_canon => 'v', root_mod => 1, root_ord => 8, system => 'roman' }
#V7	{ ext => 7, name => '#V7', qual => '', root => 'V', root_canon => 'V', root_mod => 1, root_ord => 8, system => 'roman' }
#v7	{ ext => 7, name => '#v7', qual => '-', root => 'v', root_canon => 'v', root_mod => 1, root_ord => 8, system => 'roman' }
#V^	{ ext => '^', name => '#V^', qual => '', root => 'V', root_canon => 'V', root_mod => 1, root_ord => 8, system => 'roman' }
#v^	{ ext => '^', name => '#v^', qual => '-', root => 'v', root_canon => 'v', root_mod => 1, root_ord => 8, system => 'roman' }
#Vh	{ ext => 'h', name => '#Vh', qual => '', root => 'V', root_canon => 'V', root_mod => 1, root_ord => 8, system => 'roman' }
#vh	{ ext => 'h', name => '#vh', qual => '-', root => 'v', root_canon => 'v', root_mod => 1, root_ord => 8, system => 'roman' }
#Vh7	{ ext => 'h7', name => '#Vh7', qual => '', root => 'V', root_canon => 'V', root_mod => 1, root_ord => 8, system => 'roman' }
#vh7	{ ext => 'h7', name => '#vh7', qual => '-', root => 'v', root_canon => 'v', root_mod => 1, root_ord => 8, system => 'roman' }
#V^7	{ ext => '^7', name => '#V^7', qual => '', root => 'V', root_canon => 'V', root_mod => 1, root_ord => 8, system => 'roman' }
#v^7	{ ext => '^7', name => '#v^7', qual => '-', root => 'v', root_canon => 'v', root_mod => 1, root_ord => 8, system => 'roman' }
#V0	{ ext => '', name => '#V0', qual => 0, root => 'V', root_canon => 'V', root_mod => 1, root_ord => 8, system => 'roman' }
#v0	{ ext => '', name => '#v0', qual => '-', root => 'v', root_canon => 'v', root_mod => 1, root_ord => 8, system => 'roman' }
#V07	{ ext => 7, name => '#V07', qual => 0, root => 'V', root_canon => 'V', root_mod => 1, root_ord => 8, system => 'roman' }
#v07	{ ext => 7, name => '#v07', qual => '-', root => 'v', root_canon => 'v', root_mod => 1, root_ord => 8, system => 'roman' }
#V0^	{ ext => '^', name => '#V0^', qual => 0, root => 'V', root_canon => 'V', root_mod => 1, root_ord => 8, system => 'roman' }
#v0^	{ ext => '^', name => '#v0^', qual => '-', root => 'v', root_canon => 'v', root_mod => 1, root_ord => 8, system => 'roman' }
#V0h	{ ext => 'h', name => '#V0h', qual => 0, root => 'V', root_canon => 'V', root_mod => 1, root_ord => 8, system => 'roman' }
#v0h	{ ext => 'h', name => '#v0h', qual => '-', root => 'v', root_canon => 'v', root_mod => 1, root_ord => 8, system => 'roman' }
#V0h7	{ ext => 'h7', name => '#V0h7', qual => 0, root => 'V', root_canon => 'V', root_mod => 1, root_ord => 8, system => 'roman' }
#v0h7	{ ext => 'h7', name => '#v0h7', qual => '-', root => 'v', root_canon => 'v', root_mod => 1, root_ord => 8, system => 'roman' }
#V0^7	{ ext => '^7', name => '#V0^7', qual => 0, root => 'V', root_canon => 'V', root_mod => 1, root_ord => 8, system => 'roman' }
#v0^7	{ ext => '^7', name => '#v0^7', qual => '-', root => 'v', root_canon => 'v', root_mod => 1, root_ord => 8, system => 'roman' }
#V+	{ ext => '', name => '#V+', qual => '+', root => 'V', root_canon => 'V', root_mod => 1, root_ord => 8, system => 'roman' }
#v+	{ ext => '', name => '#v+', qual => '-', root => 'v', root_canon => 'v', root_mod => 1, root_ord => 8, system => 'roman' }
#V+7	{ ext => 7, name => '#V+7', qual => '+', root => 'V', root_canon => 'V', root_mod => 1, root_ord => 8, system => 'roman' }
#v+7	{ ext => 7, name => '#v+7', qual => '-', root => 'v', root_canon => 'v', root_mod => 1, root_ord => 8, system => 'roman' }
#V+^	{ ext => '^', name => '#V+^', qual => '+', root => 'V', root_canon => 'V', root_mod => 1, root_ord => 8, system => 'roman' }
#v+^	{ ext => '^', name => '#v+^', qual => '-', root => 'v', root_canon => 'v', root_mod => 1, root_ord => 8, system => 'roman' }
#V+h	{ ext => 'h', name => '#V+h', qual => '+', root => 'V', root_canon => 'V', root_mod => 1, root_ord => 8, system => 'roman' }
#v+h	{ ext => 'h', name => '#v+h', qual => '-', root => 'v', root_canon => 'v', root_mod => 1, root_ord => 8, system => 'roman' }
#V+h7	{ ext => 'h7', name => '#V+h7', qual => '+', root => 'V', root_canon => 'V', root_mod => 1, root_ord => 8, system => 'roman' }
#v+h7	{ ext => 'h7', name => '#v+h7', qual => '-', root => 'v', root_canon => 'v', root_mod => 1, root_ord => 8, system => 'roman' }
#V+^7	{ ext => '^7', name => '#V+^7', qual => '+', root => 'V', root_canon => 'V', root_mod => 1, root_ord => 8, system => 'roman' }
#v+^7	{ ext => '^7', name => '#v+^7', qual => '-', root => 'v', root_canon => 'v', root_mod => 1, root_ord => 8, system => 'roman' }
bVI	{ ext => '', name => 'bVI', qual => '', root => 'VI', root_canon => 'VI', root_mod => -1, root_ord => 8, system => 'roman' }
bvi	{ ext => '', name => 'bvi', qual => '-', root => 'vi', root_canon => 'vi', root_mod => -1, root_ord => 8, system => 'roman' }
bVI7	{ ext => 7, name => 'bVI7', qual => '', root => 'VI', root_canon => 'VI', root_mod => -1, root_ord => 8, system => 'roman' }
bvi7	{ ext => 7, name => 'bvi7', qual => '-', root => 'vi', root_canon => 'vi', root_mod => -1, root_ord => 8, system => 'roman' }
bVI^	{ ext => '^', name => 'bVI^', qual => '', root => 'VI', root_canon => 'VI', root_mod => -1, root_ord => 8, system => 'roman' }
bvi^	{ ext => '^', name => 'bvi^', qual => '-', root => 'vi', root_canon => 'vi', root_mod => -1, root_ord => 8, system => 'roman' }
bVIh	{ ext => 'h', name => 'bVIh', qual => '', root => 'VI', root_canon => 'VI', root_mod => -1, root_ord => 8, system => 'roman' }
bvih	{ ext => 'h', name => 'bvih', qual => '-', root => 'vi', root_canon => 'vi', root_mod => -1, root_ord => 8, system => 'roman' }
bVIh7	{ ext => 'h7', name => 'bVIh7', qual => '', root => 'VI', root_canon => 'VI', root_mod => -1, root_ord => 8, system => 'roman' }
bvih7	{ ext => 'h7', name => 'bvih7', qual => '-', root => 'vi', root_canon => 'vi', root_mod => -1, root_ord => 8, system => 'roman' }
bVI^7	{ ext => '^7', name => 'bVI^7', qual => '', root => 'VI', root_canon => 'VI', root_mod => -1, root_ord => 8, system => 'roman' }
bvi^7	{ ext => '^7', name => 'bvi^7', qual => '-', root => 'vi', root_canon => 'vi', root_mod => -1, root_ord => 8, system => 'roman' }
bVI0	{ ext => '', name => 'bVI0', qual => 0, root => 'VI', root_canon => 'VI', root_mod => -1, root_ord => 8, system => 'roman' }
bvi0	{ ext => '', name => 'bvi0', qual => '-', root => 'vi', root_canon => 'vi', root_mod => -1, root_ord => 8, system => 'roman' }
bVI07	{ ext => 7, name => 'bVI07', qual => 0, root => 'VI', root_canon => 'VI', root_mod => -1, root_ord => 8, system => 'roman' }
bvi07	{ ext => 7, name => 'bvi07', qual => '-', root => 'vi', root_canon => 'vi', root_mod => -1, root_ord => 8, system => 'roman' }
bVI0^	{ ext => '^', name => 'bVI0^', qual => 0, root => 'VI', root_canon => 'VI', root_mod => -1, root_ord => 8, system => 'roman' }
bvi0^	{ ext => '^', name => 'bvi0^', qual => '-', root => 'vi', root_canon => 'vi', root_mod => -1, root_ord => 8, system => 'roman' }
bVI0h	{ ext => 'h', name => 'bVI0h', qual => 0, root => 'VI', root_canon => 'VI', root_mod => -1, root_ord => 8, system => 'roman' }
bvi0h	{ ext => 'h', name => 'bvi0h', qual => '-', root => 'vi', root_canon => 'vi', root_mod => -1, root_ord => 8, system => 'roman' }
bVI0h7	{ ext => 'h7', name => 'bVI0h7', qual => 0, root => 'VI', root_canon => 'VI', root_mod => -1, root_ord => 8, system => 'roman' }
bvi0h7	{ ext => 'h7', name => 'bvi0h7', qual => '-', root => 'vi', root_canon => 'vi', root_mod => -1, root_ord => 8, system => 'roman' }
bVI0^7	{ ext => '^7', name => 'bVI0^7', qual => 0, root => 'VI', root_canon => 'VI', root_mod => -1, root_ord => 8, system => 'roman' }
bvi0^7	{ ext => '^7', name => 'bvi0^7', qual => '-', root => 'vi', root_canon => 'vi', root_mod => -1, root_ord => 8, system => 'roman' }
bVI+	{ ext => '', name => 'bVI+', qual => '+', root => 'VI', root_canon => 'VI', root_mod => -1, root_ord => 8, system => 'roman' }
bvi+	{ ext => '', name => 'bvi+', qual => '-', root => 'vi', root_canon => 'vi', root_mod => -1, root_ord => 8, system => 'roman' }
bVI+7	{ ext => 7, name => 'bVI+7', qual => '+', root => 'VI', root_canon => 'VI', root_mod => -1, root_ord => 8, system => 'roman' }
bvi+7	{ ext => 7, name => 'bvi+7', qual => '-', root => 'vi', root_canon => 'vi', root_mod => -1, root_ord => 8, system => 'roman' }
bVI+^	{ ext => '^', name => 'bVI+^', qual => '+', root => 'VI', root_canon => 'VI', root_mod => -1, root_ord => 8, system => 'roman' }
bvi+^	{ ext => '^', name => 'bvi+^', qual => '-', root => 'vi', root_canon => 'vi', root_mod => -1, root_ord => 8, system => 'roman' }
bVI+h	{ ext => 'h', name => 'bVI+h', qual => '+', root => 'VI', root_canon => 'VI', root_mod => -1, root_ord => 8, system => 'roman' }
bvi+h	{ ext => 'h', name => 'bvi+h', qual => '-', root => 'vi', root_canon => 'vi', root_mod => -1, root_ord => 8, system => 'roman' }
bVI+h7	{ ext => 'h7', name => 'bVI+h7', qual => '+', root => 'VI', root_canon => 'VI', root_mod => -1, root_ord => 8, system => 'roman' }
bvi+h7	{ ext => 'h7', name => 'bvi+h7', qual => '-', root => 'vi', root_canon => 'vi', root_mod => -1, root_ord => 8, system => 'roman' }
bVI+^7	{ ext => '^7', name => 'bVI+^7', qual => '+', root => 'VI', root_canon => 'VI', root_mod => -1, root_ord => 8, system => 'roman' }
bvi+^7	{ ext => '^7', name => 'bvi+^7', qual => '-', root => 'vi', root_canon => 'vi', root_mod => -1, root_ord => 8, system => 'roman' }
VI	{ ext => '', name => 'VI', qual => '', root => 'VI', root_canon => 'VI', root_ord => 9, system => 'roman' }
vi	{ ext => '', name => 'vi', qual => '-', root => 'vi', root_canon => 'vi', root_ord => 9, system => 'roman' }
VI7	{ ext => 7, name => 'VI7', qual => '', root => 'VI', root_canon => 'VI', root_ord => 9, system => 'roman' }
vi7	{ ext => 7, name => 'vi7', qual => '-', root => 'vi', root_canon => 'vi', root_ord => 9, system => 'roman' }
VI^	{ ext => '^', name => 'VI^', qual => '', root => 'VI', root_canon => 'VI', root_ord => 9, system => 'roman' }
vi^	{ ext => '^', name => 'vi^', qual => '-', root => 'vi', root_canon => 'vi', root_ord => 9, system => 'roman' }
VIh	{ ext => 'h', name => 'VIh', qual => '', root => 'VI', root_canon => 'VI', root_ord => 9, system => 'roman' }
vih	{ ext => 'h', name => 'vih', qual => '-', root => 'vi', root_canon => 'vi', root_ord => 9, system => 'roman' }
VIh7	{ ext => 'h7', name => 'VIh7', qual => '', root => 'VI', root_canon => 'VI', root_ord => 9, system => 'roman' }
vih7	{ ext => 'h7', name => 'vih7', qual => '-', root => 'vi', root_canon => 'vi', root_ord => 9, system => 'roman' }
VI^7	{ ext => '^7', name => 'VI^7', qual => '', root => 'VI', root_canon => 'VI', root_ord => 9, system => 'roman' }
vi^7	{ ext => '^7', name => 'vi^7', qual => '-', root => 'vi', root_canon => 'vi', root_ord => 9, system => 'roman' }
VI0	{ ext => '', name => 'VI0', qual => 0, root => 'VI', root_canon => 'VI', root_ord => 9, system => 'roman' }
vi0	{ ext => '', name => 'vi0', qual => '-', root => 'vi', root_canon => 'vi', root_ord => 9, system => 'roman' }
VI07	{ ext => 7, name => 'VI07', qual => 0, root => 'VI', root_canon => 'VI', root_ord => 9, system => 'roman' }
vi07	{ ext => 7, name => 'vi07', qual => '-', root => 'vi', root_canon => 'vi', root_ord => 9, system => 'roman' }
VI0^	{ ext => '^', name => 'VI0^', qual => 0, root => 'VI', root_canon => 'VI', root_ord => 9, system => 'roman' }
vi0^	{ ext => '^', name => 'vi0^', qual => '-', root => 'vi', root_canon => 'vi', root_ord => 9, system => 'roman' }
VI0h	{ ext => 'h', name => 'VI0h', qual => 0, root => 'VI', root_canon => 'VI', root_ord => 9, system => 'roman' }
vi0h	{ ext => 'h', name => 'vi0h', qual => '-', root => 'vi', root_canon => 'vi', root_ord => 9, system => 'roman' }
VI0h7	{ ext => 'h7', name => 'VI0h7', qual => 0, root => 'VI', root_canon => 'VI', root_ord => 9, system => 'roman' }
vi0h7	{ ext => 'h7', name => 'vi0h7', qual => '-', root => 'vi', root_canon => 'vi', root_ord => 9, system => 'roman' }
VI0^7	{ ext => '^7', name => 'VI0^7', qual => 0, root => 'VI', root_canon => 'VI', root_ord => 9, system => 'roman' }
vi0^7	{ ext => '^7', name => 'vi0^7', qual => '-', root => 'vi', root_canon => 'vi', root_ord => 9, system => 'roman' }
VI+	{ ext => '', name => 'VI+', qual => '+', root => 'VI', root_canon => 'VI', root_ord => 9, system => 'roman' }
vi+	{ ext => '', name => 'vi+', qual => '-', root => 'vi', root_canon => 'vi', root_ord => 9, system => 'roman' }
VI+7	{ ext => 7, name => 'VI+7', qual => '+', root => 'VI', root_canon => 'VI', root_ord => 9, system => 'roman' }
vi+7	{ ext => 7, name => 'vi+7', qual => '-', root => 'vi', root_canon => 'vi', root_ord => 9, system => 'roman' }
VI+^	{ ext => '^', name => 'VI+^', qual => '+', root => 'VI', root_canon => 'VI', root_ord => 9, system => 'roman' }
vi+^	{ ext => '^', name => 'vi+^', qual => '-', root => 'vi', root_canon => 'vi', root_ord => 9, system => 'roman' }
VI+h	{ ext => 'h', name => 'VI+h', qual => '+', root => 'VI', root_canon => 'VI', root_ord => 9, system => 'roman' }
vi+h	{ ext => 'h', name => 'vi+h', qual => '-', root => 'vi', root_canon => 'vi', root_ord => 9, system => 'roman' }
VI+h7	{ ext => 'h7', name => 'VI+h7', qual => '+', root => 'VI', root_canon => 'VI', root_ord => 9, system => 'roman' }
vi+h7	{ ext => 'h7', name => 'vi+h7', qual => '-', root => 'vi', root_canon => 'vi', root_ord => 9, system => 'roman' }
VI+^7	{ ext => '^7', name => 'VI+^7', qual => '+', root => 'VI', root_canon => 'VI', root_ord => 9, system => 'roman' }
vi+^7	{ ext => '^7', name => 'vi+^7', qual => '-', root => 'vi', root_canon => 'vi', root_ord => 9, system => 'roman' }
#VI	{ ext => '', name => '#VI', qual => '', root => 'VI', root_canon => 'VI', root_mod => 1, root_ord => 10, system => 'roman' }
#vi	{ ext => '', name => '#vi', qual => '-', root => 'vi', root_canon => 'vi', root_mod => 1, root_ord => 10, system => 'roman' }
#VI7	{ ext => 7, name => '#VI7', qual => '', root => 'VI', root_canon => 'VI', root_mod => 1, root_ord => 10, system => 'roman' }
#vi7	{ ext => 7, name => '#vi7', qual => '-', root => 'vi', root_canon => 'vi', root_mod => 1, root_ord => 10, system => 'roman' }
#VI^	{ ext => '^', name => '#VI^', qual => '', root => 'VI', root_canon => 'VI', root_mod => 1, root_ord => 10, system => 'roman' }
#vi^	{ ext => '^', name => '#vi^', qual => '-', root => 'vi', root_canon => 'vi', root_mod => 1, root_ord => 10, system => 'roman' }
#VIh	{ ext => 'h', name => '#VIh', qual => '', root => 'VI', root_canon => 'VI', root_mod => 1, root_ord => 10, system => 'roman' }
#vih	{ ext => 'h', name => '#vih', qual => '-', root => 'vi', root_canon => 'vi', root_mod => 1, root_ord => 10, system => 'roman' }
#VIh7	{ ext => 'h7', name => '#VIh7', qual => '', root => 'VI', root_canon => 'VI', root_mod => 1, root_ord => 10, system => 'roman' }
#vih7	{ ext => 'h7', name => '#vih7', qual => '-', root => 'vi', root_canon => 'vi', root_mod => 1, root_ord => 10, system => 'roman' }
#VI^7	{ ext => '^7', name => '#VI^7', qual => '', root => 'VI', root_canon => 'VI', root_mod => 1, root_ord => 10, system => 'roman' }
#vi^7	{ ext => '^7', name => '#vi^7', qual => '-', root => 'vi', root_canon => 'vi', root_mod => 1, root_ord => 10, system => 'roman' }
#VI0	{ ext => '', name => '#VI0', qual => 0, root => 'VI', root_canon => 'VI', root_mod => 1, root_ord => 10, system => 'roman' }
#vi0	{ ext => '', name => '#vi0', qual => '-', root => 'vi', root_canon => 'vi', root_mod => 1, root_ord => 10, system => 'roman' }
#VI07	{ ext => 7, name => '#VI07', qual => 0, root => 'VI', root_canon => 'VI', root_mod => 1, root_ord => 10, system => 'roman' }
#vi07	{ ext => 7, name => '#vi07', qual => '-', root => 'vi', root_canon => 'vi', root_mod => 1, root_ord => 10, system => 'roman' }
#VI0^	{ ext => '^', name => '#VI0^', qual => 0, root => 'VI', root_canon => 'VI', root_mod => 1, root_ord => 10, system => 'roman' }
#vi0^	{ ext => '^', name => '#vi0^', qual => '-', root => 'vi', root_canon => 'vi', root_mod => 1, root_ord => 10, system => 'roman' }
#VI0h	{ ext => 'h', name => '#VI0h', qual => 0, root => 'VI', root_canon => 'VI', root_mod => 1, root_ord => 10, system => 'roman' }
#vi0h	{ ext => 'h', name => '#vi0h', qual => '-', root => 'vi', root_canon => 'vi', root_mod => 1, root_ord => 10, system => 'roman' }
#VI0h7	{ ext => 'h7', name => '#VI0h7', qual => 0, root => 'VI', root_canon => 'VI', root_mod => 1, root_ord => 10, system => 'roman' }
#vi0h7	{ ext => 'h7', name => '#vi0h7', qual => '-', root => 'vi', root_canon => 'vi', root_mod => 1, root_ord => 10, system => 'roman' }
#VI0^7	{ ext => '^7', name => '#VI0^7', qual => 0, root => 'VI', root_canon => 'VI', root_mod => 1, root_ord => 10, system => 'roman' }
#vi0^7	{ ext => '^7', name => '#vi0^7', qual => '-', root => 'vi', root_canon => 'vi', root_mod => 1, root_ord => 10, system => 'roman' }
#VI+	{ ext => '', name => '#VI+', qual => '+', root => 'VI', root_canon => 'VI', root_mod => 1, root_ord => 10, system => 'roman' }
#vi+	{ ext => '', name => '#vi+', qual => '-', root => 'vi', root_canon => 'vi', root_mod => 1, root_ord => 10, system => 'roman' }
#VI+7	{ ext => 7, name => '#VI+7', qual => '+', root => 'VI', root_canon => 'VI', root_mod => 1, root_ord => 10, system => 'roman' }
#vi+7	{ ext => 7, name => '#vi+7', qual => '-', root => 'vi', root_canon => 'vi', root_mod => 1, root_ord => 10, system => 'roman' }
#VI+^	{ ext => '^', name => '#VI+^', qual => '+', root => 'VI', root_canon => 'VI', root_mod => 1, root_ord => 10, system => 'roman' }
#vi+^	{ ext => '^', name => '#vi+^', qual => '-', root => 'vi', root_canon => 'vi', root_mod => 1, root_ord => 10, system => 'roman' }
#VI+h	{ ext => 'h', name => '#VI+h', qual => '+', root => 'VI', root_canon => 'VI', root_mod => 1, root_ord => 10, system => 'roman' }
#vi+h	{ ext => 'h', name => '#vi+h', qual => '-', root => 'vi', root_canon => 'vi', root_mod => 1, root_ord => 10, system => 'roman' }
#VI+h7	{ ext => 'h7', name => '#VI+h7', qual => '+', root => 'VI', root_canon => 'VI', root_mod => 1, root_ord => 10, system => 'roman' }
#vi+h7	{ ext => 'h7', name => '#vi+h7', qual => '-', root => 'vi', root_canon => 'vi', root_mod => 1, root_ord => 10, system => 'roman' }
#VI+^7	{ ext => '^7', name => '#VI+^7', qual => '+', root => 'VI', root_canon => 'VI', root_mod => 1, root_ord => 10, system => 'roman' }
#vi+^7	{ ext => '^7', name => '#vi+^7', qual => '-', root => 'vi', root_canon => 'vi', root_mod => 1, root_ord => 10, system => 'roman' }
bVII	{ ext => '', name => 'bVII', qual => '', root => 'VII', root_canon => 'VII', root_mod => -1, root_ord => 10, system => 'roman' }
bvii	{ ext => '', name => 'bvii', qual => '-', root => 'vii', root_canon => 'vii', root_mod => -1, root_ord => 10, system => 'roman' }
bVII7	{ ext => 7, name => 'bVII7', qual => '', root => 'VII', root_canon => 'VII', root_mod => -1, root_ord => 10, system => 'roman' }
bvii7	{ ext => 7, name => 'bvii7', qual => '-', root => 'vii', root_canon => 'vii', root_mod => -1, root_ord => 10, system => 'roman' }
bVII^	{ ext => '^', name => 'bVII^', qual => '', root => 'VII', root_canon => 'VII', root_mod => -1, root_ord => 10, system => 'roman' }
bvii^	{ ext => '^', name => 'bvii^', qual => '-', root => 'vii', root_canon => 'vii', root_mod => -1, root_ord => 10, system => 'roman' }
bVIIh	{ ext => 'h', name => 'bVIIh', qual => '', root => 'VII', root_canon => 'VII', root_mod => -1, root_ord => 10, system => 'roman' }
bviih	{ ext => 'h', name => 'bviih', qual => '-', root => 'vii', root_canon => 'vii', root_mod => -1, root_ord => 10, system => 'roman' }
bVIIh7	{ ext => 'h7', name => 'bVIIh7', qual => '', root => 'VII', root_canon => 'VII', root_mod => -1, root_ord => 10, system => 'roman' }
bviih7	{ ext => 'h7', name => 'bviih7', qual => '-', root => 'vii', root_canon => 'vii', root_mod => -1, root_ord => 10, system => 'roman' }
bVII^7	{ ext => '^7', name => 'bVII^7', qual => '', root => 'VII', root_canon => 'VII', root_mod => -1, root_ord => 10, system => 'roman' }
bvii^7	{ ext => '^7', name => 'bvii^7', qual => '-', root => 'vii', root_canon => 'vii', root_mod => -1, root_ord => 10, system => 'roman' }
bVII0	{ ext => '', name => 'bVII0', qual => 0, root => 'VII', root_canon => 'VII', root_mod => -1, root_ord => 10, system => 'roman' }
bvii0	{ ext => '', name => 'bvii0', qual => '-', root => 'vii', root_canon => 'vii', root_mod => -1, root_ord => 10, system => 'roman' }
bVII07	{ ext => 7, name => 'bVII07', qual => 0, root => 'VII', root_canon => 'VII', root_mod => -1, root_ord => 10, system => 'roman' }
bvii07	{ ext => 7, name => 'bvii07', qual => '-', root => 'vii', root_canon => 'vii', root_mod => -1, root_ord => 10, system => 'roman' }
bVII0^	{ ext => '^', name => 'bVII0^', qual => 0, root => 'VII', root_canon => 'VII', root_mod => -1, root_ord => 10, system => 'roman' }
bvii0^	{ ext => '^', name => 'bvii0^', qual => '-', root => 'vii', root_canon => 'vii', root_mod => -1, root_ord => 10, system => 'roman' }
bVII0h	{ ext => 'h', name => 'bVII0h', qual => 0, root => 'VII', root_canon => 'VII', root_mod => -1, root_ord => 10, system => 'roman' }
bvii0h	{ ext => 'h', name => 'bvii0h', qual => '-', root => 'vii', root_canon => 'vii', root_mod => -1, root_ord => 10, system => 'roman' }
bVII0h7	{ ext => 'h7', name => 'bVII0h7', qual => 0, root => 'VII', root_canon => 'VII', root_mod => -1, root_ord => 10, system => 'roman' }
bvii0h7	{ ext => 'h7', name => 'bvii0h7', qual => '-', root => 'vii', root_canon => 'vii', root_mod => -1, root_ord => 10, system => 'roman' }
bVII0^7	{ ext => '^7', name => 'bVII0^7', qual => 0, root => 'VII', root_canon => 'VII', root_mod => -1, root_ord => 10, system => 'roman' }
bvii0^7	{ ext => '^7', name => 'bvii0^7', qual => '-', root => 'vii', root_canon => 'vii', root_mod => -1, root_ord => 10, system => 'roman' }
bVII+	{ ext => '', name => 'bVII+', qual => '+', root => 'VII', root_canon => 'VII', root_mod => -1, root_ord => 10, system => 'roman' }
bvii+	{ ext => '', name => 'bvii+', qual => '-', root => 'vii', root_canon => 'vii', root_mod => -1, root_ord => 10, system => 'roman' }
bVII+7	{ ext => 7, name => 'bVII+7', qual => '+', root => 'VII', root_canon => 'VII', root_mod => -1, root_ord => 10, system => 'roman' }
bvii+7	{ ext => 7, name => 'bvii+7', qual => '-', root => 'vii', root_canon => 'vii', root_mod => -1, root_ord => 10, system => 'roman' }
bVII+^	{ ext => '^', name => 'bVII+^', qual => '+', root => 'VII', root_canon => 'VII', root_mod => -1, root_ord => 10, system => 'roman' }
bvii+^	{ ext => '^', name => 'bvii+^', qual => '-', root => 'vii', root_canon => 'vii', root_mod => -1, root_ord => 10, system => 'roman' }
bVII+h	{ ext => 'h', name => 'bVII+h', qual => '+', root => 'VII', root_canon => 'VII', root_mod => -1, root_ord => 10, system => 'roman' }
bvii+h	{ ext => 'h', name => 'bvii+h', qual => '-', root => 'vii', root_canon => 'vii', root_mod => -1, root_ord => 10, system => 'roman' }
bVII+h7	{ ext => 'h7', name => 'bVII+h7', qual => '+', root => 'VII', root_canon => 'VII', root_mod => -1, root_ord => 10, system => 'roman' }
bvii+h7	{ ext => 'h7', name => 'bvii+h7', qual => '-', root => 'vii', root_canon => 'vii', root_mod => -1, root_ord => 10, system => 'roman' }
bVII+^7	{ ext => '^7', name => 'bVII+^7', qual => '+', root => 'VII', root_canon => 'VII', root_mod => -1, root_ord => 10, system => 'roman' }
bvii+^7	{ ext => '^7', name => 'bvii+^7', qual => '-', root => 'vii', root_canon => 'vii', root_mod => -1, root_ord => 10, system => 'roman' }
VII	{ ext => '', name => 'VII', qual => '', root => 'VII', root_canon => 'VII', root_ord => 11, system => 'roman' }
vii	{ ext => '', name => 'vii', qual => '-', root => 'vii', root_canon => 'vii', root_ord => 11, system => 'roman' }
VII7	{ ext => 7, name => 'VII7', qual => '', root => 'VII', root_canon => 'VII', root_ord => 11, system => 'roman' }
vii7	{ ext => 7, name => 'vii7', qual => '-', root => 'vii', root_canon => 'vii', root_ord => 11, system => 'roman' }
VII^	{ ext => '^', name => 'VII^', qual => '', root => 'VII', root_canon => 'VII', root_ord => 11, system => 'roman' }
vii^	{ ext => '^', name => 'vii^', qual => '-', root => 'vii', root_canon => 'vii', root_ord => 11, system => 'roman' }
VIIh	{ ext => 'h', name => 'VIIh', qual => '', root => 'VII', root_canon => 'VII', root_ord => 11, system => 'roman' }
viih	{ ext => 'h', name => 'viih', qual => '-', root => 'vii', root_canon => 'vii', root_ord => 11, system => 'roman' }
VIIh7	{ ext => 'h7', name => 'VIIh7', qual => '', root => 'VII', root_canon => 'VII', root_ord => 11, system => 'roman' }
viih7	{ ext => 'h7', name => 'viih7', qual => '-', root => 'vii', root_canon => 'vii', root_ord => 11, system => 'roman' }
VII^7	{ ext => '^7', name => 'VII^7', qual => '', root => 'VII', root_canon => 'VII', root_ord => 11, system => 'roman' }
vii^7	{ ext => '^7', name => 'vii^7', qual => '-', root => 'vii', root_canon => 'vii', root_ord => 11, system => 'roman' }
VII0	{ ext => '', name => 'VII0', qual => 0, root => 'VII', root_canon => 'VII', root_ord => 11, system => 'roman' }
vii0	{ ext => '', name => 'vii0', qual => '-', root => 'vii', root_canon => 'vii', root_ord => 11, system => 'roman' }
VII07	{ ext => 7, name => 'VII07', qual => 0, root => 'VII', root_canon => 'VII', root_ord => 11, system => 'roman' }
vii07	{ ext => 7, name => 'vii07', qual => '-', root => 'vii', root_canon => 'vii', root_ord => 11, system => 'roman' }
VII0^	{ ext => '^', name => 'VII0^', qual => 0, root => 'VII', root_canon => 'VII', root_ord => 11, system => 'roman' }
vii0^	{ ext => '^', name => 'vii0^', qual => '-', root => 'vii', root_canon => 'vii', root_ord => 11, system => 'roman' }
VII0h	{ ext => 'h', name => 'VII0h', qual => 0, root => 'VII', root_canon => 'VII', root_ord => 11, system => 'roman' }
vii0h	{ ext => 'h', name => 'vii0h', qual => '-', root => 'vii', root_canon => 'vii', root_ord => 11, system => 'roman' }
VII0h7	{ ext => 'h7', name => 'VII0h7', qual => 0, root => 'VII', root_canon => 'VII', root_ord => 11, system => 'roman' }
vii0h7	{ ext => 'h7', name => 'vii0h7', qual => '-', root => 'vii', root_canon => 'vii', root_ord => 11, system => 'roman' }
VII0^7	{ ext => '^7', name => 'VII0^7', qual => 0, root => 'VII', root_canon => 'VII', root_ord => 11, system => 'roman' }
vii0^7	{ ext => '^7', name => 'vii0^7', qual => '-', root => 'vii', root_canon => 'vii', root_ord => 11, system => 'roman' }
VII+	{ ext => '', name => 'VII+', qual => '+', root => 'VII', root_canon => 'VII', root_ord => 11, system => 'roman' }
vii+	{ ext => '', name => 'vii+', qual => '-', root => 'vii', root_canon => 'vii', root_ord => 11, system => 'roman' }
VII+7	{ ext => 7, name => 'VII+7', qual => '+', root => 'VII', root_canon => 'VII', root_ord => 11, system => 'roman' }
vii+7	{ ext => 7, name => 'vii+7', qual => '-', root => 'vii', root_canon => 'vii', root_ord => 11, system => 'roman' }
VII+^	{ ext => '^', name => 'VII+^', qual => '+', root => 'VII', root_canon => 'VII', root_ord => 11, system => 'roman' }
vii+^	{ ext => '^', name => 'vii+^', qual => '-', root => 'vii', root_canon => 'vii', root_ord => 11, system => 'roman' }
VII+h	{ ext => 'h', name => 'VII+h', qual => '+', root => 'VII', root_canon => 'VII', root_ord => 11, system => 'roman' }
vii+h	{ ext => 'h', name => 'vii+h', qual => '-', root => 'vii', root_canon => 'vii', root_ord => 11, system => 'roman' }
VII+h7	{ ext => 'h7', name => 'VII+h7', qual => '+', root => 'VII', root_canon => 'VII', root_ord => 11, system => 'roman' }
vii+h7	{ ext => 'h7', name => 'vii+h7', qual => '-', root => 'vii', root_canon => 'vii', root_ord => 11, system => 'roman' }
VII+^7	{ ext => '^7', name => 'VII+^7', qual => '+', root => 'VII', root_canon => 'VII', root_ord => 11, system => 'roman' }
vii+^7	{ ext => '^7', name => 'vii+^7', qual => '-', root => 'vii', root_canon => 'vii', root_ord => 11, system => 'roman' }
