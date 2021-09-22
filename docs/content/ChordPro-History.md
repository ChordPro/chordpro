# History of `ChordPro`

The original program, `Chord`, was written
Martin Leclerc and Mario Dorion.
`Chord` was dreamed up (and the chord notation
invented) by the authors in june 1991 after having arrived early at
the Tennis court for their game and having to wait for 30 minutes.
Later that day Mario had his first date with his wife-to-be, though it
is not clear whether that had anything to do with the development of
`Chord`.

The simple but effective file format used to describe the chords and
lyrics was quickly adopted by many users all around the world, and for
still unknown reasons these files became known as `ChordPro` files.
The content is written in a [Domain Specific Language](https://en.wikipedia.org/wiki/Domain-specific_language) called the
ChordPro language, or short, ChordPro.

| Chord Version | Release Date     | Remarks |
|---------|----------|---|
| 1.0 | 1992-05-20 | reconstructed from internet archives|
| 1.0PL1 | 1992-05-28 | reconstructed from internet archives|
| 1.2 | 1992-09-03 | reconstructed from internet archives|
| | | the dark ages |
| 3.6 | 1995-03 | date from the manual|
| 3.6.2 | 1995-03 | date from the manual|
| 3.6.3 | | unofficial |
| 3.6.4 | 2009-12-30 | GPL release |
{ .table .table-striped .table-bordered .table-sm }

For convenience, the ChordPro language version supported by the latter
programs is set to `3`, to reflect the major version number of the
implementation.

## From `Chord` to `Chord`<sub><i>ii</i></sub>

Johan Vromans adopted `Chord` in 1992 and for several
years enhanced the program for his own personal needs,
since Martin and Mario stopped development and maintenance
and seemingly disappeared from the internet.

In 2007 Adam Monsen, also a grateful user of the tool, convinced
Johan that `Chord` may not get lost for the public, and after failure
to contact the original authors they decided to take over the program,
upgrade it to modern standards, and release it, again, to the
public. 

In its first reincarnation, the name `Chordie` was used.
Since this would cause confusion with the [chordie.com](https://www.chordie.com) website,
the name was changed into `Chord`<sub><i>ii</i></sub>,
to be pronounced as chord-ee-ee.

To avoid confusion, the first version of `Chord`<sub><i>ii</i></sub> was 4.0.
The added improvements formed the base of ChordPro language version `4`.

The last known distribution of the original `Chord`
program is 3.6.2 and dates from july 1995. It includes a statement
that `Chord` is licensed following the conditions of the
general GNU license, but with some additional restrictions. These
restrictions formed an obstacle for
`Chord`<sub><i>ii</i></sub> to be included in official
software distributions.

In december 2009 Johan Vromans finally succeeded to track down the
original authors and they agreed to create a new, GPL-only release.
This release was called 3.6.4 to avoid confusion with an already
existing unofficial 3.6.3 version. Following the `Chord` GPL release
`Chord`<sub><i>ii</i></sub> was rebased on the 3.6.4 version, making
it officially and legally GPL.

| Chord<sub><i>ii</i></sub> Version | Release Date     | Remarks |
|---------|----------|---|
| 4.0.0 | 2007-11-30 ||
| 4.1.0 | 2008-03-05 ||
| 4.2.0 | 2008-06-14 ||
| 4.3.0 | 2009-12-30 | GPL release |
| 4.4.0 | 2012-09-25 ||
| 4.5.0 | 2013-06-19 ||
| 4.5.1 | 2013-06-21 ||
| 4.5.2 | 2015-10-04 ||
| 4.5.3 | 2015-11-23 ||
| 4.6.0 | 2017-11-09 ||
| | 2020-02-02 | Post-EOL fix for legacy packages |
{ .table .table-striped .table-bordered .table-sm }

`Chord`<sub><i>ii</i></sub> development was tracked in a public repository on
[SourceForge](https://sourceforge.net/projects/chordii).


## From `Chord`<sub><i>ii</i></sub> to `ChordPro`

ChordPro language version `5` added a number of new features,
pushing the limits of the very old program.
Unicode support would have been very hard to add,
and the whole program centered around PostScript generation,
which has been superseded by PDF today.

So Johan Vromans set out to create a new program from the ground up.
He choose the programming language Perl because it is fun and flexible
with good support for Unicode and other relevant features.

The result is `ChordPro`, a program named after the file format.
It supports [almost all]({{< relref "chordpro-reference-implementation#what-is-missing" >}}) of the features of `Chord`<sub><i>ii</i></sub> and a lot more,
such as native PDF generation, Unicode input and fully customizable layout, fonts and sizes.
The first release of `ChordPro`, an alpha version, was on June 4, 2016. 

`ChordPro` development is tracked in a public repository on
[GitHub](https://github.com/chordpro/chordpro).
Its development follows the _Release Early, Release Often_ approach;
as of July 2021 there have been more than 67 releases.
 
Johan also established [ChordPro.org](https://www.chordpro.org) as
a stable home for the ChordPro language standard and supporting
implementation, and a user community on [Groups.io](https://groups.io/g/ChordPro).
