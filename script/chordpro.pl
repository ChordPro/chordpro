#!/usr/bin/perl

# ChordPro -- perl version of Chord/Chordii

# Author          : Johan Vromans
# Created On      : Fri Jul  9 14:32:34 2010
# Last Modified By: Johan Vromans
# Last Modified On: Wed Mar  3 22:11:36 2021
# Update Count    : 262
# Status          : Unknown, Use with caution!

################ Common stuff ################

=head1 NAME

chordpro - A lyrics and chords formatting program

=head1 DESCRIPTION

B<chordpro> will read a text file containing the lyrics of one or many
songs plus chord information. B<chordpro> will then generate a
photo-ready, professional looking, impress-your-friends sheet-music
suitable for printing on your nearest printer.

B<chordpro> is a wrapper around L<App::Music::ChordPro>, which does all
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
use App::Packager qw( :name App::Music::ChordPro );
use App::Music::ChordPro;
use App::Music::ChordPro::Utils qw(is_msw);
$ENV{PATH} = "$FindBin::Bin/.." . (is_msw() ? ";" : ":" ) . $ENV{PATH};

run();

################ Subroutines ################

# Synchronous system call. Used in Util module.
sub ::sys { system(@_) }

1;
