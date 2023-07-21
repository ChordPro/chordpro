#! perl

use Test::More tests => 7;
use ChordPro::Config::Properties;

my $cfg = Data::Properties->new;

$cfg->parse_lines( [ split( /[\r\n]+/, <<'EOD' ) ], '', 'base' );
a = 1
b = 2
nested {
  0 {
      c = 3
    }
  1 = 5
  2 = 6
}
EOD

my $xp = { base => {
		    a => 1,
		    b => 2,
		    nested => [
			       {
				c => 3,
			       },
			       5,
			       6,
			      ],
		   },
	 };

is_deeply( $cfg->data, $xp, "one" );

$cfg = Data::Properties->new;

$cfg->parse_lines( [ split( /[\r\n]+/, <<'EOD' ) ], '<data>', 'base' );
a = 1
b = 2
nested = [
  {
      c = 3
  }
  5
  6
]
EOD

is_deeply( $cfg->data, $xp, "two" );

$cfg = Data::Properties->new;

$cfg->parse_lines( [ split( /[\r\n]+/, <<'EOD' ) ], '<data>', 'base' );
a = 1
b = 2
nested = [
  {
      c = 3
  }
  5   6
]
EOD

is_deeply( $cfg->data, $xp, "three" );

$cfg = Data::Properties->new;

$cfg->parse_lines( [ split( /[\r\n]+/, <<'EOD' ) ], '<data>', 'base' );
nested: [ aap noot mies ]
EOD

$xp = { base => { nested => [ qw( aap noot mies ) ] } };

is_deeply( $cfg->data, $xp, "four" );

$cfg = Data::Properties->new;

$cfg->parse_lines( [ split( /[\r\n]+/, <<'EOD' ) ], '<data>', 'base' );
nested : [
  aap noot mies
]
EOD

$xp = { base => { nested => [ qw( aap noot mies ) ] } };

is_deeply( $cfg->data, $xp, "five" );

$cfg = Data::Properties->new;

$cfg->parse_lines( [ split( /[\r\n]+/, <<'EOD' ) ], '<data>', 'base' );
nested =[
  aap
  noot mies
]
EOD

$xp = { base => { nested => [ qw( aap noot mies ) ] } };

is_deeply( $cfg->data, $xp, "six" );

$cfg = Data::Properties->new;

$cfg->parse_lines( [ split( /[\r\n]+/, <<'EOD' ) ], '<data>', 'base' );
nested=[  aap
  noot mies
  ]
EOD

$xp = { base => { nested => [ qw( aap noot mies ) ] } };

is_deeply( $cfg->data, $xp, "seven" );
