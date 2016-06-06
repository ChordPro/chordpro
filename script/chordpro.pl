#!/usr/bin/perl

# ChordPro -- perl version of Chord/Chordii

# Author          : Johan Vromans
# Created On      : Fri Jul  9 14:32:34 2010
# Last Modified By: Johan Vromans
# Last Modified On: Mon Jun  6 10:01:33 2016
# Update Count    : 239
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

=cut

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../CPAN";
use lib "$FindBin::Bin/../lib";

use App::Music::ChordPro;

run();

1;
