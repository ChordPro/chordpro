# ChordPro
*A lyrics and chords formatting program*

## Description
ChordPro will read a text file containing the lyrics of one or many songs plus chord information. ChordPro will then generate a photo-ready, professional looking, impress-your-friends sheet-music suitable for printing on your nearest printer.

To learn more about ChordPro, look for the man page or do "chordpro --help" for the list of options.

ChordPro is a rewrite of the Chordii program, see <http://www.chordii.org>.

For more information about ChordPro, see <http://www.chordpro.org>.

## Motivation
Why a rewrite of Chordii?

Chordii is the de facto reference implementation of the ChordPro file format standard. It implements ChordPro version 4.

ChordPro version 5 adds a number of new features, and this was pushing the limits of the very old program. Unicode support would have been very hard to add, and the whole program centered around PostScript generation, while nowadays PDF would be a much better alternative.

So we decided to create a new reference implementation from the ground up. we chose a programming language that is flexible and very good at handling Unicode data. And that is fun to program in.

# Current Status
This program provides support for ChordPro version 5. It supports almost all of the features of Chordii, and a lot more, like native PDF generation, Unicode input and fully customizable layout, fonts and sizes.

For up-to-date information, see <https://www.chordpro.org/chordpro/ChordPro-Reference-Implementation.html>

# Installation
For up-to-date information, see <https://www.chordpro.org/chordpro/ChordPro-Installation.html>

## Suppport

ChordPro (the program) development is hosted on GitHub, repository <https://github.com/ChordPro/chordpro>.

Please report any bugs or feature requests to the GitHub issue tracker, <https://github.com/ChordPro/chordpro/issues>.

## License
Copyright © 2010,2018 The ChordPro Team

This program is free software. You can redistribute it and/or modify it under the terms of the Artistic License 2.0.
