---
title: "Configuration for PDF output"
description: "Configuration for PDF output"
---

# Configuration for PDF output

Definitions for PDF output are stored in the configuration under the key `"pdf"`.

    {
       // ... generic part ...
       "pdf" : {
         // ... layout definitions ...
       },
    }

Topics in this document:
{{< toc >}}

## Document info

PDF document properties.

      "info" : {
          "title"    : "%{title}",
          "author"   : "",
          "subject"  : "",
          "keywords" : "",
      },

Note that the context for substitutions is the first song.

## CSV

With the PDF, ChordPro can optionally generate a CSV document that
describes the content of the PDF outout. This can be used with some
third-party tools when importing or viewing the PDF document.

For details, see [Configuration for CSV output]({{< relref "chordpro-configuration-csv" >}}).

## Papersize

The size of the paper for which output must be formatted. The size can be specified either as the name of a known page size, e.g. `"a4"`, or as a 2-element list containing the width and height of the page in _PDF units_ (_DTP points_, _pt_, 1/72 inch).

        "papersize" : "a4",
        // Same as: "papersize" : [ 595, 842 ]

## Theme

These settings can be used to control the foreground and
background colours of the PDF output.

        "theme" : {
            "foreground"        : "black",
            "foreground-light"  : "grey90",
            "foreground-medium" : "grey70",
            "background"        : "none",
        }

Background `"none"` or `"white"` means there will be no background
colour added to the output.

It may be useful to put your theme settings in a separate config file,
together with additional settings that make up the theme. For example,
these settings define a 'dark' theme that can be applied to any style.

````
{
    "pdf" : {
        "theme" : {
            "foreground"       : "white",
            "foreground-light" : "#555555",
            "background"       : "black",
        },
    },
}
````

Other configuration settings that use colours can use `foreground`,
`foreground-light`, `foreground-medium`, and
`background` to refer to the colours defined in the theme.

## Inter-column space

When output is produced in multiple columns, this is the space between the columns, in pt.

        "columnspace"  :  20,

## Page margins

Click on the image for a larger version.

[![layout.png]({{< asset "images/layout.png" >}})]({{< asset "images/layout-large.png" >}})

        "margintop"    :  80,
        "marginbottom" :  40,
        "marginleft"   :  40,
        "marginright"  :  40,
        "headspace"    :  60,
        "footspace"    :  20,

## Heading on first page only

Put the heading on the first page only, and add the headspace to the other pages so they become larger.

        "head-first-only" : false,

## Spacing

This controls the distance between lines as a factor of the font size.

        "spacing" : {
            "title"  : 1.2,
            "lyrics" : 1.2,
            "chords" : 1.2,
            "grid"   : 1.2,
            "tab"    : 1.0,
            "toc"    : 1.4,
            "empty"  : 1.0,
        },

Note: By setting the spacing for `empty` to a small value, you get fine-grained control over the spacing between the various parts of the song.

## Labels

Section labels can be added to a specific verse, chorus or grid. See
e.g. [start_of_verse]({{< relref "Directives-env_verse" >}}).

        // This opens a margin for margin labels.
        "labels" : {
            // Margin width. Default is "auto".
            "width" : "auto",
            // Alignment for the labels. Default is left.
            "align" : "left",
            // Alternatively, render labels as comments.
            "comment" : ""  // "comment", "comment_italic" or "comment_box",
        },

When `comment` is set to one of the suported comment types, the label
will be printed as a comment before the section contents. The settings
of `width` and `align` are ignored.

Otherwise, when `width` is set to a positive value, the lyrics and associated
chords will be indented by this amount and section labels, if any, are
printed.

When `width` is set to `"auto"`, the song will indented automatically,
but only if labels are actually used.

`align` will control how the labels are aligned in the margin.

{{< showpage "page_labels" >}}

## Chorus style

ChordPro can format a chorus in several different ways:

* the chorus part can be indented;
* a side bar can be drawn to the left of the chorus part;
* the `{chorus}` directive can print a comment text (tag), or quote the preceding chorus.

        "chorus" : {
            // Indentation of the chorus.
            "indent"     :  0,
            // Chorus side bar.
            // Suppress by setting offset and/or width to zero.
            "bar" : {
                 "offset" :  8,
                 "width"  :  1,
                 "color"  : "foreground",
            },
            // Recall style: Print the tag using the type.
            // Alternatively, quote the lines of the preceding chorus.
            "recall" : {
                 "tag"   : "Chorus",
                 "type"  : "comment",
                 "quote" : false,
            },
        },

## Chords in a side column

