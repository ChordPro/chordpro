---
title: "Configuration for PDF output"
description: "Configuration for PDF output"
---

# Configuration for PDF output

Layout definitions for PDF output are stored in the configuration under the key `"pdf"`.

    {
       // ... generic part ...
       "pdf" : {
         // ... layout definitions ...
       },
    }

## Papersize

The size of the paper for which output must be formatted. The size can be specified either as the name of a known page size, e.g. `"a4"`, or as a 2-element list containing the width and height of the page in _PDF units_ (_DTP points_, _pt_, 1/72 inch).

        "papersize" : "a4",
        // Same as: "papersize" : [ 595, 842 ]

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
        },

When `width` is set to a positive value, the lyrics and associated
chords will be indented by this amount and section labels, if any, are
printed.

When `width` is set to `"auto"`, the song will indented automatically,
but only if labels are actually used.

`align` will control how the labels are aligned in the margin.

[![labels.png]({{< asset "images/labels.png" >}})]({{< asset "images/labels.pdf" >}})

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
                 "color"  : "black",
            },
            // Recall style: Print the tag using the type.
            // Alternatively, quote the lines of the preceding chorus.
            "recall" : {
                 "tag"   : "Chorus",
                 "type"  : "comment",
                 "quote" : false,
            },
        },

## Section styles

If you use `{start_of_`*section*`}` and `{end_of_`*section*`}`
directives to mark specific parts of a song, you can specify that the
*section* name must be printed as a comment line before the section
itself.

For example:

	{start_of_bridge}
	[F]The bridge starts with F.
	{end_of_bridge}

can produce output as if you wrote

	{comment Bridge}
	[F]The bridge starts with F.

To obtain this, use the following configuration settings:

		// Markup for sections.
		// Define what to do with begin_of_XXX directives.
		// Use fallback as fallback.
		// Default is to ignore them.
		"section" : {
			"bridge" : "comment",
		},

Instead of `comment`, any of the fonts as described under [Fonts]({{< relref "#fonts" >}}) can be used.

A special section name `fallback` can be used to handle all sections
not otherwise specified.

## Chords in a side column

This is an alternative style where the chords are placed in a separate column at the right of the lyrics. Chord changes are marked by underlining the lyrics.

[![style_modern2.png]({{< asset "images/style_modern2.png" >}})]({{< asset "images/style_modern2.pdf" >}})

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

[![style_modern3.png]({{< asset "images/style_modern3.png" >}})]({{< asset "images/style_modern3.pdf" >}})

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

## Page headers and footers

ChordPro distinguishes three types of output pages:

* the first page of the output: `first`;
* the first page of a song: `title`;
* all other pages: `default`.

Each of these page types can have settings for a page title, subtitle and footer. The settings inherit from `default` to `title` to `first`. So a `title` page has everything a `default` page has, and a `first` page has everything a `title` page has.

Each title, subtitle and footer has three parts, which are printed to the left of the page, centered, and right. When even/odd page printing is selected, the left and right parts are swapped on even pages.

All heading strings may contain references to metadata in the form
`%{`*name*`}`, for example `%{title}`. The current page number can be
obtained with `%{page}`, and the song index in the songbook with `%{songindex}`. For a complete description on how to use metadata in heading strings, see [here]({{< relref "ChordPro-Configuration-Format-Strings" >}}).

        "formats" : {

            // By default, a page has:
            "default" : {
                // No title/subtitle.
                "title"     : null,
                "subtitle"  : null,
                // Footer is title -- page number.
                "footer"    : [ "%{title}", "", "%{page}" ],
            },

            // The first page of a song has:
            "title" : {
                // Title and subtitle.
                "title"     : [ "", "%{title}", "" ],
                "subtitle"  : [ "", "%{subtitle}", "" ],
                // Footer with page number.
                "footer"    : [ "", "", "%{page}" ],
            },

            // The very first output page is slightly different:
            "first" : {
                // It has title and subtitle, like normal 'first' pages.
                // But no footer.
                "footer"    : null,
            },
        },

The effect of the default settings can be seen in the following
picture.

![]({{< asset "images/pageformats.png" >}})

Pages 2 and 4 are normal (`default`) pages. They have no heading and
have the page number and song title in the footer.

Page 3 is the first page of a song (`title`). It has the song title
and subtitle in the heading, and only the page number in the footer.

Page 1 is the very first output page (`first`). It is like a `title`
page but, according to typesetting conventions, doesn't have the page
number in the footer.

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

## Helping develop a layout

If `showlayout` is true, the margins and other page layout details are shown on the page. This can be helpful to determine the optimal settings for your desired layout.

See also [Page margins]({{< relref "#page-margins" >}}) above.

        "showlayout" : false,

