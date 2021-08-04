---
title: "Directives: start_of_abc"
description: "Directives: start_of_abc"
---

# Directives: start_of_abc

__EXPERIMENTAL__

This directive indicates that the lines that follow define a piece of
music written in [ABC music notation](https://www.abcnotation.com).

For example

    {start_of_abc}
	T:The Gentle Breeze
	M:2/4
	L:1/8
	R:Air
	K:Em
    E>F G/2E/2-E| {A}B2{^c/2B/2}A>B| G/2E/2-E d2| B/2^c/2d B/2c/2d| e>f d>f|\
    e3 B| g>B f>B| ef| eB F>B| E4:|
    {end_of_abc}

The result could look like:

![]({{< asset "images/ex_abc1.png" >}})

**Important** To render ABC, ChordPro makes use of external tools to
convert the ABC source to an image, and then embeds the image (see
[image directive]({{< relref "directives-image" >}})). Depending on
the external tools support for embedded ABC may be limited, or absent.

** Note** If you encounter problems with ABC content, first copy the ABC content
into a separate file and run it through an ABC postprocessor (e.g.
`abcm2ps` or `abc2svg`) to see if there are errors in the ABC content.

This directive may include an optional label, to be printed in the
left margin. For example:,

    {start_of_abc: Intro}

The ChordPro reference implementation prints the label in the left
margin, see [labels]({{< relref "ChordPro-Configuration-PDF#labels" >}}).

## General rules for embedding ABC source

* ChordPro transposition using `{transpose}` and/or `--transpose` will
  transpose the embedded ABC. Adding `%%transpose` to the ABC
  source will affect the ABC notes only.

* The ABC data is converted and included as a single image.
  No vertical splitting between staves.

Since the actual rendering is handled by external tools, ChordPro has
no control over what and how the output will look like.

# Directives: end_of_abc

This directive indicates the end of the abc section.