This is an alternative style where the chords are placed in a separate column at the right of the lyrics. Chord changes are marked by underlining the lyrics.

{{< showpage "style_modern2" >}}

        // This style is enabled by setting "chordscolumn" to a nonzero value.
        // Value is the column position. 
        // "chordscolumn" : 400,
        "chordscolumn" :  0,
        "capoheading" : "%{capo|Capo: %{}}",

When a capo is set a heading indicating the current capo setting is added. The text of the heading is defined by `capoheading`.

## Ignore {titles} directives

Traditionally, the `{titles}` directive was used to control titles flush. ChordPro has a much more powerful mechanism but this can conflict with legacy `{titles}` directives. If you use custom title formatting, setting `titles-directive-ignore` to a true makes ChordPro ignore the legacy directives.

        "titles-directive-ignore" : false,

## Chord diagrams

Chord diagrams are added to the song to show the chords used in the
song. By default the diagrams are at the end of the song but it is
also possible to have them at the bottom, or in a side column on the first page of the
song. See [Chords diagrams in a side column]({{< relref "#chords-diagrams-in-a-side-column" >}}) below.

A chord diagram consists of a number of cells. Cell dimensions are specified by `width` and `height`.  
The horizontal number of cells depends on the number of strings.  
The vertical number of cells is `vcells`, which should be 4 or larger to accomodate most common chords.

The horizontal distance between diagrams is `hspace` times the cell width.  
The vertical distance between lines of diagrams is `vspace` times the cell height.

`linewidth` is the thickness of the diagram lines as a fraction of the cell width.

        "diagrams" : {
            "show"     :  "bottom",   // or "top", or "right", or "below"
            "width"    :  6,
            "height"   :  6,
            "hspace"   :  3.95,
            "vspace"   :  3,
            "vcells"   :  4,
            "linewidth" : 0.1,
        },

With the above settings, chord diagrams will look like:

![]({{< asset "images/ex_chords.png" >}})

An example of `"show":"right"`, where the chord diagrams are placed in a
separate column at the right of the lyrics instead of at the end of
the song.

{{< showpage "style_modern3" >}}

## Keyboard diagrams

Keyboard diagrams are added to the song to show the chords used in the
song. By default the diagrams are at the end of the song but it is
also possible to have them at the bottom, or in a side column on the first page of the
song. See [Chords diagrams in a side column]({{< relref "#chords-diagrams-in-a-side-column" >}}) below.

By default ChordPro adds diagrams for string instruments. To add
keyboard diagrams set `diagrams.type` to `"keyboard"`, see
[Configuration file contents - Generic]({{< relref
"chordpro-configuration-generic/#printing-chord-diagrams" >}}).

A keyboard diagram consists of a number of keyboard keys, typically
spanning one or two octaves. The width of a white key is specified by
`width`, and the height of the keyboard diagram is specified by `height`.  
The number of white keys can be specified with `keys` and should have
one of the values 7, 10, 14, 17, or 21.  
Diagrams can start with the key `C` or `F`. This can be specified by
`base`.  

The horizontal distance between diagrams is `hspace` times the width.  
The vertical distance between lines of diagrams is `vspace` times the height.

`linewidth` is the thickness of the diagram lines as a fraction of the key width.

Finally, the colour to represent keys that are part of the chord
(pressed) can be specified with `pressed`. It takes the name of a
colour, or a hex format `#RRGGBB`.

        "kbdiagrams" : {
            "show"     :  "bottom",   // or "top", or "right", or "below"
            "width"    :   4,   // of a single key
            "height"   :  20,   // of the diagram
            "keys"     :  14,   // or 7, 10, 14, 17, 21
            "base"     :  "C",  // or "F"
            "linewidth" : 0.1,  // fraction of a single key width
            "pressed"  :  "foreground-medium",   // colour of a pressed key
            "hspace"   :  3.95, // ??
            "vspace"   :  0.3,  // fraction of height
        },

With the above settings, keyboard diagrams will look like:

![]({{< asset "images/ex_kbdiagram.png" >}})

## Grid lines

Properties for the lines of grid sections.

      // Grid section lines.
      // The width and colour of the cell bar lines can be specified.
      // Enable by setting the width to the desired width.
      "grids" : {
          "cellbar" : {
              "width" : 0,
              "color" : "foreground-medium",
          },
      },


## Even/odd page printing

Pages can be printed neutrally (all pages the same) or with differing left and right pages.  
This affects the page titles and footers, and the page margins.

        "even-odd-pages" : 1,

