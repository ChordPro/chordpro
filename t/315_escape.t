#! perl

use Test::More tests => 3;
use ChordPro::Config::Properties;
use utf8;
my $cfg;

$cfg = Data::Properties->new;
$cfg->parse_lines( [ split( /[\r\n]+/, <<'EOD' ) ] );
a = "aa\nbb"
b = "aa\\nbb"
c = "aa\\\nbb"
d = "aa\\\\nbb"
e = "aa\\\\\nbb"
EOD

is_deeply( $cfg->data,
	   { a => "aa\nbb",
	     b => "aa\\nbb",
	     c => "aa\\\nbb",
	     d => "aa\\\\nbb",
	     e => "aa\\\\\nbb",
	   }
);

$cfg = Data::Properties->new;
$cfg->parse_lines( [ split( /[\r\n]+/, <<'EOD' ) ] );
a0 = aa\07bb
a1 = "aa\07bb"
a2 = "aa\1bb"
a3 = "aa\11bb"
a4 = "aa\111bb"
a5 = "aa\1111bb"
a6 = "aa\01111bb"
b = "aa\x9bb"
c = "aa\x{20ce}bb"
EOD

is_deeply( $cfg->data,
	   { a0 => "aa\\07bb",
	     a1 => "aa\07bb",
	     a2 => "aa\1bb",
	     a3 => "aa\11bb",
	     a4 => "aa\111bb",
	     a5 => "aa\1111bb",
	     a6 => "aa\01111bb",
	     b => "aa\x9bb",
	     c => "aa\x{20ce}bb",
	   }
);

$cfg = Data::Properties->new;
$cfg->parse_lines( [ split( /[\r\n]+/, <<'EOD' ) ] );
a0 = aa'bb
a1 = aa\bb
a2 = 'aa\'bb'
a3 = 'aa\\bb'
f1 = a'\nb
f2 = 'a\'\nb'
f3 = "a'\\nb"
EOD

is_deeply( $cfg->data,
	   { a0 => "aa'bb",
	     a1 => 'aa\\bb',
	     a2 => "aa'bb",
	     a3 => 'aa\\bb',
	     f1 => 'a\'\nb',
	     f2 => 'a\'\nb',
	     f3 => 'a\'\nb',
	   }
);
