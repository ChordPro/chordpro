#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use App::Music::ChordPro::Testing;

use App::Packager ( ':name', 'App::Music::ChordPro' );
use App::Music::ChordPro::Config;
use App::Music::ChordPro::Chords;

my %tbl;

our $config =
  eval {
      App::Music::ChordPro::Config::configurator;
  };


while ( <DATA> ) {
    chomp;
    my ( $chord, $info ) = split( /\t/, $_ );
    my $c = $chord;
    $c =~ s/[()]//g;
    $tbl{$c} = $info;
}

plan tests => 1 + keys(%tbl);

ok( $config, "got config" );

App::Music::ChordPro::Chords::set_parser("nashville");

=for generating

for my $r ( '1', '#1', 'b2', '2', '#2', 'b3', '3', '4',
	    '#4', 'b5', '5', '#5', 'b6', '6', '#6', 'b7', '7' ) {
    for my $q ( '', '-', '0', '+' ) {
	for my $e ( '', '7', '^', 'h', 'h7', '^7' ) {
	    my $chord = "$r$q$e";
	    my $res = App::Music::ChordPro::Chords::parse_chord($chord);
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
	$res = reformat($res);
    }
    is( $res, $info, "parsing chord $c");
}

sub reformat {
    my ( $res ) = @_;
    $res = {%$res};		# unbless
    delete($res->{parser});
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
1	{ ext => '', ext_canon => '', name => 1, qual => '', qual_canon => '', root => 1, root_canon => 1, root_mod => 0, root_ord => 0, system => 'nashville' }
17	{ ext => 7, ext_canon => 7, name => 17, qual => '', qual_canon => '', root => 1, root_canon => 1, root_mod => 0, root_ord => 0, system => 'nashville' }
1^	{ ext => '^', ext_canon => '^', name => '1^', qual => '', qual_canon => '', root => 1, root_canon => 1, root_mod => 0, root_ord => 0, system => 'nashville' }
1h	{ ext => 'h', ext_canon => 'h', name => '1h', qual => '', qual_canon => '', root => 1, root_canon => 1, root_mod => 0, root_ord => 0, system => 'nashville' }
1h7	{ ext => 'h7', ext_canon => 'h7', name => '1h7', qual => '', qual_canon => '', root => 1, root_canon => 1, root_mod => 0, root_ord => 0, system => 'nashville' }
1^7	{ ext => '^7', ext_canon => '^7', name => '1^7', qual => '', qual_canon => '', root => 1, root_canon => 1, root_mod => 0, root_ord => 0, system => 'nashville' }
1-	{ ext => '', ext_canon => '', name => '1-', qual => '-', qual_canon => '-', root => 1, root_canon => 1, root_mod => 0, root_ord => 0, system => 'nashville' }
1-7	{ ext => 7, ext_canon => 7, name => '1-7', qual => '-', qual_canon => '-', root => 1, root_canon => 1, root_mod => 0, root_ord => 0, system => 'nashville' }
1-^	{ ext => '^', ext_canon => '^', name => '1-^', qual => '-', qual_canon => '-', root => 1, root_canon => 1, root_mod => 0, root_ord => 0, system => 'nashville' }
1-h	{ ext => 'h', ext_canon => 'h', name => '1-h', qual => '-', qual_canon => '-', root => 1, root_canon => 1, root_mod => 0, root_ord => 0, system => 'nashville' }
1-h7	{ ext => 'h7', ext_canon => 'h7', name => '1-h7', qual => '-', qual_canon => '-', root => 1, root_canon => 1, root_mod => 0, root_ord => 0, system => 'nashville' }
1-^7	{ ext => '^7', ext_canon => '^7', name => '1-^7', qual => '-', qual_canon => '-', root => 1, root_canon => 1, root_mod => 0, root_ord => 0, system => 'nashville' }
10	{ ext => '', ext_canon => '', name => 10, qual => 0, qual_canon => 0, root => 1, root_canon => 1, root_mod => 0, root_ord => 0, system => 'nashville' }
107	{ ext => 7, ext_canon => 7, name => 107, qual => 0, qual_canon => 0, root => 1, root_canon => 1, root_mod => 0, root_ord => 0, system => 'nashville' }
10^	{ ext => '^', ext_canon => '^', name => '10^', qual => 0, qual_canon => 0, root => 1, root_canon => 1, root_mod => 0, root_ord => 0, system => 'nashville' }
10h	{ ext => 'h', ext_canon => 'h', name => '10h', qual => 0, qual_canon => 0, root => 1, root_canon => 1, root_mod => 0, root_ord => 0, system => 'nashville' }
10h7	{ ext => 'h7', ext_canon => 'h7', name => '10h7', qual => 0, qual_canon => 0, root => 1, root_canon => 1, root_mod => 0, root_ord => 0, system => 'nashville' }
10^7	{ ext => '^7', ext_canon => '^7', name => '10^7', qual => 0, qual_canon => 0, root => 1, root_canon => 1, root_mod => 0, root_ord => 0, system => 'nashville' }
1+	{ ext => '', ext_canon => '', name => '1+', qual => '+', qual_canon => '+', root => 1, root_canon => 1, root_mod => 0, root_ord => 0, system => 'nashville' }
1+7	{ ext => 7, ext_canon => 7, name => '1+7', qual => '+', qual_canon => '+', root => 1, root_canon => 1, root_mod => 0, root_ord => 0, system => 'nashville' }
1+^	{ ext => '^', ext_canon => '^', name => '1+^', qual => '+', qual_canon => '+', root => 1, root_canon => 1, root_mod => 0, root_ord => 0, system => 'nashville' }
1+h	{ ext => 'h', ext_canon => 'h', name => '1+h', qual => '+', qual_canon => '+', root => 1, root_canon => 1, root_mod => 0, root_ord => 0, system => 'nashville' }
1+h7	{ ext => 'h7', ext_canon => 'h7', name => '1+h7', qual => '+', qual_canon => '+', root => 1, root_canon => 1, root_mod => 0, root_ord => 0, system => 'nashville' }
1+^7	{ ext => '^7', ext_canon => '^7', name => '1+^7', qual => '+', qual_canon => '+', root => 1, root_canon => 1, root_mod => 0, root_ord => 0, system => 'nashville' }
#1	{ ext => '', ext_canon => '', name => '#1', qual => '', qual_canon => '', root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#17	{ ext => 7, ext_canon => 7, name => '#17', qual => '', qual_canon => '', root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#1^	{ ext => '^', ext_canon => '^', name => '#1^', qual => '', qual_canon => '', root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#1h	{ ext => 'h', ext_canon => 'h', name => '#1h', qual => '', qual_canon => '', root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#1h7	{ ext => 'h7', ext_canon => 'h7', name => '#1h7', qual => '', qual_canon => '', root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#1^7	{ ext => '^7', ext_canon => '^7', name => '#1^7', qual => '', qual_canon => '', root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#1-	{ ext => '', ext_canon => '', name => '#1-', qual => '-', qual_canon => '-', root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#1-7	{ ext => 7, ext_canon => 7, name => '#1-7', qual => '-', qual_canon => '-', root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#1-^	{ ext => '^', ext_canon => '^', name => '#1-^', qual => '-', qual_canon => '-', root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#1-h	{ ext => 'h', ext_canon => 'h', name => '#1-h', qual => '-', qual_canon => '-', root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#1-h7	{ ext => 'h7', ext_canon => 'h7', name => '#1-h7', qual => '-', qual_canon => '-', root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#1-^7	{ ext => '^7', ext_canon => '^7', name => '#1-^7', qual => '-', qual_canon => '-', root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#10	{ ext => '', ext_canon => '', name => '#10', qual => 0, qual_canon => 0, root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#107	{ ext => 7, ext_canon => 7, name => '#107', qual => 0, qual_canon => 0, root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#10^	{ ext => '^', ext_canon => '^', name => '#10^', qual => 0, qual_canon => 0, root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#10h	{ ext => 'h', ext_canon => 'h', name => '#10h', qual => 0, qual_canon => 0, root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#10h7	{ ext => 'h7', ext_canon => 'h7', name => '#10h7', qual => 0, qual_canon => 0, root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#10^7	{ ext => '^7', ext_canon => '^7', name => '#10^7', qual => 0, qual_canon => 0, root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#1+	{ ext => '', ext_canon => '', name => '#1+', qual => '+', qual_canon => '+', root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#1+7	{ ext => 7, ext_canon => 7, name => '#1+7', qual => '+', qual_canon => '+', root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#1+^	{ ext => '^', ext_canon => '^', name => '#1+^', qual => '+', qual_canon => '+', root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#1+h	{ ext => 'h', ext_canon => 'h', name => '#1+h', qual => '+', qual_canon => '+', root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#1+h7	{ ext => 'h7', ext_canon => 'h7', name => '#1+h7', qual => '+', qual_canon => '+', root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
#1+^7	{ ext => '^7', ext_canon => '^7', name => '#1+^7', qual => '+', qual_canon => '+', root => 1, root_canon => 1, root_mod => 1, root_ord => 1, system => 'nashville' }
b2	{ ext => '', ext_canon => '', name => 'b2', qual => '', qual_canon => '', root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b27	{ ext => 7, ext_canon => 7, name => 'b27', qual => '', qual_canon => '', root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b2^	{ ext => '^', ext_canon => '^', name => 'b2^', qual => '', qual_canon => '', root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b2h	{ ext => 'h', ext_canon => 'h', name => 'b2h', qual => '', qual_canon => '', root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b2h7	{ ext => 'h7', ext_canon => 'h7', name => 'b2h7', qual => '', qual_canon => '', root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b2^7	{ ext => '^7', ext_canon => '^7', name => 'b2^7', qual => '', qual_canon => '', root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b2-	{ ext => '', ext_canon => '', name => 'b2-', qual => '-', qual_canon => '-', root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b2-7	{ ext => 7, ext_canon => 7, name => 'b2-7', qual => '-', qual_canon => '-', root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b2-^	{ ext => '^', ext_canon => '^', name => 'b2-^', qual => '-', qual_canon => '-', root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b2-h	{ ext => 'h', ext_canon => 'h', name => 'b2-h', qual => '-', qual_canon => '-', root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b2-h7	{ ext => 'h7', ext_canon => 'h7', name => 'b2-h7', qual => '-', qual_canon => '-', root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b2-^7	{ ext => '^7', ext_canon => '^7', name => 'b2-^7', qual => '-', qual_canon => '-', root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b20	{ ext => '', ext_canon => '', name => 'b20', qual => 0, qual_canon => 0, root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b207	{ ext => 7, ext_canon => 7, name => 'b207', qual => 0, qual_canon => 0, root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b20^	{ ext => '^', ext_canon => '^', name => 'b20^', qual => 0, qual_canon => 0, root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b20h	{ ext => 'h', ext_canon => 'h', name => 'b20h', qual => 0, qual_canon => 0, root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b20h7	{ ext => 'h7', ext_canon => 'h7', name => 'b20h7', qual => 0, qual_canon => 0, root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b20^7	{ ext => '^7', ext_canon => '^7', name => 'b20^7', qual => 0, qual_canon => 0, root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b2+	{ ext => '', ext_canon => '', name => 'b2+', qual => '+', qual_canon => '+', root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b2+7	{ ext => 7, ext_canon => 7, name => 'b2+7', qual => '+', qual_canon => '+', root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b2+^	{ ext => '^', ext_canon => '^', name => 'b2+^', qual => '+', qual_canon => '+', root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b2+h	{ ext => 'h', ext_canon => 'h', name => 'b2+h', qual => '+', qual_canon => '+', root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b2+h7	{ ext => 'h7', ext_canon => 'h7', name => 'b2+h7', qual => '+', qual_canon => '+', root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
b2+^7	{ ext => '^7', ext_canon => '^7', name => 'b2+^7', qual => '+', qual_canon => '+', root => 2, root_canon => 2, root_mod => -1, root_ord => 1, system => 'nashville' }
2	{ ext => '', ext_canon => '', name => 2, qual => '', qual_canon => '', root => 2, root_canon => 2, root_mod => 0, root_ord => 2, system => 'nashville' }
27	{ ext => 7, ext_canon => 7, name => 27, qual => '', qual_canon => '', root => 2, root_canon => 2, root_mod => 0, root_ord => 2, system => 'nashville' }
2^	{ ext => '^', ext_canon => '^', name => '2^', qual => '', qual_canon => '', root => 2, root_canon => 2, root_mod => 0, root_ord => 2, system => 'nashville' }
2h	{ ext => 'h', ext_canon => 'h', name => '2h', qual => '', qual_canon => '', root => 2, root_canon => 2, root_mod => 0, root_ord => 2, system => 'nashville' }
2h7	{ ext => 'h7', ext_canon => 'h7', name => '2h7', qual => '', qual_canon => '', root => 2, root_canon => 2, root_mod => 0, root_ord => 2, system => 'nashville' }
2^7	{ ext => '^7', ext_canon => '^7', name => '2^7', qual => '', qual_canon => '', root => 2, root_canon => 2, root_mod => 0, root_ord => 2, system => 'nashville' }
2-	{ ext => '', ext_canon => '', name => '2-', qual => '-', qual_canon => '-', root => 2, root_canon => 2, root_mod => 0, root_ord => 2, system => 'nashville' }
2-7	{ ext => 7, ext_canon => 7, name => '2-7', qual => '-', qual_canon => '-', root => 2, root_canon => 2, root_mod => 0, root_ord => 2, system => 'nashville' }
2-^	{ ext => '^', ext_canon => '^', name => '2-^', qual => '-', qual_canon => '-', root => 2, root_canon => 2, root_mod => 0, root_ord => 2, system => 'nashville' }
2-h	{ ext => 'h', ext_canon => 'h', name => '2-h', qual => '-', qual_canon => '-', root => 2, root_canon => 2, root_mod => 0, root_ord => 2, system => 'nashville' }
2-h7	{ ext => 'h7', ext_canon => 'h7', name => '2-h7', qual => '-', qual_canon => '-', root => 2, root_canon => 2, root_mod => 0, root_ord => 2, system => 'nashville' }
2-^7	{ ext => '^7', ext_canon => '^7', name => '2-^7', qual => '-', qual_canon => '-', root => 2, root_canon => 2, root_mod => 0, root_ord => 2, system => 'nashville' }
20	{ ext => '', ext_canon => '', name => 20, qual => 0, qual_canon => 0, root => 2, root_canon => 2, root_mod => 0, root_ord => 2, system => 'nashville' }
207	{ ext => 7, ext_canon => 7, name => 207, qual => 0, qual_canon => 0, root => 2, root_canon => 2, root_mod => 0, root_ord => 2, system => 'nashville' }
20^	{ ext => '^', ext_canon => '^', name => '20^', qual => 0, qual_canon => 0, root => 2, root_canon => 2, root_mod => 0, root_ord => 2, system => 'nashville' }
20h	{ ext => 'h', ext_canon => 'h', name => '20h', qual => 0, qual_canon => 0, root => 2, root_canon => 2, root_mod => 0, root_ord => 2, system => 'nashville' }
20h7	{ ext => 'h7', ext_canon => 'h7', name => '20h7', qual => 0, qual_canon => 0, root => 2, root_canon => 2, root_mod => 0, root_ord => 2, system => 'nashville' }
20^7	{ ext => '^7', ext_canon => '^7', name => '20^7', qual => 0, qual_canon => 0, root => 2, root_canon => 2, root_mod => 0, root_ord => 2, system => 'nashville' }
2+	{ ext => '', ext_canon => '', name => '2+', qual => '+', qual_canon => '+', root => 2, root_canon => 2, root_mod => 0, root_ord => 2, system => 'nashville' }
2+7	{ ext => 7, ext_canon => 7, name => '2+7', qual => '+', qual_canon => '+', root => 2, root_canon => 2, root_mod => 0, root_ord => 2, system => 'nashville' }
2+^	{ ext => '^', ext_canon => '^', name => '2+^', qual => '+', qual_canon => '+', root => 2, root_canon => 2, root_mod => 0, root_ord => 2, system => 'nashville' }
2+h	{ ext => 'h', ext_canon => 'h', name => '2+h', qual => '+', qual_canon => '+', root => 2, root_canon => 2, root_mod => 0, root_ord => 2, system => 'nashville' }
2+h7	{ ext => 'h7', ext_canon => 'h7', name => '2+h7', qual => '+', qual_canon => '+', root => 2, root_canon => 2, root_mod => 0, root_ord => 2, system => 'nashville' }
2+^7	{ ext => '^7', ext_canon => '^7', name => '2+^7', qual => '+', qual_canon => '+', root => 2, root_canon => 2, root_mod => 0, root_ord => 2, system => 'nashville' }
#2	{ ext => '', ext_canon => '', name => '#2', qual => '', qual_canon => '', root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#27	{ ext => 7, ext_canon => 7, name => '#27', qual => '', qual_canon => '', root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#2^	{ ext => '^', ext_canon => '^', name => '#2^', qual => '', qual_canon => '', root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#2h	{ ext => 'h', ext_canon => 'h', name => '#2h', qual => '', qual_canon => '', root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#2h7	{ ext => 'h7', ext_canon => 'h7', name => '#2h7', qual => '', qual_canon => '', root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#2^7	{ ext => '^7', ext_canon => '^7', name => '#2^7', qual => '', qual_canon => '', root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#2-	{ ext => '', ext_canon => '', name => '#2-', qual => '-', qual_canon => '-', root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#2-7	{ ext => 7, ext_canon => 7, name => '#2-7', qual => '-', qual_canon => '-', root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#2-^	{ ext => '^', ext_canon => '^', name => '#2-^', qual => '-', qual_canon => '-', root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#2-h	{ ext => 'h', ext_canon => 'h', name => '#2-h', qual => '-', qual_canon => '-', root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#2-h7	{ ext => 'h7', ext_canon => 'h7', name => '#2-h7', qual => '-', qual_canon => '-', root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#2-^7	{ ext => '^7', ext_canon => '^7', name => '#2-^7', qual => '-', qual_canon => '-', root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#20	{ ext => '', ext_canon => '', name => '#20', qual => 0, qual_canon => 0, root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#207	{ ext => 7, ext_canon => 7, name => '#207', qual => 0, qual_canon => 0, root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#20^	{ ext => '^', ext_canon => '^', name => '#20^', qual => 0, qual_canon => 0, root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#20h	{ ext => 'h', ext_canon => 'h', name => '#20h', qual => 0, qual_canon => 0, root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#20h7	{ ext => 'h7', ext_canon => 'h7', name => '#20h7', qual => 0, qual_canon => 0, root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#20^7	{ ext => '^7', ext_canon => '^7', name => '#20^7', qual => 0, qual_canon => 0, root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#2+	{ ext => '', ext_canon => '', name => '#2+', qual => '+', qual_canon => '+', root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#2+7	{ ext => 7, ext_canon => 7, name => '#2+7', qual => '+', qual_canon => '+', root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#2+^	{ ext => '^', ext_canon => '^', name => '#2+^', qual => '+', qual_canon => '+', root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#2+h	{ ext => 'h', ext_canon => 'h', name => '#2+h', qual => '+', qual_canon => '+', root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#2+h7	{ ext => 'h7', ext_canon => 'h7', name => '#2+h7', qual => '+', qual_canon => '+', root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
#2+^7	{ ext => '^7', ext_canon => '^7', name => '#2+^7', qual => '+', qual_canon => '+', root => 2, root_canon => 2, root_mod => 1, root_ord => 3, system => 'nashville' }
b3	{ ext => '', ext_canon => '', name => 'b3', qual => '', qual_canon => '', root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b37	{ ext => 7, ext_canon => 7, name => 'b37', qual => '', qual_canon => '', root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b3^	{ ext => '^', ext_canon => '^', name => 'b3^', qual => '', qual_canon => '', root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b3h	{ ext => 'h', ext_canon => 'h', name => 'b3h', qual => '', qual_canon => '', root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b3h7	{ ext => 'h7', ext_canon => 'h7', name => 'b3h7', qual => '', qual_canon => '', root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b3^7	{ ext => '^7', ext_canon => '^7', name => 'b3^7', qual => '', qual_canon => '', root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b3-	{ ext => '', ext_canon => '', name => 'b3-', qual => '-', qual_canon => '-', root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b3-7	{ ext => 7, ext_canon => 7, name => 'b3-7', qual => '-', qual_canon => '-', root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b3-^	{ ext => '^', ext_canon => '^', name => 'b3-^', qual => '-', qual_canon => '-', root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b3-h	{ ext => 'h', ext_canon => 'h', name => 'b3-h', qual => '-', qual_canon => '-', root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b3-h7	{ ext => 'h7', ext_canon => 'h7', name => 'b3-h7', qual => '-', qual_canon => '-', root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b3-^7	{ ext => '^7', ext_canon => '^7', name => 'b3-^7', qual => '-', qual_canon => '-', root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b30	{ ext => '', ext_canon => '', name => 'b30', qual => 0, qual_canon => 0, root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b307	{ ext => 7, ext_canon => 7, name => 'b307', qual => 0, qual_canon => 0, root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b30^	{ ext => '^', ext_canon => '^', name => 'b30^', qual => 0, qual_canon => 0, root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b30h	{ ext => 'h', ext_canon => 'h', name => 'b30h', qual => 0, qual_canon => 0, root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b30h7	{ ext => 'h7', ext_canon => 'h7', name => 'b30h7', qual => 0, qual_canon => 0, root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b30^7	{ ext => '^7', ext_canon => '^7', name => 'b30^7', qual => 0, qual_canon => 0, root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b3+	{ ext => '', ext_canon => '', name => 'b3+', qual => '+', qual_canon => '+', root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b3+7	{ ext => 7, ext_canon => 7, name => 'b3+7', qual => '+', qual_canon => '+', root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b3+^	{ ext => '^', ext_canon => '^', name => 'b3+^', qual => '+', qual_canon => '+', root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b3+h	{ ext => 'h', ext_canon => 'h', name => 'b3+h', qual => '+', qual_canon => '+', root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b3+h7	{ ext => 'h7', ext_canon => 'h7', name => 'b3+h7', qual => '+', qual_canon => '+', root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
b3+^7	{ ext => '^7', ext_canon => '^7', name => 'b3+^7', qual => '+', qual_canon => '+', root => 3, root_canon => 3, root_mod => -1, root_ord => 3, system => 'nashville' }
3	{ ext => '', ext_canon => '', name => 3, qual => '', qual_canon => '', root => 3, root_canon => 3, root_mod => 0, root_ord => 4, system => 'nashville' }
37	{ ext => 7, ext_canon => 7, name => 37, qual => '', qual_canon => '', root => 3, root_canon => 3, root_mod => 0, root_ord => 4, system => 'nashville' }
3^	{ ext => '^', ext_canon => '^', name => '3^', qual => '', qual_canon => '', root => 3, root_canon => 3, root_mod => 0, root_ord => 4, system => 'nashville' }
3h	{ ext => 'h', ext_canon => 'h', name => '3h', qual => '', qual_canon => '', root => 3, root_canon => 3, root_mod => 0, root_ord => 4, system => 'nashville' }
3h7	{ ext => 'h7', ext_canon => 'h7', name => '3h7', qual => '', qual_canon => '', root => 3, root_canon => 3, root_mod => 0, root_ord => 4, system => 'nashville' }
3^7	{ ext => '^7', ext_canon => '^7', name => '3^7', qual => '', qual_canon => '', root => 3, root_canon => 3, root_mod => 0, root_ord => 4, system => 'nashville' }
3-	{ ext => '', ext_canon => '', name => '3-', qual => '-', qual_canon => '-', root => 3, root_canon => 3, root_mod => 0, root_ord => 4, system => 'nashville' }
3-7	{ ext => 7, ext_canon => 7, name => '3-7', qual => '-', qual_canon => '-', root => 3, root_canon => 3, root_mod => 0, root_ord => 4, system => 'nashville' }
3-^	{ ext => '^', ext_canon => '^', name => '3-^', qual => '-', qual_canon => '-', root => 3, root_canon => 3, root_mod => 0, root_ord => 4, system => 'nashville' }
3-h	{ ext => 'h', ext_canon => 'h', name => '3-h', qual => '-', qual_canon => '-', root => 3, root_canon => 3, root_mod => 0, root_ord => 4, system => 'nashville' }
3-h7	{ ext => 'h7', ext_canon => 'h7', name => '3-h7', qual => '-', qual_canon => '-', root => 3, root_canon => 3, root_mod => 0, root_ord => 4, system => 'nashville' }
3-^7	{ ext => '^7', ext_canon => '^7', name => '3-^7', qual => '-', qual_canon => '-', root => 3, root_canon => 3, root_mod => 0, root_ord => 4, system => 'nashville' }
30	{ ext => '', ext_canon => '', name => 30, qual => 0, qual_canon => 0, root => 3, root_canon => 3, root_mod => 0, root_ord => 4, system => 'nashville' }
307	{ ext => 7, ext_canon => 7, name => 307, qual => 0, qual_canon => 0, root => 3, root_canon => 3, root_mod => 0, root_ord => 4, system => 'nashville' }
30^	{ ext => '^', ext_canon => '^', name => '30^', qual => 0, qual_canon => 0, root => 3, root_canon => 3, root_mod => 0, root_ord => 4, system => 'nashville' }
30h	{ ext => 'h', ext_canon => 'h', name => '30h', qual => 0, qual_canon => 0, root => 3, root_canon => 3, root_mod => 0, root_ord => 4, system => 'nashville' }
30h7	{ ext => 'h7', ext_canon => 'h7', name => '30h7', qual => 0, qual_canon => 0, root => 3, root_canon => 3, root_mod => 0, root_ord => 4, system => 'nashville' }
30^7	{ ext => '^7', ext_canon => '^7', name => '30^7', qual => 0, qual_canon => 0, root => 3, root_canon => 3, root_mod => 0, root_ord => 4, system => 'nashville' }
3+	{ ext => '', ext_canon => '', name => '3+', qual => '+', qual_canon => '+', root => 3, root_canon => 3, root_mod => 0, root_ord => 4, system => 'nashville' }
3+7	{ ext => 7, ext_canon => 7, name => '3+7', qual => '+', qual_canon => '+', root => 3, root_canon => 3, root_mod => 0, root_ord => 4, system => 'nashville' }
3+^	{ ext => '^', ext_canon => '^', name => '3+^', qual => '+', qual_canon => '+', root => 3, root_canon => 3, root_mod => 0, root_ord => 4, system => 'nashville' }
3+h	{ ext => 'h', ext_canon => 'h', name => '3+h', qual => '+', qual_canon => '+', root => 3, root_canon => 3, root_mod => 0, root_ord => 4, system => 'nashville' }
3+h7	{ ext => 'h7', ext_canon => 'h7', name => '3+h7', qual => '+', qual_canon => '+', root => 3, root_canon => 3, root_mod => 0, root_ord => 4, system => 'nashville' }
3+^7	{ ext => '^7', ext_canon => '^7', name => '3+^7', qual => '+', qual_canon => '+', root => 3, root_canon => 3, root_mod => 0, root_ord => 4, system => 'nashville' }
4	{ ext => '', ext_canon => '', name => 4, qual => '', qual_canon => '', root => 4, root_canon => 4, root_mod => 0, root_ord => 5, system => 'nashville' }
47	{ ext => 7, ext_canon => 7, name => 47, qual => '', qual_canon => '', root => 4, root_canon => 4, root_mod => 0, root_ord => 5, system => 'nashville' }
4^	{ ext => '^', ext_canon => '^', name => '4^', qual => '', qual_canon => '', root => 4, root_canon => 4, root_mod => 0, root_ord => 5, system => 'nashville' }
4h	{ ext => 'h', ext_canon => 'h', name => '4h', qual => '', qual_canon => '', root => 4, root_canon => 4, root_mod => 0, root_ord => 5, system => 'nashville' }
4h7	{ ext => 'h7', ext_canon => 'h7', name => '4h7', qual => '', qual_canon => '', root => 4, root_canon => 4, root_mod => 0, root_ord => 5, system => 'nashville' }
4^7	{ ext => '^7', ext_canon => '^7', name => '4^7', qual => '', qual_canon => '', root => 4, root_canon => 4, root_mod => 0, root_ord => 5, system => 'nashville' }
4-	{ ext => '', ext_canon => '', name => '4-', qual => '-', qual_canon => '-', root => 4, root_canon => 4, root_mod => 0, root_ord => 5, system => 'nashville' }
4-7	{ ext => 7, ext_canon => 7, name => '4-7', qual => '-', qual_canon => '-', root => 4, root_canon => 4, root_mod => 0, root_ord => 5, system => 'nashville' }
4-^	{ ext => '^', ext_canon => '^', name => '4-^', qual => '-', qual_canon => '-', root => 4, root_canon => 4, root_mod => 0, root_ord => 5, system => 'nashville' }
4-h	{ ext => 'h', ext_canon => 'h', name => '4-h', qual => '-', qual_canon => '-', root => 4, root_canon => 4, root_mod => 0, root_ord => 5, system => 'nashville' }
4-h7	{ ext => 'h7', ext_canon => 'h7', name => '4-h7', qual => '-', qual_canon => '-', root => 4, root_canon => 4, root_mod => 0, root_ord => 5, system => 'nashville' }
4-^7	{ ext => '^7', ext_canon => '^7', name => '4-^7', qual => '-', qual_canon => '-', root => 4, root_canon => 4, root_mod => 0, root_ord => 5, system => 'nashville' }
40	{ ext => '', ext_canon => '', name => 40, qual => 0, qual_canon => 0, root => 4, root_canon => 4, root_mod => 0, root_ord => 5, system => 'nashville' }
407	{ ext => 7, ext_canon => 7, name => 407, qual => 0, qual_canon => 0, root => 4, root_canon => 4, root_mod => 0, root_ord => 5, system => 'nashville' }
40^	{ ext => '^', ext_canon => '^', name => '40^', qual => 0, qual_canon => 0, root => 4, root_canon => 4, root_mod => 0, root_ord => 5, system => 'nashville' }
40h	{ ext => 'h', ext_canon => 'h', name => '40h', qual => 0, qual_canon => 0, root => 4, root_canon => 4, root_mod => 0, root_ord => 5, system => 'nashville' }
40h7	{ ext => 'h7', ext_canon => 'h7', name => '40h7', qual => 0, qual_canon => 0, root => 4, root_canon => 4, root_mod => 0, root_ord => 5, system => 'nashville' }
40^7	{ ext => '^7', ext_canon => '^7', name => '40^7', qual => 0, qual_canon => 0, root => 4, root_canon => 4, root_mod => 0, root_ord => 5, system => 'nashville' }
4+	{ ext => '', ext_canon => '', name => '4+', qual => '+', qual_canon => '+', root => 4, root_canon => 4, root_mod => 0, root_ord => 5, system => 'nashville' }
4+7	{ ext => 7, ext_canon => 7, name => '4+7', qual => '+', qual_canon => '+', root => 4, root_canon => 4, root_mod => 0, root_ord => 5, system => 'nashville' }
4+^	{ ext => '^', ext_canon => '^', name => '4+^', qual => '+', qual_canon => '+', root => 4, root_canon => 4, root_mod => 0, root_ord => 5, system => 'nashville' }
4+h	{ ext => 'h', ext_canon => 'h', name => '4+h', qual => '+', qual_canon => '+', root => 4, root_canon => 4, root_mod => 0, root_ord => 5, system => 'nashville' }
4+h7	{ ext => 'h7', ext_canon => 'h7', name => '4+h7', qual => '+', qual_canon => '+', root => 4, root_canon => 4, root_mod => 0, root_ord => 5, system => 'nashville' }
4+^7	{ ext => '^7', ext_canon => '^7', name => '4+^7', qual => '+', qual_canon => '+', root => 4, root_canon => 4, root_mod => 0, root_ord => 5, system => 'nashville' }
#4	{ ext => '', ext_canon => '', name => '#4', qual => '', qual_canon => '', root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#47	{ ext => 7, ext_canon => 7, name => '#47', qual => '', qual_canon => '', root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#4^	{ ext => '^', ext_canon => '^', name => '#4^', qual => '', qual_canon => '', root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#4h	{ ext => 'h', ext_canon => 'h', name => '#4h', qual => '', qual_canon => '', root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#4h7	{ ext => 'h7', ext_canon => 'h7', name => '#4h7', qual => '', qual_canon => '', root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#4^7	{ ext => '^7', ext_canon => '^7', name => '#4^7', qual => '', qual_canon => '', root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#4-	{ ext => '', ext_canon => '', name => '#4-', qual => '-', qual_canon => '-', root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#4-7	{ ext => 7, ext_canon => 7, name => '#4-7', qual => '-', qual_canon => '-', root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#4-^	{ ext => '^', ext_canon => '^', name => '#4-^', qual => '-', qual_canon => '-', root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#4-h	{ ext => 'h', ext_canon => 'h', name => '#4-h', qual => '-', qual_canon => '-', root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#4-h7	{ ext => 'h7', ext_canon => 'h7', name => '#4-h7', qual => '-', qual_canon => '-', root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#4-^7	{ ext => '^7', ext_canon => '^7', name => '#4-^7', qual => '-', qual_canon => '-', root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#40	{ ext => '', ext_canon => '', name => '#40', qual => 0, qual_canon => 0, root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#407	{ ext => 7, ext_canon => 7, name => '#407', qual => 0, qual_canon => 0, root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#40^	{ ext => '^', ext_canon => '^', name => '#40^', qual => 0, qual_canon => 0, root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#40h	{ ext => 'h', ext_canon => 'h', name => '#40h', qual => 0, qual_canon => 0, root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#40h7	{ ext => 'h7', ext_canon => 'h7', name => '#40h7', qual => 0, qual_canon => 0, root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#40^7	{ ext => '^7', ext_canon => '^7', name => '#40^7', qual => 0, qual_canon => 0, root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#4+	{ ext => '', ext_canon => '', name => '#4+', qual => '+', qual_canon => '+', root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#4+7	{ ext => 7, ext_canon => 7, name => '#4+7', qual => '+', qual_canon => '+', root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#4+^	{ ext => '^', ext_canon => '^', name => '#4+^', qual => '+', qual_canon => '+', root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#4+h	{ ext => 'h', ext_canon => 'h', name => '#4+h', qual => '+', qual_canon => '+', root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#4+h7	{ ext => 'h7', ext_canon => 'h7', name => '#4+h7', qual => '+', qual_canon => '+', root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
#4+^7	{ ext => '^7', ext_canon => '^7', name => '#4+^7', qual => '+', qual_canon => '+', root => 4, root_canon => 4, root_mod => 1, root_ord => 6, system => 'nashville' }
b5	{ ext => '', ext_canon => '', name => 'b5', qual => '', qual_canon => '', root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b57	{ ext => 7, ext_canon => 7, name => 'b57', qual => '', qual_canon => '', root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b5^	{ ext => '^', ext_canon => '^', name => 'b5^', qual => '', qual_canon => '', root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b5h	{ ext => 'h', ext_canon => 'h', name => 'b5h', qual => '', qual_canon => '', root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b5h7	{ ext => 'h7', ext_canon => 'h7', name => 'b5h7', qual => '', qual_canon => '', root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b5^7	{ ext => '^7', ext_canon => '^7', name => 'b5^7', qual => '', qual_canon => '', root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b5-	{ ext => '', ext_canon => '', name => 'b5-', qual => '-', qual_canon => '-', root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b5-7	{ ext => 7, ext_canon => 7, name => 'b5-7', qual => '-', qual_canon => '-', root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b5-^	{ ext => '^', ext_canon => '^', name => 'b5-^', qual => '-', qual_canon => '-', root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b5-h	{ ext => 'h', ext_canon => 'h', name => 'b5-h', qual => '-', qual_canon => '-', root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b5-h7	{ ext => 'h7', ext_canon => 'h7', name => 'b5-h7', qual => '-', qual_canon => '-', root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b5-^7	{ ext => '^7', ext_canon => '^7', name => 'b5-^7', qual => '-', qual_canon => '-', root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b50	{ ext => '', ext_canon => '', name => 'b50', qual => 0, qual_canon => 0, root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b507	{ ext => 7, ext_canon => 7, name => 'b507', qual => 0, qual_canon => 0, root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b50^	{ ext => '^', ext_canon => '^', name => 'b50^', qual => 0, qual_canon => 0, root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b50h	{ ext => 'h', ext_canon => 'h', name => 'b50h', qual => 0, qual_canon => 0, root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b50h7	{ ext => 'h7', ext_canon => 'h7', name => 'b50h7', qual => 0, qual_canon => 0, root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b50^7	{ ext => '^7', ext_canon => '^7', name => 'b50^7', qual => 0, qual_canon => 0, root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b5+	{ ext => '', ext_canon => '', name => 'b5+', qual => '+', qual_canon => '+', root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b5+7	{ ext => 7, ext_canon => 7, name => 'b5+7', qual => '+', qual_canon => '+', root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b5+^	{ ext => '^', ext_canon => '^', name => 'b5+^', qual => '+', qual_canon => '+', root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b5+h	{ ext => 'h', ext_canon => 'h', name => 'b5+h', qual => '+', qual_canon => '+', root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b5+h7	{ ext => 'h7', ext_canon => 'h7', name => 'b5+h7', qual => '+', qual_canon => '+', root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
b5+^7	{ ext => '^7', ext_canon => '^7', name => 'b5+^7', qual => '+', qual_canon => '+', root => 5, root_canon => 5, root_mod => -1, root_ord => 6, system => 'nashville' }
5	{ ext => '', ext_canon => '', name => 5, qual => '', qual_canon => '', root => 5, root_canon => 5, root_mod => 0, root_ord => 7, system => 'nashville' }
57	{ ext => 7, ext_canon => 7, name => 57, qual => '', qual_canon => '', root => 5, root_canon => 5, root_mod => 0, root_ord => 7, system => 'nashville' }
5^	{ ext => '^', ext_canon => '^', name => '5^', qual => '', qual_canon => '', root => 5, root_canon => 5, root_mod => 0, root_ord => 7, system => 'nashville' }
5h	{ ext => 'h', ext_canon => 'h', name => '5h', qual => '', qual_canon => '', root => 5, root_canon => 5, root_mod => 0, root_ord => 7, system => 'nashville' }
5h7	{ ext => 'h7', ext_canon => 'h7', name => '5h7', qual => '', qual_canon => '', root => 5, root_canon => 5, root_mod => 0, root_ord => 7, system => 'nashville' }
5^7	{ ext => '^7', ext_canon => '^7', name => '5^7', qual => '', qual_canon => '', root => 5, root_canon => 5, root_mod => 0, root_ord => 7, system => 'nashville' }
5-	{ ext => '', ext_canon => '', name => '5-', qual => '-', qual_canon => '-', root => 5, root_canon => 5, root_mod => 0, root_ord => 7, system => 'nashville' }
5-7	{ ext => 7, ext_canon => 7, name => '5-7', qual => '-', qual_canon => '-', root => 5, root_canon => 5, root_mod => 0, root_ord => 7, system => 'nashville' }
5-^	{ ext => '^', ext_canon => '^', name => '5-^', qual => '-', qual_canon => '-', root => 5, root_canon => 5, root_mod => 0, root_ord => 7, system => 'nashville' }
5-h	{ ext => 'h', ext_canon => 'h', name => '5-h', qual => '-', qual_canon => '-', root => 5, root_canon => 5, root_mod => 0, root_ord => 7, system => 'nashville' }
5-h7	{ ext => 'h7', ext_canon => 'h7', name => '5-h7', qual => '-', qual_canon => '-', root => 5, root_canon => 5, root_mod => 0, root_ord => 7, system => 'nashville' }
5-^7	{ ext => '^7', ext_canon => '^7', name => '5-^7', qual => '-', qual_canon => '-', root => 5, root_canon => 5, root_mod => 0, root_ord => 7, system => 'nashville' }
50	{ ext => '', ext_canon => '', name => 50, qual => 0, qual_canon => 0, root => 5, root_canon => 5, root_mod => 0, root_ord => 7, system => 'nashville' }
507	{ ext => 7, ext_canon => 7, name => 507, qual => 0, qual_canon => 0, root => 5, root_canon => 5, root_mod => 0, root_ord => 7, system => 'nashville' }
50^	{ ext => '^', ext_canon => '^', name => '50^', qual => 0, qual_canon => 0, root => 5, root_canon => 5, root_mod => 0, root_ord => 7, system => 'nashville' }
50h	{ ext => 'h', ext_canon => 'h', name => '50h', qual => 0, qual_canon => 0, root => 5, root_canon => 5, root_mod => 0, root_ord => 7, system => 'nashville' }
50h7	{ ext => 'h7', ext_canon => 'h7', name => '50h7', qual => 0, qual_canon => 0, root => 5, root_canon => 5, root_mod => 0, root_ord => 7, system => 'nashville' }
50^7	{ ext => '^7', ext_canon => '^7', name => '50^7', qual => 0, qual_canon => 0, root => 5, root_canon => 5, root_mod => 0, root_ord => 7, system => 'nashville' }
5+	{ ext => '', ext_canon => '', name => '5+', qual => '+', qual_canon => '+', root => 5, root_canon => 5, root_mod => 0, root_ord => 7, system => 'nashville' }
5+7	{ ext => 7, ext_canon => 7, name => '5+7', qual => '+', qual_canon => '+', root => 5, root_canon => 5, root_mod => 0, root_ord => 7, system => 'nashville' }
5+^	{ ext => '^', ext_canon => '^', name => '5+^', qual => '+', qual_canon => '+', root => 5, root_canon => 5, root_mod => 0, root_ord => 7, system => 'nashville' }
5+h	{ ext => 'h', ext_canon => 'h', name => '5+h', qual => '+', qual_canon => '+', root => 5, root_canon => 5, root_mod => 0, root_ord => 7, system => 'nashville' }
5+h7	{ ext => 'h7', ext_canon => 'h7', name => '5+h7', qual => '+', qual_canon => '+', root => 5, root_canon => 5, root_mod => 0, root_ord => 7, system => 'nashville' }
5+^7	{ ext => '^7', ext_canon => '^7', name => '5+^7', qual => '+', qual_canon => '+', root => 5, root_canon => 5, root_mod => 0, root_ord => 7, system => 'nashville' }
#5	{ ext => '', ext_canon => '', name => '#5', qual => '', qual_canon => '', root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#57	{ ext => 7, ext_canon => 7, name => '#57', qual => '', qual_canon => '', root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#5^	{ ext => '^', ext_canon => '^', name => '#5^', qual => '', qual_canon => '', root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#5h	{ ext => 'h', ext_canon => 'h', name => '#5h', qual => '', qual_canon => '', root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#5h7	{ ext => 'h7', ext_canon => 'h7', name => '#5h7', qual => '', qual_canon => '', root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#5^7	{ ext => '^7', ext_canon => '^7', name => '#5^7', qual => '', qual_canon => '', root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#5-	{ ext => '', ext_canon => '', name => '#5-', qual => '-', qual_canon => '-', root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#5-7	{ ext => 7, ext_canon => 7, name => '#5-7', qual => '-', qual_canon => '-', root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#5-^	{ ext => '^', ext_canon => '^', name => '#5-^', qual => '-', qual_canon => '-', root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#5-h	{ ext => 'h', ext_canon => 'h', name => '#5-h', qual => '-', qual_canon => '-', root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#5-h7	{ ext => 'h7', ext_canon => 'h7', name => '#5-h7', qual => '-', qual_canon => '-', root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#5-^7	{ ext => '^7', ext_canon => '^7', name => '#5-^7', qual => '-', qual_canon => '-', root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#50	{ ext => '', ext_canon => '', name => '#50', qual => 0, qual_canon => 0, root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#507	{ ext => 7, ext_canon => 7, name => '#507', qual => 0, qual_canon => 0, root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#50^	{ ext => '^', ext_canon => '^', name => '#50^', qual => 0, qual_canon => 0, root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#50h	{ ext => 'h', ext_canon => 'h', name => '#50h', qual => 0, qual_canon => 0, root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#50h7	{ ext => 'h7', ext_canon => 'h7', name => '#50h7', qual => 0, qual_canon => 0, root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#50^7	{ ext => '^7', ext_canon => '^7', name => '#50^7', qual => 0, qual_canon => 0, root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#5+	{ ext => '', ext_canon => '', name => '#5+', qual => '+', qual_canon => '+', root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#5+7	{ ext => 7, ext_canon => 7, name => '#5+7', qual => '+', qual_canon => '+', root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#5+^	{ ext => '^', ext_canon => '^', name => '#5+^', qual => '+', qual_canon => '+', root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#5+h	{ ext => 'h', ext_canon => 'h', name => '#5+h', qual => '+', qual_canon => '+', root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#5+h7	{ ext => 'h7', ext_canon => 'h7', name => '#5+h7', qual => '+', qual_canon => '+', root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
#5+^7	{ ext => '^7', ext_canon => '^7', name => '#5+^7', qual => '+', qual_canon => '+', root => 5, root_canon => 5, root_mod => 1, root_ord => 8, system => 'nashville' }
b6	{ ext => '', ext_canon => '', name => 'b6', qual => '', qual_canon => '', root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b67	{ ext => 7, ext_canon => 7, name => 'b67', qual => '', qual_canon => '', root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b6^	{ ext => '^', ext_canon => '^', name => 'b6^', qual => '', qual_canon => '', root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b6h	{ ext => 'h', ext_canon => 'h', name => 'b6h', qual => '', qual_canon => '', root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b6h7	{ ext => 'h7', ext_canon => 'h7', name => 'b6h7', qual => '', qual_canon => '', root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b6^7	{ ext => '^7', ext_canon => '^7', name => 'b6^7', qual => '', qual_canon => '', root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b6-	{ ext => '', ext_canon => '', name => 'b6-', qual => '-', qual_canon => '-', root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b6-7	{ ext => 7, ext_canon => 7, name => 'b6-7', qual => '-', qual_canon => '-', root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b6-^	{ ext => '^', ext_canon => '^', name => 'b6-^', qual => '-', qual_canon => '-', root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b6-h	{ ext => 'h', ext_canon => 'h', name => 'b6-h', qual => '-', qual_canon => '-', root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b6-h7	{ ext => 'h7', ext_canon => 'h7', name => 'b6-h7', qual => '-', qual_canon => '-', root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b6-^7	{ ext => '^7', ext_canon => '^7', name => 'b6-^7', qual => '-', qual_canon => '-', root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b60	{ ext => '', ext_canon => '', name => 'b60', qual => 0, qual_canon => 0, root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b607	{ ext => 7, ext_canon => 7, name => 'b607', qual => 0, qual_canon => 0, root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b60^	{ ext => '^', ext_canon => '^', name => 'b60^', qual => 0, qual_canon => 0, root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b60h	{ ext => 'h', ext_canon => 'h', name => 'b60h', qual => 0, qual_canon => 0, root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b60h7	{ ext => 'h7', ext_canon => 'h7', name => 'b60h7', qual => 0, qual_canon => 0, root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b60^7	{ ext => '^7', ext_canon => '^7', name => 'b60^7', qual => 0, qual_canon => 0, root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b6+	{ ext => '', ext_canon => '', name => 'b6+', qual => '+', qual_canon => '+', root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b6+7	{ ext => 7, ext_canon => 7, name => 'b6+7', qual => '+', qual_canon => '+', root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b6+^	{ ext => '^', ext_canon => '^', name => 'b6+^', qual => '+', qual_canon => '+', root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b6+h	{ ext => 'h', ext_canon => 'h', name => 'b6+h', qual => '+', qual_canon => '+', root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b6+h7	{ ext => 'h7', ext_canon => 'h7', name => 'b6+h7', qual => '+', qual_canon => '+', root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
b6+^7	{ ext => '^7', ext_canon => '^7', name => 'b6+^7', qual => '+', qual_canon => '+', root => 6, root_canon => 6, root_mod => -1, root_ord => 8, system => 'nashville' }
6	{ ext => '', ext_canon => '', name => 6, qual => '', qual_canon => '', root => 6, root_canon => 6, root_mod => 0, root_ord => 9, system => 'nashville' }
67	{ ext => 7, ext_canon => 7, name => 67, qual => '', qual_canon => '', root => 6, root_canon => 6, root_mod => 0, root_ord => 9, system => 'nashville' }
6^	{ ext => '^', ext_canon => '^', name => '6^', qual => '', qual_canon => '', root => 6, root_canon => 6, root_mod => 0, root_ord => 9, system => 'nashville' }
6h	{ ext => 'h', ext_canon => 'h', name => '6h', qual => '', qual_canon => '', root => 6, root_canon => 6, root_mod => 0, root_ord => 9, system => 'nashville' }
6h7	{ ext => 'h7', ext_canon => 'h7', name => '6h7', qual => '', qual_canon => '', root => 6, root_canon => 6, root_mod => 0, root_ord => 9, system => 'nashville' }
6^7	{ ext => '^7', ext_canon => '^7', name => '6^7', qual => '', qual_canon => '', root => 6, root_canon => 6, root_mod => 0, root_ord => 9, system => 'nashville' }
6-	{ ext => '', ext_canon => '', name => '6-', qual => '-', qual_canon => '-', root => 6, root_canon => 6, root_mod => 0, root_ord => 9, system => 'nashville' }
6-7	{ ext => 7, ext_canon => 7, name => '6-7', qual => '-', qual_canon => '-', root => 6, root_canon => 6, root_mod => 0, root_ord => 9, system => 'nashville' }
6-^	{ ext => '^', ext_canon => '^', name => '6-^', qual => '-', qual_canon => '-', root => 6, root_canon => 6, root_mod => 0, root_ord => 9, system => 'nashville' }
6-h	{ ext => 'h', ext_canon => 'h', name => '6-h', qual => '-', qual_canon => '-', root => 6, root_canon => 6, root_mod => 0, root_ord => 9, system => 'nashville' }
6-h7	{ ext => 'h7', ext_canon => 'h7', name => '6-h7', qual => '-', qual_canon => '-', root => 6, root_canon => 6, root_mod => 0, root_ord => 9, system => 'nashville' }
6-^7	{ ext => '^7', ext_canon => '^7', name => '6-^7', qual => '-', qual_canon => '-', root => 6, root_canon => 6, root_mod => 0, root_ord => 9, system => 'nashville' }
60	{ ext => '', ext_canon => '', name => 60, qual => 0, qual_canon => 0, root => 6, root_canon => 6, root_mod => 0, root_ord => 9, system => 'nashville' }
607	{ ext => 7, ext_canon => 7, name => 607, qual => 0, qual_canon => 0, root => 6, root_canon => 6, root_mod => 0, root_ord => 9, system => 'nashville' }
60^	{ ext => '^', ext_canon => '^', name => '60^', qual => 0, qual_canon => 0, root => 6, root_canon => 6, root_mod => 0, root_ord => 9, system => 'nashville' }
60h	{ ext => 'h', ext_canon => 'h', name => '60h', qual => 0, qual_canon => 0, root => 6, root_canon => 6, root_mod => 0, root_ord => 9, system => 'nashville' }
60h7	{ ext => 'h7', ext_canon => 'h7', name => '60h7', qual => 0, qual_canon => 0, root => 6, root_canon => 6, root_mod => 0, root_ord => 9, system => 'nashville' }
60^7	{ ext => '^7', ext_canon => '^7', name => '60^7', qual => 0, qual_canon => 0, root => 6, root_canon => 6, root_mod => 0, root_ord => 9, system => 'nashville' }
6+	{ ext => '', ext_canon => '', name => '6+', qual => '+', qual_canon => '+', root => 6, root_canon => 6, root_mod => 0, root_ord => 9, system => 'nashville' }
6+7	{ ext => 7, ext_canon => 7, name => '6+7', qual => '+', qual_canon => '+', root => 6, root_canon => 6, root_mod => 0, root_ord => 9, system => 'nashville' }
6+^	{ ext => '^', ext_canon => '^', name => '6+^', qual => '+', qual_canon => '+', root => 6, root_canon => 6, root_mod => 0, root_ord => 9, system => 'nashville' }
6+h	{ ext => 'h', ext_canon => 'h', name => '6+h', qual => '+', qual_canon => '+', root => 6, root_canon => 6, root_mod => 0, root_ord => 9, system => 'nashville' }
6+h7	{ ext => 'h7', ext_canon => 'h7', name => '6+h7', qual => '+', qual_canon => '+', root => 6, root_canon => 6, root_mod => 0, root_ord => 9, system => 'nashville' }
6+^7	{ ext => '^7', ext_canon => '^7', name => '6+^7', qual => '+', qual_canon => '+', root => 6, root_canon => 6, root_mod => 0, root_ord => 9, system => 'nashville' }
#6	{ ext => '', ext_canon => '', name => '#6', qual => '', qual_canon => '', root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#67	{ ext => 7, ext_canon => 7, name => '#67', qual => '', qual_canon => '', root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#6^	{ ext => '^', ext_canon => '^', name => '#6^', qual => '', qual_canon => '', root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#6h	{ ext => 'h', ext_canon => 'h', name => '#6h', qual => '', qual_canon => '', root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#6h7	{ ext => 'h7', ext_canon => 'h7', name => '#6h7', qual => '', qual_canon => '', root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#6^7	{ ext => '^7', ext_canon => '^7', name => '#6^7', qual => '', qual_canon => '', root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#6-	{ ext => '', ext_canon => '', name => '#6-', qual => '-', qual_canon => '-', root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#6-7	{ ext => 7, ext_canon => 7, name => '#6-7', qual => '-', qual_canon => '-', root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#6-^	{ ext => '^', ext_canon => '^', name => '#6-^', qual => '-', qual_canon => '-', root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#6-h	{ ext => 'h', ext_canon => 'h', name => '#6-h', qual => '-', qual_canon => '-', root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#6-h7	{ ext => 'h7', ext_canon => 'h7', name => '#6-h7', qual => '-', qual_canon => '-', root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#6-^7	{ ext => '^7', ext_canon => '^7', name => '#6-^7', qual => '-', qual_canon => '-', root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#60	{ ext => '', ext_canon => '', name => '#60', qual => 0, qual_canon => 0, root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#607	{ ext => 7, ext_canon => 7, name => '#607', qual => 0, qual_canon => 0, root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#60^	{ ext => '^', ext_canon => '^', name => '#60^', qual => 0, qual_canon => 0, root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#60h	{ ext => 'h', ext_canon => 'h', name => '#60h', qual => 0, qual_canon => 0, root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#60h7	{ ext => 'h7', ext_canon => 'h7', name => '#60h7', qual => 0, qual_canon => 0, root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#60^7	{ ext => '^7', ext_canon => '^7', name => '#60^7', qual => 0, qual_canon => 0, root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#6+	{ ext => '', ext_canon => '', name => '#6+', qual => '+', qual_canon => '+', root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#6+7	{ ext => 7, ext_canon => 7, name => '#6+7', qual => '+', qual_canon => '+', root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#6+^	{ ext => '^', ext_canon => '^', name => '#6+^', qual => '+', qual_canon => '+', root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#6+h	{ ext => 'h', ext_canon => 'h', name => '#6+h', qual => '+', qual_canon => '+', root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#6+h7	{ ext => 'h7', ext_canon => 'h7', name => '#6+h7', qual => '+', qual_canon => '+', root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
#6+^7	{ ext => '^7', ext_canon => '^7', name => '#6+^7', qual => '+', qual_canon => '+', root => 6, root_canon => 6, root_mod => 1, root_ord => 10, system => 'nashville' }
b7	{ ext => '', ext_canon => '', name => 'b7', qual => '', qual_canon => '', root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b77	{ ext => 7, ext_canon => 7, name => 'b77', qual => '', qual_canon => '', root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b7^	{ ext => '^', ext_canon => '^', name => 'b7^', qual => '', qual_canon => '', root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b7h	{ ext => 'h', ext_canon => 'h', name => 'b7h', qual => '', qual_canon => '', root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b7h7	{ ext => 'h7', ext_canon => 'h7', name => 'b7h7', qual => '', qual_canon => '', root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b7^7	{ ext => '^7', ext_canon => '^7', name => 'b7^7', qual => '', qual_canon => '', root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b7-	{ ext => '', ext_canon => '', name => 'b7-', qual => '-', qual_canon => '-', root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b7-7	{ ext => 7, ext_canon => 7, name => 'b7-7', qual => '-', qual_canon => '-', root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b7-^	{ ext => '^', ext_canon => '^', name => 'b7-^', qual => '-', qual_canon => '-', root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b7-h	{ ext => 'h', ext_canon => 'h', name => 'b7-h', qual => '-', qual_canon => '-', root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b7-h7	{ ext => 'h7', ext_canon => 'h7', name => 'b7-h7', qual => '-', qual_canon => '-', root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b7-^7	{ ext => '^7', ext_canon => '^7', name => 'b7-^7', qual => '-', qual_canon => '-', root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b70	{ ext => '', ext_canon => '', name => 'b70', qual => 0, qual_canon => 0, root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b707	{ ext => 7, ext_canon => 7, name => 'b707', qual => 0, qual_canon => 0, root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b70^	{ ext => '^', ext_canon => '^', name => 'b70^', qual => 0, qual_canon => 0, root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b70h	{ ext => 'h', ext_canon => 'h', name => 'b70h', qual => 0, qual_canon => 0, root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b70h7	{ ext => 'h7', ext_canon => 'h7', name => 'b70h7', qual => 0, qual_canon => 0, root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b70^7	{ ext => '^7', ext_canon => '^7', name => 'b70^7', qual => 0, qual_canon => 0, root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b7+	{ ext => '', ext_canon => '', name => 'b7+', qual => '+', qual_canon => '+', root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b7+7	{ ext => 7, ext_canon => 7, name => 'b7+7', qual => '+', qual_canon => '+', root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b7+^	{ ext => '^', ext_canon => '^', name => 'b7+^', qual => '+', qual_canon => '+', root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b7+h	{ ext => 'h', ext_canon => 'h', name => 'b7+h', qual => '+', qual_canon => '+', root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b7+h7	{ ext => 'h7', ext_canon => 'h7', name => 'b7+h7', qual => '+', qual_canon => '+', root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
b7+^7	{ ext => '^7', ext_canon => '^7', name => 'b7+^7', qual => '+', qual_canon => '+', root => 7, root_canon => 7, root_mod => -1, root_ord => 10, system => 'nashville' }
7	{ ext => '', ext_canon => '', name => 7, qual => '', qual_canon => '', root => 7, root_canon => 7, root_mod => 0, root_ord => 11, system => 'nashville' }
77	{ ext => 7, ext_canon => 7, name => 77, qual => '', qual_canon => '', root => 7, root_canon => 7, root_mod => 0, root_ord => 11, system => 'nashville' }
7^	{ ext => '^', ext_canon => '^', name => '7^', qual => '', qual_canon => '', root => 7, root_canon => 7, root_mod => 0, root_ord => 11, system => 'nashville' }
7h	{ ext => 'h', ext_canon => 'h', name => '7h', qual => '', qual_canon => '', root => 7, root_canon => 7, root_mod => 0, root_ord => 11, system => 'nashville' }
7h7	{ ext => 'h7', ext_canon => 'h7', name => '7h7', qual => '', qual_canon => '', root => 7, root_canon => 7, root_mod => 0, root_ord => 11, system => 'nashville' }
7^7	{ ext => '^7', ext_canon => '^7', name => '7^7', qual => '', qual_canon => '', root => 7, root_canon => 7, root_mod => 0, root_ord => 11, system => 'nashville' }
7-	{ ext => '', ext_canon => '', name => '7-', qual => '-', qual_canon => '-', root => 7, root_canon => 7, root_mod => 0, root_ord => 11, system => 'nashville' }
7-7	{ ext => 7, ext_canon => 7, name => '7-7', qual => '-', qual_canon => '-', root => 7, root_canon => 7, root_mod => 0, root_ord => 11, system => 'nashville' }
7-^	{ ext => '^', ext_canon => '^', name => '7-^', qual => '-', qual_canon => '-', root => 7, root_canon => 7, root_mod => 0, root_ord => 11, system => 'nashville' }
7-h	{ ext => 'h', ext_canon => 'h', name => '7-h', qual => '-', qual_canon => '-', root => 7, root_canon => 7, root_mod => 0, root_ord => 11, system => 'nashville' }
7-h7	{ ext => 'h7', ext_canon => 'h7', name => '7-h7', qual => '-', qual_canon => '-', root => 7, root_canon => 7, root_mod => 0, root_ord => 11, system => 'nashville' }
7-^7	{ ext => '^7', ext_canon => '^7', name => '7-^7', qual => '-', qual_canon => '-', root => 7, root_canon => 7, root_mod => 0, root_ord => 11, system => 'nashville' }
70	{ ext => '', ext_canon => '', name => 70, qual => 0, qual_canon => 0, root => 7, root_canon => 7, root_mod => 0, root_ord => 11, system => 'nashville' }
707	{ ext => 7, ext_canon => 7, name => 707, qual => 0, qual_canon => 0, root => 7, root_canon => 7, root_mod => 0, root_ord => 11, system => 'nashville' }
70^	{ ext => '^', ext_canon => '^', name => '70^', qual => 0, qual_canon => 0, root => 7, root_canon => 7, root_mod => 0, root_ord => 11, system => 'nashville' }
70h	{ ext => 'h', ext_canon => 'h', name => '70h', qual => 0, qual_canon => 0, root => 7, root_canon => 7, root_mod => 0, root_ord => 11, system => 'nashville' }
70h7	{ ext => 'h7', ext_canon => 'h7', name => '70h7', qual => 0, qual_canon => 0, root => 7, root_canon => 7, root_mod => 0, root_ord => 11, system => 'nashville' }
70^7	{ ext => '^7', ext_canon => '^7', name => '70^7', qual => 0, qual_canon => 0, root => 7, root_canon => 7, root_mod => 0, root_ord => 11, system => 'nashville' }
7+	{ ext => '', ext_canon => '', name => '7+', qual => '+', qual_canon => '+', root => 7, root_canon => 7, root_mod => 0, root_ord => 11, system => 'nashville' }
7+7	{ ext => 7, ext_canon => 7, name => '7+7', qual => '+', qual_canon => '+', root => 7, root_canon => 7, root_mod => 0, root_ord => 11, system => 'nashville' }
7+^	{ ext => '^', ext_canon => '^', name => '7+^', qual => '+', qual_canon => '+', root => 7, root_canon => 7, root_mod => 0, root_ord => 11, system => 'nashville' }
7+h	{ ext => 'h', ext_canon => 'h', name => '7+h', qual => '+', qual_canon => '+', root => 7, root_canon => 7, root_mod => 0, root_ord => 11, system => 'nashville' }
7+h7	{ ext => 'h7', ext_canon => 'h7', name => '7+h7', qual => '+', qual_canon => '+', root => 7, root_canon => 7, root_mod => 0, root_ord => 11, system => 'nashville' }
7+^7	{ ext => '^7', ext_canon => '^7', name => '7+^7', qual => '+', qual_canon => '+', root => 7, root_canon => 7, root_mod => 0, root_ord => 11, system => 'nashville' }
