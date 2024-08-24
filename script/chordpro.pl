#!/usr/bin/perl

# ChordPro -- Successor of Chord/Chordii

# Author          : Johan Vromans
# Created On      : Fri Jul  9 14:32:34 2010
# Last Modified On: Mon Feb 12 22:11:02 2024
# Update Count    : 282
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
use lib "$FindBin::Bin/../lib";
use ChordPro;
use ChordPro::Paths;
CP->pathprepend( "$FindBin::Bin", "$FindBin::Bin/.." );

run();

################ Subroutines ################

# Synchronous system call. Used in Util module.
sub ::sys { system(@_) }

1;
