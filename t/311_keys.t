#! perl

use Test::More tests => 2;
use ChordPro::Config::Properties;

my $cfg = Data::Properties->new;

$cfg->parse_lines( [ split( /[\r\n]+/, <<EOD ) ] );
version = 1
config.version = 2
nested {
  version = 3
  "some thing" = 4
}
nested = 5
EOD

is( $cfg->dump, <<EOD );
# @ = version config nested
version = '1'
config.version = '2'
# nested.@ = version some thing
nested.version = '3'
nested.some thing = '4'
nested = '5'
EOD

is_deeply( $cfg->{_props},
	   { '@' => [
		     'version',
		     'config',
		     'nested',
		    ],
	     'config.@' => [
			    'version',
			   ],
	     'config.version' => 2,
	     'nested.@' => [
			    'version',
			    'some thing',
			   ],
	     'nested.some thing' => 4,
	     'nested.version' => 3,
	     nested  => 5,
	     version => 1,
	   } );
