# The ChordPro Reference Implementation

## Overview

Historically, the ChordPro file format was defined solely by the behaviour of the program implementating it: the `chord` program by Martin Leclerc and Mario Dorion. That was 25 years ago. Since then the easy to use file format was adopted and extended by many implementations. For practical reasons, this is called ChordPro version 4. Its latest reference implementation is an updated version of the old `chord` program called _Chord_<sub>ii</sub>.

ChordPro version 5 is designed from the ground up, using version 4 and several alternative implementations as a starting point. With version 5, a brand new reference implementation was written by Johan Vromans: ChordPro. This program provides support for ChordPro version 5, but it also supports most of the features of _Chord_<sub>ii</sub>, and a lot more.

## Native PDF generation

While PostScript was a good choice 25 years ago, nowadays PDF is much better. Not only for printing, but also for viewing on PCs, phones, tablets and so on. ChordPro produces PDF documents natively, i.e., without the help of 3rd party tools.

## Unicode support

The original `chord` program was already revolutionary in supporting the ISO-8859.1 character set for input, allowing most european languages to be processed. ChordPro takes all input in UTF-8 encoded UNICODE but falls back to ISO-8859.1 if needed. When the input files contain a [Byte Order Mark](https://en.wikipedia.org/wiki/Byte_order_mark), UTF-16 and UTF-32 are also handled automatically.

Note that the default fonts that ChordPro uses only have limited support for
non-Latin1 characters. If you need more extensive Unicode support, you
must configure ChordPro to use TrueType or OpenType fonts that have
sufficient Unicode support.

## User defined chords and tunings, not limited to 6 strings

Originally developed for guitar players, `chord` was hard coded to support 6-string instruments. This frustrated mandolin, banjo and ukulele players. ChordPro lifts this limitation and allows an arbitrary number of strings. 

## Support for Nashville Numbering and Roman Numbering

Often asked for, and ChordPro finally got it: Nashville Numbering and Roman Numbering of chords.

## Fully customizable layout, fonts and sizes

Using configuration files you can not just change fonts and sizes, but you get total control over the appearance of the output. Margins, headers, footers, columns, and more.

## Support for external TrueType and OpenType fonts

While this may be considered a feature, it is in fact a necessity since most basic fonts do not have sufficient support for UNICODE.

## A basic but effective GUI version

Traditionally a command line program, `chord` was not a trivial tool for users of Windows based systems. ChordPro adds WxChordPro, a GUI version of the program.

## What is missing?

There are just a few features that ChordPro does not, and will not, support:

* The notion of ‘easy’ and ‘hard’ chords.  
The [[chord|Directives chord]] directive can be used if you want diagrams for specific chords.

* Logical pages, i.e. 2-up and 4-up printing.  
PDF viewers and print tools can do that for you.

### More information

* [[Installation|ChordPro Installation]]
* [[Configuration|ChordPro Configuration]]
* [[User guide|Using ChordPro]]
* [[Release info|ChordPro Reference RelNotes]]
