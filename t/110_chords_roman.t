#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use App::Music::ChordPro::Testing;
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

plan tests => 0 + keys(%tbl);

App::Music::ChordPro::Chords::set_parser("roman");

=for generating

for my $r ( 'I', '#I', 'bII', 'II', '#II', 'bIII', 'III', 'IV',
	    '#IV', 'bV', 'V', '#V', 'bVI', 'VI', '#VI', 'bVII', 'VII' ) {
    for my $q ( '', '0', '+' ) {
	for my $e ( '', '7', '^', 'h', 'h7', '^7' ) {
	    my $chord = "$r$q$e";
	    my $res = App::Music::ChordPro::Chords::parse_chord($chord);
	    unless ( $res ) {
		print( "$chord\tFAIL\n");
		next;
	    }
	    print("$chord\t", reformat($res), "\n");
	    $chord = lc($r)."$q$e";
	    $res = App::Music::ChordPro::Chords::parse_chord($chord);
	    unless ( $res ) {
		print( "$chord\tFAIL\n");
		next;
	    }
	    print("$chord\t", reformat($res), "\n");
	}
    }
}

exit;

=cut

while ( my ( $c, $info ) = each %tbl ) {
    my $res = App::Music::ChordPro::Chords::parse_chord($c);
    $res //= "FAIL";
    if ( UNIVERSAL::isa( $res, 'HASH' ) ) {
	delete($res->{parser});
	$res = reformat($res);
    }
    is( $res, $info, "parsing chord $c");
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
I	{ ext => '', ext_canon => '', name => 'I', qual => '', qual_canon => '', root => 'I', root_canon => 'I', root_mod => 0, root_ord => 0, system => 'roman' }
i	{ ext => '', ext_canon => '', name => 'i', qual => '', qual_canon => '-', root => 'i', root_canon => 'i', root_mod => 0, root_ord => 0, system => 'roman' }
I7	{ ext => 7, ext_canon => 7, name => 'I7', qual => '', qual_canon => '', root => 'I', root_canon => 'I', root_mod => 0, root_ord => 0, system => 'roman' }
i7	{ ext => 7, ext_canon => 7, name => 'i7', qual => '', qual_canon => '-', root => 'i', root_canon => 'i', root_mod => 0, root_ord => 0, system => 'roman' }
I^	{ ext => '^', ext_canon => '^', name => 'I^', qual => '', qual_canon => '', root => 'I', root_canon => 'I', root_mod => 0, root_ord => 0, system => 'roman' }
i^	{ ext => '^', ext_canon => '^', name => 'i^', qual => '', qual_canon => '-', root => 'i', root_canon => 'i', root_mod => 0, root_ord => 0, system => 'roman' }
Ih	{ ext => '', ext_canon => '', name => 'Ih', qual => 'h', qual_canon => 'h', root => 'I', root_canon => 'I', root_mod => 0, root_ord => 0, system => 'roman' }
ih	{ ext => '', ext_canon => '', name => 'ih', qual => 'h', qual_canon => '-', root => 'i', root_canon => 'i', root_mod => 0, root_ord => 0, system => 'roman' }
Ih7	{ ext => 7, ext_canon => 7, name => 'Ih7', qual => 'h', qual_canon => 'h', root => 'I', root_canon => 'I', root_mod => 0, root_ord => 0, system => 'roman' }
ih7	{ ext => 7, ext_canon => 7, name => 'ih7', qual => 'h', qual_canon => '-', root => 'i', root_canon => 'i', root_mod => 0, root_ord => 0, system => 'roman' }
I^7	{ ext => '^7', ext_canon => '^7', name => 'I^7', qual => '', qual_canon => '', root => 'I', root_canon => 'I', root_mod => 0, root_ord => 0, system => 'roman' }
i^7	{ ext => '^7', ext_canon => '^7', name => 'i^7', qual => '', qual_canon => '-', root => 'i', root_canon => 'i', root_mod => 0, root_ord => 0, system => 'roman' }
I0	{ ext => '', ext_canon => '', name => 'I0', qual => 0, qual_canon => 0, root => 'I', root_canon => 'I', root_mod => 0, root_ord => 0, system => 'roman' }
i0	{ ext => '', ext_canon => '', name => 'i0', qual => 0, qual_canon => '-', root => 'i', root_canon => 'i', root_mod => 0, root_ord => 0, system => 'roman' }
I07	{ ext => 7, ext_canon => 7, name => 'I07', qual => 0, qual_canon => 0, root => 'I', root_canon => 'I', root_mod => 0, root_ord => 0, system => 'roman' }
i07	{ ext => 7, ext_canon => 7, name => 'i07', qual => 0, qual_canon => '-', root => 'i', root_canon => 'i', root_mod => 0, root_ord => 0, system => 'roman' }
I0^	{ ext => '^', ext_canon => '^', name => 'I0^', qual => 0, qual_canon => 0, root => 'I', root_canon => 'I', root_mod => 0, root_ord => 0, system => 'roman' }
i0^	{ ext => '^', ext_canon => '^', name => 'i0^', qual => 0, qual_canon => '-', root => 'i', root_canon => 'i', root_mod => 0, root_ord => 0, system => 'roman' }
I0h	{ ext => 'h', ext_canon => 'h', name => 'I0h', qual => 0, qual_canon => 0, root => 'I', root_canon => 'I', root_mod => 0, root_ord => 0, system => 'roman' }
i0h	{ ext => 'h', ext_canon => 'h', name => 'i0h', qual => 0, qual_canon => '-', root => 'i', root_canon => 'i', root_mod => 0, root_ord => 0, system => 'roman' }
I0h7	{ ext => 'h7', ext_canon => 'h7', name => 'I0h7', qual => 0, qual_canon => 0, root => 'I', root_canon => 'I', root_mod => 0, root_ord => 0, system => 'roman' }
i0h7	{ ext => 'h7', ext_canon => 'h7', name => 'i0h7', qual => 0, qual_canon => '-', root => 'i', root_canon => 'i', root_mod => 0, root_ord => 0, system => 'roman' }
I0^7	{ ext => '^7', ext_canon => '^7', name => 'I0^7', qual => 0, qual_canon => 0, root => 'I', root_canon => 'I', root_mod => 0, root_ord => 0, system => 'roman' }
i0^7	{ ext => '^7', ext_canon => '^7', name => 'i0^7', qual => 0, qual_canon => '-', root => 'i', root_canon => 'i', root_mod => 0, root_ord => 0, system => 'roman' }
I+	{ ext => '', ext_canon => '', name => 'I+', qual => '+', qual_canon => '+', root => 'I', root_canon => 'I', root_mod => 0, root_ord => 0, system => 'roman' }
i+	{ ext => '', ext_canon => '', name => 'i+', qual => '+', qual_canon => '-', root => 'i', root_canon => 'i', root_mod => 0, root_ord => 0, system => 'roman' }
I+7	{ ext => 7, ext_canon => 7, name => 'I+7', qual => '+', qual_canon => '+', root => 'I', root_canon => 'I', root_mod => 0, root_ord => 0, system => 'roman' }
i+7	{ ext => 7, ext_canon => 7, name => 'i+7', qual => '+', qual_canon => '-', root => 'i', root_canon => 'i', root_mod => 0, root_ord => 0, system => 'roman' }
I+^	{ ext => '^', ext_canon => '^', name => 'I+^', qual => '+', qual_canon => '+', root => 'I', root_canon => 'I', root_mod => 0, root_ord => 0, system => 'roman' }
i+^	{ ext => '^', ext_canon => '^', name => 'i+^', qual => '+', qual_canon => '-', root => 'i', root_canon => 'i', root_mod => 0, root_ord => 0, system => 'roman' }
I+h	{ ext => 'h', ext_canon => 'h', name => 'I+h', qual => '+', qual_canon => '+', root => 'I', root_canon => 'I', root_mod => 0, root_ord => 0, system => 'roman' }
i+h	{ ext => 'h', ext_canon => 'h', name => 'i+h', qual => '+', qual_canon => '-', root => 'i', root_canon => 'i', root_mod => 0, root_ord => 0, system => 'roman' }
I+h7	{ ext => 'h7', ext_canon => 'h7', name => 'I+h7', qual => '+', qual_canon => '+', root => 'I', root_canon => 'I', root_mod => 0, root_ord => 0, system => 'roman' }
i+h7	{ ext => 'h7', ext_canon => 'h7', name => 'i+h7', qual => '+', qual_canon => '-', root => 'i', root_canon => 'i', root_mod => 0, root_ord => 0, system => 'roman' }
I+^7	{ ext => '^7', ext_canon => '^7', name => 'I+^7', qual => '+', qual_canon => '+', root => 'I', root_canon => 'I', root_mod => 0, root_ord => 0, system => 'roman' }
i+^7	{ ext => '^7', ext_canon => '^7', name => 'i+^7', qual => '+', qual_canon => '-', root => 'i', root_canon => 'i', root_mod => 0, root_ord => 0, system => 'roman' }
#I	{ ext => '', ext_canon => '', name => '#I', qual => '', qual_canon => '', root => '#I', root_canon => '#I', root_mod => 1, root_ord => 1, system => 'roman' }
#i	{ ext => '', ext_canon => '', name => '#i', qual => '', qual_canon => '-', root => '#i', root_canon => '#i', root_mod => 1, root_ord => 1, system => 'roman' }
#I7	{ ext => 7, ext_canon => 7, name => '#I7', qual => '', qual_canon => '', root => '#I', root_canon => '#I', root_mod => 1, root_ord => 1, system => 'roman' }
#i7	{ ext => 7, ext_canon => 7, name => '#i7', qual => '', qual_canon => '-', root => '#i', root_canon => '#i', root_mod => 1, root_ord => 1, system => 'roman' }
#I^	{ ext => '^', ext_canon => '^', name => '#I^', qual => '', qual_canon => '', root => '#I', root_canon => '#I', root_mod => 1, root_ord => 1, system => 'roman' }
#i^	{ ext => '^', ext_canon => '^', name => '#i^', qual => '', qual_canon => '-', root => '#i', root_canon => '#i', root_mod => 1, root_ord => 1, system => 'roman' }
#Ih	{ ext => '', ext_canon => '', name => '#Ih', qual => 'h', qual_canon => 'h', root => '#I', root_canon => '#I', root_mod => 1, root_ord => 1, system => 'roman' }
#ih	{ ext => '', ext_canon => '', name => '#ih', qual => 'h', qual_canon => '-', root => '#i', root_canon => '#i', root_mod => 1, root_ord => 1, system => 'roman' }
#Ih7	{ ext => 7, ext_canon => 7, name => '#Ih7', qual => 'h', qual_canon => 'h', root => '#I', root_canon => '#I', root_mod => 1, root_ord => 1, system => 'roman' }
#ih7	{ ext => 7, ext_canon => 7, name => '#ih7', qual => 'h', qual_canon => '-', root => '#i', root_canon => '#i', root_mod => 1, root_ord => 1, system => 'roman' }
#I^7	{ ext => '^7', ext_canon => '^7', name => '#I^7', qual => '', qual_canon => '', root => '#I', root_canon => '#I', root_mod => 1, root_ord => 1, system => 'roman' }
#i^7	{ ext => '^7', ext_canon => '^7', name => '#i^7', qual => '', qual_canon => '-', root => '#i', root_canon => '#i', root_mod => 1, root_ord => 1, system => 'roman' }
#I0	{ ext => '', ext_canon => '', name => '#I0', qual => 0, qual_canon => 0, root => '#I', root_canon => '#I', root_mod => 1, root_ord => 1, system => 'roman' }
#i0	{ ext => '', ext_canon => '', name => '#i0', qual => 0, qual_canon => '-', root => '#i', root_canon => '#i', root_mod => 1, root_ord => 1, system => 'roman' }
#I07	{ ext => 7, ext_canon => 7, name => '#I07', qual => 0, qual_canon => 0, root => '#I', root_canon => '#I', root_mod => 1, root_ord => 1, system => 'roman' }
#i07	{ ext => 7, ext_canon => 7, name => '#i07', qual => 0, qual_canon => '-', root => '#i', root_canon => '#i', root_mod => 1, root_ord => 1, system => 'roman' }
#I0^	{ ext => '^', ext_canon => '^', name => '#I0^', qual => 0, qual_canon => 0, root => '#I', root_canon => '#I', root_mod => 1, root_ord => 1, system => 'roman' }
#i0^	{ ext => '^', ext_canon => '^', name => '#i0^', qual => 0, qual_canon => '-', root => '#i', root_canon => '#i', root_mod => 1, root_ord => 1, system => 'roman' }
#I0h	{ ext => 'h', ext_canon => 'h', name => '#I0h', qual => 0, qual_canon => 0, root => '#I', root_canon => '#I', root_mod => 1, root_ord => 1, system => 'roman' }
#i0h	{ ext => 'h', ext_canon => 'h', name => '#i0h', qual => 0, qual_canon => '-', root => '#i', root_canon => '#i', root_mod => 1, root_ord => 1, system => 'roman' }
#I0h7	{ ext => 'h7', ext_canon => 'h7', name => '#I0h7', qual => 0, qual_canon => 0, root => '#I', root_canon => '#I', root_mod => 1, root_ord => 1, system => 'roman' }
#i0h7	{ ext => 'h7', ext_canon => 'h7', name => '#i0h7', qual => 0, qual_canon => '-', root => '#i', root_canon => '#i', root_mod => 1, root_ord => 1, system => 'roman' }
#I0^7	{ ext => '^7', ext_canon => '^7', name => '#I0^7', qual => 0, qual_canon => 0, root => '#I', root_canon => '#I', root_mod => 1, root_ord => 1, system => 'roman' }
#i0^7	{ ext => '^7', ext_canon => '^7', name => '#i0^7', qual => 0, qual_canon => '-', root => '#i', root_canon => '#i', root_mod => 1, root_ord => 1, system => 'roman' }
#I+	{ ext => '', ext_canon => '', name => '#I+', qual => '+', qual_canon => '+', root => '#I', root_canon => '#I', root_mod => 1, root_ord => 1, system => 'roman' }
#i+	{ ext => '', ext_canon => '', name => '#i+', qual => '+', qual_canon => '-', root => '#i', root_canon => '#i', root_mod => 1, root_ord => 1, system => 'roman' }
#I+7	{ ext => 7, ext_canon => 7, name => '#I+7', qual => '+', qual_canon => '+', root => '#I', root_canon => '#I', root_mod => 1, root_ord => 1, system => 'roman' }
#i+7	{ ext => 7, ext_canon => 7, name => '#i+7', qual => '+', qual_canon => '-', root => '#i', root_canon => '#i', root_mod => 1, root_ord => 1, system => 'roman' }
#I+^	{ ext => '^', ext_canon => '^', name => '#I+^', qual => '+', qual_canon => '+', root => '#I', root_canon => '#I', root_mod => 1, root_ord => 1, system => 'roman' }
#i+^	{ ext => '^', ext_canon => '^', name => '#i+^', qual => '+', qual_canon => '-', root => '#i', root_canon => '#i', root_mod => 1, root_ord => 1, system => 'roman' }
#I+h	{ ext => 'h', ext_canon => 'h', name => '#I+h', qual => '+', qual_canon => '+', root => '#I', root_canon => '#I', root_mod => 1, root_ord => 1, system => 'roman' }
#i+h	{ ext => 'h', ext_canon => 'h', name => '#i+h', qual => '+', qual_canon => '-', root => '#i', root_canon => '#i', root_mod => 1, root_ord => 1, system => 'roman' }
#I+h7	{ ext => 'h7', ext_canon => 'h7', name => '#I+h7', qual => '+', qual_canon => '+', root => '#I', root_canon => '#I', root_mod => 1, root_ord => 1, system => 'roman' }
#i+h7	{ ext => 'h7', ext_canon => 'h7', name => '#i+h7', qual => '+', qual_canon => '-', root => '#i', root_canon => '#i', root_mod => 1, root_ord => 1, system => 'roman' }
#I+^7	{ ext => '^7', ext_canon => '^7', name => '#I+^7', qual => '+', qual_canon => '+', root => '#I', root_canon => '#I', root_mod => 1, root_ord => 1, system => 'roman' }
#i+^7	{ ext => '^7', ext_canon => '^7', name => '#i+^7', qual => '+', qual_canon => '-', root => '#i', root_canon => '#i', root_mod => 1, root_ord => 1, system => 'roman' }
bII	{ ext => '', ext_canon => '', name => 'bII', qual => '', qual_canon => '', root => 'bII', root_canon => 'bII', root_mod => -1, root_ord => 11, system => 'roman' }
bii	{ ext => '', ext_canon => '', name => 'bii', qual => '', qual_canon => '-', root => 'bii', root_canon => 'bii', root_mod => -1, root_ord => 11, system => 'roman' }
bII7	{ ext => 7, ext_canon => 7, name => 'bII7', qual => '', qual_canon => '', root => 'bII', root_canon => 'bII', root_mod => -1, root_ord => 11, system => 'roman' }
bii7	{ ext => 7, ext_canon => 7, name => 'bii7', qual => '', qual_canon => '-', root => 'bii', root_canon => 'bii', root_mod => -1, root_ord => 11, system => 'roman' }
bII^	{ ext => '^', ext_canon => '^', name => 'bII^', qual => '', qual_canon => '', root => 'bII', root_canon => 'bII', root_mod => -1, root_ord => 11, system => 'roman' }
bii^	{ ext => '^', ext_canon => '^', name => 'bii^', qual => '', qual_canon => '-', root => 'bii', root_canon => 'bii', root_mod => -1, root_ord => 11, system => 'roman' }
bIIh	{ ext => '', ext_canon => '', name => 'bIIh', qual => 'h', qual_canon => 'h', root => 'bII', root_canon => 'bII', root_mod => -1, root_ord => 11, system => 'roman' }
biih	{ ext => '', ext_canon => '', name => 'biih', qual => 'h', qual_canon => '-', root => 'bii', root_canon => 'bii', root_mod => -1, root_ord => 11, system => 'roman' }
bIIh7	{ ext => 7, ext_canon => 7, name => 'bIIh7', qual => 'h', qual_canon => 'h', root => 'bII', root_canon => 'bII', root_mod => -1, root_ord => 11, system => 'roman' }
biih7	{ ext => 7, ext_canon => 7, name => 'biih7', qual => 'h', qual_canon => '-', root => 'bii', root_canon => 'bii', root_mod => -1, root_ord => 11, system => 'roman' }
bII^7	{ ext => '^7', ext_canon => '^7', name => 'bII^7', qual => '', qual_canon => '', root => 'bII', root_canon => 'bII', root_mod => -1, root_ord => 11, system => 'roman' }
bii^7	{ ext => '^7', ext_canon => '^7', name => 'bii^7', qual => '', qual_canon => '-', root => 'bii', root_canon => 'bii', root_mod => -1, root_ord => 11, system => 'roman' }
bII0	{ ext => '', ext_canon => '', name => 'bII0', qual => 0, qual_canon => 0, root => 'bII', root_canon => 'bII', root_mod => -1, root_ord => 11, system => 'roman' }
bii0	{ ext => '', ext_canon => '', name => 'bii0', qual => 0, qual_canon => '-', root => 'bii', root_canon => 'bii', root_mod => -1, root_ord => 11, system => 'roman' }
bII07	{ ext => 7, ext_canon => 7, name => 'bII07', qual => 0, qual_canon => 0, root => 'bII', root_canon => 'bII', root_mod => -1, root_ord => 11, system => 'roman' }
bii07	{ ext => 7, ext_canon => 7, name => 'bii07', qual => 0, qual_canon => '-', root => 'bii', root_canon => 'bii', root_mod => -1, root_ord => 11, system => 'roman' }
bII0^	{ ext => '^', ext_canon => '^', name => 'bII0^', qual => 0, qual_canon => 0, root => 'bII', root_canon => 'bII', root_mod => -1, root_ord => 11, system => 'roman' }
bii0^	{ ext => '^', ext_canon => '^', name => 'bii0^', qual => 0, qual_canon => '-', root => 'bii', root_canon => 'bii', root_mod => -1, root_ord => 11, system => 'roman' }
bII0h	{ ext => 'h', ext_canon => 'h', name => 'bII0h', qual => 0, qual_canon => 0, root => 'bII', root_canon => 'bII', root_mod => -1, root_ord => 11, system => 'roman' }
bii0h	{ ext => 'h', ext_canon => 'h', name => 'bii0h', qual => 0, qual_canon => '-', root => 'bii', root_canon => 'bii', root_mod => -1, root_ord => 11, system => 'roman' }
bII0h7	{ ext => 'h7', ext_canon => 'h7', name => 'bII0h7', qual => 0, qual_canon => 0, root => 'bII', root_canon => 'bII', root_mod => -1, root_ord => 11, system => 'roman' }
bii0h7	{ ext => 'h7', ext_canon => 'h7', name => 'bii0h7', qual => 0, qual_canon => '-', root => 'bii', root_canon => 'bii', root_mod => -1, root_ord => 11, system => 'roman' }
bII0^7	{ ext => '^7', ext_canon => '^7', name => 'bII0^7', qual => 0, qual_canon => 0, root => 'bII', root_canon => 'bII', root_mod => -1, root_ord => 11, system => 'roman' }
bii0^7	{ ext => '^7', ext_canon => '^7', name => 'bii0^7', qual => 0, qual_canon => '-', root => 'bii', root_canon => 'bii', root_mod => -1, root_ord => 11, system => 'roman' }
bII+	{ ext => '', ext_canon => '', name => 'bII+', qual => '+', qual_canon => '+', root => 'bII', root_canon => 'bII', root_mod => -1, root_ord => 11, system => 'roman' }
bii+	{ ext => '', ext_canon => '', name => 'bii+', qual => '+', qual_canon => '-', root => 'bii', root_canon => 'bii', root_mod => -1, root_ord => 11, system => 'roman' }
bII+7	{ ext => 7, ext_canon => 7, name => 'bII+7', qual => '+', qual_canon => '+', root => 'bII', root_canon => 'bII', root_mod => -1, root_ord => 11, system => 'roman' }
bii+7	{ ext => 7, ext_canon => 7, name => 'bii+7', qual => '+', qual_canon => '-', root => 'bii', root_canon => 'bii', root_mod => -1, root_ord => 11, system => 'roman' }
bII+^	{ ext => '^', ext_canon => '^', name => 'bII+^', qual => '+', qual_canon => '+', root => 'bII', root_canon => 'bII', root_mod => -1, root_ord => 11, system => 'roman' }
bii+^	{ ext => '^', ext_canon => '^', name => 'bii+^', qual => '+', qual_canon => '-', root => 'bii', root_canon => 'bii', root_mod => -1, root_ord => 11, system => 'roman' }
bII+h	{ ext => 'h', ext_canon => 'h', name => 'bII+h', qual => '+', qual_canon => '+', root => 'bII', root_canon => 'bII', root_mod => -1, root_ord => 11, system => 'roman' }
bii+h	{ ext => 'h', ext_canon => 'h', name => 'bii+h', qual => '+', qual_canon => '-', root => 'bii', root_canon => 'bii', root_mod => -1, root_ord => 11, system => 'roman' }
bII+h7	{ ext => 'h7', ext_canon => 'h7', name => 'bII+h7', qual => '+', qual_canon => '+', root => 'bII', root_canon => 'bII', root_mod => -1, root_ord => 11, system => 'roman' }
bii+h7	{ ext => 'h7', ext_canon => 'h7', name => 'bii+h7', qual => '+', qual_canon => '-', root => 'bii', root_canon => 'bii', root_mod => -1, root_ord => 11, system => 'roman' }
bII+^7	{ ext => '^7', ext_canon => '^7', name => 'bII+^7', qual => '+', qual_canon => '+', root => 'bII', root_canon => 'bII', root_mod => -1, root_ord => 11, system => 'roman' }
bii+^7	{ ext => '^7', ext_canon => '^7', name => 'bii+^7', qual => '+', qual_canon => '-', root => 'bii', root_canon => 'bii', root_mod => -1, root_ord => 11, system => 'roman' }
II	{ ext => '', ext_canon => '', name => 'II', qual => '', qual_canon => '', root => 'II', root_canon => 'II', root_mod => 0, root_ord => 2, system => 'roman' }
ii	{ ext => '', ext_canon => '', name => 'ii', qual => '', qual_canon => '-', root => 'ii', root_canon => 'ii', root_mod => 0, root_ord => 2, system => 'roman' }
II7	{ ext => 7, ext_canon => 7, name => 'II7', qual => '', qual_canon => '', root => 'II', root_canon => 'II', root_mod => 0, root_ord => 2, system => 'roman' }
ii7	{ ext => 7, ext_canon => 7, name => 'ii7', qual => '', qual_canon => '-', root => 'ii', root_canon => 'ii', root_mod => 0, root_ord => 2, system => 'roman' }
II^	{ ext => '^', ext_canon => '^', name => 'II^', qual => '', qual_canon => '', root => 'II', root_canon => 'II', root_mod => 0, root_ord => 2, system => 'roman' }
ii^	{ ext => '^', ext_canon => '^', name => 'ii^', qual => '', qual_canon => '-', root => 'ii', root_canon => 'ii', root_mod => 0, root_ord => 2, system => 'roman' }
IIh	{ ext => '', ext_canon => '', name => 'IIh', qual => 'h', qual_canon => 'h', root => 'II', root_canon => 'II', root_mod => 0, root_ord => 2, system => 'roman' }
iih	{ ext => '', ext_canon => '', name => 'iih', qual => 'h', qual_canon => '-', root => 'ii', root_canon => 'ii', root_mod => 0, root_ord => 2, system => 'roman' }
IIh7	{ ext => 7, ext_canon => 7, name => 'IIh7', qual => 'h', qual_canon => 'h', root => 'II', root_canon => 'II', root_mod => 0, root_ord => 2, system => 'roman' }
iih7	{ ext => 7, ext_canon => 7, name => 'iih7', qual => 'h', qual_canon => '-', root => 'ii', root_canon => 'ii', root_mod => 0, root_ord => 2, system => 'roman' }
II^7	{ ext => '^7', ext_canon => '^7', name => 'II^7', qual => '', qual_canon => '', root => 'II', root_canon => 'II', root_mod => 0, root_ord => 2, system => 'roman' }
ii^7	{ ext => '^7', ext_canon => '^7', name => 'ii^7', qual => '', qual_canon => '-', root => 'ii', root_canon => 'ii', root_mod => 0, root_ord => 2, system => 'roman' }
II0	{ ext => '', ext_canon => '', name => 'II0', qual => 0, qual_canon => 0, root => 'II', root_canon => 'II', root_mod => 0, root_ord => 2, system => 'roman' }
ii0	{ ext => '', ext_canon => '', name => 'ii0', qual => 0, qual_canon => '-', root => 'ii', root_canon => 'ii', root_mod => 0, root_ord => 2, system => 'roman' }
II07	{ ext => 7, ext_canon => 7, name => 'II07', qual => 0, qual_canon => 0, root => 'II', root_canon => 'II', root_mod => 0, root_ord => 2, system => 'roman' }
ii07	{ ext => 7, ext_canon => 7, name => 'ii07', qual => 0, qual_canon => '-', root => 'ii', root_canon => 'ii', root_mod => 0, root_ord => 2, system => 'roman' }
II0^	{ ext => '^', ext_canon => '^', name => 'II0^', qual => 0, qual_canon => 0, root => 'II', root_canon => 'II', root_mod => 0, root_ord => 2, system => 'roman' }
ii0^	{ ext => '^', ext_canon => '^', name => 'ii0^', qual => 0, qual_canon => '-', root => 'ii', root_canon => 'ii', root_mod => 0, root_ord => 2, system => 'roman' }
II0h	{ ext => 'h', ext_canon => 'h', name => 'II0h', qual => 0, qual_canon => 0, root => 'II', root_canon => 'II', root_mod => 0, root_ord => 2, system => 'roman' }
ii0h	{ ext => 'h', ext_canon => 'h', name => 'ii0h', qual => 0, qual_canon => '-', root => 'ii', root_canon => 'ii', root_mod => 0, root_ord => 2, system => 'roman' }
II0h7	{ ext => 'h7', ext_canon => 'h7', name => 'II0h7', qual => 0, qual_canon => 0, root => 'II', root_canon => 'II', root_mod => 0, root_ord => 2, system => 'roman' }
ii0h7	{ ext => 'h7', ext_canon => 'h7', name => 'ii0h7', qual => 0, qual_canon => '-', root => 'ii', root_canon => 'ii', root_mod => 0, root_ord => 2, system => 'roman' }
II0^7	{ ext => '^7', ext_canon => '^7', name => 'II0^7', qual => 0, qual_canon => 0, root => 'II', root_canon => 'II', root_mod => 0, root_ord => 2, system => 'roman' }
ii0^7	{ ext => '^7', ext_canon => '^7', name => 'ii0^7', qual => 0, qual_canon => '-', root => 'ii', root_canon => 'ii', root_mod => 0, root_ord => 2, system => 'roman' }
II+	{ ext => '', ext_canon => '', name => 'II+', qual => '+', qual_canon => '+', root => 'II', root_canon => 'II', root_mod => 0, root_ord => 2, system => 'roman' }
ii+	{ ext => '', ext_canon => '', name => 'ii+', qual => '+', qual_canon => '-', root => 'ii', root_canon => 'ii', root_mod => 0, root_ord => 2, system => 'roman' }
II+7	{ ext => 7, ext_canon => 7, name => 'II+7', qual => '+', qual_canon => '+', root => 'II', root_canon => 'II', root_mod => 0, root_ord => 2, system => 'roman' }
ii+7	{ ext => 7, ext_canon => 7, name => 'ii+7', qual => '+', qual_canon => '-', root => 'ii', root_canon => 'ii', root_mod => 0, root_ord => 2, system => 'roman' }
II+^	{ ext => '^', ext_canon => '^', name => 'II+^', qual => '+', qual_canon => '+', root => 'II', root_canon => 'II', root_mod => 0, root_ord => 2, system => 'roman' }
ii+^	{ ext => '^', ext_canon => '^', name => 'ii+^', qual => '+', qual_canon => '-', root => 'ii', root_canon => 'ii', root_mod => 0, root_ord => 2, system => 'roman' }
II+h	{ ext => 'h', ext_canon => 'h', name => 'II+h', qual => '+', qual_canon => '+', root => 'II', root_canon => 'II', root_mod => 0, root_ord => 2, system => 'roman' }
ii+h	{ ext => 'h', ext_canon => 'h', name => 'ii+h', qual => '+', qual_canon => '-', root => 'ii', root_canon => 'ii', root_mod => 0, root_ord => 2, system => 'roman' }
II+h7	{ ext => 'h7', ext_canon => 'h7', name => 'II+h7', qual => '+', qual_canon => '+', root => 'II', root_canon => 'II', root_mod => 0, root_ord => 2, system => 'roman' }
ii+h7	{ ext => 'h7', ext_canon => 'h7', name => 'ii+h7', qual => '+', qual_canon => '-', root => 'ii', root_canon => 'ii', root_mod => 0, root_ord => 2, system => 'roman' }
II+^7	{ ext => '^7', ext_canon => '^7', name => 'II+^7', qual => '+', qual_canon => '+', root => 'II', root_canon => 'II', root_mod => 0, root_ord => 2, system => 'roman' }
ii+^7	{ ext => '^7', ext_canon => '^7', name => 'ii+^7', qual => '+', qual_canon => '-', root => 'ii', root_canon => 'ii', root_mod => 0, root_ord => 2, system => 'roman' }
#II	{ ext => '', ext_canon => '', name => '#II', qual => '', qual_canon => '', root => '#II', root_canon => '#II', root_mod => 1, root_ord => 1, system => 'roman' }
#ii	{ ext => '', ext_canon => '', name => '#ii', qual => '', qual_canon => '-', root => '#ii', root_canon => '#ii', root_mod => 1, root_ord => 1, system => 'roman' }
#II7	{ ext => 7, ext_canon => 7, name => '#II7', qual => '', qual_canon => '', root => '#II', root_canon => '#II', root_mod => 1, root_ord => 1, system => 'roman' }
#ii7	{ ext => 7, ext_canon => 7, name => '#ii7', qual => '', qual_canon => '-', root => '#ii', root_canon => '#ii', root_mod => 1, root_ord => 1, system => 'roman' }
#II^	{ ext => '^', ext_canon => '^', name => '#II^', qual => '', qual_canon => '', root => '#II', root_canon => '#II', root_mod => 1, root_ord => 1, system => 'roman' }
#ii^	{ ext => '^', ext_canon => '^', name => '#ii^', qual => '', qual_canon => '-', root => '#ii', root_canon => '#ii', root_mod => 1, root_ord => 1, system => 'roman' }
#IIh	{ ext => '', ext_canon => '', name => '#IIh', qual => 'h', qual_canon => 'h', root => '#II', root_canon => '#II', root_mod => 1, root_ord => 1, system => 'roman' }
#iih	{ ext => '', ext_canon => '', name => '#iih', qual => 'h', qual_canon => '-', root => '#ii', root_canon => '#ii', root_mod => 1, root_ord => 1, system => 'roman' }
#IIh7	{ ext => 7, ext_canon => 7, name => '#IIh7', qual => 'h', qual_canon => 'h', root => '#II', root_canon => '#II', root_mod => 1, root_ord => 1, system => 'roman' }
#iih7	{ ext => 7, ext_canon => 7, name => '#iih7', qual => 'h', qual_canon => '-', root => '#ii', root_canon => '#ii', root_mod => 1, root_ord => 1, system => 'roman' }
#II^7	{ ext => '^7', ext_canon => '^7', name => '#II^7', qual => '', qual_canon => '', root => '#II', root_canon => '#II', root_mod => 1, root_ord => 1, system => 'roman' }
#ii^7	{ ext => '^7', ext_canon => '^7', name => '#ii^7', qual => '', qual_canon => '-', root => '#ii', root_canon => '#ii', root_mod => 1, root_ord => 1, system => 'roman' }
#II0	{ ext => '', ext_canon => '', name => '#II0', qual => 0, qual_canon => 0, root => '#II', root_canon => '#II', root_mod => 1, root_ord => 1, system => 'roman' }
#ii0	{ ext => '', ext_canon => '', name => '#ii0', qual => 0, qual_canon => '-', root => '#ii', root_canon => '#ii', root_mod => 1, root_ord => 1, system => 'roman' }
#II07	{ ext => 7, ext_canon => 7, name => '#II07', qual => 0, qual_canon => 0, root => '#II', root_canon => '#II', root_mod => 1, root_ord => 1, system => 'roman' }
#ii07	{ ext => 7, ext_canon => 7, name => '#ii07', qual => 0, qual_canon => '-', root => '#ii', root_canon => '#ii', root_mod => 1, root_ord => 1, system => 'roman' }
#II0^	{ ext => '^', ext_canon => '^', name => '#II0^', qual => 0, qual_canon => 0, root => '#II', root_canon => '#II', root_mod => 1, root_ord => 1, system => 'roman' }
#ii0^	{ ext => '^', ext_canon => '^', name => '#ii0^', qual => 0, qual_canon => '-', root => '#ii', root_canon => '#ii', root_mod => 1, root_ord => 1, system => 'roman' }
#II0h	{ ext => 'h', ext_canon => 'h', name => '#II0h', qual => 0, qual_canon => 0, root => '#II', root_canon => '#II', root_mod => 1, root_ord => 1, system => 'roman' }
#ii0h	{ ext => 'h', ext_canon => 'h', name => '#ii0h', qual => 0, qual_canon => '-', root => '#ii', root_canon => '#ii', root_mod => 1, root_ord => 1, system => 'roman' }
#II0h7	{ ext => 'h7', ext_canon => 'h7', name => '#II0h7', qual => 0, qual_canon => 0, root => '#II', root_canon => '#II', root_mod => 1, root_ord => 1, system => 'roman' }
#ii0h7	{ ext => 'h7', ext_canon => 'h7', name => '#ii0h7', qual => 0, qual_canon => '-', root => '#ii', root_canon => '#ii', root_mod => 1, root_ord => 1, system => 'roman' }
#II0^7	{ ext => '^7', ext_canon => '^7', name => '#II0^7', qual => 0, qual_canon => 0, root => '#II', root_canon => '#II', root_mod => 1, root_ord => 1, system => 'roman' }
#ii0^7	{ ext => '^7', ext_canon => '^7', name => '#ii0^7', qual => 0, qual_canon => '-', root => '#ii', root_canon => '#ii', root_mod => 1, root_ord => 1, system => 'roman' }
#II+	{ ext => '', ext_canon => '', name => '#II+', qual => '+', qual_canon => '+', root => '#II', root_canon => '#II', root_mod => 1, root_ord => 1, system => 'roman' }
#ii+	{ ext => '', ext_canon => '', name => '#ii+', qual => '+', qual_canon => '-', root => '#ii', root_canon => '#ii', root_mod => 1, root_ord => 1, system => 'roman' }
#II+7	{ ext => 7, ext_canon => 7, name => '#II+7', qual => '+', qual_canon => '+', root => '#II', root_canon => '#II', root_mod => 1, root_ord => 1, system => 'roman' }
#ii+7	{ ext => 7, ext_canon => 7, name => '#ii+7', qual => '+', qual_canon => '-', root => '#ii', root_canon => '#ii', root_mod => 1, root_ord => 1, system => 'roman' }
#II+^	{ ext => '^', ext_canon => '^', name => '#II+^', qual => '+', qual_canon => '+', root => '#II', root_canon => '#II', root_mod => 1, root_ord => 1, system => 'roman' }
#ii+^	{ ext => '^', ext_canon => '^', name => '#ii+^', qual => '+', qual_canon => '-', root => '#ii', root_canon => '#ii', root_mod => 1, root_ord => 1, system => 'roman' }
#II+h	{ ext => 'h', ext_canon => 'h', name => '#II+h', qual => '+', qual_canon => '+', root => '#II', root_canon => '#II', root_mod => 1, root_ord => 1, system => 'roman' }
#ii+h	{ ext => 'h', ext_canon => 'h', name => '#ii+h', qual => '+', qual_canon => '-', root => '#ii', root_canon => '#ii', root_mod => 1, root_ord => 1, system => 'roman' }
#II+h7	{ ext => 'h7', ext_canon => 'h7', name => '#II+h7', qual => '+', qual_canon => '+', root => '#II', root_canon => '#II', root_mod => 1, root_ord => 1, system => 'roman' }
#ii+h7	{ ext => 'h7', ext_canon => 'h7', name => '#ii+h7', qual => '+', qual_canon => '-', root => '#ii', root_canon => '#ii', root_mod => 1, root_ord => 1, system => 'roman' }
#II+^7	{ ext => '^7', ext_canon => '^7', name => '#II+^7', qual => '+', qual_canon => '+', root => '#II', root_canon => '#II', root_mod => 1, root_ord => 1, system => 'roman' }
#ii+^7	{ ext => '^7', ext_canon => '^7', name => '#ii+^7', qual => '+', qual_canon => '-', root => '#ii', root_canon => '#ii', root_mod => 1, root_ord => 1, system => 'roman' }
bIII	{ ext => '', ext_canon => '', name => 'bIII', qual => '', qual_canon => '', root => 'bIII', root_canon => 'bIII', root_mod => -1, root_ord => 11, system => 'roman' }
biii	{ ext => '', ext_canon => '', name => 'biii', qual => '', qual_canon => '-', root => 'biii', root_canon => 'biii', root_mod => -1, root_ord => 11, system => 'roman' }
bIII7	{ ext => 7, ext_canon => 7, name => 'bIII7', qual => '', qual_canon => '', root => 'bIII', root_canon => 'bIII', root_mod => -1, root_ord => 11, system => 'roman' }
biii7	{ ext => 7, ext_canon => 7, name => 'biii7', qual => '', qual_canon => '-', root => 'biii', root_canon => 'biii', root_mod => -1, root_ord => 11, system => 'roman' }
bIII^	{ ext => '^', ext_canon => '^', name => 'bIII^', qual => '', qual_canon => '', root => 'bIII', root_canon => 'bIII', root_mod => -1, root_ord => 11, system => 'roman' }
biii^	{ ext => '^', ext_canon => '^', name => 'biii^', qual => '', qual_canon => '-', root => 'biii', root_canon => 'biii', root_mod => -1, root_ord => 11, system => 'roman' }
bIIIh	{ ext => '', ext_canon => '', name => 'bIIIh', qual => 'h', qual_canon => 'h', root => 'bIII', root_canon => 'bIII', root_mod => -1, root_ord => 11, system => 'roman' }
biiih	{ ext => '', ext_canon => '', name => 'biiih', qual => 'h', qual_canon => '-', root => 'biii', root_canon => 'biii', root_mod => -1, root_ord => 11, system => 'roman' }
bIIIh7	{ ext => 7, ext_canon => 7, name => 'bIIIh7', qual => 'h', qual_canon => 'h', root => 'bIII', root_canon => 'bIII', root_mod => -1, root_ord => 11, system => 'roman' }
biiih7	{ ext => 7, ext_canon => 7, name => 'biiih7', qual => 'h', qual_canon => '-', root => 'biii', root_canon => 'biii', root_mod => -1, root_ord => 11, system => 'roman' }
bIII^7	{ ext => '^7', ext_canon => '^7', name => 'bIII^7', qual => '', qual_canon => '', root => 'bIII', root_canon => 'bIII', root_mod => -1, root_ord => 11, system => 'roman' }
biii^7	{ ext => '^7', ext_canon => '^7', name => 'biii^7', qual => '', qual_canon => '-', root => 'biii', root_canon => 'biii', root_mod => -1, root_ord => 11, system => 'roman' }
bIII0	{ ext => '', ext_canon => '', name => 'bIII0', qual => 0, qual_canon => 0, root => 'bIII', root_canon => 'bIII', root_mod => -1, root_ord => 11, system => 'roman' }
biii0	{ ext => '', ext_canon => '', name => 'biii0', qual => 0, qual_canon => '-', root => 'biii', root_canon => 'biii', root_mod => -1, root_ord => 11, system => 'roman' }
bIII07	{ ext => 7, ext_canon => 7, name => 'bIII07', qual => 0, qual_canon => 0, root => 'bIII', root_canon => 'bIII', root_mod => -1, root_ord => 11, system => 'roman' }
biii07	{ ext => 7, ext_canon => 7, name => 'biii07', qual => 0, qual_canon => '-', root => 'biii', root_canon => 'biii', root_mod => -1, root_ord => 11, system => 'roman' }
bIII0^	{ ext => '^', ext_canon => '^', name => 'bIII0^', qual => 0, qual_canon => 0, root => 'bIII', root_canon => 'bIII', root_mod => -1, root_ord => 11, system => 'roman' }
biii0^	{ ext => '^', ext_canon => '^', name => 'biii0^', qual => 0, qual_canon => '-', root => 'biii', root_canon => 'biii', root_mod => -1, root_ord => 11, system => 'roman' }
bIII0h	{ ext => 'h', ext_canon => 'h', name => 'bIII0h', qual => 0, qual_canon => 0, root => 'bIII', root_canon => 'bIII', root_mod => -1, root_ord => 11, system => 'roman' }
biii0h	{ ext => 'h', ext_canon => 'h', name => 'biii0h', qual => 0, qual_canon => '-', root => 'biii', root_canon => 'biii', root_mod => -1, root_ord => 11, system => 'roman' }
bIII0h7	{ ext => 'h7', ext_canon => 'h7', name => 'bIII0h7', qual => 0, qual_canon => 0, root => 'bIII', root_canon => 'bIII', root_mod => -1, root_ord => 11, system => 'roman' }
biii0h7	{ ext => 'h7', ext_canon => 'h7', name => 'biii0h7', qual => 0, qual_canon => '-', root => 'biii', root_canon => 'biii', root_mod => -1, root_ord => 11, system => 'roman' }
bIII0^7	{ ext => '^7', ext_canon => '^7', name => 'bIII0^7', qual => 0, qual_canon => 0, root => 'bIII', root_canon => 'bIII', root_mod => -1, root_ord => 11, system => 'roman' }
biii0^7	{ ext => '^7', ext_canon => '^7', name => 'biii0^7', qual => 0, qual_canon => '-', root => 'biii', root_canon => 'biii', root_mod => -1, root_ord => 11, system => 'roman' }
bIII+	{ ext => '', ext_canon => '', name => 'bIII+', qual => '+', qual_canon => '+', root => 'bIII', root_canon => 'bIII', root_mod => -1, root_ord => 11, system => 'roman' }
biii+	{ ext => '', ext_canon => '', name => 'biii+', qual => '+', qual_canon => '-', root => 'biii', root_canon => 'biii', root_mod => -1, root_ord => 11, system => 'roman' }
bIII+7	{ ext => 7, ext_canon => 7, name => 'bIII+7', qual => '+', qual_canon => '+', root => 'bIII', root_canon => 'bIII', root_mod => -1, root_ord => 11, system => 'roman' }
biii+7	{ ext => 7, ext_canon => 7, name => 'biii+7', qual => '+', qual_canon => '-', root => 'biii', root_canon => 'biii', root_mod => -1, root_ord => 11, system => 'roman' }
bIII+^	{ ext => '^', ext_canon => '^', name => 'bIII+^', qual => '+', qual_canon => '+', root => 'bIII', root_canon => 'bIII', root_mod => -1, root_ord => 11, system => 'roman' }
biii+^	{ ext => '^', ext_canon => '^', name => 'biii+^', qual => '+', qual_canon => '-', root => 'biii', root_canon => 'biii', root_mod => -1, root_ord => 11, system => 'roman' }
bIII+h	{ ext => 'h', ext_canon => 'h', name => 'bIII+h', qual => '+', qual_canon => '+', root => 'bIII', root_canon => 'bIII', root_mod => -1, root_ord => 11, system => 'roman' }
biii+h	{ ext => 'h', ext_canon => 'h', name => 'biii+h', qual => '+', qual_canon => '-', root => 'biii', root_canon => 'biii', root_mod => -1, root_ord => 11, system => 'roman' }
bIII+h7	{ ext => 'h7', ext_canon => 'h7', name => 'bIII+h7', qual => '+', qual_canon => '+', root => 'bIII', root_canon => 'bIII', root_mod => -1, root_ord => 11, system => 'roman' }
biii+h7	{ ext => 'h7', ext_canon => 'h7', name => 'biii+h7', qual => '+', qual_canon => '-', root => 'biii', root_canon => 'biii', root_mod => -1, root_ord => 11, system => 'roman' }
bIII+^7	{ ext => '^7', ext_canon => '^7', name => 'bIII+^7', qual => '+', qual_canon => '+', root => 'bIII', root_canon => 'bIII', root_mod => -1, root_ord => 11, system => 'roman' }
biii+^7	{ ext => '^7', ext_canon => '^7', name => 'biii+^7', qual => '+', qual_canon => '-', root => 'biii', root_canon => 'biii', root_mod => -1, root_ord => 11, system => 'roman' }
III	{ ext => '', ext_canon => '', name => 'III', qual => '', qual_canon => '', root => 'III', root_canon => 'III', root_mod => 0, root_ord => 4, system => 'roman' }
iii	{ ext => '', ext_canon => '', name => 'iii', qual => '', qual_canon => '-', root => 'iii', root_canon => 'iii', root_mod => 0, root_ord => 4, system => 'roman' }
III7	{ ext => 7, ext_canon => 7, name => 'III7', qual => '', qual_canon => '', root => 'III', root_canon => 'III', root_mod => 0, root_ord => 4, system => 'roman' }
iii7	{ ext => 7, ext_canon => 7, name => 'iii7', qual => '', qual_canon => '-', root => 'iii', root_canon => 'iii', root_mod => 0, root_ord => 4, system => 'roman' }
III^	{ ext => '^', ext_canon => '^', name => 'III^', qual => '', qual_canon => '', root => 'III', root_canon => 'III', root_mod => 0, root_ord => 4, system => 'roman' }
iii^	{ ext => '^', ext_canon => '^', name => 'iii^', qual => '', qual_canon => '-', root => 'iii', root_canon => 'iii', root_mod => 0, root_ord => 4, system => 'roman' }
IIIh	{ ext => '', ext_canon => '', name => 'IIIh', qual => 'h', qual_canon => 'h', root => 'III', root_canon => 'III', root_mod => 0, root_ord => 4, system => 'roman' }
iiih	{ ext => '', ext_canon => '', name => 'iiih', qual => 'h', qual_canon => '-', root => 'iii', root_canon => 'iii', root_mod => 0, root_ord => 4, system => 'roman' }
IIIh7	{ ext => 7, ext_canon => 7, name => 'IIIh7', qual => 'h', qual_canon => 'h', root => 'III', root_canon => 'III', root_mod => 0, root_ord => 4, system => 'roman' }
iiih7	{ ext => 7, ext_canon => 7, name => 'iiih7', qual => 'h', qual_canon => '-', root => 'iii', root_canon => 'iii', root_mod => 0, root_ord => 4, system => 'roman' }
III^7	{ ext => '^7', ext_canon => '^7', name => 'III^7', qual => '', qual_canon => '', root => 'III', root_canon => 'III', root_mod => 0, root_ord => 4, system => 'roman' }
iii^7	{ ext => '^7', ext_canon => '^7', name => 'iii^7', qual => '', qual_canon => '-', root => 'iii', root_canon => 'iii', root_mod => 0, root_ord => 4, system => 'roman' }
III0	{ ext => '', ext_canon => '', name => 'III0', qual => 0, qual_canon => 0, root => 'III', root_canon => 'III', root_mod => 0, root_ord => 4, system => 'roman' }
iii0	{ ext => '', ext_canon => '', name => 'iii0', qual => 0, qual_canon => '-', root => 'iii', root_canon => 'iii', root_mod => 0, root_ord => 4, system => 'roman' }
III07	{ ext => 7, ext_canon => 7, name => 'III07', qual => 0, qual_canon => 0, root => 'III', root_canon => 'III', root_mod => 0, root_ord => 4, system => 'roman' }
iii07	{ ext => 7, ext_canon => 7, name => 'iii07', qual => 0, qual_canon => '-', root => 'iii', root_canon => 'iii', root_mod => 0, root_ord => 4, system => 'roman' }
III0^	{ ext => '^', ext_canon => '^', name => 'III0^', qual => 0, qual_canon => 0, root => 'III', root_canon => 'III', root_mod => 0, root_ord => 4, system => 'roman' }
iii0^	{ ext => '^', ext_canon => '^', name => 'iii0^', qual => 0, qual_canon => '-', root => 'iii', root_canon => 'iii', root_mod => 0, root_ord => 4, system => 'roman' }
III0h	{ ext => 'h', ext_canon => 'h', name => 'III0h', qual => 0, qual_canon => 0, root => 'III', root_canon => 'III', root_mod => 0, root_ord => 4, system => 'roman' }
iii0h	{ ext => 'h', ext_canon => 'h', name => 'iii0h', qual => 0, qual_canon => '-', root => 'iii', root_canon => 'iii', root_mod => 0, root_ord => 4, system => 'roman' }
III0h7	{ ext => 'h7', ext_canon => 'h7', name => 'III0h7', qual => 0, qual_canon => 0, root => 'III', root_canon => 'III', root_mod => 0, root_ord => 4, system => 'roman' }
iii0h7	{ ext => 'h7', ext_canon => 'h7', name => 'iii0h7', qual => 0, qual_canon => '-', root => 'iii', root_canon => 'iii', root_mod => 0, root_ord => 4, system => 'roman' }
III0^7	{ ext => '^7', ext_canon => '^7', name => 'III0^7', qual => 0, qual_canon => 0, root => 'III', root_canon => 'III', root_mod => 0, root_ord => 4, system => 'roman' }
iii0^7	{ ext => '^7', ext_canon => '^7', name => 'iii0^7', qual => 0, qual_canon => '-', root => 'iii', root_canon => 'iii', root_mod => 0, root_ord => 4, system => 'roman' }
III+	{ ext => '', ext_canon => '', name => 'III+', qual => '+', qual_canon => '+', root => 'III', root_canon => 'III', root_mod => 0, root_ord => 4, system => 'roman' }
iii+	{ ext => '', ext_canon => '', name => 'iii+', qual => '+', qual_canon => '-', root => 'iii', root_canon => 'iii', root_mod => 0, root_ord => 4, system => 'roman' }
III+7	{ ext => 7, ext_canon => 7, name => 'III+7', qual => '+', qual_canon => '+', root => 'III', root_canon => 'III', root_mod => 0, root_ord => 4, system => 'roman' }
iii+7	{ ext => 7, ext_canon => 7, name => 'iii+7', qual => '+', qual_canon => '-', root => 'iii', root_canon => 'iii', root_mod => 0, root_ord => 4, system => 'roman' }
III+^	{ ext => '^', ext_canon => '^', name => 'III+^', qual => '+', qual_canon => '+', root => 'III', root_canon => 'III', root_mod => 0, root_ord => 4, system => 'roman' }
iii+^	{ ext => '^', ext_canon => '^', name => 'iii+^', qual => '+', qual_canon => '-', root => 'iii', root_canon => 'iii', root_mod => 0, root_ord => 4, system => 'roman' }
III+h	{ ext => 'h', ext_canon => 'h', name => 'III+h', qual => '+', qual_canon => '+', root => 'III', root_canon => 'III', root_mod => 0, root_ord => 4, system => 'roman' }
iii+h	{ ext => 'h', ext_canon => 'h', name => 'iii+h', qual => '+', qual_canon => '-', root => 'iii', root_canon => 'iii', root_mod => 0, root_ord => 4, system => 'roman' }
III+h7	{ ext => 'h7', ext_canon => 'h7', name => 'III+h7', qual => '+', qual_canon => '+', root => 'III', root_canon => 'III', root_mod => 0, root_ord => 4, system => 'roman' }
iii+h7	{ ext => 'h7', ext_canon => 'h7', name => 'iii+h7', qual => '+', qual_canon => '-', root => 'iii', root_canon => 'iii', root_mod => 0, root_ord => 4, system => 'roman' }
III+^7	{ ext => '^7', ext_canon => '^7', name => 'III+^7', qual => '+', qual_canon => '+', root => 'III', root_canon => 'III', root_mod => 0, root_ord => 4, system => 'roman' }
iii+^7	{ ext => '^7', ext_canon => '^7', name => 'iii+^7', qual => '+', qual_canon => '-', root => 'iii', root_canon => 'iii', root_mod => 0, root_ord => 4, system => 'roman' }
IV	{ ext => '', ext_canon => '', name => 'IV', qual => '', qual_canon => '', root => 'IV', root_canon => 'IV', root_mod => 0, root_ord => 5, system => 'roman' }
iv	{ ext => '', ext_canon => '', name => 'iv', qual => '', qual_canon => '-', root => 'iv', root_canon => 'iv', root_mod => 0, root_ord => 5, system => 'roman' }
IV7	{ ext => 7, ext_canon => 7, name => 'IV7', qual => '', qual_canon => '', root => 'IV', root_canon => 'IV', root_mod => 0, root_ord => 5, system => 'roman' }
iv7	{ ext => 7, ext_canon => 7, name => 'iv7', qual => '', qual_canon => '-', root => 'iv', root_canon => 'iv', root_mod => 0, root_ord => 5, system => 'roman' }
IV^	{ ext => '^', ext_canon => '^', name => 'IV^', qual => '', qual_canon => '', root => 'IV', root_canon => 'IV', root_mod => 0, root_ord => 5, system => 'roman' }
iv^	{ ext => '^', ext_canon => '^', name => 'iv^', qual => '', qual_canon => '-', root => 'iv', root_canon => 'iv', root_mod => 0, root_ord => 5, system => 'roman' }
IVh	{ ext => '', ext_canon => '', name => 'IVh', qual => 'h', qual_canon => 'h', root => 'IV', root_canon => 'IV', root_mod => 0, root_ord => 5, system => 'roman' }
ivh	{ ext => '', ext_canon => '', name => 'ivh', qual => 'h', qual_canon => '-', root => 'iv', root_canon => 'iv', root_mod => 0, root_ord => 5, system => 'roman' }
IVh7	{ ext => 7, ext_canon => 7, name => 'IVh7', qual => 'h', qual_canon => 'h', root => 'IV', root_canon => 'IV', root_mod => 0, root_ord => 5, system => 'roman' }
ivh7	{ ext => 7, ext_canon => 7, name => 'ivh7', qual => 'h', qual_canon => '-', root => 'iv', root_canon => 'iv', root_mod => 0, root_ord => 5, system => 'roman' }
IV^7	{ ext => '^7', ext_canon => '^7', name => 'IV^7', qual => '', qual_canon => '', root => 'IV', root_canon => 'IV', root_mod => 0, root_ord => 5, system => 'roman' }
iv^7	{ ext => '^7', ext_canon => '^7', name => 'iv^7', qual => '', qual_canon => '-', root => 'iv', root_canon => 'iv', root_mod => 0, root_ord => 5, system => 'roman' }
IV0	{ ext => '', ext_canon => '', name => 'IV0', qual => 0, qual_canon => 0, root => 'IV', root_canon => 'IV', root_mod => 0, root_ord => 5, system => 'roman' }
iv0	{ ext => '', ext_canon => '', name => 'iv0', qual => 0, qual_canon => '-', root => 'iv', root_canon => 'iv', root_mod => 0, root_ord => 5, system => 'roman' }
IV07	{ ext => 7, ext_canon => 7, name => 'IV07', qual => 0, qual_canon => 0, root => 'IV', root_canon => 'IV', root_mod => 0, root_ord => 5, system => 'roman' }
iv07	{ ext => 7, ext_canon => 7, name => 'iv07', qual => 0, qual_canon => '-', root => 'iv', root_canon => 'iv', root_mod => 0, root_ord => 5, system => 'roman' }
IV0^	{ ext => '^', ext_canon => '^', name => 'IV0^', qual => 0, qual_canon => 0, root => 'IV', root_canon => 'IV', root_mod => 0, root_ord => 5, system => 'roman' }
iv0^	{ ext => '^', ext_canon => '^', name => 'iv0^', qual => 0, qual_canon => '-', root => 'iv', root_canon => 'iv', root_mod => 0, root_ord => 5, system => 'roman' }
IV0h	{ ext => 'h', ext_canon => 'h', name => 'IV0h', qual => 0, qual_canon => 0, root => 'IV', root_canon => 'IV', root_mod => 0, root_ord => 5, system => 'roman' }
iv0h	{ ext => 'h', ext_canon => 'h', name => 'iv0h', qual => 0, qual_canon => '-', root => 'iv', root_canon => 'iv', root_mod => 0, root_ord => 5, system => 'roman' }
IV0h7	{ ext => 'h7', ext_canon => 'h7', name => 'IV0h7', qual => 0, qual_canon => 0, root => 'IV', root_canon => 'IV', root_mod => 0, root_ord => 5, system => 'roman' }
iv0h7	{ ext => 'h7', ext_canon => 'h7', name => 'iv0h7', qual => 0, qual_canon => '-', root => 'iv', root_canon => 'iv', root_mod => 0, root_ord => 5, system => 'roman' }
IV0^7	{ ext => '^7', ext_canon => '^7', name => 'IV0^7', qual => 0, qual_canon => 0, root => 'IV', root_canon => 'IV', root_mod => 0, root_ord => 5, system => 'roman' }
iv0^7	{ ext => '^7', ext_canon => '^7', name => 'iv0^7', qual => 0, qual_canon => '-', root => 'iv', root_canon => 'iv', root_mod => 0, root_ord => 5, system => 'roman' }
IV+	{ ext => '', ext_canon => '', name => 'IV+', qual => '+', qual_canon => '+', root => 'IV', root_canon => 'IV', root_mod => 0, root_ord => 5, system => 'roman' }
iv+	{ ext => '', ext_canon => '', name => 'iv+', qual => '+', qual_canon => '-', root => 'iv', root_canon => 'iv', root_mod => 0, root_ord => 5, system => 'roman' }
IV+7	{ ext => 7, ext_canon => 7, name => 'IV+7', qual => '+', qual_canon => '+', root => 'IV', root_canon => 'IV', root_mod => 0, root_ord => 5, system => 'roman' }
iv+7	{ ext => 7, ext_canon => 7, name => 'iv+7', qual => '+', qual_canon => '-', root => 'iv', root_canon => 'iv', root_mod => 0, root_ord => 5, system => 'roman' }
IV+^	{ ext => '^', ext_canon => '^', name => 'IV+^', qual => '+', qual_canon => '+', root => 'IV', root_canon => 'IV', root_mod => 0, root_ord => 5, system => 'roman' }
iv+^	{ ext => '^', ext_canon => '^', name => 'iv+^', qual => '+', qual_canon => '-', root => 'iv', root_canon => 'iv', root_mod => 0, root_ord => 5, system => 'roman' }
IV+h	{ ext => 'h', ext_canon => 'h', name => 'IV+h', qual => '+', qual_canon => '+', root => 'IV', root_canon => 'IV', root_mod => 0, root_ord => 5, system => 'roman' }
iv+h	{ ext => 'h', ext_canon => 'h', name => 'iv+h', qual => '+', qual_canon => '-', root => 'iv', root_canon => 'iv', root_mod => 0, root_ord => 5, system => 'roman' }
IV+h7	{ ext => 'h7', ext_canon => 'h7', name => 'IV+h7', qual => '+', qual_canon => '+', root => 'IV', root_canon => 'IV', root_mod => 0, root_ord => 5, system => 'roman' }
iv+h7	{ ext => 'h7', ext_canon => 'h7', name => 'iv+h7', qual => '+', qual_canon => '-', root => 'iv', root_canon => 'iv', root_mod => 0, root_ord => 5, system => 'roman' }
IV+^7	{ ext => '^7', ext_canon => '^7', name => 'IV+^7', qual => '+', qual_canon => '+', root => 'IV', root_canon => 'IV', root_mod => 0, root_ord => 5, system => 'roman' }
iv+^7	{ ext => '^7', ext_canon => '^7', name => 'iv+^7', qual => '+', qual_canon => '-', root => 'iv', root_canon => 'iv', root_mod => 0, root_ord => 5, system => 'roman' }
#IV	{ ext => '', ext_canon => '', name => '#IV', qual => '', qual_canon => '', root => '#IV', root_canon => '#IV', root_mod => 1, root_ord => 1, system => 'roman' }
#iv	{ ext => '', ext_canon => '', name => '#iv', qual => '', qual_canon => '-', root => '#iv', root_canon => '#iv', root_mod => 1, root_ord => 1, system => 'roman' }
#IV7	{ ext => 7, ext_canon => 7, name => '#IV7', qual => '', qual_canon => '', root => '#IV', root_canon => '#IV', root_mod => 1, root_ord => 1, system => 'roman' }
#iv7	{ ext => 7, ext_canon => 7, name => '#iv7', qual => '', qual_canon => '-', root => '#iv', root_canon => '#iv', root_mod => 1, root_ord => 1, system => 'roman' }
#IV^	{ ext => '^', ext_canon => '^', name => '#IV^', qual => '', qual_canon => '', root => '#IV', root_canon => '#IV', root_mod => 1, root_ord => 1, system => 'roman' }
#iv^	{ ext => '^', ext_canon => '^', name => '#iv^', qual => '', qual_canon => '-', root => '#iv', root_canon => '#iv', root_mod => 1, root_ord => 1, system => 'roman' }
#IVh	{ ext => '', ext_canon => '', name => '#IVh', qual => 'h', qual_canon => 'h', root => '#IV', root_canon => '#IV', root_mod => 1, root_ord => 1, system => 'roman' }
#ivh	{ ext => '', ext_canon => '', name => '#ivh', qual => 'h', qual_canon => '-', root => '#iv', root_canon => '#iv', root_mod => 1, root_ord => 1, system => 'roman' }
#IVh7	{ ext => 7, ext_canon => 7, name => '#IVh7', qual => 'h', qual_canon => 'h', root => '#IV', root_canon => '#IV', root_mod => 1, root_ord => 1, system => 'roman' }
#ivh7	{ ext => 7, ext_canon => 7, name => '#ivh7', qual => 'h', qual_canon => '-', root => '#iv', root_canon => '#iv', root_mod => 1, root_ord => 1, system => 'roman' }
#IV^7	{ ext => '^7', ext_canon => '^7', name => '#IV^7', qual => '', qual_canon => '', root => '#IV', root_canon => '#IV', root_mod => 1, root_ord => 1, system => 'roman' }
#iv^7	{ ext => '^7', ext_canon => '^7', name => '#iv^7', qual => '', qual_canon => '-', root => '#iv', root_canon => '#iv', root_mod => 1, root_ord => 1, system => 'roman' }
#IV0	{ ext => '', ext_canon => '', name => '#IV0', qual => 0, qual_canon => 0, root => '#IV', root_canon => '#IV', root_mod => 1, root_ord => 1, system => 'roman' }
#iv0	{ ext => '', ext_canon => '', name => '#iv0', qual => 0, qual_canon => '-', root => '#iv', root_canon => '#iv', root_mod => 1, root_ord => 1, system => 'roman' }
#IV07	{ ext => 7, ext_canon => 7, name => '#IV07', qual => 0, qual_canon => 0, root => '#IV', root_canon => '#IV', root_mod => 1, root_ord => 1, system => 'roman' }
#iv07	{ ext => 7, ext_canon => 7, name => '#iv07', qual => 0, qual_canon => '-', root => '#iv', root_canon => '#iv', root_mod => 1, root_ord => 1, system => 'roman' }
#IV0^	{ ext => '^', ext_canon => '^', name => '#IV0^', qual => 0, qual_canon => 0, root => '#IV', root_canon => '#IV', root_mod => 1, root_ord => 1, system => 'roman' }
#iv0^	{ ext => '^', ext_canon => '^', name => '#iv0^', qual => 0, qual_canon => '-', root => '#iv', root_canon => '#iv', root_mod => 1, root_ord => 1, system => 'roman' }
#IV0h	{ ext => 'h', ext_canon => 'h', name => '#IV0h', qual => 0, qual_canon => 0, root => '#IV', root_canon => '#IV', root_mod => 1, root_ord => 1, system => 'roman' }
#iv0h	{ ext => 'h', ext_canon => 'h', name => '#iv0h', qual => 0, qual_canon => '-', root => '#iv', root_canon => '#iv', root_mod => 1, root_ord => 1, system => 'roman' }
#IV0h7	{ ext => 'h7', ext_canon => 'h7', name => '#IV0h7', qual => 0, qual_canon => 0, root => '#IV', root_canon => '#IV', root_mod => 1, root_ord => 1, system => 'roman' }
#iv0h7	{ ext => 'h7', ext_canon => 'h7', name => '#iv0h7', qual => 0, qual_canon => '-', root => '#iv', root_canon => '#iv', root_mod => 1, root_ord => 1, system => 'roman' }
#IV0^7	{ ext => '^7', ext_canon => '^7', name => '#IV0^7', qual => 0, qual_canon => 0, root => '#IV', root_canon => '#IV', root_mod => 1, root_ord => 1, system => 'roman' }
#iv0^7	{ ext => '^7', ext_canon => '^7', name => '#iv0^7', qual => 0, qual_canon => '-', root => '#iv', root_canon => '#iv', root_mod => 1, root_ord => 1, system => 'roman' }
#IV+	{ ext => '', ext_canon => '', name => '#IV+', qual => '+', qual_canon => '+', root => '#IV', root_canon => '#IV', root_mod => 1, root_ord => 1, system => 'roman' }
#iv+	{ ext => '', ext_canon => '', name => '#iv+', qual => '+', qual_canon => '-', root => '#iv', root_canon => '#iv', root_mod => 1, root_ord => 1, system => 'roman' }
#IV+7	{ ext => 7, ext_canon => 7, name => '#IV+7', qual => '+', qual_canon => '+', root => '#IV', root_canon => '#IV', root_mod => 1, root_ord => 1, system => 'roman' }
#iv+7	{ ext => 7, ext_canon => 7, name => '#iv+7', qual => '+', qual_canon => '-', root => '#iv', root_canon => '#iv', root_mod => 1, root_ord => 1, system => 'roman' }
#IV+^	{ ext => '^', ext_canon => '^', name => '#IV+^', qual => '+', qual_canon => '+', root => '#IV', root_canon => '#IV', root_mod => 1, root_ord => 1, system => 'roman' }
#iv+^	{ ext => '^', ext_canon => '^', name => '#iv+^', qual => '+', qual_canon => '-', root => '#iv', root_canon => '#iv', root_mod => 1, root_ord => 1, system => 'roman' }
#IV+h	{ ext => 'h', ext_canon => 'h', name => '#IV+h', qual => '+', qual_canon => '+', root => '#IV', root_canon => '#IV', root_mod => 1, root_ord => 1, system => 'roman' }
#iv+h	{ ext => 'h', ext_canon => 'h', name => '#iv+h', qual => '+', qual_canon => '-', root => '#iv', root_canon => '#iv', root_mod => 1, root_ord => 1, system => 'roman' }
#IV+h7	{ ext => 'h7', ext_canon => 'h7', name => '#IV+h7', qual => '+', qual_canon => '+', root => '#IV', root_canon => '#IV', root_mod => 1, root_ord => 1, system => 'roman' }
#iv+h7	{ ext => 'h7', ext_canon => 'h7', name => '#iv+h7', qual => '+', qual_canon => '-', root => '#iv', root_canon => '#iv', root_mod => 1, root_ord => 1, system => 'roman' }
#IV+^7	{ ext => '^7', ext_canon => '^7', name => '#IV+^7', qual => '+', qual_canon => '+', root => '#IV', root_canon => '#IV', root_mod => 1, root_ord => 1, system => 'roman' }
#iv+^7	{ ext => '^7', ext_canon => '^7', name => '#iv+^7', qual => '+', qual_canon => '-', root => '#iv', root_canon => '#iv', root_mod => 1, root_ord => 1, system => 'roman' }
bV	{ ext => '', ext_canon => '', name => 'bV', qual => '', qual_canon => '', root => 'bV', root_canon => 'bV', root_mod => -1, root_ord => 11, system => 'roman' }
bv	{ ext => '', ext_canon => '', name => 'bv', qual => '', qual_canon => '-', root => 'bv', root_canon => 'bv', root_mod => -1, root_ord => 11, system => 'roman' }
bV7	{ ext => 7, ext_canon => 7, name => 'bV7', qual => '', qual_canon => '', root => 'bV', root_canon => 'bV', root_mod => -1, root_ord => 11, system => 'roman' }
bv7	{ ext => 7, ext_canon => 7, name => 'bv7', qual => '', qual_canon => '-', root => 'bv', root_canon => 'bv', root_mod => -1, root_ord => 11, system => 'roman' }
bV^	{ ext => '^', ext_canon => '^', name => 'bV^', qual => '', qual_canon => '', root => 'bV', root_canon => 'bV', root_mod => -1, root_ord => 11, system => 'roman' }
bv^	{ ext => '^', ext_canon => '^', name => 'bv^', qual => '', qual_canon => '-', root => 'bv', root_canon => 'bv', root_mod => -1, root_ord => 11, system => 'roman' }
bVh	{ ext => '', ext_canon => '', name => 'bVh', qual => 'h', qual_canon => 'h', root => 'bV', root_canon => 'bV', root_mod => -1, root_ord => 11, system => 'roman' }
bvh	{ ext => '', ext_canon => '', name => 'bvh', qual => 'h', qual_canon => '-', root => 'bv', root_canon => 'bv', root_mod => -1, root_ord => 11, system => 'roman' }
bVh7	{ ext => 7, ext_canon => 7, name => 'bVh7', qual => 'h', qual_canon => 'h', root => 'bV', root_canon => 'bV', root_mod => -1, root_ord => 11, system => 'roman' }
bvh7	{ ext => 7, ext_canon => 7, name => 'bvh7', qual => 'h', qual_canon => '-', root => 'bv', root_canon => 'bv', root_mod => -1, root_ord => 11, system => 'roman' }
bV^7	{ ext => '^7', ext_canon => '^7', name => 'bV^7', qual => '', qual_canon => '', root => 'bV', root_canon => 'bV', root_mod => -1, root_ord => 11, system => 'roman' }
bv^7	{ ext => '^7', ext_canon => '^7', name => 'bv^7', qual => '', qual_canon => '-', root => 'bv', root_canon => 'bv', root_mod => -1, root_ord => 11, system => 'roman' }
bV0	{ ext => '', ext_canon => '', name => 'bV0', qual => 0, qual_canon => 0, root => 'bV', root_canon => 'bV', root_mod => -1, root_ord => 11, system => 'roman' }
bv0	{ ext => '', ext_canon => '', name => 'bv0', qual => 0, qual_canon => '-', root => 'bv', root_canon => 'bv', root_mod => -1, root_ord => 11, system => 'roman' }
bV07	{ ext => 7, ext_canon => 7, name => 'bV07', qual => 0, qual_canon => 0, root => 'bV', root_canon => 'bV', root_mod => -1, root_ord => 11, system => 'roman' }
bv07	{ ext => 7, ext_canon => 7, name => 'bv07', qual => 0, qual_canon => '-', root => 'bv', root_canon => 'bv', root_mod => -1, root_ord => 11, system => 'roman' }
bV0^	{ ext => '^', ext_canon => '^', name => 'bV0^', qual => 0, qual_canon => 0, root => 'bV', root_canon => 'bV', root_mod => -1, root_ord => 11, system => 'roman' }
bv0^	{ ext => '^', ext_canon => '^', name => 'bv0^', qual => 0, qual_canon => '-', root => 'bv', root_canon => 'bv', root_mod => -1, root_ord => 11, system => 'roman' }
bV0h	{ ext => 'h', ext_canon => 'h', name => 'bV0h', qual => 0, qual_canon => 0, root => 'bV', root_canon => 'bV', root_mod => -1, root_ord => 11, system => 'roman' }
bv0h	{ ext => 'h', ext_canon => 'h', name => 'bv0h', qual => 0, qual_canon => '-', root => 'bv', root_canon => 'bv', root_mod => -1, root_ord => 11, system => 'roman' }
bV0h7	{ ext => 'h7', ext_canon => 'h7', name => 'bV0h7', qual => 0, qual_canon => 0, root => 'bV', root_canon => 'bV', root_mod => -1, root_ord => 11, system => 'roman' }
bv0h7	{ ext => 'h7', ext_canon => 'h7', name => 'bv0h7', qual => 0, qual_canon => '-', root => 'bv', root_canon => 'bv', root_mod => -1, root_ord => 11, system => 'roman' }
bV0^7	{ ext => '^7', ext_canon => '^7', name => 'bV0^7', qual => 0, qual_canon => 0, root => 'bV', root_canon => 'bV', root_mod => -1, root_ord => 11, system => 'roman' }
bv0^7	{ ext => '^7', ext_canon => '^7', name => 'bv0^7', qual => 0, qual_canon => '-', root => 'bv', root_canon => 'bv', root_mod => -1, root_ord => 11, system => 'roman' }
bV+	{ ext => '', ext_canon => '', name => 'bV+', qual => '+', qual_canon => '+', root => 'bV', root_canon => 'bV', root_mod => -1, root_ord => 11, system => 'roman' }
bv+	{ ext => '', ext_canon => '', name => 'bv+', qual => '+', qual_canon => '-', root => 'bv', root_canon => 'bv', root_mod => -1, root_ord => 11, system => 'roman' }
bV+7	{ ext => 7, ext_canon => 7, name => 'bV+7', qual => '+', qual_canon => '+', root => 'bV', root_canon => 'bV', root_mod => -1, root_ord => 11, system => 'roman' }
bv+7	{ ext => 7, ext_canon => 7, name => 'bv+7', qual => '+', qual_canon => '-', root => 'bv', root_canon => 'bv', root_mod => -1, root_ord => 11, system => 'roman' }
bV+^	{ ext => '^', ext_canon => '^', name => 'bV+^', qual => '+', qual_canon => '+', root => 'bV', root_canon => 'bV', root_mod => -1, root_ord => 11, system => 'roman' }
bv+^	{ ext => '^', ext_canon => '^', name => 'bv+^', qual => '+', qual_canon => '-', root => 'bv', root_canon => 'bv', root_mod => -1, root_ord => 11, system => 'roman' }
bV+h	{ ext => 'h', ext_canon => 'h', name => 'bV+h', qual => '+', qual_canon => '+', root => 'bV', root_canon => 'bV', root_mod => -1, root_ord => 11, system => 'roman' }
bv+h	{ ext => 'h', ext_canon => 'h', name => 'bv+h', qual => '+', qual_canon => '-', root => 'bv', root_canon => 'bv', root_mod => -1, root_ord => 11, system => 'roman' }
bV+h7	{ ext => 'h7', ext_canon => 'h7', name => 'bV+h7', qual => '+', qual_canon => '+', root => 'bV', root_canon => 'bV', root_mod => -1, root_ord => 11, system => 'roman' }
bv+h7	{ ext => 'h7', ext_canon => 'h7', name => 'bv+h7', qual => '+', qual_canon => '-', root => 'bv', root_canon => 'bv', root_mod => -1, root_ord => 11, system => 'roman' }
bV+^7	{ ext => '^7', ext_canon => '^7', name => 'bV+^7', qual => '+', qual_canon => '+', root => 'bV', root_canon => 'bV', root_mod => -1, root_ord => 11, system => 'roman' }
bv+^7	{ ext => '^7', ext_canon => '^7', name => 'bv+^7', qual => '+', qual_canon => '-', root => 'bv', root_canon => 'bv', root_mod => -1, root_ord => 11, system => 'roman' }
V	{ ext => '', ext_canon => '', name => 'V', qual => '', qual_canon => '', root => 'V', root_canon => 'V', root_mod => 0, root_ord => 7, system => 'roman' }
v	{ ext => '', ext_canon => '', name => 'v', qual => '', qual_canon => '-', root => 'v', root_canon => 'v', root_mod => 0, root_ord => 7, system => 'roman' }
V7	{ ext => 7, ext_canon => 7, name => 'V7', qual => '', qual_canon => '', root => 'V', root_canon => 'V', root_mod => 0, root_ord => 7, system => 'roman' }
v7	{ ext => 7, ext_canon => 7, name => 'v7', qual => '', qual_canon => '-', root => 'v', root_canon => 'v', root_mod => 0, root_ord => 7, system => 'roman' }
V^	{ ext => '^', ext_canon => '^', name => 'V^', qual => '', qual_canon => '', root => 'V', root_canon => 'V', root_mod => 0, root_ord => 7, system => 'roman' }
v^	{ ext => '^', ext_canon => '^', name => 'v^', qual => '', qual_canon => '-', root => 'v', root_canon => 'v', root_mod => 0, root_ord => 7, system => 'roman' }
Vh	{ ext => '', ext_canon => '', name => 'Vh', qual => 'h', qual_canon => 'h', root => 'V', root_canon => 'V', root_mod => 0, root_ord => 7, system => 'roman' }
vh	{ ext => '', ext_canon => '', name => 'vh', qual => 'h', qual_canon => '-', root => 'v', root_canon => 'v', root_mod => 0, root_ord => 7, system => 'roman' }
Vh7	{ ext => 7, ext_canon => 7, name => 'Vh7', qual => 'h', qual_canon => 'h', root => 'V', root_canon => 'V', root_mod => 0, root_ord => 7, system => 'roman' }
vh7	{ ext => 7, ext_canon => 7, name => 'vh7', qual => 'h', qual_canon => '-', root => 'v', root_canon => 'v', root_mod => 0, root_ord => 7, system => 'roman' }
V^7	{ ext => '^7', ext_canon => '^7', name => 'V^7', qual => '', qual_canon => '', root => 'V', root_canon => 'V', root_mod => 0, root_ord => 7, system => 'roman' }
v^7	{ ext => '^7', ext_canon => '^7', name => 'v^7', qual => '', qual_canon => '-', root => 'v', root_canon => 'v', root_mod => 0, root_ord => 7, system => 'roman' }
V0	{ ext => '', ext_canon => '', name => 'V0', qual => 0, qual_canon => 0, root => 'V', root_canon => 'V', root_mod => 0, root_ord => 7, system => 'roman' }
v0	{ ext => '', ext_canon => '', name => 'v0', qual => 0, qual_canon => '-', root => 'v', root_canon => 'v', root_mod => 0, root_ord => 7, system => 'roman' }
V07	{ ext => 7, ext_canon => 7, name => 'V07', qual => 0, qual_canon => 0, root => 'V', root_canon => 'V', root_mod => 0, root_ord => 7, system => 'roman' }
v07	{ ext => 7, ext_canon => 7, name => 'v07', qual => 0, qual_canon => '-', root => 'v', root_canon => 'v', root_mod => 0, root_ord => 7, system => 'roman' }
V0^	{ ext => '^', ext_canon => '^', name => 'V0^', qual => 0, qual_canon => 0, root => 'V', root_canon => 'V', root_mod => 0, root_ord => 7, system => 'roman' }
v0^	{ ext => '^', ext_canon => '^', name => 'v0^', qual => 0, qual_canon => '-', root => 'v', root_canon => 'v', root_mod => 0, root_ord => 7, system => 'roman' }
V0h	{ ext => 'h', ext_canon => 'h', name => 'V0h', qual => 0, qual_canon => 0, root => 'V', root_canon => 'V', root_mod => 0, root_ord => 7, system => 'roman' }
v0h	{ ext => 'h', ext_canon => 'h', name => 'v0h', qual => 0, qual_canon => '-', root => 'v', root_canon => 'v', root_mod => 0, root_ord => 7, system => 'roman' }
V0h7	{ ext => 'h7', ext_canon => 'h7', name => 'V0h7', qual => 0, qual_canon => 0, root => 'V', root_canon => 'V', root_mod => 0, root_ord => 7, system => 'roman' }
v0h7	{ ext => 'h7', ext_canon => 'h7', name => 'v0h7', qual => 0, qual_canon => '-', root => 'v', root_canon => 'v', root_mod => 0, root_ord => 7, system => 'roman' }
V0^7	{ ext => '^7', ext_canon => '^7', name => 'V0^7', qual => 0, qual_canon => 0, root => 'V', root_canon => 'V', root_mod => 0, root_ord => 7, system => 'roman' }
v0^7	{ ext => '^7', ext_canon => '^7', name => 'v0^7', qual => 0, qual_canon => '-', root => 'v', root_canon => 'v', root_mod => 0, root_ord => 7, system => 'roman' }
V+	{ ext => '', ext_canon => '', name => 'V+', qual => '+', qual_canon => '+', root => 'V', root_canon => 'V', root_mod => 0, root_ord => 7, system => 'roman' }
v+	{ ext => '', ext_canon => '', name => 'v+', qual => '+', qual_canon => '-', root => 'v', root_canon => 'v', root_mod => 0, root_ord => 7, system => 'roman' }
V+7	{ ext => 7, ext_canon => 7, name => 'V+7', qual => '+', qual_canon => '+', root => 'V', root_canon => 'V', root_mod => 0, root_ord => 7, system => 'roman' }
v+7	{ ext => 7, ext_canon => 7, name => 'v+7', qual => '+', qual_canon => '-', root => 'v', root_canon => 'v', root_mod => 0, root_ord => 7, system => 'roman' }
V+^	{ ext => '^', ext_canon => '^', name => 'V+^', qual => '+', qual_canon => '+', root => 'V', root_canon => 'V', root_mod => 0, root_ord => 7, system => 'roman' }
v+^	{ ext => '^', ext_canon => '^', name => 'v+^', qual => '+', qual_canon => '-', root => 'v', root_canon => 'v', root_mod => 0, root_ord => 7, system => 'roman' }
V+h	{ ext => 'h', ext_canon => 'h', name => 'V+h', qual => '+', qual_canon => '+', root => 'V', root_canon => 'V', root_mod => 0, root_ord => 7, system => 'roman' }
v+h	{ ext => 'h', ext_canon => 'h', name => 'v+h', qual => '+', qual_canon => '-', root => 'v', root_canon => 'v', root_mod => 0, root_ord => 7, system => 'roman' }
V+h7	{ ext => 'h7', ext_canon => 'h7', name => 'V+h7', qual => '+', qual_canon => '+', root => 'V', root_canon => 'V', root_mod => 0, root_ord => 7, system => 'roman' }
v+h7	{ ext => 'h7', ext_canon => 'h7', name => 'v+h7', qual => '+', qual_canon => '-', root => 'v', root_canon => 'v', root_mod => 0, root_ord => 7, system => 'roman' }
V+^7	{ ext => '^7', ext_canon => '^7', name => 'V+^7', qual => '+', qual_canon => '+', root => 'V', root_canon => 'V', root_mod => 0, root_ord => 7, system => 'roman' }
v+^7	{ ext => '^7', ext_canon => '^7', name => 'v+^7', qual => '+', qual_canon => '-', root => 'v', root_canon => 'v', root_mod => 0, root_ord => 7, system => 'roman' }
#V	{ ext => '', ext_canon => '', name => '#V', qual => '', qual_canon => '', root => '#V', root_canon => '#V', root_mod => 1, root_ord => 1, system => 'roman' }
#v	{ ext => '', ext_canon => '', name => '#v', qual => '', qual_canon => '-', root => '#v', root_canon => '#v', root_mod => 1, root_ord => 1, system => 'roman' }
#V7	{ ext => 7, ext_canon => 7, name => '#V7', qual => '', qual_canon => '', root => '#V', root_canon => '#V', root_mod => 1, root_ord => 1, system => 'roman' }
#v7	{ ext => 7, ext_canon => 7, name => '#v7', qual => '', qual_canon => '-', root => '#v', root_canon => '#v', root_mod => 1, root_ord => 1, system => 'roman' }
#V^	{ ext => '^', ext_canon => '^', name => '#V^', qual => '', qual_canon => '', root => '#V', root_canon => '#V', root_mod => 1, root_ord => 1, system => 'roman' }
#v^	{ ext => '^', ext_canon => '^', name => '#v^', qual => '', qual_canon => '-', root => '#v', root_canon => '#v', root_mod => 1, root_ord => 1, system => 'roman' }
#Vh	{ ext => '', ext_canon => '', name => '#Vh', qual => 'h', qual_canon => 'h', root => '#V', root_canon => '#V', root_mod => 1, root_ord => 1, system => 'roman' }
#vh	{ ext => '', ext_canon => '', name => '#vh', qual => 'h', qual_canon => '-', root => '#v', root_canon => '#v', root_mod => 1, root_ord => 1, system => 'roman' }
#Vh7	{ ext => 7, ext_canon => 7, name => '#Vh7', qual => 'h', qual_canon => 'h', root => '#V', root_canon => '#V', root_mod => 1, root_ord => 1, system => 'roman' }
#vh7	{ ext => 7, ext_canon => 7, name => '#vh7', qual => 'h', qual_canon => '-', root => '#v', root_canon => '#v', root_mod => 1, root_ord => 1, system => 'roman' }
#V^7	{ ext => '^7', ext_canon => '^7', name => '#V^7', qual => '', qual_canon => '', root => '#V', root_canon => '#V', root_mod => 1, root_ord => 1, system => 'roman' }
#v^7	{ ext => '^7', ext_canon => '^7', name => '#v^7', qual => '', qual_canon => '-', root => '#v', root_canon => '#v', root_mod => 1, root_ord => 1, system => 'roman' }
#V0	{ ext => '', ext_canon => '', name => '#V0', qual => 0, qual_canon => 0, root => '#V', root_canon => '#V', root_mod => 1, root_ord => 1, system => 'roman' }
#v0	{ ext => '', ext_canon => '', name => '#v0', qual => 0, qual_canon => '-', root => '#v', root_canon => '#v', root_mod => 1, root_ord => 1, system => 'roman' }
#V07	{ ext => 7, ext_canon => 7, name => '#V07', qual => 0, qual_canon => 0, root => '#V', root_canon => '#V', root_mod => 1, root_ord => 1, system => 'roman' }
#v07	{ ext => 7, ext_canon => 7, name => '#v07', qual => 0, qual_canon => '-', root => '#v', root_canon => '#v', root_mod => 1, root_ord => 1, system => 'roman' }
#V0^	{ ext => '^', ext_canon => '^', name => '#V0^', qual => 0, qual_canon => 0, root => '#V', root_canon => '#V', root_mod => 1, root_ord => 1, system => 'roman' }
#v0^	{ ext => '^', ext_canon => '^', name => '#v0^', qual => 0, qual_canon => '-', root => '#v', root_canon => '#v', root_mod => 1, root_ord => 1, system => 'roman' }
#V0h	{ ext => 'h', ext_canon => 'h', name => '#V0h', qual => 0, qual_canon => 0, root => '#V', root_canon => '#V', root_mod => 1, root_ord => 1, system => 'roman' }
#v0h	{ ext => 'h', ext_canon => 'h', name => '#v0h', qual => 0, qual_canon => '-', root => '#v', root_canon => '#v', root_mod => 1, root_ord => 1, system => 'roman' }
#V0h7	{ ext => 'h7', ext_canon => 'h7', name => '#V0h7', qual => 0, qual_canon => 0, root => '#V', root_canon => '#V', root_mod => 1, root_ord => 1, system => 'roman' }
#v0h7	{ ext => 'h7', ext_canon => 'h7', name => '#v0h7', qual => 0, qual_canon => '-', root => '#v', root_canon => '#v', root_mod => 1, root_ord => 1, system => 'roman' }
#V0^7	{ ext => '^7', ext_canon => '^7', name => '#V0^7', qual => 0, qual_canon => 0, root => '#V', root_canon => '#V', root_mod => 1, root_ord => 1, system => 'roman' }
#v0^7	{ ext => '^7', ext_canon => '^7', name => '#v0^7', qual => 0, qual_canon => '-', root => '#v', root_canon => '#v', root_mod => 1, root_ord => 1, system => 'roman' }
#V+	{ ext => '', ext_canon => '', name => '#V+', qual => '+', qual_canon => '+', root => '#V', root_canon => '#V', root_mod => 1, root_ord => 1, system => 'roman' }
#v+	{ ext => '', ext_canon => '', name => '#v+', qual => '+', qual_canon => '-', root => '#v', root_canon => '#v', root_mod => 1, root_ord => 1, system => 'roman' }
#V+7	{ ext => 7, ext_canon => 7, name => '#V+7', qual => '+', qual_canon => '+', root => '#V', root_canon => '#V', root_mod => 1, root_ord => 1, system => 'roman' }
#v+7	{ ext => 7, ext_canon => 7, name => '#v+7', qual => '+', qual_canon => '-', root => '#v', root_canon => '#v', root_mod => 1, root_ord => 1, system => 'roman' }
#V+^	{ ext => '^', ext_canon => '^', name => '#V+^', qual => '+', qual_canon => '+', root => '#V', root_canon => '#V', root_mod => 1, root_ord => 1, system => 'roman' }
#v+^	{ ext => '^', ext_canon => '^', name => '#v+^', qual => '+', qual_canon => '-', root => '#v', root_canon => '#v', root_mod => 1, root_ord => 1, system => 'roman' }
#V+h	{ ext => 'h', ext_canon => 'h', name => '#V+h', qual => '+', qual_canon => '+', root => '#V', root_canon => '#V', root_mod => 1, root_ord => 1, system => 'roman' }
#v+h	{ ext => 'h', ext_canon => 'h', name => '#v+h', qual => '+', qual_canon => '-', root => '#v', root_canon => '#v', root_mod => 1, root_ord => 1, system => 'roman' }
#V+h7	{ ext => 'h7', ext_canon => 'h7', name => '#V+h7', qual => '+', qual_canon => '+', root => '#V', root_canon => '#V', root_mod => 1, root_ord => 1, system => 'roman' }
#v+h7	{ ext => 'h7', ext_canon => 'h7', name => '#v+h7', qual => '+', qual_canon => '-', root => '#v', root_canon => '#v', root_mod => 1, root_ord => 1, system => 'roman' }
#V+^7	{ ext => '^7', ext_canon => '^7', name => '#V+^7', qual => '+', qual_canon => '+', root => '#V', root_canon => '#V', root_mod => 1, root_ord => 1, system => 'roman' }
#v+^7	{ ext => '^7', ext_canon => '^7', name => '#v+^7', qual => '+', qual_canon => '-', root => '#v', root_canon => '#v', root_mod => 1, root_ord => 1, system => 'roman' }
bVI	{ ext => '', ext_canon => '', name => 'bVI', qual => '', qual_canon => '', root => 'bVI', root_canon => 'bVI', root_mod => -1, root_ord => 11, system => 'roman' }
bvi	{ ext => '', ext_canon => '', name => 'bvi', qual => '', qual_canon => '-', root => 'bvi', root_canon => 'bvi', root_mod => -1, root_ord => 11, system => 'roman' }
bVI7	{ ext => 7, ext_canon => 7, name => 'bVI7', qual => '', qual_canon => '', root => 'bVI', root_canon => 'bVI', root_mod => -1, root_ord => 11, system => 'roman' }
bvi7	{ ext => 7, ext_canon => 7, name => 'bvi7', qual => '', qual_canon => '-', root => 'bvi', root_canon => 'bvi', root_mod => -1, root_ord => 11, system => 'roman' }
bVI^	{ ext => '^', ext_canon => '^', name => 'bVI^', qual => '', qual_canon => '', root => 'bVI', root_canon => 'bVI', root_mod => -1, root_ord => 11, system => 'roman' }
bvi^	{ ext => '^', ext_canon => '^', name => 'bvi^', qual => '', qual_canon => '-', root => 'bvi', root_canon => 'bvi', root_mod => -1, root_ord => 11, system => 'roman' }
bVIh	{ ext => '', ext_canon => '', name => 'bVIh', qual => 'h', qual_canon => 'h', root => 'bVI', root_canon => 'bVI', root_mod => -1, root_ord => 11, system => 'roman' }
bvih	{ ext => '', ext_canon => '', name => 'bvih', qual => 'h', qual_canon => '-', root => 'bvi', root_canon => 'bvi', root_mod => -1, root_ord => 11, system => 'roman' }
bVIh7	{ ext => 7, ext_canon => 7, name => 'bVIh7', qual => 'h', qual_canon => 'h', root => 'bVI', root_canon => 'bVI', root_mod => -1, root_ord => 11, system => 'roman' }
bvih7	{ ext => 7, ext_canon => 7, name => 'bvih7', qual => 'h', qual_canon => '-', root => 'bvi', root_canon => 'bvi', root_mod => -1, root_ord => 11, system => 'roman' }
bVI^7	{ ext => '^7', ext_canon => '^7', name => 'bVI^7', qual => '', qual_canon => '', root => 'bVI', root_canon => 'bVI', root_mod => -1, root_ord => 11, system => 'roman' }
bvi^7	{ ext => '^7', ext_canon => '^7', name => 'bvi^7', qual => '', qual_canon => '-', root => 'bvi', root_canon => 'bvi', root_mod => -1, root_ord => 11, system => 'roman' }
bVI0	{ ext => '', ext_canon => '', name => 'bVI0', qual => 0, qual_canon => 0, root => 'bVI', root_canon => 'bVI', root_mod => -1, root_ord => 11, system => 'roman' }
bvi0	{ ext => '', ext_canon => '', name => 'bvi0', qual => 0, qual_canon => '-', root => 'bvi', root_canon => 'bvi', root_mod => -1, root_ord => 11, system => 'roman' }
bVI07	{ ext => 7, ext_canon => 7, name => 'bVI07', qual => 0, qual_canon => 0, root => 'bVI', root_canon => 'bVI', root_mod => -1, root_ord => 11, system => 'roman' }
bvi07	{ ext => 7, ext_canon => 7, name => 'bvi07', qual => 0, qual_canon => '-', root => 'bvi', root_canon => 'bvi', root_mod => -1, root_ord => 11, system => 'roman' }
bVI0^	{ ext => '^', ext_canon => '^', name => 'bVI0^', qual => 0, qual_canon => 0, root => 'bVI', root_canon => 'bVI', root_mod => -1, root_ord => 11, system => 'roman' }
bvi0^	{ ext => '^', ext_canon => '^', name => 'bvi0^', qual => 0, qual_canon => '-', root => 'bvi', root_canon => 'bvi', root_mod => -1, root_ord => 11, system => 'roman' }
bVI0h	{ ext => 'h', ext_canon => 'h', name => 'bVI0h', qual => 0, qual_canon => 0, root => 'bVI', root_canon => 'bVI', root_mod => -1, root_ord => 11, system => 'roman' }
bvi0h	{ ext => 'h', ext_canon => 'h', name => 'bvi0h', qual => 0, qual_canon => '-', root => 'bvi', root_canon => 'bvi', root_mod => -1, root_ord => 11, system => 'roman' }
bVI0h7	{ ext => 'h7', ext_canon => 'h7', name => 'bVI0h7', qual => 0, qual_canon => 0, root => 'bVI', root_canon => 'bVI', root_mod => -1, root_ord => 11, system => 'roman' }
bvi0h7	{ ext => 'h7', ext_canon => 'h7', name => 'bvi0h7', qual => 0, qual_canon => '-', root => 'bvi', root_canon => 'bvi', root_mod => -1, root_ord => 11, system => 'roman' }
bVI0^7	{ ext => '^7', ext_canon => '^7', name => 'bVI0^7', qual => 0, qual_canon => 0, root => 'bVI', root_canon => 'bVI', root_mod => -1, root_ord => 11, system => 'roman' }
bvi0^7	{ ext => '^7', ext_canon => '^7', name => 'bvi0^7', qual => 0, qual_canon => '-', root => 'bvi', root_canon => 'bvi', root_mod => -1, root_ord => 11, system => 'roman' }
bVI+	{ ext => '', ext_canon => '', name => 'bVI+', qual => '+', qual_canon => '+', root => 'bVI', root_canon => 'bVI', root_mod => -1, root_ord => 11, system => 'roman' }
bvi+	{ ext => '', ext_canon => '', name => 'bvi+', qual => '+', qual_canon => '-', root => 'bvi', root_canon => 'bvi', root_mod => -1, root_ord => 11, system => 'roman' }
bVI+7	{ ext => 7, ext_canon => 7, name => 'bVI+7', qual => '+', qual_canon => '+', root => 'bVI', root_canon => 'bVI', root_mod => -1, root_ord => 11, system => 'roman' }
bvi+7	{ ext => 7, ext_canon => 7, name => 'bvi+7', qual => '+', qual_canon => '-', root => 'bvi', root_canon => 'bvi', root_mod => -1, root_ord => 11, system => 'roman' }
bVI+^	{ ext => '^', ext_canon => '^', name => 'bVI+^', qual => '+', qual_canon => '+', root => 'bVI', root_canon => 'bVI', root_mod => -1, root_ord => 11, system => 'roman' }
bvi+^	{ ext => '^', ext_canon => '^', name => 'bvi+^', qual => '+', qual_canon => '-', root => 'bvi', root_canon => 'bvi', root_mod => -1, root_ord => 11, system => 'roman' }
bVI+h	{ ext => 'h', ext_canon => 'h', name => 'bVI+h', qual => '+', qual_canon => '+', root => 'bVI', root_canon => 'bVI', root_mod => -1, root_ord => 11, system => 'roman' }
bvi+h	{ ext => 'h', ext_canon => 'h', name => 'bvi+h', qual => '+', qual_canon => '-', root => 'bvi', root_canon => 'bvi', root_mod => -1, root_ord => 11, system => 'roman' }
bVI+h7	{ ext => 'h7', ext_canon => 'h7', name => 'bVI+h7', qual => '+', qual_canon => '+', root => 'bVI', root_canon => 'bVI', root_mod => -1, root_ord => 11, system => 'roman' }
bvi+h7	{ ext => 'h7', ext_canon => 'h7', name => 'bvi+h7', qual => '+', qual_canon => '-', root => 'bvi', root_canon => 'bvi', root_mod => -1, root_ord => 11, system => 'roman' }
bVI+^7	{ ext => '^7', ext_canon => '^7', name => 'bVI+^7', qual => '+', qual_canon => '+', root => 'bVI', root_canon => 'bVI', root_mod => -1, root_ord => 11, system => 'roman' }
bvi+^7	{ ext => '^7', ext_canon => '^7', name => 'bvi+^7', qual => '+', qual_canon => '-', root => 'bvi', root_canon => 'bvi', root_mod => -1, root_ord => 11, system => 'roman' }
VI	{ ext => '', ext_canon => '', name => 'VI', qual => '', qual_canon => '', root => 'VI', root_canon => 'VI', root_mod => 0, root_ord => 9, system => 'roman' }
vi	{ ext => '', ext_canon => '', name => 'vi', qual => '', qual_canon => '-', root => 'vi', root_canon => 'vi', root_mod => 0, root_ord => 9, system => 'roman' }
VI7	{ ext => 7, ext_canon => 7, name => 'VI7', qual => '', qual_canon => '', root => 'VI', root_canon => 'VI', root_mod => 0, root_ord => 9, system => 'roman' }
vi7	{ ext => 7, ext_canon => 7, name => 'vi7', qual => '', qual_canon => '-', root => 'vi', root_canon => 'vi', root_mod => 0, root_ord => 9, system => 'roman' }
VI^	{ ext => '^', ext_canon => '^', name => 'VI^', qual => '', qual_canon => '', root => 'VI', root_canon => 'VI', root_mod => 0, root_ord => 9, system => 'roman' }
vi^	{ ext => '^', ext_canon => '^', name => 'vi^', qual => '', qual_canon => '-', root => 'vi', root_canon => 'vi', root_mod => 0, root_ord => 9, system => 'roman' }
VIh	{ ext => '', ext_canon => '', name => 'VIh', qual => 'h', qual_canon => 'h', root => 'VI', root_canon => 'VI', root_mod => 0, root_ord => 9, system => 'roman' }
vih	{ ext => '', ext_canon => '', name => 'vih', qual => 'h', qual_canon => '-', root => 'vi', root_canon => 'vi', root_mod => 0, root_ord => 9, system => 'roman' }
VIh7	{ ext => 7, ext_canon => 7, name => 'VIh7', qual => 'h', qual_canon => 'h', root => 'VI', root_canon => 'VI', root_mod => 0, root_ord => 9, system => 'roman' }
vih7	{ ext => 7, ext_canon => 7, name => 'vih7', qual => 'h', qual_canon => '-', root => 'vi', root_canon => 'vi', root_mod => 0, root_ord => 9, system => 'roman' }
VI^7	{ ext => '^7', ext_canon => '^7', name => 'VI^7', qual => '', qual_canon => '', root => 'VI', root_canon => 'VI', root_mod => 0, root_ord => 9, system => 'roman' }
vi^7	{ ext => '^7', ext_canon => '^7', name => 'vi^7', qual => '', qual_canon => '-', root => 'vi', root_canon => 'vi', root_mod => 0, root_ord => 9, system => 'roman' }
VI0	{ ext => '', ext_canon => '', name => 'VI0', qual => 0, qual_canon => 0, root => 'VI', root_canon => 'VI', root_mod => 0, root_ord => 9, system => 'roman' }
vi0	{ ext => '', ext_canon => '', name => 'vi0', qual => 0, qual_canon => '-', root => 'vi', root_canon => 'vi', root_mod => 0, root_ord => 9, system => 'roman' }
VI07	{ ext => 7, ext_canon => 7, name => 'VI07', qual => 0, qual_canon => 0, root => 'VI', root_canon => 'VI', root_mod => 0, root_ord => 9, system => 'roman' }
vi07	{ ext => 7, ext_canon => 7, name => 'vi07', qual => 0, qual_canon => '-', root => 'vi', root_canon => 'vi', root_mod => 0, root_ord => 9, system => 'roman' }
VI0^	{ ext => '^', ext_canon => '^', name => 'VI0^', qual => 0, qual_canon => 0, root => 'VI', root_canon => 'VI', root_mod => 0, root_ord => 9, system => 'roman' }
vi0^	{ ext => '^', ext_canon => '^', name => 'vi0^', qual => 0, qual_canon => '-', root => 'vi', root_canon => 'vi', root_mod => 0, root_ord => 9, system => 'roman' }
VI0h	{ ext => 'h', ext_canon => 'h', name => 'VI0h', qual => 0, qual_canon => 0, root => 'VI', root_canon => 'VI', root_mod => 0, root_ord => 9, system => 'roman' }
vi0h	{ ext => 'h', ext_canon => 'h', name => 'vi0h', qual => 0, qual_canon => '-', root => 'vi', root_canon => 'vi', root_mod => 0, root_ord => 9, system => 'roman' }
VI0h7	{ ext => 'h7', ext_canon => 'h7', name => 'VI0h7', qual => 0, qual_canon => 0, root => 'VI', root_canon => 'VI', root_mod => 0, root_ord => 9, system => 'roman' }
vi0h7	{ ext => 'h7', ext_canon => 'h7', name => 'vi0h7', qual => 0, qual_canon => '-', root => 'vi', root_canon => 'vi', root_mod => 0, root_ord => 9, system => 'roman' }
VI0^7	{ ext => '^7', ext_canon => '^7', name => 'VI0^7', qual => 0, qual_canon => 0, root => 'VI', root_canon => 'VI', root_mod => 0, root_ord => 9, system => 'roman' }
vi0^7	{ ext => '^7', ext_canon => '^7', name => 'vi0^7', qual => 0, qual_canon => '-', root => 'vi', root_canon => 'vi', root_mod => 0, root_ord => 9, system => 'roman' }
VI+	{ ext => '', ext_canon => '', name => 'VI+', qual => '+', qual_canon => '+', root => 'VI', root_canon => 'VI', root_mod => 0, root_ord => 9, system => 'roman' }
vi+	{ ext => '', ext_canon => '', name => 'vi+', qual => '+', qual_canon => '-', root => 'vi', root_canon => 'vi', root_mod => 0, root_ord => 9, system => 'roman' }
VI+7	{ ext => 7, ext_canon => 7, name => 'VI+7', qual => '+', qual_canon => '+', root => 'VI', root_canon => 'VI', root_mod => 0, root_ord => 9, system => 'roman' }
vi+7	{ ext => 7, ext_canon => 7, name => 'vi+7', qual => '+', qual_canon => '-', root => 'vi', root_canon => 'vi', root_mod => 0, root_ord => 9, system => 'roman' }
VI+^	{ ext => '^', ext_canon => '^', name => 'VI+^', qual => '+', qual_canon => '+', root => 'VI', root_canon => 'VI', root_mod => 0, root_ord => 9, system => 'roman' }
vi+^	{ ext => '^', ext_canon => '^', name => 'vi+^', qual => '+', qual_canon => '-', root => 'vi', root_canon => 'vi', root_mod => 0, root_ord => 9, system => 'roman' }
VI+h	{ ext => 'h', ext_canon => 'h', name => 'VI+h', qual => '+', qual_canon => '+', root => 'VI', root_canon => 'VI', root_mod => 0, root_ord => 9, system => 'roman' }
vi+h	{ ext => 'h', ext_canon => 'h', name => 'vi+h', qual => '+', qual_canon => '-', root => 'vi', root_canon => 'vi', root_mod => 0, root_ord => 9, system => 'roman' }
VI+h7	{ ext => 'h7', ext_canon => 'h7', name => 'VI+h7', qual => '+', qual_canon => '+', root => 'VI', root_canon => 'VI', root_mod => 0, root_ord => 9, system => 'roman' }
vi+h7	{ ext => 'h7', ext_canon => 'h7', name => 'vi+h7', qual => '+', qual_canon => '-', root => 'vi', root_canon => 'vi', root_mod => 0, root_ord => 9, system => 'roman' }
VI+^7	{ ext => '^7', ext_canon => '^7', name => 'VI+^7', qual => '+', qual_canon => '+', root => 'VI', root_canon => 'VI', root_mod => 0, root_ord => 9, system => 'roman' }
vi+^7	{ ext => '^7', ext_canon => '^7', name => 'vi+^7', qual => '+', qual_canon => '-', root => 'vi', root_canon => 'vi', root_mod => 0, root_ord => 9, system => 'roman' }
#VI	{ ext => '', ext_canon => '', name => '#VI', qual => '', qual_canon => '', root => '#VI', root_canon => '#VI', root_mod => 1, root_ord => 1, system => 'roman' }
#vi	{ ext => '', ext_canon => '', name => '#vi', qual => '', qual_canon => '-', root => '#vi', root_canon => '#vi', root_mod => 1, root_ord => 1, system => 'roman' }
#VI7	{ ext => 7, ext_canon => 7, name => '#VI7', qual => '', qual_canon => '', root => '#VI', root_canon => '#VI', root_mod => 1, root_ord => 1, system => 'roman' }
#vi7	{ ext => 7, ext_canon => 7, name => '#vi7', qual => '', qual_canon => '-', root => '#vi', root_canon => '#vi', root_mod => 1, root_ord => 1, system => 'roman' }
#VI^	{ ext => '^', ext_canon => '^', name => '#VI^', qual => '', qual_canon => '', root => '#VI', root_canon => '#VI', root_mod => 1, root_ord => 1, system => 'roman' }
#vi^	{ ext => '^', ext_canon => '^', name => '#vi^', qual => '', qual_canon => '-', root => '#vi', root_canon => '#vi', root_mod => 1, root_ord => 1, system => 'roman' }
#VIh	{ ext => '', ext_canon => '', name => '#VIh', qual => 'h', qual_canon => 'h', root => '#VI', root_canon => '#VI', root_mod => 1, root_ord => 1, system => 'roman' }
#vih	{ ext => '', ext_canon => '', name => '#vih', qual => 'h', qual_canon => '-', root => '#vi', root_canon => '#vi', root_mod => 1, root_ord => 1, system => 'roman' }
#VIh7	{ ext => 7, ext_canon => 7, name => '#VIh7', qual => 'h', qual_canon => 'h', root => '#VI', root_canon => '#VI', root_mod => 1, root_ord => 1, system => 'roman' }
#vih7	{ ext => 7, ext_canon => 7, name => '#vih7', qual => 'h', qual_canon => '-', root => '#vi', root_canon => '#vi', root_mod => 1, root_ord => 1, system => 'roman' }
#VI^7	{ ext => '^7', ext_canon => '^7', name => '#VI^7', qual => '', qual_canon => '', root => '#VI', root_canon => '#VI', root_mod => 1, root_ord => 1, system => 'roman' }
#vi^7	{ ext => '^7', ext_canon => '^7', name => '#vi^7', qual => '', qual_canon => '-', root => '#vi', root_canon => '#vi', root_mod => 1, root_ord => 1, system => 'roman' }
#VI0	{ ext => '', ext_canon => '', name => '#VI0', qual => 0, qual_canon => 0, root => '#VI', root_canon => '#VI', root_mod => 1, root_ord => 1, system => 'roman' }
#vi0	{ ext => '', ext_canon => '', name => '#vi0', qual => 0, qual_canon => '-', root => '#vi', root_canon => '#vi', root_mod => 1, root_ord => 1, system => 'roman' }
#VI07	{ ext => 7, ext_canon => 7, name => '#VI07', qual => 0, qual_canon => 0, root => '#VI', root_canon => '#VI', root_mod => 1, root_ord => 1, system => 'roman' }
#vi07	{ ext => 7, ext_canon => 7, name => '#vi07', qual => 0, qual_canon => '-', root => '#vi', root_canon => '#vi', root_mod => 1, root_ord => 1, system => 'roman' }
#VI0^	{ ext => '^', ext_canon => '^', name => '#VI0^', qual => 0, qual_canon => 0, root => '#VI', root_canon => '#VI', root_mod => 1, root_ord => 1, system => 'roman' }
#vi0^	{ ext => '^', ext_canon => '^', name => '#vi0^', qual => 0, qual_canon => '-', root => '#vi', root_canon => '#vi', root_mod => 1, root_ord => 1, system => 'roman' }
#VI0h	{ ext => 'h', ext_canon => 'h', name => '#VI0h', qual => 0, qual_canon => 0, root => '#VI', root_canon => '#VI', root_mod => 1, root_ord => 1, system => 'roman' }
#vi0h	{ ext => 'h', ext_canon => 'h', name => '#vi0h', qual => 0, qual_canon => '-', root => '#vi', root_canon => '#vi', root_mod => 1, root_ord => 1, system => 'roman' }
#VI0h7	{ ext => 'h7', ext_canon => 'h7', name => '#VI0h7', qual => 0, qual_canon => 0, root => '#VI', root_canon => '#VI', root_mod => 1, root_ord => 1, system => 'roman' }
#vi0h7	{ ext => 'h7', ext_canon => 'h7', name => '#vi0h7', qual => 0, qual_canon => '-', root => '#vi', root_canon => '#vi', root_mod => 1, root_ord => 1, system => 'roman' }
#VI0^7	{ ext => '^7', ext_canon => '^7', name => '#VI0^7', qual => 0, qual_canon => 0, root => '#VI', root_canon => '#VI', root_mod => 1, root_ord => 1, system => 'roman' }
#vi0^7	{ ext => '^7', ext_canon => '^7', name => '#vi0^7', qual => 0, qual_canon => '-', root => '#vi', root_canon => '#vi', root_mod => 1, root_ord => 1, system => 'roman' }
#VI+	{ ext => '', ext_canon => '', name => '#VI+', qual => '+', qual_canon => '+', root => '#VI', root_canon => '#VI', root_mod => 1, root_ord => 1, system => 'roman' }
#vi+	{ ext => '', ext_canon => '', name => '#vi+', qual => '+', qual_canon => '-', root => '#vi', root_canon => '#vi', root_mod => 1, root_ord => 1, system => 'roman' }
#VI+7	{ ext => 7, ext_canon => 7, name => '#VI+7', qual => '+', qual_canon => '+', root => '#VI', root_canon => '#VI', root_mod => 1, root_ord => 1, system => 'roman' }
#vi+7	{ ext => 7, ext_canon => 7, name => '#vi+7', qual => '+', qual_canon => '-', root => '#vi', root_canon => '#vi', root_mod => 1, root_ord => 1, system => 'roman' }
#VI+^	{ ext => '^', ext_canon => '^', name => '#VI+^', qual => '+', qual_canon => '+', root => '#VI', root_canon => '#VI', root_mod => 1, root_ord => 1, system => 'roman' }
#vi+^	{ ext => '^', ext_canon => '^', name => '#vi+^', qual => '+', qual_canon => '-', root => '#vi', root_canon => '#vi', root_mod => 1, root_ord => 1, system => 'roman' }
#VI+h	{ ext => 'h', ext_canon => 'h', name => '#VI+h', qual => '+', qual_canon => '+', root => '#VI', root_canon => '#VI', root_mod => 1, root_ord => 1, system => 'roman' }
#vi+h	{ ext => 'h', ext_canon => 'h', name => '#vi+h', qual => '+', qual_canon => '-', root => '#vi', root_canon => '#vi', root_mod => 1, root_ord => 1, system => 'roman' }
#VI+h7	{ ext => 'h7', ext_canon => 'h7', name => '#VI+h7', qual => '+', qual_canon => '+', root => '#VI', root_canon => '#VI', root_mod => 1, root_ord => 1, system => 'roman' }
#vi+h7	{ ext => 'h7', ext_canon => 'h7', name => '#vi+h7', qual => '+', qual_canon => '-', root => '#vi', root_canon => '#vi', root_mod => 1, root_ord => 1, system => 'roman' }
#VI+^7	{ ext => '^7', ext_canon => '^7', name => '#VI+^7', qual => '+', qual_canon => '+', root => '#VI', root_canon => '#VI', root_mod => 1, root_ord => 1, system => 'roman' }
#vi+^7	{ ext => '^7', ext_canon => '^7', name => '#vi+^7', qual => '+', qual_canon => '-', root => '#vi', root_canon => '#vi', root_mod => 1, root_ord => 1, system => 'roman' }
bVII	{ ext => '', ext_canon => '', name => 'bVII', qual => '', qual_canon => '', root => 'bVII', root_canon => 'bVII', root_mod => -1, root_ord => 11, system => 'roman' }
bvii	{ ext => '', ext_canon => '', name => 'bvii', qual => '', qual_canon => '-', root => 'bvii', root_canon => 'bvii', root_mod => -1, root_ord => 11, system => 'roman' }
bVII7	{ ext => 7, ext_canon => 7, name => 'bVII7', qual => '', qual_canon => '', root => 'bVII', root_canon => 'bVII', root_mod => -1, root_ord => 11, system => 'roman' }
bvii7	{ ext => 7, ext_canon => 7, name => 'bvii7', qual => '', qual_canon => '-', root => 'bvii', root_canon => 'bvii', root_mod => -1, root_ord => 11, system => 'roman' }
bVII^	{ ext => '^', ext_canon => '^', name => 'bVII^', qual => '', qual_canon => '', root => 'bVII', root_canon => 'bVII', root_mod => -1, root_ord => 11, system => 'roman' }
bvii^	{ ext => '^', ext_canon => '^', name => 'bvii^', qual => '', qual_canon => '-', root => 'bvii', root_canon => 'bvii', root_mod => -1, root_ord => 11, system => 'roman' }
bVIIh	{ ext => '', ext_canon => '', name => 'bVIIh', qual => 'h', qual_canon => 'h', root => 'bVII', root_canon => 'bVII', root_mod => -1, root_ord => 11, system => 'roman' }
bviih	{ ext => '', ext_canon => '', name => 'bviih', qual => 'h', qual_canon => '-', root => 'bvii', root_canon => 'bvii', root_mod => -1, root_ord => 11, system => 'roman' }
bVIIh7	{ ext => 7, ext_canon => 7, name => 'bVIIh7', qual => 'h', qual_canon => 'h', root => 'bVII', root_canon => 'bVII', root_mod => -1, root_ord => 11, system => 'roman' }
bviih7	{ ext => 7, ext_canon => 7, name => 'bviih7', qual => 'h', qual_canon => '-', root => 'bvii', root_canon => 'bvii', root_mod => -1, root_ord => 11, system => 'roman' }
bVII^7	{ ext => '^7', ext_canon => '^7', name => 'bVII^7', qual => '', qual_canon => '', root => 'bVII', root_canon => 'bVII', root_mod => -1, root_ord => 11, system => 'roman' }
bvii^7	{ ext => '^7', ext_canon => '^7', name => 'bvii^7', qual => '', qual_canon => '-', root => 'bvii', root_canon => 'bvii', root_mod => -1, root_ord => 11, system => 'roman' }
bVII0	{ ext => '', ext_canon => '', name => 'bVII0', qual => 0, qual_canon => 0, root => 'bVII', root_canon => 'bVII', root_mod => -1, root_ord => 11, system => 'roman' }
bvii0	{ ext => '', ext_canon => '', name => 'bvii0', qual => 0, qual_canon => '-', root => 'bvii', root_canon => 'bvii', root_mod => -1, root_ord => 11, system => 'roman' }
bVII07	{ ext => 7, ext_canon => 7, name => 'bVII07', qual => 0, qual_canon => 0, root => 'bVII', root_canon => 'bVII', root_mod => -1, root_ord => 11, system => 'roman' }
bvii07	{ ext => 7, ext_canon => 7, name => 'bvii07', qual => 0, qual_canon => '-', root => 'bvii', root_canon => 'bvii', root_mod => -1, root_ord => 11, system => 'roman' }
bVII0^	{ ext => '^', ext_canon => '^', name => 'bVII0^', qual => 0, qual_canon => 0, root => 'bVII', root_canon => 'bVII', root_mod => -1, root_ord => 11, system => 'roman' }
bvii0^	{ ext => '^', ext_canon => '^', name => 'bvii0^', qual => 0, qual_canon => '-', root => 'bvii', root_canon => 'bvii', root_mod => -1, root_ord => 11, system => 'roman' }
bVII0h	{ ext => 'h', ext_canon => 'h', name => 'bVII0h', qual => 0, qual_canon => 0, root => 'bVII', root_canon => 'bVII', root_mod => -1, root_ord => 11, system => 'roman' }
bvii0h	{ ext => 'h', ext_canon => 'h', name => 'bvii0h', qual => 0, qual_canon => '-', root => 'bvii', root_canon => 'bvii', root_mod => -1, root_ord => 11, system => 'roman' }
bVII0h7	{ ext => 'h7', ext_canon => 'h7', name => 'bVII0h7', qual => 0, qual_canon => 0, root => 'bVII', root_canon => 'bVII', root_mod => -1, root_ord => 11, system => 'roman' }
bvii0h7	{ ext => 'h7', ext_canon => 'h7', name => 'bvii0h7', qual => 0, qual_canon => '-', root => 'bvii', root_canon => 'bvii', root_mod => -1, root_ord => 11, system => 'roman' }
bVII0^7	{ ext => '^7', ext_canon => '^7', name => 'bVII0^7', qual => 0, qual_canon => 0, root => 'bVII', root_canon => 'bVII', root_mod => -1, root_ord => 11, system => 'roman' }
bvii0^7	{ ext => '^7', ext_canon => '^7', name => 'bvii0^7', qual => 0, qual_canon => '-', root => 'bvii', root_canon => 'bvii', root_mod => -1, root_ord => 11, system => 'roman' }
bVII+	{ ext => '', ext_canon => '', name => 'bVII+', qual => '+', qual_canon => '+', root => 'bVII', root_canon => 'bVII', root_mod => -1, root_ord => 11, system => 'roman' }
bvii+	{ ext => '', ext_canon => '', name => 'bvii+', qual => '+', qual_canon => '-', root => 'bvii', root_canon => 'bvii', root_mod => -1, root_ord => 11, system => 'roman' }
bVII+7	{ ext => 7, ext_canon => 7, name => 'bVII+7', qual => '+', qual_canon => '+', root => 'bVII', root_canon => 'bVII', root_mod => -1, root_ord => 11, system => 'roman' }
bvii+7	{ ext => 7, ext_canon => 7, name => 'bvii+7', qual => '+', qual_canon => '-', root => 'bvii', root_canon => 'bvii', root_mod => -1, root_ord => 11, system => 'roman' }
bVII+^	{ ext => '^', ext_canon => '^', name => 'bVII+^', qual => '+', qual_canon => '+', root => 'bVII', root_canon => 'bVII', root_mod => -1, root_ord => 11, system => 'roman' }
bvii+^	{ ext => '^', ext_canon => '^', name => 'bvii+^', qual => '+', qual_canon => '-', root => 'bvii', root_canon => 'bvii', root_mod => -1, root_ord => 11, system => 'roman' }
bVII+h	{ ext => 'h', ext_canon => 'h', name => 'bVII+h', qual => '+', qual_canon => '+', root => 'bVII', root_canon => 'bVII', root_mod => -1, root_ord => 11, system => 'roman' }
bvii+h	{ ext => 'h', ext_canon => 'h', name => 'bvii+h', qual => '+', qual_canon => '-', root => 'bvii', root_canon => 'bvii', root_mod => -1, root_ord => 11, system => 'roman' }
bVII+h7	{ ext => 'h7', ext_canon => 'h7', name => 'bVII+h7', qual => '+', qual_canon => '+', root => 'bVII', root_canon => 'bVII', root_mod => -1, root_ord => 11, system => 'roman' }
bvii+h7	{ ext => 'h7', ext_canon => 'h7', name => 'bvii+h7', qual => '+', qual_canon => '-', root => 'bvii', root_canon => 'bvii', root_mod => -1, root_ord => 11, system => 'roman' }
bVII+^7	{ ext => '^7', ext_canon => '^7', name => 'bVII+^7', qual => '+', qual_canon => '+', root => 'bVII', root_canon => 'bVII', root_mod => -1, root_ord => 11, system => 'roman' }
bvii+^7	{ ext => '^7', ext_canon => '^7', name => 'bvii+^7', qual => '+', qual_canon => '-', root => 'bvii', root_canon => 'bvii', root_mod => -1, root_ord => 11, system => 'roman' }
VII	{ ext => '', ext_canon => '', name => 'VII', qual => '', qual_canon => '', root => 'VII', root_canon => 'VII', root_mod => 0, root_ord => 11, system => 'roman' }
vii	{ ext => '', ext_canon => '', name => 'vii', qual => '', qual_canon => '-', root => 'vii', root_canon => 'vii', root_mod => 0, root_ord => 11, system => 'roman' }
VII7	{ ext => 7, ext_canon => 7, name => 'VII7', qual => '', qual_canon => '', root => 'VII', root_canon => 'VII', root_mod => 0, root_ord => 11, system => 'roman' }
vii7	{ ext => 7, ext_canon => 7, name => 'vii7', qual => '', qual_canon => '-', root => 'vii', root_canon => 'vii', root_mod => 0, root_ord => 11, system => 'roman' }
VII^	{ ext => '^', ext_canon => '^', name => 'VII^', qual => '', qual_canon => '', root => 'VII', root_canon => 'VII', root_mod => 0, root_ord => 11, system => 'roman' }
vii^	{ ext => '^', ext_canon => '^', name => 'vii^', qual => '', qual_canon => '-', root => 'vii', root_canon => 'vii', root_mod => 0, root_ord => 11, system => 'roman' }
VIIh	{ ext => '', ext_canon => '', name => 'VIIh', qual => 'h', qual_canon => 'h', root => 'VII', root_canon => 'VII', root_mod => 0, root_ord => 11, system => 'roman' }
viih	{ ext => '', ext_canon => '', name => 'viih', qual => 'h', qual_canon => '-', root => 'vii', root_canon => 'vii', root_mod => 0, root_ord => 11, system => 'roman' }
VIIh7	{ ext => 7, ext_canon => 7, name => 'VIIh7', qual => 'h', qual_canon => 'h', root => 'VII', root_canon => 'VII', root_mod => 0, root_ord => 11, system => 'roman' }
viih7	{ ext => 7, ext_canon => 7, name => 'viih7', qual => 'h', qual_canon => '-', root => 'vii', root_canon => 'vii', root_mod => 0, root_ord => 11, system => 'roman' }
VII^7	{ ext => '^7', ext_canon => '^7', name => 'VII^7', qual => '', qual_canon => '', root => 'VII', root_canon => 'VII', root_mod => 0, root_ord => 11, system => 'roman' }
vii^7	{ ext => '^7', ext_canon => '^7', name => 'vii^7', qual => '', qual_canon => '-', root => 'vii', root_canon => 'vii', root_mod => 0, root_ord => 11, system => 'roman' }
VII0	{ ext => '', ext_canon => '', name => 'VII0', qual => 0, qual_canon => 0, root => 'VII', root_canon => 'VII', root_mod => 0, root_ord => 11, system => 'roman' }
vii0	{ ext => '', ext_canon => '', name => 'vii0', qual => 0, qual_canon => '-', root => 'vii', root_canon => 'vii', root_mod => 0, root_ord => 11, system => 'roman' }
VII07	{ ext => 7, ext_canon => 7, name => 'VII07', qual => 0, qual_canon => 0, root => 'VII', root_canon => 'VII', root_mod => 0, root_ord => 11, system => 'roman' }
vii07	{ ext => 7, ext_canon => 7, name => 'vii07', qual => 0, qual_canon => '-', root => 'vii', root_canon => 'vii', root_mod => 0, root_ord => 11, system => 'roman' }
VII0^	{ ext => '^', ext_canon => '^', name => 'VII0^', qual => 0, qual_canon => 0, root => 'VII', root_canon => 'VII', root_mod => 0, root_ord => 11, system => 'roman' }
vii0^	{ ext => '^', ext_canon => '^', name => 'vii0^', qual => 0, qual_canon => '-', root => 'vii', root_canon => 'vii', root_mod => 0, root_ord => 11, system => 'roman' }
VII0h	{ ext => 'h', ext_canon => 'h', name => 'VII0h', qual => 0, qual_canon => 0, root => 'VII', root_canon => 'VII', root_mod => 0, root_ord => 11, system => 'roman' }
vii0h	{ ext => 'h', ext_canon => 'h', name => 'vii0h', qual => 0, qual_canon => '-', root => 'vii', root_canon => 'vii', root_mod => 0, root_ord => 11, system => 'roman' }
VII0h7	{ ext => 'h7', ext_canon => 'h7', name => 'VII0h7', qual => 0, qual_canon => 0, root => 'VII', root_canon => 'VII', root_mod => 0, root_ord => 11, system => 'roman' }
vii0h7	{ ext => 'h7', ext_canon => 'h7', name => 'vii0h7', qual => 0, qual_canon => '-', root => 'vii', root_canon => 'vii', root_mod => 0, root_ord => 11, system => 'roman' }
VII0^7	{ ext => '^7', ext_canon => '^7', name => 'VII0^7', qual => 0, qual_canon => 0, root => 'VII', root_canon => 'VII', root_mod => 0, root_ord => 11, system => 'roman' }
vii0^7	{ ext => '^7', ext_canon => '^7', name => 'vii0^7', qual => 0, qual_canon => '-', root => 'vii', root_canon => 'vii', root_mod => 0, root_ord => 11, system => 'roman' }
VII+	{ ext => '', ext_canon => '', name => 'VII+', qual => '+', qual_canon => '+', root => 'VII', root_canon => 'VII', root_mod => 0, root_ord => 11, system => 'roman' }
vii+	{ ext => '', ext_canon => '', name => 'vii+', qual => '+', qual_canon => '-', root => 'vii', root_canon => 'vii', root_mod => 0, root_ord => 11, system => 'roman' }
VII+7	{ ext => 7, ext_canon => 7, name => 'VII+7', qual => '+', qual_canon => '+', root => 'VII', root_canon => 'VII', root_mod => 0, root_ord => 11, system => 'roman' }
vii+7	{ ext => 7, ext_canon => 7, name => 'vii+7', qual => '+', qual_canon => '-', root => 'vii', root_canon => 'vii', root_mod => 0, root_ord => 11, system => 'roman' }
VII+^	{ ext => '^', ext_canon => '^', name => 'VII+^', qual => '+', qual_canon => '+', root => 'VII', root_canon => 'VII', root_mod => 0, root_ord => 11, system => 'roman' }
vii+^	{ ext => '^', ext_canon => '^', name => 'vii+^', qual => '+', qual_canon => '-', root => 'vii', root_canon => 'vii', root_mod => 0, root_ord => 11, system => 'roman' }
VII+h	{ ext => 'h', ext_canon => 'h', name => 'VII+h', qual => '+', qual_canon => '+', root => 'VII', root_canon => 'VII', root_mod => 0, root_ord => 11, system => 'roman' }
vii+h	{ ext => 'h', ext_canon => 'h', name => 'vii+h', qual => '+', qual_canon => '-', root => 'vii', root_canon => 'vii', root_mod => 0, root_ord => 11, system => 'roman' }
VII+h7	{ ext => 'h7', ext_canon => 'h7', name => 'VII+h7', qual => '+', qual_canon => '+', root => 'VII', root_canon => 'VII', root_mod => 0, root_ord => 11, system => 'roman' }
vii+h7	{ ext => 'h7', ext_canon => 'h7', name => 'vii+h7', qual => '+', qual_canon => '-', root => 'vii', root_canon => 'vii', root_mod => 0, root_ord => 11, system => 'roman' }
VII+^7	{ ext => '^7', ext_canon => '^7', name => 'VII+^7', qual => '+', qual_canon => '+', root => 'VII', root_canon => 'VII', root_mod => 0, root_ord => 11, system => 'roman' }
vii+^7	{ ext => '^7', ext_canon => '^7', name => 'vii+^7', qual => '+', qual_canon => '-', root => 'vii', root_canon => 'vii', root_mod => 0, root_ord => 11, system => 'roman' }
