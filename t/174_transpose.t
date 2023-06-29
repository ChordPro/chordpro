#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use App::Packager qw( :name ChordPro );
use ChordPro;
use Test::More;

plan tests => 13;

my $data1 = <<EOD;
{title: Transpose}
{key: D}
{C:  |  D  |  %{key}  |  %{key_actual}  |  [D]   | }
EOD

my @argv = ( "--no-default-configs",
	     "--generate", "Text",
	     "--backend-option", "expand=1" );

sub test {
    my $t = shift;

    my $decapo    = ( $t & 0x01 ) ? 1 : 0;
    my $capo      = ( $t & 0x02 ) ? 2 : 0;
    my $xpose     = ( $t & 0x04 ) ? 2 : 0;	# local
    my $transpose = ( $t & 0x08 ) ? 2 : 0;	# global

    return if $decapo && !$capo;

    my $data = $data1;

    if ( $xpose ) {
	$data =~ s/(\{C:)/{transpose $xpose}\n$1/;
    }
    if ( $capo ) {
	$data =~ s/(\{C:)/{capo $capo}\n$1/;
    }

    @ARGV = ( @argv,
	      $transpose ? "--transpose=$transpose" : (),
	      $decapo ? "--decapo" : (),
	      "--output", '*', \$data );

    my $res = ::run();		# --output=*

    for ( @$res ) {
	next unless /^-- \|\s+/;
	my $line = $';
	my @a = split( / +\| +/, $line );
	unshift( @a,
		 $transpose || "-",
		 $xpose     || "-",
		 $capo      || "-",
		 $capo?$decapo?"t":"f":"-" );
	return sprintf( "|  %-3.3s|  %-3.3s|  %-3.3s|  %-3.3s|".
			"  %-3.3s|  %-3.3s|  %-3.3s|  %-4.4s |",  @a);
    }
}

my @xp = split(/[\n\r]+/, <<EOD);
|  -  |  -  |  -  |  -  |  D  |  D  |  D  |  [D]  |
|  -  |  -  |  -  |  -  |  D  |  D  |  D  |  [D]  |
|  -  |  -  |  2  |  f  |  D  |  D  |  E  |  [D]  |
|  -  |  -  |  2  |  t  |  D  |  E  |  E  |  [E]  |
|  -  |  2  |  -  |  -  |  D  |  D  |  E  |  [E]  |
|  -  |  2  |  -  |  -  |  D  |  D  |  E  |  [E]  |
|  -  |  2  |  2  |  f  |  D  |  D  |  F# |  [E]  |
|  -  |  2  |  2  |  t  |  D  |  E  |  F# |  [F#] |
|  2  |  -  |  -  |  -  |  D  |  E  |  E  |  [E]  |
|  2  |  -  |  -  |  -  |  D  |  E  |  E  |  [E]  |
|  2  |  -  |  2  |  f  |  D  |  E  |  F# |  [E]  |
|  2  |  -  |  2  |  t  |  D  |  F# |  F# |  [F#] |
|  2  |  2  |  -  |  -  |  D  |  E  |  F# |  [F#] |
|  2  |  2  |  -  |  -  |  D  |  E  |  F# |  [F#] |
|  2  |  2  |  2  |  f  |  D  |  E  |  G# |  [F#] |
|  2  |  2  |  2  |  t  |  D  |  F# |  G# |  [G#] |
EOD
ok( @xp == 16, "Number of tests = 12" );

for my $index ( 0..15 ) {
    my $res = test($index);
    next unless $res;
    is( $res, $xp[$index],
	sprintf("%02x %s", $index, substr($xp[$index], 0, 25) ) );
}

