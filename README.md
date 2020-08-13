# [ChordPro](https://www.chordpro.org)
*A lyrics and chords formatting program*

![GitHub issues](https://img.shields.io/github/issues/chordpro/chordpro)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)
[![Built by musicians](https://img.shields.io/badge/built%20by-musicians%20𝄞-d15d27.svg?&labelColor=e36d25)](https://forthebadge.com)
[![@ChordPro_Org on Twitter](https://img.shields.io/badge/twitter-@ChordPro%5FOrg-1DA1F2.svg)](https://twitter.com/ChordPro_Org)

## Description
ChordPro will read a text file containing the lyrics of one or many songs plus chord information. ChordPro will then generate a photo-ready, professional looking, impress-your-friends sheet-music suitable for printing on your nearest printer.

To learn more about ChordPro, look for the man page or do `chordpro --help` for the list of options.

ChordPro is a rewrite of the Chordii program, see <http://www.chordii.org>.

For more information about ChordPro, see the [website](http://www.chordpro.org).

## Motivation
Why a rewrite of Chordii?

Chordii is the de facto reference implementation of the ChordPro file format standard. It implements ChordPro version 4.

ChordPro version 5 adds a number of new features, and this was pushing the limits of the very old program. Unicode support would have been very hard to add, and the whole program centered around PostScript generation, while nowadays PDF would be a much better alternative.

So, we decided to create a new reference implementation from the ground up. We chose a programming language that is flexible and very good at handling Unicode data. And that is fun to program in.

## Current Status
This program provides support for ChordPro version 6. It supports
almost all of the features of Chordii, and a lot more, like native PDF
generation, Unicode input and fully customizable layout, fonts and
sizes.

Prominent features of ChordPro 6 are Pango style text markup,
annotations, and a more powerful way of assigning typefaces to layout
items.

For up-to-date information, see <https://www.chordpro.org/chordpro/ChordPro-Reference-Implementation.html>

## Installation
For up-to-date information, see <https://www.chordpro.org/chordpro/ChordPro-Installation.html>

## Suppport
For general discussion, please see [google groups](https://groups.google.com/forum/#!forum/chordpro).

Bugs and feature requests go to [the GitHub issue tracker](https://github.com/ChordPro/chordpro/issues).

## License
Copyright © 2010,2018 The ChordPro Team

This program is free software. You can redistribute it and/or modify it under the terms of the Artistic License 2.0.
