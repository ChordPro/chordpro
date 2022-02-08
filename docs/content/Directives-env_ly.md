---
title: "Directives: start_of_ly"
description: "Directives: start_of_ly"
---

# Directives: start_of_ly

__EXPERIMENTAL__

This directive indicates that the lines that follow define a piece of
music written in [Lilypond](https://lilypond.org).

For example

    {start_of_ly}
    \relative { g'8\( a b[ c b\) a] g4 }
    {end_of_ly}

The result could look like:

![]({{< asset "images/ex_ly1.png" >}})

**Important** To render Lilypond, ChordPro makes use of external tools to
convert the Lilypond source to an image, and then embeds the image (see
[image directive]({{< relref "directives-image" >}})). Depending on
the external tools support for embedded Lilypond may be limited, or absent.

This directive may include an optional label, to be printed in the
left margin. For example:,

    {start_of_ly: Intro}

The ChordPro reference implementation prints the label in the left
margin, see [labels]({{< relref "ChordPro-Configuration-PDF#labels" >}}).

## General rules for embedding Lilypond source

* A suitable `\version` directive will be prepended, although it is
  always better to include your own.

* To prevent large (full-page) images, printing the Lilypond tag line is
  suppressed by prepending

      \header { tagline = ##f }

* ChordPro transposition using `{transpose}` and/or `--transpose` will
  **not transpose** the embedded Lilypond. This is hopefully a
  temporary restriction. Adding `\transpose` to the Lilypond
  source will work as usual, affecting the Lilypond notes only.

* The Lilypond data is converted and included as a single image.
  No vertical splitting between staves.

* The LilyPond data must start with a line that
  starts with a percent `%` sign or backslash `\`. Anything before this
  line will be considered formatting instructions (see below).

Since the actual rendering is handled by external tools, ChordPro has
no control over what and how the output will look like.

## Formatting instructioms

The Lilypond data may be preceded by formatting instructions:

* scale=_n_  
  Scale the image with the given factor.

* center  
  Center the image on the page.

# Directives: end_of_ly

This directive indicates the end of the Lilypond section.
