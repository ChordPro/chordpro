#! perl

use strict;
use warnings;
use utf8;

# Checking consistency between the JSON and PRP versions of the config.

use ChordPro::Testing;
use ChordPro::Config::Properties;
use JSON::PP;
use File::LoadLines qw(loadblob);

my $lib = "lib/ChordPro/res/config";
$lib = "../$lib" unless -d 'xt';

my $dp = Data::Properties->new;
my $d1 = $dp->parse_file("$lib/chordpro.prp")->data;
ok( $d1, "Got PRP config");
#diag("PRP: ", scalar(keys(%$d1)), " top level keys");

my $d2 = JSON::PP->new->relaxed->utf8(1)
  ->boolean_values(0,1)
  ->decode(loadblob("$lib/chordpro.json"));
ok( $d2, "Got JSON config");
#diag("JSON: ", scalar(keys(%$d2)), " top level keys");

Test::More::is_deeply( $d1, $d2, "PRP and JSON config match" );

