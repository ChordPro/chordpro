#! perl

use strict;
use warnings;
use utf8;

use Test::More;
use ChordPro::Utils qw( is_msw );
use ChordPro::Files;
use Encode qw( encode_utf8 decode_utf8 );

# Stolen from Test::More::UTF8.
my @h = qw(failure_output todo_output output);
binmode Test::More->builder->$_, ':utf8' for @h;

if ( -d "t" ) {
    chdir "t";
    $0 =~ s;(^|/)t/;$1;;
}

use lib "../script";

my %files = ( "Test.fstst"    => 1,
	      "Café.fstst"    => 1,
	      "I♡Perl.fstst" => 1 );

plan tests => 2 + 10 * keys(%files);

for ( keys %files ) {
    my $fd = fs_open( $_, '>:utf8' );
    ok( $fd, "$_ created" );
    my $msg = "Hello $_\n";
    print $fd $msg;
    ok( close($fd), "$_ closed" );
    $msg = encode_utf8($msg);
    my $size = length($msg) + ( is_msw ? 1 : 0 );
    is( fs_test( 's',  $_ ), $size, length($msg)." bytes" );
    is( fs_test( 'rs', $_ ), $size, "test rs" );
    is( fs_test( 'sr', $_ ), 1,	"test sr" );
    $fd = fs_open($_);
    ok( $fd, "$_ opened" );
    my $read = do { local $/; <$fd> };
    is( $read, decode_utf8($msg), "contents" );
    ok( close($fd), "$_ closed" );
};

my $files = fs_find( ".", { filter => qr/\.fstst$/i } );
is( 0+@$files, 0+keys(%files), "Found ".@$files." files" );

dd($files);

dd($_, "K") for keys %files;

for my $file ( @$files ) {
    my $name = $file->{name};#decode_utf8($file->{name});
    if ( $files{$name} ) {
	pass( "Found $name" );
	delete $files{$name};
	is( 1, fs_unlink($name), "File $name removed" );
    }
    else {
	fail( "Unknown file found: $name" );
	fail( "Unknown file found: $name" );
	dd($name, "X1" );
	$name = decode_utf8($file->{name});
	dd($name, "X2" );
    }
}

is( 0+keys(%files), 0, "All files found" );

sub dd {
    return;
    use DDP;
    diag np( $_[0],
	     show_unicode => 1,
	     escape_chars=>'nonascii',
	     unicode_charnames => 1,
	     $_[1] ? ( as => $_[1] ) : () );
}
