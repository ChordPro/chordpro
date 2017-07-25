## The ChordPro Reference Implementation

Historically, the ChordPro file format was defined solely by the behaviour of the program implementating it: the `chord` program by Martin Leclerc and Mario Dorion. That was 25 years ago. Since then the easy to use file format was adopted and extended by many implementations. For practical reasons, this is called ChordPro version 4. Its latest reference implementation is an updated version of the old `chord` program called _Chord_<sub>ii</sub>.

ChordPro version 5 is designed from the ground up, using version 4 and several alternative implementations as a starting point. With version 5, a brand new reference implementation was written by Johan Vromans: ChordPro. This program provides support for ChordPro version 5, but it also supports most of the features of _Chord_<sub>ii</sub>, and a lot more:

    * Native PDF generation.

    * Unicode support (all input is UTF8).

    * User defined chords and tunings, not limited to 6 strings.

    * Support for Nashville Numbering and Roman Numbering.

    * Support for external TrueType and OpenType fonts.

    * Font kerning (with external fonts).

    * Fully customizable layout, fonts and sizes.

    * A basic but effective GUI version (optional).

    * Customizable backends for PDF, ChordPro, LilyPond*, LaTeX* and HTML*.
      (* = under development)
