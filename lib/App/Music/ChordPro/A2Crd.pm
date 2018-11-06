#! perl

use strict;
use warnings;
use utf8;
use Carp;

package App::Music::ChordPro::A2Crd;

################ Subroutines ################

# API: Produce ChordPro data from AsciiCRD lines.
sub a2cho {
    my ( $lines, $options ) = @_;
    my $map = "";
    foreach ( @$lines ) {
	$map .= classify($_);
    }
    maplines( $map, $lines );
}

# Classify the line and return a single-char token.
sub classify {
    my ( $line ) = @_;
    return '_' if $line =~ /^\s*$/;	# empty line
    return '{' if $line =~ /^\{.+/;	# directive

    # Lyrics or Chords heuristic.
    my $len = length($line);
    $line =~ s/\s+//g;
    return ( $len / length($line) - 1 ) < 1 ? 'l' : 'c';
}

# Process the lines via the map.
sub maplines {
    my ( $map, $lines ) = @_;
    my @out;

    # Preamble.
    while ( $map =~ s/^([l_{])// ) {
	push( @out, ($1 eq "l" ? "# " : "" ) . shift( @$lines ) );
    }

    # Process the lines using the map.
    while ( $map ) {
	# warn($map);

	# Blank line preceding chords: pass.
	if ( $map =~ s/^_c/c/ ) {
	    push( @out, '');
	    shift(@$lines);
	    # Fall through.
	}

	# The normal case: chords + lyrics.
	if ( $map =~ s/^cl// ) {
	    push( @out, combine( shift(@$lines), shift(@$lines), "cl" ) );
	}

	# Empty line preceding a chordless lyrics line.
	elsif ( $map =~ s/^__l// ) {
	    push( @out, '' );
	    shift( @$lines );
	    push( @out, combine( shift(@$lines), shift(@$lines), "__l" ) );
	}

	# Chordless lyrics line.
	elsif ( $map =~ s/^_l// ) {
	    push( @out, combine( shift(@$lines), shift(@$lines), "_l" ) );
	}

	# Lone lyrics or directives.
	elsif ( $map =~ s/^[l{]// ) {
	    push( @out, shift( @$lines ) );
	}

	# Lone chords.
	elsif ( $map =~ s/^c// ) {
	    push( @out, combine( shift(@$lines), '', "c" ) );
	}

	# Empty line.
	elsif ( $map =~ s/^_// ) {
	    push( @out, '' );
	    shift( @$lines );
	}

	# Can't happen.
	else {
	    croak("MAP: $map");
	}
    }
    return wantarray ? @out : \@out;
}

# Combine two lines (chords + lyrics) into lyrics with [chords].
sub combine {
    my ( $l1, $l2 ) = @_;
    my $res = "";
    while ( $l1 =~ /^(\s*)(\S+)(.*)/ ) {
	$res .= join( '',
		      substr( $l2, 0, length($1), '' ),
		      '[' . $2 . ']',
		      substr( $l2, 0, length($2), '' ) );
	$l1 = $3;
    }
    return $res.$l2;
}

1;
