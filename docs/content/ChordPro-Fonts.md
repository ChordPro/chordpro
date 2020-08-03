---
title: "ChordPro Implementation: Fonts"
description: "ChordPro Implementation: Fonts"
---

# ChordPro Implementation: Fonts

ChordPro uses _fonts_ for typesetting. In the config file fonts are specified for  chords, lyrics, titles and so on. For example, in the config file in section `"pdf"` there is a section `"fonts"` that has a specification for the page titles:

    "title" : {
		    "file"        : "dejavu/DejaVuSerif-Bold.ttf",
		    "name"        : "Times-Bold",
		    "size"        : 14
    },

The `"file"` specifically designates a font file on the system.
The example also has a `"name"` that designates the built-in font
`"Times-Roman"`. The `"file"` setting takes precedence, so ChordPro
will try to load the designated font file. If you remove the `"file"`
setting, ChordPro will use the built-in font.

## Using a font filename

A font filename must be either and absolute filename, or a relative
filename which is interpreted relative to the _font path_, which
consists of [configuration setting]({{< relref "ChordPro-Configuration" >}})
`fontdir`, the `fonts` resource dir, and the contents of environment
variable `FONTDIR`. In any case, the filename should point to a valid
TrueType (`.ttf`) or OpenType (`.otf`) font.

If you have quality PostScript Type1 fonts (a collection of `.pfa` or `.pfb`, with `.afm` and/or `.pfm` files) they can easily be converted to TrueType or OpenType using a tool like [FontForge](https://fontforge.github.io/).

## Using a built-in font

The ChordPro Reference Implementation supports the following built-in
font names:

* Courier, Courier-Bold, Courier-BoldOblique, Courier-Oblique
* Georgia, Georgia-Bold, Georgia-BoldItalic, Georgia-Italic
* Helvetica, Helvetica-Bold, Helvetica-BoldOblique, Helvetica-Oblique
* Verdana, Verdana-Bold, Verdana-BoldItalic, Verdana-Italic
* Times-Roman, Times-Bold, Times-BoldItalic, Times-Italic 
* Symbol, Webdings, Wingdings, ZapfDingbats

**Note** that using built-in font names has some disadvantages. The
fonts have only a limited number of characters (glyphs) and may not be
suitable for anything but English and Western European languages. The
quality of the output is less, since the built-in fonts do not support
kerning. Since real versions of these fonts are [easily
available](http://mscorefonts2.sourceforge.net/), if not already
installed, it is **strongly advised** to not use built-in fonts unless
you can deal with the limitations.

