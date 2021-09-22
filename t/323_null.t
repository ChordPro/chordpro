#! perl

use Test::More tests => 2;
use App::Music::ChordPro::Config::Properties;

my $cfg = Data::Properties->new;

$cfg->parse_lines( [ split( /[\r\n]+/, <<'EOD' ) ] );
a = null
x =
c = a: ${a?|${a|value|empty}|null}
d = x: ${x?|${x|value|empty}|null}
EOD

is( $cfg->dump, <<EOD );
# @ = a x c d
a = null
x = ''
c = 'a: null'
d = 'x: empty'
EOD

is_deeply( $cfg->{_props},
	   { '@' => [ qw( a x c d )],
	     a => undef,
	     c => 'a: null',
	     d => 'x: empty',
	     x => '',
	   } );

