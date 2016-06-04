#! perl

package App::Music::ChordPro;

our $VERSION = "0.51";

=head1 NAME

App::Music::ChordPro - A lyrics and chords formatting program

=head1 DESCRIPTION

ChordPro will read a text file containing the lyrics of one or many
songs plus chord information. ChordPro will then generate a
photo-ready, professional looking, impress-your-friends sheet-music
suitable for printing on your nearest printer.

To learn more about ChordPro, look for the man page or do
"chordpro --help" for the list of options.

ChordPro is a rewrite of the Chordii program, see
L<http://www.chordii.org>.

For more information about ChordPro, see L<http://www.chordpro.org>.

=head1 MOTIVATION

Why a rewrite of Chordii?

Chordii is the de facto reference implementation of the ChordPro file
format standard. It implements ChordPro version 4.

ChordPro version 5 adds a number of new features, and this was pushing
the limits of the very old program. Unicode support would have been
very hard to add, and the whole program centered around PostScript
generation, while nowadays PDF would be a much better alternative.

So I decided to create a new reference implementation from the ground
up. I chose a programming language that is flexible and very good at
handling Unicode data. And that is fun to program in.

=head1 CURRENT STATUS

This program provides alpha support for ChordPro version 5. It
supports most of the features of Chordii, and a lot more:

* Native PDF generation

* Unicode support (all input is UTF8)

* Support for external TrueType fonts

* Font kerning (with external TrueType fonts)

* Customizable layout, fonts and sizes

* Customizable backends for PDF, ChordPro, LilyPond*, LaTeX* and HTML.

=head1 LICENSE

Copyright (C) 2010,2016 Johan Vromans,

This module is free software. You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

1;
