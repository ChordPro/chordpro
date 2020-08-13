---
title: "ChordPro Implementation: Chords"
description: "ChordPro Implementation: Chords"
---

# ChordPro Implementation: Chords

In ChordPro files, lyrics are interspersed with chords between
brackets `[` and `]`. Strictly speaking it doesn't matter what you put
between the `[]`, it is put on top of the syllable whatever it is. But
there are situations where it **does** matter: for chord diagrams and
transpositions.

In general, ChordPro will try to interpret what is between the
brackets as a valid chord name, unless the first character is an
asterisk, `*`. In that case ChordPro will remove the asterisk and
treat everything else as a text that will be printed just like the
chord names. This can be used to add small annotations, e.g. `[*Coda]`
and `[*Rit.]`.

ChordPro can parse chord names in two modes: _strict_ and _relaxed_.

In _strict_ mode, chord names are only recognized if they consist of
* a root note, e.g. `C`, `F#` or `Bb`.
* a _qualifier_, e.g. `m` (minor), `aug` (augmented), or empty.
* an _extension_, which must be one of the extension names built-in.

In _relaxed_ mode, the same rules apply for root note and qualifier,
but the extension is not required to be known. You are free to make up
your own. In relaxed mode, `[Coda]` would be a valid chord name.

Many ChordPro implementations (formatters) provide chord diagrams at
the end of a song, using a built-in list of known chords and
fingerings. Clearly, this can only work when the chords in the
ChordPro file can be recognized, either in strict mode, or in relaxed
mode.

For transposition it is slightly easier. For example, when you're
transposing from A to C, you can replace everything chord-like that
starts with ‘A’ by ‘C’ and whatever follows the ‘A’. ‘Am7’ becomes
‘Cm7’ and ‘Alpha’ would become ‘Clpha’, who cares?

Although the ChordPro File Format Specification deliberately doesn't
say anything about valid chords, it is advised to stick to commonly
accepted chord names. The ChordPro Reference Implementation
supports at least:

* A, B, C, …, G (European/Dutch), H (German)
* I, II, III, …, VII (Roman)
* 1, 2, 3, …, 7 (Nashville)
* `b` for flat, and `#` for sharp
* Common qualifiers like `m`, `dim`, etc.
* Common extensions like `7`, `alt`, etc.

# ChordPro Implementation: Notes

If enabled in the [config]({{< relref "chordpro-configuration-generic#general-settings" >}}), ChordPro will understand lowercase root-only
chords to mean note names. Note names will be treated (shown,
transposed) exactly as chords, but will not account for diagrams. 

This can be used for example for intro's that start with some single
notes before the chords:

````
{comment: Intro [f] [g] [a] [E] }
````
