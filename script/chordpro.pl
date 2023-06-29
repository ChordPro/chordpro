#!/usr/bin/perl

# ChordPro -- Successor of Chord/Chordii

# Author          : Johan Vromans
# Created On      : Fri Jul  9 14:32:34 2010
# Last Modified By: 
# Last Modified On: Thu Jun 29 09:19:42 2023
# Update Count    : 269
# Status          : Unknown, Use with caution!

################ Common stuff ################

=head1 NAME

chordpro - A lyrics and chords formatting program

=head1 DESCRIPTION

B<chordpro> will read a text file containing the lyrics of one or many
songs plus chord information. B<chordpro> will then generate a
photo-ready, professional looking, impress-your-friends sheet-music
suitable for printing on your nearest printer.

B<chordpro> is a wrapper around module L<ChordPro>, which does all
of the work.

When invoked as B<a2crd>, or with first argument B<--a2crd>, the input
will be interpreted as an 'chords over lyrics' file, converted to
ChordPro and written to standard output.

=cut

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../CPAN";
use lib "$FindBin::Bin/../lib";
use App::Packager qw( :name ChordPro );
use ChordPro;
use ChordPro::Utils qw(is_msw);

$ENV{PATH} = join( is_msw() ? ";" : ":",
		   "$FindBin::Bin", "$FindBin::Bin/..",
		   $ENV{PATH} );

run();

################ Subroutines ################

# Synchronous system call. Used in Util module.
sub ::sys { system(@_) }

1;
