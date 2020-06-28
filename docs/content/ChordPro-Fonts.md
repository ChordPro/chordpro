---
title: "ChordPro Implementation: Fonts"
description: "ChordPro Implementation: Fonts"
---

# ChordPro Implementation: Fonts

ChordPro uses _fonts_ for typesetting. In the config file fonts are specified for  chords, lyrics, titles and so on. For example, in the config file in section `"pdf"` there is a section `"fonts"` that has a specification for the page titles:

    "title" : {
		    "description" : "Serif Bold",
		    "file"        : "dejavu/DejaVuSerif-Bold.ttf",
		    "name"        : "Times-Bold",
		    "size"        : 14
    },

This example has a `"description"` that generically describes what kind of font is wanted: a _serif_ font that is _bold_.
The `"file"` specifically designates a font file on the system.
The example also has a `"name"` that designates the built-in font `"Times-Roman"`. Depending on the software libraries that are installed on your system, ChordPro will use the description to find a suitable font, or load the designated font file, or use the built-in font.

## Using a font description

A font description is a flexible and system independent way to
select a font. The description is a string containing up to four identifying items: the font *family*, the *style*, the *weight* and the *size*. A font family
**must** be provided, the other parts are optional.

For example, to select the bold version of Arial at 14 point size, the
font description to be used is `"arial bold 14"`. The system will
then try to find a font file for this font, e.g. `Arial-Bold.ttf` or a
suitable replacement if this exact font could not be found.

Generic family names (*aliases*) can be used instead of existing family
names. So you can use `"serif"` for a serif font, and leave it to the
system to find an appropriate font for it. Other frequently used
aliases are `"sans"` and `"mono"`.

### Why is using font descriptions important?

Because ChordPro allows you to use [Pango style markup]({{< relref "Pango_Markup.html" >}}) in all your lyrics, titles and so on. For example:

    [C]winkle, twinkle <bold>little</bold> [G]star

When you designate a font family to be used for your lyrics, ChordPro can find the bold and italic members of the same font. With a particular font like `"myfont.ttf"` it will not possible to find the other family members.

### How does the system find the appropriate fonts?

Most modern systems are equipped with a facility called `fontconfig` or `fc-conf` or something similar. This facility can be used to fetch font information, e.g. the font file name, for fonts installed on the system.

ChordPro also provides a font search facility. This can be used if your system does not have `fontconfig`, or when you want to override the system behaviour.

In the config file in section `"pdf"` there is a section `"fontconfig"` that can be used to map family names to real font files. For example:

    "fontconfig" : {
	    "serif" : {
		    ""            : "dejavu/DejaVuSerif-Regular.ttf",
		    "bold"        : "dejavu/DejaVuSerif-Bold.ttf",
		    "italic"      : "dejavu/DejaVuSerif-Italic.ttf",
		    "bolditalic"  : "dejavu/DejaVuSerif-BoldItalic.ttf",
      },
    },

For each family name you should specify four members: a regular font (with an empty key), a bold font (key `"bold"` or `"b"`), an italic font (key `"italic"` or `"i"` or `"oblique"` or `"o"`), and a bold-italic font.

This is the short story. The longer story is that instead of a file name you can specify another set of key/value pairs, for example:

    "fontconfig" : {
	    "serif" : {
		    ""            : {
		      "file"      : "dejavu/DejaVuSerif-Regular.ttf",
		      "interline" : 1,
		    },
		    ...
    },

`"interline"` is a font property that changes the way ChordPro deals with the font. Exact semantics of font properties are still under development.

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

