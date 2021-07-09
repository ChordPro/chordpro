---
title: "ChordPro Implementation: Fonts"
description: "ChordPro Implementation: Fonts"
---

# ChordPro Implementation: Fonts

{{< toc >}}

TL;DR? See the [examples]({{< relref "#examples" >}}).

ChordPro uses _fonts_ for PDF typesetting. In the config file fonts
are specified for chords, lyrics, page titles and so on. For example, in
the default config file in section `"pdf"` there is a section `"fonts"` that
has a specification for the page titles:

    "title" : {
            "name"        : "Times-Bold",
            "size"        : 14
    },

The `"name"` designates the built-in font `"Times-Roman"`.
Alternatively you can use `"file"` to designate a font file on your
system, or `"description"` to find a suitable font using _font families_.
The order of precedence is `"file"`, `"description"`, and `"name"`.

## Method 1: Using a font filename

A font filename can be specified with `"file"` and must be either an
absolute filename, or a relative filename which is interpreted
relative to the _font path_, which consists of [configuration
setting]({{< relref "ChordPro-Configuration" >}}) `fontdir`, the
`fonts` resource dir, and the contents of environment variable
`FONTDIR`. In any case, the filename should point to a valid TrueType
(`.ttf`) or OpenType (`.otf`) font.

If the font file cannot be found, ChordPro will abort with an
appropriate error message.

