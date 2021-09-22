#! perl

use Test::More tests => 3;
use App::Music::ChordPro::Config::Properties;

my $cfg = Data::Properties->new;

$cfg->set_property( "version", 1 );
$cfg->parse_lines( [ 'vv = ${version:2}' ] );

is( $cfg->gps("vv"), 1, "v1" );
$cfg->parse_lines( [ 'vv = ${vercsion:2}' ] );
is( $cfg->gps("vv"), 2, "v2" );
$cfg->parse_lines( [ 'vv = ${vercsion:2:3}' ] );
is( $cfg->gps("vv"), '2:3', "v3" );
