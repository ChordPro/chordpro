# Configuration file contents - PDF output

Layout definitions for PDF output are stored in the configuration under the key `"pdf"`.

    {
       // ... generic part ...
       "pdf" : {
         // ... layout definitions ...
       },
    }

#### Papersize

The size of the paper for which output must be formatted. The size can be specified either as the name of a known page size, e.g. `"a4"`, or as a 2-element list containing the width and height of the page in _PDF units_ (_DTP points_, _pt_, 1/72 inch).

        "papersize" : "a4",
        // Same as: "papersize" : [ 595, 842 ]

#### Inter-column space

When output is produced in multiple columns, this is the space between the columns, in pt.

        "columnspace"  :  20,

#### Page margins

Click on the image for a larger version.

[![layout.png](images/layout.png)](images/layout-large.png)

        "margintop"    :  80,
        "marginbottom" :  40,
        "marginleft"   :  40,
        "marginright"  :  40,
        "headspace"    :  60,
        "footspace"    :  20,

#### Heading on first page only

Put the heading on the first page only, and add the headspace to the other pages so they become larger.

        "head-first-only" : false,

#### Spacing

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

Note: By setting the spacing for `empt` to a small value, you get fine-grained control over the spacing between the various parts of the song.

#### Chorus style

ChordPro can format a chorus in several different ways:

* the chorus part can be indented;
* a side bar can be drawn to the left of the chorus part;
* the `{chorus}` directive can print a comment text (tag), or quote the preceding chorus, or both.

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
            // Optionally quote the lines of the preceding chorus.
            "recall" : {
                 "tag"   : "Chorus",
                 "type"  : "comment",
                 "quote" : false,
            },
        },

#### Chords in a side column

This is an alternative style where the chords are placed in a separate column at the right of the lyrics. Chord changes are marked by underlining the lyrics.

[![style_modern2.png](images/style_modern2.png)](images/style_modern2.pdf)

        // This style is enabled by setting "chordscolumn" to a nonzero value.
        // Value is the column position. 
        // "chordscolumn" : 400,
        "chordscolumn" :  0,

#### Ignore {titles} directives

Traditionally, the `{titles}` directive was used to control titles flush. ChordPro has a much more powerful mechanism but this can conflict with legacy `{titles}` directives. If you use custom title formatting, setting `titles-directive-ignore` to a true makes ChordPro ignore the legacy directives.

        "titles-directive-ignore" : false,

#### Chord diagrams

Chord diagrams are printed at the end of the song to show the chords used in the song.

A chord diagram consists of a number of cells. Cell dimensions are specified by `width` and `height`.  
The horizontal number of cells depends on the number of strings.  
The vertical number of cells is `vcells`, which should be 4 or larger to accomodate most common chords.

The horizontal distance between diagrams is `hspace` times the cell width.  
The vertical distance between lines of diagrams is `vspace` times the cell height.

`linewidth` is the thickness of the diagram lines as a fraction of the cell width.

        "diagram" : {
            "width"    :  6,
            "height"   :  6,
            "hspace"   :  3.95,
            "vspace"   :  3,
            "vcells"   :  4,
            "linewidth" : 0.1,
        },

#### Even/odd page printing

Pages can be printed neutrally (all pages the same) or with differing left and right pages.  
This affects the page titles and footers.

        // Even/odd pages. A value of -1 denotes odd/even pages.
        "even-odd-pages" : 1,

#### Page headers and footers

ChordPro distinguishes three types of output pages:

* the first page of the output: `first`;
* the first page of a song: `title`;
* all other pages: `default`.

Each of these page types can have settings for a page title, subtitle and footer. The settings inherit from `default` to `title` to `first`. So a `title` page has everything a `default` page has, and a `first` page has everything a `title` page has.

Each title, subtitle and footer has three parts, which are printed to the left of the page, centered, and right. When even/odd page printing is selected, the left and right parts are swapped on even pages.

All heading strings may contain references to metadata in the form `%{`_NAME_`}`, for example `%{title}`. The current page number can be obtained with `%{page}`. For a complete descrition on how to use metadata in heading strings, see [[here|ChordPro Configuration Format Strings]].

        "formats" : {

            // By default, a page has:
            "default" : {
                // No title/subtitle.
                "title"     : null,
                "subtitle"  : null,
                // Footer is title -- page number.
                "footer"    : [ "%{title}", "", "%{page}" ],
                // Title for ToC.
                "toc-title" : "Table of Contents",
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

#### Fonts

        // Fonts.
        // Fonts can be specified by name (for the corefonts)
        // or a filename (for TrueType/OpenType fonts).
        // Relative filenames are looked up in the fontdir.
        "fontdir" : null,

        // Fonts for chords and comments can have a background
        // colour associated.
        // Colours are "#RRGGBB" or predefined names like "black", "white",
        // and lots of others.

        "fonts" : {
            "title" : {
                "name" : "Times-Bold",
                "size" : 14
            },
            "text" : {
                "name" : "Times-Roman",
                "size" : 12
            },
            "chord" : {
                "name" : "Helvetica-Oblique",
                "size" : 10
            },
            "comment" : {
                "name" : "Helvetica",
                "size" : 12
            },
            "tab" : {
                "name" : "Courier",
                "size" : 10
            },
            "toc" : {
                "name" : "Times-Roman",
                "size" : 11
            },
            "grid" : {
                "name" : "Helvetica",
                "size" : 10
            },
        },

        // Fonts that can be specified, but need not.
        // subtitle       --> text
        // comment        --> text
        // comment_italic --> chord
        // comment_box    --> chord
        // toc            --> text
        // grid           --> chord
        // grid_margin    --> comment
        // footer         --> subtitle @ 60%
        // empty          --> text
        // diagram        --> comment
        // diagram_capo   --> text (but at a small size)

#### Helping develop a layout

If `showlayout` is true, the margins and other page layout details are shown on the page. This can be helpful to determine the optimal settings for your desired layout.

See also [Page margins](#configuration-file-contents-pdf-output_page-margins) above.

        "showlayout" : false,

