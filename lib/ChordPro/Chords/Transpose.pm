#! perl

use v5.26;
use Object::Pad;
use utf8;
use Carp;

class transpose;

# Amount of intervals to transpose.
field $xp     :accessor :param = 0;

# Forced use of flats/sharps.
# 0 = not forced
# 1 = always use sharps
# 2 = always use flats
# 3 = follow key
use ChordPro::Utils qw( :xp );
field $forced :accessor :param = XP_DEFAULT;

# Key to follow;
field $key    :accessor :param = undef;

# Actual direction for sharps or flats.
# Implied from xp sign unless forced.
field $dir    :mutator :param = 0;

method set_key($k) {
    $key = $k;
    if ( $forced >= XP_KEY ) {
	$dir = $k->is_key_flat ? -1 : 1;
    }
}

method as_string {
    ( $xp > 0 ? "+" : "" ) . $xp .
      ( "", "s", "f" , "k" )[$forced]; # breaks XP_ hiding
}

method as_stringx {
    my $res = $self->as_string;
    $res .= $key->keyname if defined $key;
    $res .= ("-","","+")[$self->dir+1];
    $res;
}

method invert {
    transpose->new( xp => -$xp,
		    forced => $forced,
		    key => $key,
		    dir => $forced == XP_FOLLOW ? $dir <=> 0 : 0 );
}

method add( $right, $swapped ) {
    my $left = $self;

    # Explicit overrules explicit.
    # Implicit does not overrule implicit.
    if ( UNIVERSAL::isa( $right, "transpose" ) ) {
	# Implies not swapped.
	# Strategies (see also t/176_transpose.t):
	#  implicit does not overrule explicit
	#  explicit overrules implicit
	#  explicit overrules explicit

	my $res = transpose->new
	  ( xp     => $left->xp + $right->xp,
	    dir    => $right->forced ? $right->dir : $left->dir,
	    forced => $right->forced || $left->forced,
	    key    => $right->key    || $left->key,
	  );
	if ( $right->forced == XP_KEY && $right->key ) {
	    $res->dir = $right->key->is_key_flat ? -1 : 1;
	}
	elsif ( ( $right->forced == XP_KEY || $left->forced == XP_KEY )
		&& $left->key ) {
	    $res->dir = $left->key->is_key_flat ? -1 : 1;
	}
	elsif ( $left->forced == XP_FOLLOW && $right->forced == XP_FOLLOW ) {
	    $res->dir = $res->xp <=> 0;
	}
	return $res;
    }

    Carp::confess("Can't happen") unless defined($right);
    return transpose->new
      ( xp     => $left->xp + $right,
	dir    => $left->dir,
	forced => $left->forced,
	key    => $left->key,
      );
}

use overload
  '""' => \&as_stringx,
  'eq' => sub( $left, $right, $swapped ) { "$left" eq "$right" },
  'ne' => sub( $left, $right, $swapped ) { "$left" ne "$right" },
  '+'  => \&add,
  ;

method _data_printer( $ddp = undef ) {
    $self->as_stringx;
}

package ChordPro::Chords::Transpose;

use Exporter 'import';
our @EXPORT;
use utf8;
use ChordPro::Utils qw( :xp );

sub parse_transpose( $xp ) {

    return unless $xp =~ m;^([-+]?\d+)(?:([s#♯])|([fb♭])|([k]))?$;;

    my $forced = $4 ? XP_KEY : $2 ? XP_SHARP : $3 ? XP_FLAT : XP_FOLLOW;

    return transpose->new( xp     => 0 + $1,
			   forced => $forced,
			   dir    => (!!$2 - !!$3) || $1 <=> 0 );
}

push( @EXPORT, "parse_transpose" );

1;
