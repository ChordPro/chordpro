# [ChordPro](https://www.chordpro.org)
*A lyrics and chords formatting program*

![GitHub issues](https://img.shields.io/github/issues/chordpro/chordpro)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)
[![Built by musicians](https://img.shields.io/badge/built%20by-musicians%20𝄞-d15d27.svg?&labelColor=e36d25)](https://forthebadge.com)
[![@ChordPro_Org on Twitter](https://img.shields.io/badge/twitter-@ChordPro%5FOrg-1DA1F2.svg)](https://twitter.com/ChordPro_Org)

ChordPro generates professional-looking sheet music from a text file
containing the lyrics of one or many songs with chord information.
Check <https://www.chordpro.org/chordpro/chordpro-installation> for installation instructions
and execute `chordpro --help` for an overview about the available options.

## Support
For general discussion, please see [the user group](https://groups.io/g/ChordPro/topics).

Bugs and feature requests go to [the GitHub issue tracker](https://github.com/ChordPro/chordpro/issues).

## Development Status
This program provides support for ChordPro version 6.
It supports almost all features of Chordii, and many more,
such as native PDF generation, Unicode input
and fully customizable layout, fonts and sizes.

Prominent features of ChordPro 6 are
Pango style text markup, annotations,
and a more powerful way of assigning typefaces to layout items.

For up-to-date information, see <https://www.chordpro.org/chordpro/chordpro-reference-implementation>.

## Motivation
ChordPro is a rewrite of Chordii.
Why a rewrite?
Chordii was the de facto reference implementation of the ChordPro file format standard version 4.

ChordPro version 5 added a number of new features, pushing the limits of the very old program.
Unicode support would have been very hard to add
and the whole program was centered around generating PostScript,
while nowadays PDF is the standard.

So we decided to create a new reference implementation from the ground up.
We chose a programming language that is flexible and very good at handling Unicode data.
And that is fun to program in.

## License

Copyright © 2010,2018 The ChordPro Team

This program is free software. You can redistribute it and/or modify it under the terms of the Artistic License 2.0.