If you have quality PostScript Type1 fonts (a collection of `.pfa` or
`.pfb`, with `.afm` and/or `.pfm` files) they can easily be converted
to TrueType or OpenType using a tool like
[FontForge](https://fontforge.github.io/).

## Method 2: Using a font description

A font description is a flexible and system independent way to select
a font. The description is a string containing up to four identifying
items: the font *family*, the *style*, the *weight* and the *size*. A
font family **must** be provided, the other parts are optional.

For example, to select the bold version of Arial at 14 point size for
the titles:

    "title" : {
            "description" : "arial bold 14",
    },

The system will then try to find a font file for this font, e.g.
`Arial-Bold.ttf` or a suitable replacement if this exact font could
not be found.

Generic family names (*aliases*) can be used instead of existing family
names. So you can use `"serif"` for a serif font, and leave it to the
system to find an appropriate font for it. Other frequently used
aliases are `"sans"` and `"mono"`.

### Why is using font descriptions important?

Because ChordPro allows you to use [Pango style markup]({{< relref
"Pango_Markup.html" >}}) in all your lyrics, titles and so on. For
example:

    [C]winkle, twinkle <bold>little</bold> [G]star

When you designate a font family to be used for your lyrics, ChordPro
can find the bold and italic members of the same font. When specifying
a built-in font or a font file like `"myfont.ttf"` it will generally
not possible to find the other family members.

### How does the system find the appropriate fonts?

Most modern systems are equipped with a facility called `fontconfig`
or `fc-conf` or something similar. This facility can be used to fetch
font information, e.g. the font file name, for fonts installed on the
system.

ChordPro also provides its own font search facility. This can be used
if your system does not have `fontconfig`, or when you want to
override the system behaviour for precise control over the fonts being
used.

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

`"interline"` is a font property that changes the way ChordPro deals
with the font.

Another property is `"shaping"`. This property is mandatory for
typesetting languages that need special glyph processing. For example:

    "fontconfig" : {
        "devanagari" : {
            ""            : {
                "file"    : "lohit-devanagari/Lohit-Devanagari.ttf",
                "shaping" : 1,
            },
            ...
    },

Note that shaping requires the perl module `HarfBuzz::Shaper` to be
installed on the system.

_Exact semantics of font properties are still under development._

## Method 3: Using a built-in font

Built-in fonts are specified with `"name"`. The ChordPro Reference
Implementation supports the following built-in font names:

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

# Examples

Note that the examples only show the `"fontconfig"` and `"fonts"`
parts. These should be part of the `"pdf"` config as explained in 
[Configuration for PDF output](http://phoenix.squirrel.nl:1313/chordpro-configuration-pdf/).

Each example consists of two parts: the mapping of font families, 
and associating output elements to font families. The latter part is
**identical in all examples** but included for convenience.

## Example setup using built-in fonts

````
// "fontconfig" maps members of font families to built-in fonts.

"fontconfig" : {
    // alternatives: regular r normal <empty>
    // alternatives: bold b strong
    // alternatives: italic i oblique o emphasis
    // alternatives: bolditalic bi italicbold ib boldoblique bo obliquebold ob
    "serif" : {
        ""            : "Times-Roman",
        "bold"        : "Times-Bold",
        "italic"      : "Times-Italic",
        "bolditalic"  : "Times-BoldItalic",
    },
    "sans" : {
        ""            : "Helvetica",
        "bold"        : "Helvetica-Bold",
        "oblique"     : "Helvetica-Oblique",
        "boldoblique" : "Helvetica-BoldOblique",
    },
    "monospace" : {
        ""            : "Courier",
        "bold"        : "Courier-Bold",
        "italic"      : "Courier-Italic",
        "bolditalic"  : "Courier-BoldItalic",
    },
    "dingbats" : {
        ""            : "ZapfDingbats",
    },
},

// "fonts" associates output elements to font families as defined in
// "fontconfig" above.
// Not all elements need to be associated since they default to other
// settings.

"fonts" : {
    "title" : {
        "description" : "serif bold 14",
    },
    "subtitle" : {
        "description" : "serif 11",
    },
    "text" : {
        "description" : "serif 12",
    },
    "chord" : {
        "description" : "sans italic 10",
    },
    "comment" : {
        "description" : "sans 12",
        "background" : "#E5E5E5"
    },
    "comment_italic" : {
        "description" : "sans italic 12",
    },
    "comment_box" : {
        "description" : "sans 12",
        "frame" : 1
    },
    "tab" : {
        "description" : "monospace 10",
    },
    "toc" : {
        "description" : "serif 11",
    },
    "grid" : {
        "description" : "sans 10",
    },
    "chordfingers" : {
        "description" : "dingbats 10",
    },
},
````

## Example setup using TrueType fonts (Linux)

````
// Relative filenames are looked up in the fontdirs.
// Note that font locations may be different on your system.

"fontdir" : [
    "/usr/share/fonts/liberation-serif",
    "/usr/share/fonts/liberation-sans",
    "/usr/share/fonts/liberation-mono",
],

// "fontconfig" maps members of font families to font files.

"fontconfig" : {
    // alternatives: regular r normal <empty>
    // alternatives: bold b strong
    // alternatives: italic i oblique o emphasis
    // alternatives: bolditalic bi italicbold ib boldoblique bo obliquebold ob
    "serif" : {
        ""            : "LiberationSerif-Regular.ttf",
        "bold"        : "LiberationSerif-Bold.ttf",
        "italic"      : "LiberationSerif-Italic.ttf",
        "bolditalic"  : "LiberationSerif-BoldItalic.ttf",
    },
    "sans" : {
        ""            : "LiberationSans-Regular.ttf",
        "bold"        : "LiberationSans-Bold.ttf",
        "oblique"     : "LiberationSans-Italic.ttf",
        "boldoblique" : "LiberationSans-BoldItalic.ttf",
    },
    "monospace" : {
        ""            : "LiberationMono-Regular.ttf",
        "bold"        : "LiberationMono-Bold.ttf",
        "italic"      : "LiberationMono-Italic.ttf",
        "bolditalic"  : "LiberationMono-BoldItalic.ttf",
    },
    "dingbats" : {
        // No Liberation equivalent, use corefont.
        ""            : "ZapfDingbats",
    },

// "fonts" associates output elements to font families as defined in
// "fontconfig" above.
// Not all elements need to be associated since they default to other
// settings.

"fonts" : {
    "title" : {
        "description" : "serif bold 14",
    },
    "subtitle" : {
        "description" : "serif 11",
    },
    "text" : {
        "description" : "serif 12",
    },
    "chord" : {
        "description" : "sans italic 10",
    },
    "comment" : {
        "description" : "sans 12",
        "background" : "#E5E5E5"
    },
    "comment_italic" : {
        "description" : "sans italic 12",
    },
    "comment_box" : {
        "description" : "sans 12",
        "frame" : 1
    },
    "tab" : {
        "description" : "monospace 10",
    },
    "toc" : {
        "description" : "serif 11",
    },
    "grid" : {
        "description" : "sans 10",
    },
    "chordfingers" : {
        "description" : "dingbats 10",
    },
},

````

## Example setup using TrueType fonts (Microsoft Windows)

````
// Relative filenames are looked up in the fontdirs.
"fontdir" : [ "C:\\Windows\\Fonts" ],

// "fontconfig" maps members of font families to physical fonts.

"fontconfig" : {
    // alternatives: regular r normal <empty>
    // alternatives: bold b strong
    // alternatives: italic i oblique o emphasis
    // alternatives: bolditalic bi italicbold ib boldoblique bo obliquebold ob
    "serif" : {
        ""            : "georgia.ttf",
        "bold"        : "georgiab.ttf",
        "italic"      : "georgiai.ttf",
        "bolditalic"  : "georgiaz.ttf",
    },
    "sans" : {
        ""            : "arial.ttf",
        "bold"        : "arialbd.ttf",
        "oblique"     : "ariali.ttf",
        "boldoblique" : "arialbi.ttf",
    },
    "monospace" : {
        ""            : "cour.ttf",
        "bold"        : "courbd.ttf",
        "italic"      : "couri.ttf",
        "bolditalic"  : "courbi.ttf",
    },
    "dingbats" : {
        // No equivalent, use corefont.
        ""            : "ZapfDingbats",
    },
},

// "fonts" associates output elements to font families as defined in
// "fontconfig" above.
// Not all elements need to be associated since they default to other
// settings.

"fonts" : {
    "title" : {
        "description" : "serif bold 14",
    },
    "subtitle" : {
        "description" : "serif 11",
    },
    "text" : {
        "description" : "serif 12",
    },
    "chord" : {
        "description" : "sans italic 10",
    },
    "comment" : {
        "description" : "sans 12",
        "background" : "#E5E5E5"
    },
    "comment_italic" : {
        "description" : "sans italic 12",
    },
    "comment_box" : {
        "description" : "sans 12",
        "frame" : 1
    },
    "tab" : {
        "description" : "monospace 10",
    },
    "toc" : {
        "description" : "serif 11",
    },
    "grid" : {
        "description" : "sans 10",
    },
    "chordfingers" : {
        "description" : "dingbats 10",
    },
},
````

## Example font config using system fonts

While this will always generate good results, the results may, and
will, be different when run on another system. Of after a system
update.

````
// Explicitly disable our fontconfig, so fonts will be looked up
// by the system.
"fontconfig" : [],

// "fonts" associates output elements to font families as defined in
// "fontconfig" above.
// Not all elements need to be associated since they default to other
// settings.

"fonts" : {
    "title" : {
        "description" : "serif bold 14",
    },
    "subtitle" : {
        "description" : "serif 11",
    },
    "text" : {
        "description" : "serif 12",
    },
    "chord" : {
        "description" : "sans italic 10",
    },
    "comment" : {
        "description" : "sans 12",
        "background" : "#E5E5E5"
    },
    "comment_italic" : {
        "description" : "sans italic 12",
    },
    "comment_box" : {
        "description" : "sans 12",
        "frame" : 1
    },
    "tab" : {
        "description" : "monospace 10",
    },
    "toc" : {
        "description" : "serif 11",
    },
    "grid" : {
        "description" : "sans 10",
    },
    "chordfingers" : {
        "description" : "dingbats 10",
    },
},

// On my system, this yields:
// dingbats      --  /usr/share/fonts/urw-base35/D050000L.otf
// monospace     --  /usr/share/fonts/dejavu/DejaVuSansMono.ttf
// sans          --  /usr/share/fonts/dejavu/DejaVuSans.ttf
// sans italic   --  /usr/share/fonts/dejavu/DejaVuSans-Oblique.ttf
// serif         --  /usr/share/fonts/dejavu/DejaVuSerif.ttf
// serif bold    --  /usr/share/fonts/dejavu/DejaVuSerif-Bold.ttf
````
