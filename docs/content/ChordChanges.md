---
title: "Chord Changes"
description: "Chord Changes"
---

# Chord Changes

**Warning: This is an experimental feature. Its behaviour may change
in future releases.**

## Memorise and Recall

When ChordPro processes the lyrics of a section, e.g. a verse, it
remembers the chords that are used. This can be used later to recall
in another section.

To recall a chord, the special 'chord' `[^]` is used. Every occurrence
of the recall chord will be replaced by the corresponding chord that
was memorised from a preceding verse.

````
{start_of_verse}
I [D]looked over Jordan, and [G]what did I [D]see,
{end_of_verse}

{start_of_verse}
If [^]you get back to heaven be[^]fore I [^]do,
{end_of_verse}
````

In the first verse section, ChordPro memorises the chords `D`, `G` and
`D` as a sequential list.
In the second verse section, each `[^]` is usually replaced by the
next unused chord from that list (unless overridden, described below).

The number of recalls in a section may not exceed the number of chords
memorised, but may be fewer. That is, when the list of memorised
chords has been used up, there are no more chords left to use.

You can have multiple verse sections that recall chords, but it is
important to keep in mind that only the chords of the **first** verse
section are memorised.

The musical term for a sequence of chords is _chord progression_ or
_chord change_, ChordPro uses the latter term.

Chord memory is available only for sections defined using `{start_of_
...}` and `{end_of_ ...}` directives, but you can use arbitrary
sections like `{start_of_verse_a}` and `{start_of_verse_b}` to
memorise and recall two different sets of verse chords.

In the ChordPro config you can add

    settings.memorize: true

This will allow a sole `^` character to recall chords:

````
{start_of_verse}
If ^you get back to heaven be^fore I ^do,
{end_of_verse}
````

## Overriding recalled chords

Sometimes you do not want all chords, but most of them. For example,
when the section has a differing chord at a certain place. This can be
achieved by simply writing the desired chord instead of `[^]`.

````
{start_of_verse}
I [D]looked over Jordan, and [G]what did I [D]see,
{end_of_verse}

{start_of_verse}
If [^]you get back to heaven be[G7]fore I [^]do,
{end_of_verse}
````

The first `[^]` will be replaced by the first memorised chord, `D`.
The `[G7]` will produce a `G7` chord, and _skip the second memorised
chord_. The final `[^]` will be replaced by the third memorised chord,
`D`.

The net result for the second verse section will be

````
{start_of_verse}
I [D]looked over Jordan, and [G7]what did I [D]see,
{end_of_verse}
````
## Predefine Chord Changes

In the examples above the chord changes were memorised on the fly
while processing a section. It is also possible to predefine chord
changes for a section using the `cc` attribute.

````
{start_of_verse cc="D G D"}
I [^]looked over Jordan, and [^]what did I [^]see,
{end_of_verse}
````

The `cc` attribute value is a string containing a series of
space-separated chords to be memorised.

## Named Chord Changes

Each set of chord changes is automatically associated with a type of
section, such as verse, in which it is initially memorised, then
recalled whenever `[^]` is used in subsequent `start_of_verse` sections.
Similarly, with `start_of_chorus` or `start_of_bridge` sections, each can
have its own set of memorised chords, which reflects the type of
section.

It is also possible to name each set of chord changes
independently of the section type, by using the `cc` attribute:
	
````
{start_of_verse cc="Verse1"}
I [D]looked over Jordan, and [G]what did I [D]see,
{end_of_verse}

{start_of_verse cc="Verse1"}
If [^]you get back to heaven be[^]fore I [^]do,
{end_of_verse}
````

The first verse memorises chord changes under the name Verse1, and the
second verse recalls them. This allows us to use the `{start_of_verse}`
directive for all verses, but memorise/recall different sets of named
chord changes for some verses.

You can combine a predefined chord change with an explicit name by
specifying the name, followed by a colon, followed by the list of
chords. For example,

````
{start_of_verse cc="Verse1:D G D"}
If [^]you get back to heaven be[^]fore I [^]do,
{end_of_verse}
````

## Chord Changes from Grid sections

Grid sections memorise chords under the name `grid`. This name
can be changed with a `cc` attribute.

Single-measure `%` and double measure `%%` repeats are expanded for
the memorisation, and so are `|:` and `:|` repeats. Repeats with
alternatives are currently not functional, this may be added later.

````
{start_of_grid cc="verse"}
|: C | D | % | G :|
{end_of_grid}
````

This memorises the chord changes `C D D G C D D G` under the name
`verse`, so that a subsequent verse section can recall them.
