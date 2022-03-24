---
title: "Hints and Tips"
description: "Hints and Tips"
---

# Hints and Tips

## Bold chorus

A common style nowadays puts the chorus in bold.
You need two modifications to achieve this.

First off, set some config keys:

````
pdf.chorus.indent=0
pdf.chorus.bar.width=0
pdf.chorus.recall.quote=1
pdf.chorus.recall.choruslike=1
````

Secondly, wrap the chorus in `textfont` directives:

````
{soc}
{textfont Times-Bold}
[E]Dreaming, [A]Dreaming, [B]Just go on
[E]Dreaming, [A]Dreaming, [B]Just go on
{textfont}
{eoc}
````

## Chords too close to the lyrics

The distance between the chords and the lyrics is determined by the
properties of the font used for the chords. Some fonts use the size of
the font as distance, which results in chords being placed too close,
and other fonts use the distance to the next line, resulting in chords
being higher above the lyrics.

You can adjust the chord spacing in the PDF config:

````
{ "pdf" :
  { "spacing" :
    { "chords" : 1.2,
	...
````

The value specified is a factor, it is multiplied by the font size to
obtain the distance between baseline of the chords and the baseline of
the lyrics.

## Conditional chords

You can use the following preprocessor directive
to suffix chords with an instrument name
and thus generate versions of different difficulty or specificity.
````
{
  // Settings for the parser/preprocessor.
  // Replaces all instrument-specific chords with conditional directives
  "parser" : {
    "preprocess" : {
      "songline" : [
        { "pattern" : "\\[([^-\\]]+)-(\\w+)\\]",
          "replace" : "%{instrument=$2|[$1]}"
        }
      ],
    },
  },
}
````

An example of how to use it:
````
{comment This is the %{instrument} variant}
{begin_of_verse}
[A]He[A7-piano]llo, [Bm]World![C-keyboard]
[A]Swe[A7-piano]et [Bm]Home![C-keyboard]
{end_of_verse}
````
