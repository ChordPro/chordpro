#!/usr/bin/perl

package App::Music::ChordPro::Output::Common;

use strict;
use warnings;
use App::Music::ChordPro::Chords;
use utf8;

# Substitute %X sequences in title formats and comments.
use Text::Balanced qw( extract_bracketed );

sub fmt_subst {
    my ( $s, $t, $cur ) = @_;
    my $res = "";
    my $m = $s->{meta};

    # Derived item(s).
    $m->{_key} = $m->{key} if exists $m->{key};
    if ( $m->{key} && $m->{capo} && (my $capo = $m->{capo}->[-1]) ) {
	$m->{_key} =
	  [ map { App::Music::ChordPro::Chords::transpose( $_, $capo ) }
	        @{$m->{key}} ];
    }

    # Hide escaped specials by replacing them with Unicode noncharacters.
    $t =~ s/\\\\/\x{fdd0}/g;
    $t =~ s/\\\{/\x{fdd1}/g;
    $t =~ s/\\\}/\x{fdd2}/g;
    $t =~ s/\\\|/\x{fdd3}/g;

    # Examine %{ sequences.
    while ( $t =~ /^(.*?)\%\{(.*)/ ) {
	$res .= $1;
	$t = $2;

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
	my ( $bal, $post, $pre ) = extract_bracketed( "{".$t, '{}' );
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
	    last; # error
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

	my ( $key, $op, $test );
	if ( $if =~ /^(.+?)([=])(.*)/ ) {
	    $key  = lc $1; #fmt_subst( $s, $1);
	    $op   = $2;
	    $test = $3; #fmt_subst( $s, $3 );
	}
	else {
	    $key = lc $if;
	    $op = "";
	}

	( $key, my $inx ) = ( $1, $2 )
	  if $key =~ /^(.*)\.(-?\d+)$/;

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
		# Allow substitutions in (sub)titles.
		if ( $key =~ /^(?:sub)?title$/ ) {
		    $val = fmt_subst( $s, $val );
		}
	    }
	}

	# Use the true/false parts to get a new value.
	$val //= "";
	if ( ( $val ne "" || $op ne "" )
	     && ( $op eq '='
		  ? $val eq $test
		  : 1 )
	   ) {
	    if ( defined $then ) {
		$val = fmt_subst( $s, $then, $val );
	    }
	    # else use the value as is.
	}
	elsif ( defined $else ) {
	    $val = fmt_subst( $s, $else, "" );
	}

	# Append and continue.
	$res .= $val if defined $val;
	next;
    }

    # Add the unprocessed rest.
    $res .= $t;

    # Unescape escaped specials.
    $res =~ s/\x{fdd0}/\\/g;
    $res =~ s/\x{fdd1}/{/g;
    $res =~ s/\x{fdd2}/}/g;
    $res =~ s/\x{fdd3}/|/g;

    # Return new value.
    return $res;
}

1;
