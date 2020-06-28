---
title: "ChordPro Release info"
description: "ChordPro Release info"
---

# ChordPro Release info

Release information for the __ChordPro file format__.

For release information for the ChordPro __reference implementation__, see
[here]({{< relref "ChordPro-Reference-RelNotes.html" >}}).

## ChordPro version 6

### Markup

In all texts (lyrics, titles, chordnames, comments, etc.) markup
instructions can be used to manipulate the appearance.

The markup instructions conform to the [Pango Markup
Language](Pango_Markup.html).

For example:

    [C]Roses are <span color="red">red</span>, [G]<b>don't forget!</b>
	
The reference implementation will produce something similar to:

![Example markup]({{< asset "images/rosesarered.png" >}})

### Annotations

Annotations are arbitrary remarks that go with a song. They are
specified just like chords, but start with an `*` symbol.

For example:

    [Em]This is the [*Rit.]end my [Am]friend.

The reference implementation will produce something similar to:

![Example annotation]({{< asset "images/thisistheend.png" >}})

Even though they are written using chord-like syntax, it is important
to know that annotations are _not_ chords. In particular:

- ChordPro processing tools may choose to show annotations in a
  different way than chords.
- No attempts will be made to transpose, transcode, or draw chord
  diagrams for annotations.

### New section directives

The following directives are added:

* start_of_verse (short: sov)
* end_of_verse (short: eov)
* start_of_bridge (short: sob)
* end_of_bridge (short: eob)

The purpose of these directives is to be able to identify portions of
the song. ChordPro processing tools may choose to use this
information, e.g. to show a bridge in a different way than a verse.

In addition to these directives it is possible to add your own section
directives, for example `{start_of_lead}` or `{start_of_coda}`. All
sections must be closed with the corresponding `{end_of_`*section*`}`.

The reference implementation treats all sections (except `chorus`,
`tab` and `grid`) as lyrics.

### Section labels

All section directives can take an optional label, which can be used
to tag individual sections. For example:

````
{start_of_verse: Verse 1}
[A]Hello there!
{end_of_verse}
 
{start_of_verse: Verse 2}
[B]Nice seeing you.
{end_of_verse}
````

The reference implementation will add a left margin to the output and
place the label text in this margin.

