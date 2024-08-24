---
title: "ChordPro: Introduction"
description: "ChordPro: The File Format Specification"
---

# Introduction to ChordPro

In a hurry? See the
[ChordPro Cheat Sheet]({{< relref "ChordPro-Cheat_Sheet" >}}).

Want to know what's new? See the
[ChordPro 6 Release information]({{< relref "ChordPro6-RelNotes" >}}).

## Overview

In 1992 Martin Leclerc and Mario Dorion developed a simple text file format to write _lead sheets_, songs with lyrics and chords, and a tool to create neatly printed lead sheets out of these text files. The tool was called `chord`, and the text files were called `chord` files. It soon became a popular way to write lead sheets and many users and tools adopted this format for similar purposes. For still unknown reasons people started calling the files `chordpro` files.

Read more?
See the [ChordPro history overview]({{< relref "Chordpro-History" >}}).

As mentioned, the ChordPro file format is a simple text file format. Any text editor or word processor can be used to create and maintain them. The text files can have arbitrary names and arbitrary types (extensions). Common filename extensions for ChordPro files are `.cho`, `.crd`, `.chopro`, `.chord` and `.pro`. If you need to choose an extension for new ChordPro files, we advise to use `.cho`. Simple, short, easy to remember, and not heavily used by other applications.

## The basics

This is an example of a simple song:

    # A simple ChordPro song.

    {title: Swing Low Sweet Chariot}

    {start_of_chorus}
    Swing [D]low, sweet [G]chari[D]ot,
    Comin’ for to carry me [A7]home.
    Swing [D7]low, sweet [G]chari[D]ot,
    Comin’ for to [A7]carry me [D]home.
    {end_of_chorus}

    I [D]looked over Jordan, and [G]what did I [D]see,
    Comin’ for to carry me [A7]home.
    A [D]band of angels [G]comin’ after [D]me,
    Comin’ for to [A7]carry me [D]home.

    {comment: Chorus}

As you can see, the lyrics of the song are interspersed with chords written between brackets `[` and `]`. The chords are placed in front of the syllable they belong to. In the printed output the chords will be printed on top of the syllable, looking like this (but much nicer):

          D          G    D
    Swing low, sweet chariot,
                           A7
    Comin’ for to carry me home.

Besides lyrics with chords, the ChordPro file contains _directives_, lines that start with `{` and end with `}`. The directives play an important part in how the printed output will look like. In the example above

    {title: Swing Low Sweet Chariot}

defines the _title_ of the song, which will most likely be placed on top of the output page.

The directives `{start_of_chorus}` and `{end_of_chorus}` indicate that the lines contained form the chorus of the song. This allows the chorus to be printed in an outstanding way. The line `{comment: Chorus}` will result in a text line containing the text `Chorus` as an indicator that the chorus should be played here.

Finally, all lines that start with a `#` are ignored. These can be used to insert remarks into the ChordPro file that are only relevant for maintainers.

In print, this song could look like one of these (click on the thumbnail to
view a larger version):

{{< showpage "style_default" "style_modern3" "style_modern2" >}}

## Markup and annotations

It is possible to use _markup_ in lyrics and other texts to change the
way how these will be typeset.
The [markup instructions]({{< relref "ChordPro_Markup" >}}) resemble the
[Pango Markup Language](https://docs.gtk.org/Pango/pango_markup.html)
as defined by the [Gnome organisation](https://www.gnome.org/)
and can be used to change text size, color, typeface (font) and more.

_Annotations_ are textual remarks placed above the lyrics, just like
chords. Annotations are specified with `[*`*text*`]`, again just like
chords. Depending on the software used to process the ChordPro data,
annotations may be rendered in an outstanding manner.

Markup and anotations are available as of [ChordPro version 6]({{< relref "ChordPro6-RelNotes" >}}).

## Is this all?

Yes, this is all there is to say about the ChordPro file format. Lyrics-and-chords lines, directives, empty lines and `#`-remarks. Of course, the most interesting part is what directives are possible and what effects they have. This is discussed in [ChordPro Directives]({{< relref "ChordPro-Directives" >}}). Also relevant is what chords can be used, this is discussed in [ChordPro Chords]({{< relref "ChordPro-Chords" >}}).

## Printing?

In the early days of ChordPro, the only way to get a nicely formatted lead sheet was to print it on a LaserWriter. The original `chord` program created a so called PostScript document that could be sent to the printer.

Much has changed. Nowadays PDF documents are used for printed output, but they can also be viewed on PC, phone and tablets. The [ChordPro reference implementation]({{< relref "ChordPro-Reference-Implementation" >}}) produces PDF by default. Nevertheless, in this document we will still use the term ‘printing’ when referring to the result of processing ChordPro files.