The default value is `1`, which means that the first page is right, the second page is left, and so on.  
The value `-1` means the first page is left, the second page is right, and so
on.  
The value `0` makes all pages the same (left).

The setting of `even-off-pages` affects content items cover page (if
any), table of contents (if any) and the songbook. These content items
will start on a right page (`even-odd-pages` = `1`) or a left page
(`even-odd-pages` = `-1`).

The setting of `pagealign-songs` controls whether each *song* starts on
an even or odd page as well.

        "pagealign-songs" : 1,

With a value greater than `1`, ChordPro will additionally force the
resultant PDF to always have an even number of pages.

Note that with `pagealign-songs` = 1 empty (blank) pages are inserted
(as conventional in book printing), while with `pagealign-songs` > 1
the empty pages have headings and footers.

## Page headers and footers

ChordPro distinguishes three types of output pages:

* the first page of the output: `first`;
* the first page of a song: `title`;
* all other pages: `default`.

Each of these page types can have settings for a page title, subtitle,
footer, and background.
The settings inherit from `default` to `title` to `first`.
So a `title` page has everything a `default` page has, and a `first`
page has everything a `title` page has.

Each title, subtitle and footer has three parts, which are printed to
the left of the page, centered, and right. When even/odd page printing
is selected, the left and right parts are swapped on even pages.

The title, subtitle and footer may also be set to an *array* of three
part strings, which will be printed on separate lines. 

All heading strings may contain references to metadata in the form
`%{`*name*`}`, for example `%{title}`. The current page number can be
obtained with `%{page}`, and the song index in the songbook with
`%{songindex}`. For a complete description on how to use metadata in
heading strings, see [here]({{< relref
"ChordPro-Configuration-Format-Strings" >}}).

`background` can be used to designate an existing PDF document to be
used as background. It has the form _filename_ or _filename:page_.
Page numbers count from one. If odd/even printing is in effect, the
designated page number is used for left pages, and the next page (if
it exists) for right pages.

        "formats" : {

            // By default, a page has:
            "default" : {
                // No title/subtitle.
                "title"     : null,
                "subtitle"  : null,
                // Footer is title -- page number.
                "footer"    : [ "%{title}", "", "%{page}" ],
                // Background pages: 5 and 6 from bgdemo.
               "background" : "examples/bgdemo.pdf:5",
            },

            // The first page of a song has:
            "title" : {
                // Title and subtitle.
                "title"     : [ "", "%{title}", "" ],
                "subtitle"  : [ "", "%{subtitle}", "" ],
                // Footer with page number.
                "footer"    : [ "", "", "%{page}" ],
                // Background pages: 3 and 4 from bgdemo.
               "background" : "examples/bgdemo.pdf:3",
            },

            // The very first output page is slightly different:
            "first" : {
                // It has title and subtitle, like normal 'first' pages.
                // But no footer.
                "footer"    : null,
                // Background pages: 1 and 2 from bgdemo.
               "background" : "examples/bgdemo.pdf:1",
            },
        },

The effect of the above settings can be seen in the following
picture.

![]({{< asset "images/pageformats.png" >}})

Page 1 is the very first output page (type `first`). It is like a `title`
page but, according to typesetting conventions, doesn't have the page
number in the footer.

Page 4 is the first page of a song, but not the very first (type `title`).
It has the song title and subtitle in the heading, and only the page
number in the footer.

The other pages are normal pages (type `default`). They have no heading and
have the page number and song title in the footer. Pages inserted for
alignment are completely blank.

Note that by default ChordPro produces different odd and even pages.
Therefore the page number on (odd) page 3 is at the left side, while it is at
the right side on (even) pages 2 and 4.

## Font libraries

You can either designate a built-in font by its name, or give the filename of a TrueType (ttf) or OpenType font (otf).  
The filename should be the full name of a file on disk, or a relative filename which will be looked up in system dependent font libraries.

The `fontdir` setting can be used to add one or more private font directories to
the font libraries. The private directories will be searched first.

        // Fonts.
        // Fonts can be specified by name (for the corefonts)
        // or a filename (for TrueType/OpenType fonts).
        // Relative filenames are looked up in the fontdir.
        // "fontdir" : [ "/usr/share/fonts/liberation", "/home/me/fonts" ],
        "fontdir" : null,

See also [ChordPro Fonts]({{< relref "ChordPro-Fonts" >}}).

## Fonts

All printable items like lyrics, chords and comments can be associated with a font specification. This allows fine-grained control over the printed output.

For example:

        "fonts" : {
            "title" : {
                "name" : "Times-Bold",
                "size" : 14,
                "color" : "blue",
            },
            ...
        },

