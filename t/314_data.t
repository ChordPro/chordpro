#! perl

use Test::More tests => 1;
use ChordPro::Config::Properties;
use utf8;
my $cfg = Data::Properties->new;

$cfg->parse_lines( [ split( /[\r\n]+/, <<EOD ) ], '', 'base' );
version = 1
config.version = 2
nested {
  version = 3
  something = 4
}

# This is how to make an array
list {
   0 {
        beest = aap
   }
   1 = noot♩
   2 = mies
}
EOD

is_deeply( $cfg->data,
	   { base => {
		      config => {
				 version => 2,
				},
		      list => [
			       {
				beest => 'aap',
			       },
			       "noot\x{2669}",
			       'mies',
			      ],
		      nested => {
				 something => 4,
				 version => 3,
				},
		      version => 1,
		     },
	   }
);
