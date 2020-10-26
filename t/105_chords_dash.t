#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Test::More;

use App::Packager ( ':name', 'App::Music::ChordPro' );
use App::Music::ChordPro::Config;
use App::Music::ChordPro::Chords;

my %tbl;

our $config =
  eval {
      App::Music::ChordPro::Config::configurator
	  ( { nosysconfig => 1, nolegacyconfig => 1, nouserconfig => 1,
	      config => getresource("notes/common.json") } );
  };

=for generating

while ( <DATA> ) {
    chomp;
    my ( $chord, $info ) = split( /\t/, $_ );
    my $c = $chord;
    $c =~ s/[()]//g;
    my $res = App::Music::ChordPro::Chords::parse_chord($c);
    unless ( $res ) {
	print( "$_\tFAIL\n");
	next;
    }
    print("$chord\t", reformat($res), "\n");
}

exit;

=cut

while ( <DATA> ) {
    chomp;
    my ( $chord, $info ) = split( /\t/, $_ );
    my $c = $chord;
    $c =~ s/[()]//g;
    $tbl{$c} = $info;
}

plan tests => 1 + keys(%tbl);

ok( $config, "got config" );

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
    $res = {%$res};
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
C#7(-5)	{ ext => '7-5', ext_canon => '7-5', name => 'C#7-5', qual => '', qual_canon => '', root => 'C#', root_canon => 'C#', root_mod => 1, root_ord => 1, system => 'common' }
E7(-5)	{ ext => '7-5', ext_canon => '7-5', name => 'E7-5', qual => '', qual_canon => '', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4, system => 'common' }
E7-9	{ ext => '7-9', ext_canon => '7-9', name => 'E7-9', qual => '', qual_canon => '', root => 'E', root_canon => 'E', root_mod => 0, root_ord => 4, system => 'common' }
F#m7-5	{ ext => '7-5', ext_canon => '7-5', name => 'F#m7-5', qual => 'm', qual_canon => '-', root => 'F#', root_canon => 'F#', root_mod => 1, root_ord => 6, system => 'common' }
G7-9	{ ext => '7-9', ext_canon => '7-9', name => 'G7-9', qual => '', qual_canon => '', root => 'G', root_canon => 'G', root_mod => 0, root_ord => 7, system => 'common' }
Bm7-5	{ ext => '7-5', ext_canon => '7-5', name => 'Bm7-5', qual => 'm', qual_canon => '-', root => 'B', root_canon => 'B', root_mod => 0, root_ord => 11, system => 'common' }
