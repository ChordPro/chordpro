#! perl

use Test::More tests => 2;
use App::Music::ChordPro::Config::Properties;

my $cfg = Data::Properties->new;

$cfg->parse_lines( [ split( /[\r\n]+/, <<EOD ) ], '', 'base' );
version = 1
config.version = 2
nested {
  version = 3
  something = 4
}
EOD

# Note that single key elements have no @ line in the dump.
is( $cfg->dump, <<EOD );
# base.@ = version config nested
base.version = '1'
base.config.version = '2'
# base.nested.@ = version something
base.nested.version = '3'
base.nested.something = '4'
EOD

is_deeply( $cfg->{_props},
	   { '@' => [ 'base' ],
	     'base.@' => [
		     'version',
		     'config',
		     'nested',
		    ],
	     'base.config.@' => [
			    'version',
			   ],
	     'base.config.version' => 2,
	     'base.nested.@' => [
			    'version',
			    'something',
			   ],
	     'base.nested.something' => 4,
	     'base.nested.version' => 3,
	     'base.version' => 1,
	   } );

