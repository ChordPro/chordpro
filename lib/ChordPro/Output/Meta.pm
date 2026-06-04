#! perl

use v5.26;
use Object::Pad;

# Output backend to extract meta data.

class ChordPro::Output::Meta;

use ChordPro::Utils qw( qquote max );
use Ref::Util qw(is_arrayref);

my $sep = "; ";

method generate_songbook :common ($sb) {
    my @res = ( "[" );

    for my $song ( @{ $sb->{songs} } ) {
	my $m = $song->{meta};
	my @r;
	my $ll = 0;

	for ( qw( songindex title subtitle ) ) {
	    my $v = flatten($m->{$_});
	    push( @r, [ qquote($_, 1), qquote( $v, !looks_like_number($v) ) ] );
	    $ll = max( $ll, length($r[-1][0]) );
	}

	# The rest.
	for ( sort keys %$m ) {
	    next if /^((sub)?title|songindex)$/; # already done
	    next if /^(chordpro\..*|bookmark|_.*)/; # internal meta
	    next if /^(num)?chords$/; # internal meta
	    next if /^key_(actual|from)/;	 # transient meta
	    my $v = flatten($m->{$_});
	    push( @r, [ qquote($_, 1), qquote( $v, !looks_like_number($v) ) ] );
	    $ll = max( $ll, length($r[-1][0]) );
	}

	push( @res, "  {" );
	for ( @r ) {
	    push( @res, sprintf( "    %-${ll}s : %s,", @$_ ) );
	}
	$res[-1] =~ s/,$//;
	push( @res, "  }," );
    }
    $res[-1] =~ s/,$//;

    push( @res, "]" );
    \@res;
}

sub looks_like_number($v) {
    defined($v) && $v =~ /^[-+]?\d+(?:\.\d*)?$/;
}

sub kv( $k, $v ) {
    $v = flatten($v);
    qquote($k, 1) . " : " . qquote($v, !looks_like_number($v));
}

sub flatten($v) {
    return $v unless is_arrayref($v);
    return $v->[0] if @$v == 1;
    join( $sep, @$v );
}

1;
