---
title: "Chord Changes"
description: "Chord Changes"
---

# Chord Changes

**Warning: This is an experimental feature. Its behaviour may change
in future releases.**

## Memorise and Recall

When ChordPro processes the lyrics of a verse, it remembers the chords
that are used. This can be used later to recall in another verse.

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

In the first verse, ChordPro memorises the chords `D`, `G` and `D`. In the
second verse, the memorised chords are inserted in order for each
occurrence of `[^]`.

The number of recalls may not exceed the number of chords memorised.
It may be less, though.

The musical term for a sequence of chords is _chord progression_ or
_chord change_, ChordPro uses the latter term.

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

The net result for the second verse will be

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

Chord changes are associated with sections. The above example contains
two `verse` sections. The first verse section memorises the chord
changes and all subsequent verse sections can recall them. The chord
changes are memorised under the name of the section. `verse` sections
share memorised chords under the name `verse`, likewise `bridge`
sections and so on. `bridge` sections use the name `bridge` so they
won't see the chords of `verse` sections and vice versa.

It is possible to change the name with which the chord changes are
memorised, also with the `cc` attribute:

````
{start_of_verse cc="Verse1"}
I [D]looked over Jordan, and [G]what did I [D]see,
{end_of_verse}

{start_of_verse cc="Verse1"}
If [^]you get back to heaven be[^]fore I [^]do,
{end_of_verse}
````

The first verse memorises chord changes under the name `Verse1`, and
the second verse recalls them.

You can combine a predefined chord change with an explicit name by
specifying the name, followed by a colon, followed by the list of
chords. For example,

````
{start_of_verse cc="Verse1:D G D"}
If [^]you get back to heaven be[^]fore I [^]do,
{end_of_verse}
````

