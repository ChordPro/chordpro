#! perl

use Test::More tests => 4;
use ChordPro::Config::Properties;

my $cfg = Data::Properties->new;

$cfg->parse_lines( [ split( /[\r\n]+/, <<EOD ) ] );
a = [ ]
b = [ ]
EOD

is( $cfg->dump, <<EOD );
# @ = a b
a = null
b = null
EOD

is_deeply( $cfg->{_props},
	   { '@' => [ qw( a b )],
	     a => undef,
	     b => undef,
	   } );

$cfg = Data::Properties->new;

$cfg->parse_lines( [ split( /[\r\n]+/, <<EOD ) ] );
x {
a = [ ]
}
EOD

is( $cfg->dump, <<EOD );
x.a = null
EOD

is_deeply( $cfg->{_props},
	   { '@' => [ qw(x)],
	     'x.@' => [ qw(a) ],
	     'x.a' => undef,
	   } );

