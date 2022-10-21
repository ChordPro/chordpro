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
	X:1
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

This directive may include an optional label, to be printed in the
left margin. For example:,

    {start_of_abc: Intro}

The ChordPro reference implementation prints the label in the left
margin, see [labels]({{< relref "ChordPro-Configuration-PDF#labels" >}}).

## General rules for embedding ABC source

* Always start ABC content with `X:1` as first line and insert an
  empty line before the `{end_of_abc}` directive. 
  Anything before this
  line will be considered formatting instructions (see below).
  See also [Remarks]({{< relref "#remarks" >}}).

* ChordPro transposition using `{transpose}` and/or `--transpose` will
  transpose the embedded ABC. Adding `%%transpose` to the ABC
  source will affect the ABC notes only.

* The ABC data is converted and included as a single image.
  No vertical splitting between staves.

Since the actual rendering is handled by external tools, ChordPro has
no control over what and how the output will look like.

## Formatting instructions

The ABC data may be preceded by formatting instructions:

* scale=_n_  
  Scale the image with the given factor.

* center  
  Center the image on the page.

* split  
  ChordPro will attempt to split the generated image into individual
  systems so longer scores can be put into multiple pages.  
  Note that there is no guarantee this will work for your score.

# Directives: end_of_abc

This directive indicates the end of the abc section.

# Remarks

To render ABC, ChordPro makes use of external tools to
convert the ABC source to an image, and then embeds the image (see
[image directive]({{< relref "directives-image" >}})). **Depending on
the external tools support for embedded ABC may be limited, or absent.**

Always include `X:1` as the first line of the ABC content, and insert
an empty line before the `{end_of_abc}`. This delimits the ABC content
so 3rd party tools can manupulate the ABC content directly from the
ChordPro source.

If you encounter problems with ABC content, run your ChordPro file
through an ABC postprocessor (e.g. `abcm2ps` or `abc2svg`) to see if
there are errors in the ABC content.

