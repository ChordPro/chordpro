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

This might become easier in the future,
see https://github.com/ChordPro/chordpro/issues/174.

## [Conditional chords](https://github.com/ChordPro/chordpro/issues/176)

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
