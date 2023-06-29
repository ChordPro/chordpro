#! perl

use Test::More tests => 1;
use ChordPro::Config::Properties;

my $cfg = Data::Properties->new;

delete $ENV{XXDATAPROPERTIESXX};
delete $ENV{xxdatapropertiesxx};
$ENV{XXDATAPROPERTIESXX} = "env";
my $caseinsensitive = $ENV{xxdatapropertiesxx} && $ENV{xxdatapropertiesxx} eq "env";

$cfg->parse_lines( [ split( /[\r\n]+/, <<'EOD' ) ] );
version = 1
nested {
  nothing = ${.version||xxx}
  version = 3
  # version at this level
  something = ${.version}
  # version at global level
  else = ${version}
}
XXDATAPROPERTIESXX = "local"
# This should be overridden by the env. var.
test1 = ${XXDATAPROPERTIESXX}
# But env var names are usually not case insensitive
test2 = ${xxdatapropertiesxx}
EOD

my $xx = $caseinsensitive ? "env" : "local";
is( $cfg->dump, <<EOD );
# @ = version nested XXDATAPROPERTIESXX test1 test2
version = '1'
# nested.@ = nothing version something else
nested.nothing = 'xxx'
nested.version = '3'
nested.something = '3'
nested.else = '1'
XXDATAPROPERTIESXX = 'local'
test1 = 'env'
test2 = '$xx'
EOD
