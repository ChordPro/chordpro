#!/usr/bin/perl

package App::Music::ChordPro::Output::Common;

use strict;
use warnings;

# Substitute %X sequences in title formats.
use Text::Balanced qw( extract_bracketed );

sub fmt_subst {
    my ( $s, $t, $strict, $cur ) = @_;
    my $res = "";
    my $m = $s->{meta};

    # Examine % sequences.
    while ( $t =~ /^(.*?)\%(.)(.*)/ ) {
	$res .= $1;
	$t = $3;
	my $f = $2;

	if ( $f eq '{' ) {

	    # %{} indicates the current key value, so you can write
	    # things like "%{capo|CAPO %{}}".
	    if ( $t =~ /^}(.*)/ ) {
		$t = $1;
		$res .= $cur // "";
		next;
	    }

	    # Complex sequence:
	    #  %{var}
	    #  %{var|true}
	    #  %{var|true|false}
	    # where true and false may contain nested %{...} sequences.

	    # Extract the complete sequence.
	    my ( $bal, $post, $pre ) = extract_bracketed( $f.$t, '{}' );
	    return $res . $t unless defined $bal; # error
	    die if $pre;
	    $t = $post;
	    $bal =~ s/^\{(.*)\}$/$1/; # strip outer { }

	    my ( $if, $then, $else );

	    # Get the substitution key.
	    if ( $bal =~ /^([^|}]+)(.*)/ ) {
		$if = $1;
		$bal = $2;
	    }
	    else {
		return $res . $t; # error
	    }

	    # We cannot use extract_bracketed since we must also look
	    # for | tokens.
	    my @a = split( /([{}|%])/, $bal );
	    shift(@a) if @a && $a[0] eq "";

	    # Do we have a 'true' part?
	    if ( @a && $a[0] eq '|' ) {
		shift(@a);
		$then = "";
		my $lvl = 0;
		while ( @a ) {
		    my $a = shift(@a);
		    unshift( @a, $a ), last
		      if ( $a eq '|' || $a eq '}' ) && $lvl <= 0;
		    $then .= $a;
		    if ( $a eq '{' ) {
			$lvl++;
		    }
		    elsif ( $a eq '}' ) {
			$lvl--;
		    }
		}
	    }

	    # Do we have a 'false' part?
	    if ( @a && $a[0] eq '|' ) {
		shift(@a);
		$else = join( "", @a );
	    }

	    my $key = lc($if);
	    ( $key, my $inx ) = ( $1, $2 ) if $key =~ /^(.*)\.(-?\d+)$/;

	    # Establish the value for this key.
	    my $val;
	    if ( defined $m->{$key} ) {
		if ( $inx ) {
		    if ( $inx > 0 && $inx <= @{ $m->{$key} } ) {
			$val = $m->{$key}->[$inx-1];
		    }
		    else {
			$val = $m->{$key}->[$inx];
		    }
		}
		else {
		    $val = join( $::config->{metadata}->{separator}, @{ $m->{$key} } );
		}
	    }

	    # Use the true/false parts to get a new value.
	    if ( defined($val) && $val ne "" ) {
		if ( defined $then ) {
		    $val = fmt_subst( $s, $then, $strict, $val );
		}
		# else use the value as is.
	    }
	    elsif ( defined $else ) {
		$val = fmt_subst( $s, $else, $strict, "" );
	    }

	    # Append and continue.
	    $res .= $val if defined $val;
	    next;
	}
	next if $strict;

	# Single-character substitutions.
	if ( $f eq '%' ) {
	    $res .= '%';
	}
	elsif ( $f eq 't' ) {
	    $res .= $m->{title}->[0] if $m->{title}->[0];
	}
	elsif ( $f eq 's' ) {
	    $res .= $m->{subtitle}->[0] if $m->{subtitle}->[0];
	}
	elsif ( $f eq 'p' ) {
	    $res .= $s->{page} if $s->{page};
	}
	elsif ( $f eq 'P' ) {
	    $res .= $s->{page};	####FIXME
	}
	else {
	    warn("Ignoring unknown %$f sequence in title.");
	}
    }

    # Return new value plus the unprocessed rest.
    $res . $t;
}

1;
