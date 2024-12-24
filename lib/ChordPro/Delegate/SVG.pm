#! perl

use v5.26;
use strict;
use warnings;
use feature qw( signatures );
no warnings "experimental::signatures";
use utf8;

package ChordPro::Delegate::SVG;

use ChordPro::Utils;

sub DEBUG() { $::config->{debug}->{svg} }

sub svg2svg( $self, %args ) {
    my $elt = $args{elt};

    my @data = @{ $elt->{data} };
    my @pre;

    while ( $data[0] !~ /<svg/ ) {
	push( @pre, shift(@data) );
    }
    my $kv = parse_kvm( @pre ) if @pre;
    $kv->{split} //= 1;		# less overhead. really.
    $kv->{scale} ||= 1;

    return
	  { type     => "image",
	    subtype   => "svg",
	    line      => $elt->{line},
	    data      => \@data,
	    opts      => { %$kv, %{$elt->{opts}//{}} },
	  };
}

# Pre-scan.
sub options( $data ) {

    my @pre;

    while ( $data->[0] !~ /<svg/ ) {
	push( @pre, shift(@$data) );
    }
    my $kv = parse_kvm( @pre ) if @pre;
    $kv;
}

1;
