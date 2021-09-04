#! perl

use Test::More tests => 4;
use App::Music::ChordPro::Config::Properties;

my $cfg = Data::Properties->new;

$cfg->parse_lines(["version:1"]);

is( $cfg->dump, "version = '1'\n" );

# Case insensitive.
$cfg = Data::Properties->new;

$cfg->parse_lines(["vERSION:1"]);

is( $cfg->dump, "vERSION = '1'\n" );
is( $cfg->get_property("VERSION"), 1 );

# Content is appended.
$cfg->parse_lines(["data = 0"]);
is( $cfg->dump, <<EOD );
# @ = vERSION data
vERSION = '1'
data = '0'
EOD



# Use of environment variables.
#$cfg = Data::Properties->new;
#$ENV{"_DATA__PROPERTIES_"} = "Yes!";
#$cfg->parse_lines([ 'foo = %{_DATA__PROPERTIES_}' ] );
#is( $cfg->get_property("foo"), "Yes!" );