A font specification consists of the following settings:

* `name` or `file`  
You can either designate a built-in font by its name, or give the filename of a TrueType (ttf) or OpenType font (otf).  
The filename should be the full name of a file on disk, or a relative filename which will be looked up in system dependent font libraries. See [Font libraries]({{< relref "#font-libraries" >}}).
* `size`  
The size of the font, in PDF units (1/72 inch).
* `color`  
The colour of the font. See [ChordPro Colours]({{< relref "ChordPro-Colours" >}}) for
details on colours.
* `background`  
The background color.
* `frame`  
A boolean value indicating that a frame (box) should be drawn around
the text.

The following printable items can have fonts associated.

* `title`  
The font used for page titles.  
Default is "Times-Bold" at size 14.
* `subtitle`  
The font used for page subtitles.  
Default is the setting for `text`.
* `footer`  
Default is the setting for `subtitle` at 60% size.
* `text`  
The font used for lyrics texts.  
Default is "Times-Roman" at size 12.
* `chord`  
The font used for chords above the lyrics.  
Default is "Helvetica-Oblique" at size 10.
* `annotation`  
The font used for annotations.  
Defaults to the `chord` font.
* `comment`  
The font used for comments.  
Default is "Helvetica" at size 12, with a grey background.
* `comment_italic`  
Default is "HelveticaOblique" at size 12, with a grey background.
* `comment_boxed`  
Default is "Helvetica" at size 12, with a frame.
* `tab`  
The font used for the contents of
[tab environments]({{< relref "Directives-env_tab" >}}).  
Default is "Courier" at size 10.
* `label`  
The font used for section labels.  
Default is the setting for `text`.
* `toc`  
The font used for the table of contents.  
Default is "Times-Roman" at size 11.
* `grid`  
The font used for grid elements.  
Default is the setting for `chord`.
* `grid_margin`  
The font used for grid margin texts.  
Default is the setting for `comment`.
* `empty`  
The font used for empty lines. While this may not seem very relevant
at first, by setting the font's _size_ you can get a precise control
over the amount of vertical whitespace in the output.  
Default is the setting for `text`.
* `diagram`  
The font for the chord names above chord diagrams.  
Default is the setting for `comment`.
* `diagram_base`  
The font for the base fret numbers in chord diagrams.  
Default is the setting for `text` but at a small size.
* `chordfingers`  
The font used for drawing the fret positions that have fingering
associated. This should **not** be modified unless you know what you
are doing (and you probably don't).  
This font has an additonal property `numbercolor` that can be set to
control the colour of the finger number. By default this is the theme
background colour. Setting this colour to the foreground colour
effectively hides the finger numbers.

## Outlines

Outlines (bookmarks) can be automatically generated, controlled by
settings in the config file. Most PDF viewers can show outlines and
use them for easy navigation.

````
    // Bookmarks (PDF outlines).
    // fields:   primary and (optional) secondary fields.
    // label:    outline label
    // line:     text of the outline element
    // collapse: initial display is collapsed
    // letter:   sublevel with first letters if more
    // fold:     group by primary (NYI)
    // omit:     ignore this
    "outlines" : [
        { "fields"   : [ "sorttitle", "artist" ],
          "label"    : "By Title",
          "line"     : "%{title}%{artist| - %{}}",
          "collapse" : false,
          "letter"   : 5,
          "fold"     : false,
        },
        { "fields"   : [ "artist", "sorttitle" ],
          "label"    : "By Artist",
          "line"     : "%{artist|%{} - }%{title}",
          "collapse" : false,
          "letter"   : 5,
          "fold"     : false,
        },
    ],
````

The default configuration generates two outlines, one labelled `By
Title` and one labelled `By Artist`. Each outline is ordered according
to the meta data specified in `"fields"`. The format of the outlines
is specified in `"line"`.

* `fields`  
The ordering of the outline. You can specify one or two metadata
items.  
When you specify a metadata item that has multiple values they are
split out in the outline.
* `label`  
The label for this outline.
* `line`  
The format of the outline.
* `collapse`  
If true, the outline is initially collapsed.
* `letter`  
If there are more outline items with differing first letters than the
amount specified here, an extra level of outlines (letter index) is
created for easy navigation.  
A value of zero disables this.
* `fold`  
For future use.

## Helping develop a layout

If `showlayout` is true, the margins and other page layout details are shown on the page. This can be helpful to determine the optimal settings for your desired layout.

See also [Page margins]({{< relref "#page-margins" >}}) above.

        "showlayout" : false,

