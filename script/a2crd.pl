#!/usr/bin/perl

# A2ChordPro -- perl version of Chord/A2Crd

# Author          : Johan Vromans
# Created On      : Mon Oct 29 10:45:24 2018
# Last Modified By: Johan Vromans
# Last Modified On: Wed Nov  7 14:46:32 2018
# Update Count    : 37
# Status          : Unknown, Use with caution!

################ Common stuff ################

=head1 NAME

a2crd - Convert ASCII Crd to ChordPro

=head1 DESCRIPTION

B<a2crd> will read a text file containing the lyrics of one or many
songs with chord information written visually above the lyrics. This
is often referred to as I<crd> data. B<a2crd> will then generate
equivalent ChordPro output.

Note that the output will generally need some additional editing to be
useful as input to ChordPro.

B<a2crd> is a wrapper around L<App::Music::ChordPro::A2Crd>, which
does all of the work. Alternatively, you can use the B<chordpro>
program and pass C<--a2crd> as the I<first> command line argument.

=cut

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../CPAN";
use lib "$FindBin::Bin/../lib";
use App::Packager qw( :name App::Music::ChordPro );

use App::Music::ChordPro::A2Crd;

::run();

1;
