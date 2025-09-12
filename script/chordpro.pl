#!/usr/bin/perl

# ChordPro -- Successor of Chord/Chordii

# Author          : Johan Vromans
# Created On      : Fri Jul  9 14:32:34 2010
# Last Modified On: Fri Sep 12 22:51:49 2025
# Update Count    : 299
# Status          : Unknown, Use with caution!

################ Common stuff ################

=head1 NAME

chordpro - A lyrics and chords formatting program

=head1 SYNOPSYS

    chordpro [ options ] file [ file ... ]

=head1 DESCRIPTION

B<chordpro> will read one or more text files containing the lyrics of
one or many songs plus chord information. B<chordpro> will then
generate a photo-ready, professional looking, impress-your-friends
sheet-music suitable for printing on your nearest printer.

When invoked as B<a2crd>, or with first argument B<--a2crd>, the input
will be interpreted as a 'chords over lyrics' file, converted to
ChordPro and written to standard output.

For command line usage summary, use

    chordpro --manual

Visit the web site L<https://chordpro.org> for complete documentation.

=cut

use strict;
use warnings;

use FindBin;

# @INC construction...
# Standard paths are lib and lib/ChordPro/lib relative to the parent
# of the script directory.
# Directories in CHORDPRO_XLIBS follow, to augment the path.
# For example, to add custom delegates.
# Directories in CHORDPRO_XXLIBS are put in front, these can be used
# to overrule standard modules. For example, to provide a patches
# module to an installed kit. Caveat emptor.
my @xlibs;
BEGIN {
    for ( $ENV{CHORDPRO_XXLIBS} ) {
	push( @xlibs, split( $^O =~ /msw/ ? ";" : ":", $_ ) ) if $_;
    }
    push( @xlibs, "$FindBin::Bin/../lib", "$FindBin::Bin/../lib/ChordPro/lib",  );
    for ( $ENV{CHORDPRO_XLIBS} ) {
	push( @xlibs, split( $^O =~ /msw/ ? ";" : ":", $_ ) ) if $_;
    }
};
use lib @xlibs;

use ChordPro;
use ChordPro::Paths;
CP->pathprepend( "$FindBin::Bin", "$FindBin::Bin/.." );

run();

################ Subroutines ################

# Synchronous system call. Used in Util module.
sub ::sys { system(@_) }

1;
