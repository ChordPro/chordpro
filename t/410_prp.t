#! perl

use v5.26;
use feature 'signatures';
no warnings 'experimental::signatures';
use utf8;

use ChordPro::Testing;
use ChordPro::Utils qw(prpadd2cfg);
use ChordPro::Config;

plan tests => 29;

my $cfg = struct();

# Check return value.
is_deeply( testit( $cfg, "a.0" => "x" ),
	   { a => [ "x", ["c"], { f => "g" } ] }, "a.0 (ret)" );
# Struct arg should be modified as well.
is_deeply( $cfg, { a => [ "x", ["c"], { f => "g" } ] }, "a.0 (arg)" );

$cfg = struct();
eval { testit( $cfg, "a.0.0" => "x" ) };
like( $@, qr/Key a.0 is scalar, not array/, "a.0.0" );

$cfg = struct();
eval { testit( $cfg, "a.0.a" => "x" ) };
like( $@, qr/Key a.0 is scalar, not hash/, "a.0.a" );

$cfg = struct();
testit( $cfg, "a.1.0" => "x" );
is_deeply( $cfg, { a => [ "b", ["x"], { f => "g" } ] }, "a.1.0" );

$cfg = struct();
testit( $cfg, "a.1.0" => "true" );
is_deeply( $cfg, { a => [ "b", [1], { f => "g" } ] }, "a.1.0 true" );

$cfg = struct();
testit( $cfg, "a.1.0" => "false" );
is_deeply( $cfg, { a => [ "b", [0], { f => "g" } ] }, "a.1.0 false" );

$cfg = struct();
testit( $cfg, "a.1.0" => "null" );
is_deeply( $cfg, { a => [ "b", [undef], { f => "g" } ] }, "a.1.0 null" );

$cfg = struct();
testit( $cfg, "a.1.>" => "y" );
is_deeply( $cfg, { a => [ "b", ["c","y"], { f => "g" } ] }, "a.1.>" );

$cfg = struct();
testit( $cfg, "a.1.>" => "y", "a.1.>0" => "z" );
is_deeply( $cfg, { a => [ "b", ["c","z","y"], { f => "g" } ] }, "a.1.>" );

$cfg = struct();
testit( $cfg, "a.1.<" => "z" );
is_deeply( $cfg, { a => [ "b", ["z","c"], { f => "g" } ] }, "a.1.<" );

$cfg = struct();
testit( $cfg, "a.2" => "z" );
is_deeply( $cfg, { a => [ "b", ["c"], "z" ] }, "a.2" );

$cfg = struct();
testit( $cfg, "a.2.a" => "b" );
is_deeply( $cfg, { a => [ "b", ["c"], { f => "g", a => "b" } ] }, "a.2.a" );

$cfg = struct();
testit( $cfg, "a.2.a" => '{x:y}', "a.2.a.b" => "c" );
is_deeply( $cfg, { a => [ "b", ["c"], { a => { x => "y", b => "c" }, f => "g" } ] }, "a.2.a/b" );

$cfg = struct();
testit( $cfg, "a.2.a" => { x => "y" }, "a.2.a.b" => "c" );
is_deeply( $cfg, { a => [ "b", ["c"], { a => { x => "y", b => "c" }, f => "g" } ] }, "a.2.a/b" );

$cfg = struct();
testit( $cfg, "a.2.a" => [ qw(x y) ], "a.2.a.>" => "c" );
is_deeply( $cfg, { a => [ "b", ["c"], { a => [ qw(x y c) ], f => "g" } ] }, "a.2.a/>" );

# Testing array manipulations.
is_deeply( prpadd2cfg( [qw(x y z)], ">"   => "a" ), [qw(x y z a)], ">" );
is_deeply( prpadd2cfg( [qw(x y z)], ">0"  => "a" ), [qw(x a y z)], ">0" );
is_deeply( prpadd2cfg( [qw(x y z)], ">-0" => "a" ), [qw(x a y z)], ">-0" );
is_deeply( prpadd2cfg( [qw(x y z)], ">1"  => "a" ), [qw(x y a z)], ">1" );
is_deeply( prpadd2cfg( [qw(x y z)], ">-1" => "a" ), [qw(x y z a)], ">-1" );

is_deeply( prpadd2cfg( [qw(x y z)], "<"   => "a" ), [qw(a x y z)], "<" );
is_deeply( prpadd2cfg( [qw(x y z)], "<0"  => "a" ), [qw(a x y z)], "<0" );
is_deeply( prpadd2cfg( [qw(x y z)], "<-0" => "a" ), [qw(a x y z)], "<-0" );
is_deeply( prpadd2cfg( [qw(x y z)], "<1"  => "a" ), [qw(x a y z)], "<1" );
is_deeply( prpadd2cfg( [qw(x y z)], "<-1" => "a" ), [qw(x y a z)], "<-1" );

is_deeply( prpadd2cfg( [qw(x y z a)], "/"   => "" ), [qw(x y z)], "/" );
is_deeply( prpadd2cfg( [qw(x y z a)], "/0"  => "" ), [qw(y z a)], "/0" );
is_deeply( prpadd2cfg( [qw(x y z a)], "/-1" => "" ), [qw(x y z)], "/-1" );

################ Helpers ################

# use DDP;
sub testit( $struct, @delta ) {
#    p($struct, as => "before" );
    prpadd2cfg( $struct, @delta );
#    p($struct, as => "after" );
}

sub struct {
    { a => [ "b", ["c"], { f => "g" } ] }
}
