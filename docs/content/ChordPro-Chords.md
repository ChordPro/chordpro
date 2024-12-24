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

## Parsing chords — the chord properties

ChordPro can parse chord names in two modes: _strict_ and _relaxed_.

In _strict_ mode, enabled by default, chord names are only recognized
if they consist of
* a root note, e.g. `C`, `F#` or `Bb`.
* an optional _qualifier_, e.g. `m` (minor), `aug` (augmented).
* an optional _extension_, which must be one of the extension names built-in.
* an optional _bass_, a slash `/` followed by another root note.

When a chord name is successfully parsed, each of the above
constituents is registered with the chord as properties `root`,
`qual`, `ext` and `bass`.
It's name is registered as property `name`. These properties are
referred to as the *chord properties* of the chord.

Some examples:

| name   | root  | qual | ext | bass |
|--------|-------|------|-----|------|
| `C`    | `C`   |      |     |      |
| `F#`   | `F#`  |      |     |      |
| `Besm` | `Bes` | `m`  |     |      |
| `Am7`  | `A`   | `m`  | `7` |      |
| `C/B`  | `C`   |      |     | `B`  |
{ .table .table-striped .table-bordered .table-sm }

Note: What is recognized as a root note and what is stored in the
`root` property is controlled by the 
[`notes` section]({{< relref "chordpro-configuration-instrument" >}})
of the config files. For example, in the common notation `B♭`, `Bb`
and `Bes` all designate a B-flat note.

In _relaxed_ mode, the same rules apply for root note and qualifier,
but the extension is not required to be known. You are free to make up
your own. In relaxed mode, `[Coda]` would be a valid chord name: root
`C` plus extension `oda`.

| name   | root | qual | ext   | bass |
|--------|------|------|-------|------|
| `Coda` | `C`  |      | `oda` |      |
| `Gm*`  | `G`  | `m`  | `*`   |      |
{ .table .table-striped .table-bordered .table-sm }

Chord properties can be used as [metadata for substitutions]({{<
relref "Chordpro-Configuration-Format-Strings/#chord-display-strings" >}}).

## Chord diagrams — the diagram properties

Many ChordPro implementations (formatters) provide chord diagrams at
the end of a song, using a built-in list of known chords and
fingerings. Clearly, this can only work when the chords in the
ChordPro file can be recognized, either in strict mode, or in relaxed
mode. If a chord is known there may be some additional
properties that are used internally to produce chord diagrams. This
set of properties is referred to as the *diagram properties* of the
chord.

Some examples:

| name  | base | frets       | fingers     | keys     |
|-------|------|-------------|-------------|----------|
| `Am7` | 1    | x 0 2 0 1 3 | x x 2 3 1 x | 0 3 7 10 |
| `B`   | 2    | 1 1 3 3 3 1 | 1 1 2 3 4 1 | 0 4 7    |
{ .table .table-striped .table-bordered .table-sm }

The list of known chords is read from the config files and can be
extended by defining chords using the [define directive]({{< relref
"Directives-define" >}}).

## Transposition and transcoding

For transposition and transcoding the chord **must** have at least a
`root` property. This controls what and how can be transposed or
transcoded. 
For example, when you're
transposing from A to C, you can replace everything chord-like that
starts with `A` by `C` and whatever follows the `A`. `Am7` becomes
`Cm7` and `Alpha` would become `Clpha`, who cares?

## Valid chord names

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

# Appendix: List of known chord extensions

Note that _extensions_ here include the _qualifier_.

The following chord extensions are currently built-in.

### Extensions for major chords

Note that `^` is an alternative for `maj`.

````
   2
   3
   4
   5
   6
   69
   7
   7-5
   7#5 7#9 7#9#5 7#9b5 7#9#11
   7b5 7b9 7b9#5 7b9#9 7b9#11 7b9b13 7b9b5 7b9sus 7b13 7b13sus
   7-9 7-9#11 7-9#5 7-9#9 7-9-13 7-9-5 7-9sus
   711
   7#11
   7-13 7-13sus
   7sus 7susadd3
   7+
   7alt
   9
   9+
   9#5
   9b5
   9-5
   9sus
   9add6
   maj7 maj711 maj7#11 maj13 maj7#5 maj7sus2 maj7sus4
   ^7 ^711 ^7#11 ^7#5 ^7sus2 ^7sus4
   maj9 maj911
   ^9 ^911
   ^13
   ^9#11
   11
   911
   9#11
   13
   13#11
   13#9
   13b9
   alt
   add2 add4 add9
   sus2 sus4 sus9
   6sus2 6sus4
   7sus2 7sus4
   13sus2 13sus4
````

### Extensions for minor chords

Minor chords can use `m`, `mi`, `min` and `-`. 

In the list below only the `m` variants are enumerated,

````
   m#5
   m11
   m6
   m69
   m7b5
   m7-5
   mmaj7
   mmaj9
   m9maj7
   m9^7
   madd9
   mb6
   m#7
   msus4 msus9
   m7sus4
````

### Other extensions

````
   aug +
   dim 0
   dim7
   h h7
   h9
````
