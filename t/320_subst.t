#! perl

use Test::More tests => 2;
use ChordPro::Config::Properties;

my $cfg = Data::Properties->new;
$cfg->parse_lines( [ split( /[\r\n]+/, <<'EOD' ) ] );
version = 1
nested {
  version = 3
  # version at this level
  something = ${.version}
  # version at global level
  else = ${version}
}
EOD

# Note that single key elements have no @ line in the dump.
is( $cfg->dump, <<EOD );
# @ = version nested
version = '1'
# nested.@ = version something else
nested.version = '3'
nested.something = '3'
nested.else = '1'
EOD

is_deeply( $cfg->{_props},
	   { '@' => [
		     'version',
		     'nested',
		    ],
	     'nested.@' => [
			    'version',
			    'something',
			    'else',
			   ],
	     'nested.something' => 3,
	     'nested.version' => 3,
	     'nested.else' => 1,
	     'version' => 1,
	   } );

