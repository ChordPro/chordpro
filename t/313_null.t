#! perl

use Test::More tests => 2;
use App::Music::ChordPro::Config::Properties;

my $cfg = Data::Properties->new;

$cfg->parse_lines( [ split( /[\r\n]+/, <<EOD ) ] );
a = null
b = NULl
x =
c = "null"
d = 'null'
EOD

is( $cfg->dump, <<EOD );
# @ = a b x c d
a = null
b = null
x = ''
c = 'null'
d = 'null'
EOD

is_deeply( $cfg->{_props},
	   { '@' => [ qw( a b x c d )],
	     a => undef,
	     b => undef,
	     c => 'null',
	     d => 'null',
	     x => '',
	   } );

