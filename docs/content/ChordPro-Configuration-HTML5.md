---
title: "Configuration for HTML5 output"
description: "Configuration for HTML5 output (responsive, screen, print)"
---

# Configuration for HTML5 output

Definitions for HTML5 output are stored in the configuration under the
key `"html5"`. For example, when setting a CSS color, this really means

    html5.css.colors.chord: "#0066cc"

or

    html5 {
        css {
            colors {
                chord: "#0066cc"
            }
        }
    }

Topics in this document:
{{< toc >}}

## Overview

ChordPro provides a single modern HTML5 backend with multiple output modes:

* **print** (default): Paginated output using [Paged.js](https://pagedjs.org/) for print-ready PDFs
* **responsive**: Fluid layout for web viewing and mobile screens
* **screen**: Fixed layout optimized for on-screen display

Select the mode with `html5.mode` in your configuration. The same backend is used for all modes, with `html5.paged` providing the extra settings used only for print mode. `print` and `paged` are accepted synonyms for the paged layout.

If you want `.html` output to use the modern HTML5 backend by default, set:

    html.module : "HTML5"

Print mode configuration lives under `html5.paged`. When values are not set, the
backend inherits paper size and margins from `pdf.*`.

```
html5 {
    mode : "print"
    paged {
        papersize    : "letter"
        margintop    : 72
        marginbottom : 54
    }
}
```

## Configuration Reference

This section lists the supported HTML5 configuration keys and the defaults supplied by the
main configuration. Examples are shown in relaxed JSON syntax.

### Core HTML5 Settings

```
html5 {
    // Output mode: "print" (default), "responsive", or "screen".
    mode : "print"

    // Optional songbook parts (HTML or image files).
    cover : false
    front-matter : false
    back-matter : false

    // Template include paths (searched before defaults).
    template_include_path : []

    // Templates for HTML/CSS generation.
    templates {
        css            : "html5/css/base.tt"
        songbook       : "html5/songbook.tt"
        song           : "html5/song.tt"
        songline       : "html5/songline.tt"
        comment        : "html5/comment.tt"
        image          : "html5/image.tt"
        chord_diagrams : "html5/chord-diagrams.tt"
    }

    // CSS customization (colors, fonts, sizes, spacing).
    css {
        colors  : {}
        fonts   : {}
        sizes   : {}
        spacing : {}
    }

    // Optional external CSS file appended after generated CSS.
    // css.custom-css-file : "/path/to/extra.css"
}
```

### Print Mode Settings (html5.paged)

```
html5.paged {
    // Paper size and margins (inherit from pdf.* when not set).
    // papersize    : "a4"
    // margintop    : 80
    // marginbottom : 40
    // marginleft   : 40
    // marginright  : 40
    // headspace    : 60
    // footspace    : 20

    // Template include paths (searched before defaults).
    template_include_path : []

    // Templates for paged HTML/CSS generation.
    templates {
        css      : "html5/paged/css/base.tt"
        songbook : "html5/paged/songbook.tt"
        song     : "html5/paged/song.tt"
        toc      : "html5/paged/toc.tt"
    }

    // Song pagination controls.
    song {
        // Page break before/after each song.
        // Values: "none", "before", "after", "both".
        // Targeted breaks: "before-right", "before-left", "before-recto", "before-verso",
        //                  "after-right", "after-left", "after-recto", "after-verso",
        //                  "right", "left", "recto", "verso" (aliases for before-*).
        page-break : "none"
    }

    // Note: "before" and "both" insert breaks only between songs (after the first)
    // to avoid leading blank pages.

    // Newpage/new_physical_page pagination controls.
    newpage {
        // Targeted page break for {new_page}: "page", "right", "left", "recto", "verso".
        page-break : "page"
    }

    // CSS customization for paged output.
    css {
        colors  : {}
        fonts   : {}
        sizes   : {}
        spacing : {}
    }
}
```

### PDF Compatibility Keys

HTML5 output reuses PDF configuration when HTML5-specific overrides are missing:

* Page size and margins: `pdf.papersize`, `pdf.margintop`, `pdf.marginbottom`,
  `pdf.marginleft`, `pdf.marginright`, `pdf.headspace`, `pdf.footspace`
* Formats (headers/footers): `pdf.formats.*`
* Theme colors: `pdf.theme.*`
* Spacing multipliers: `pdf.spacing.*`
* Chorus styling: `pdf.chorus.*`
* Chord diagrams: `pdf.diagrams.*`

## Template System

The HTML5 backend uses [Template Toolkit](http://www.template-toolkit.org/) for generating HTML output, providing maximum flexibility and customization without modifying the backend code.

### Template Configuration

Example:

    html5 {
        templates {
            css            : "html5/css/base.tt"
            songbook       : "html5/songbook.tt"
            song           : "html5/song.tt"
            songline       : "html5/songline.tt"
            comment        : "html5/comment.tt"
            image          : "html5/image.tt"
            chord_diagrams : "html5/chord-diagrams.tt"
        }
    }

Example (print mode overrides):

    html5.paged {
        templates {
            css      : "html5/paged/css/base.tt"
            songbook : "html5/paged/songbook.tt"
            song     : "html5/paged/song.tt"
            toc      : "html5/paged/toc.tt"
        }
    }

### Template Include Paths

Example:

    html5 {
        template_include_path : [
            "/path/to/my/templates",
            "$HOME/.config/chordpro/templates"
        ]
    }

Example (print mode include paths):

    html5.paged {
        template_include_path : [
            "/path/to/my/paged-templates"
        ]
    }

Templates in these directories override the built-in templates.

### Creating Custom Templates

To customize the HTML output, copy the built-in templates from `lib/ChordPro/res/templates/html5/` to your custom directory and modify them. The template files include:

* **songbook.tt**: Document wrapper with CSS and song array
* **song.tt**: Song structure with title, metadata, and body
* **songline.tt**: Chord-lyric pairs with flexbox positioning
* **comment.tt**: Comment text with optional italic styling
* **image.tt**: Image elements with attributes
* **chord-diagrams.tt**: SVG chord diagram rendering
* **css/*.tt**: Modular CSS templates for styling

Example:

    html5 {
        templates {
            song : "my-custom-song.tt"
        }
    }

Template variables available include `title`, `subtitle`, `meta` (artist, composer, album, etc.), `body` (song content), and `chord_diagrams` (SVG diagrams).

## CSS Customization

The HTML5 backend generates embedded CSS for single-file output. CSS can be customized through configuration.

### CSS Structure

CSS is generated from modular templates in `templates/html5/css/`:

* **base.tt**: Master CSS template that includes all others
* **variables.tt**: CSS custom properties (colors, fonts, sizes)
* **typography.tt**: Text styling (titles, lyrics, chords)
* **songlines.tt**: Chord-lyric positioning with flexbox
* **sections.tt**: Verse, chorus, bridge, tab styling
* **tab-grid.tt**: Tab and grid section formatting
* **chord-diagrams.tt**: SVG diagram styling
* **print-media.tt**: Print media queries

### CSS Color Customization

Example:

    html5 {
        css {
            colors {
                chord   : "#0066cc"     // Chord color
                title   : "#333333"     // Title color
                text    : "#000000"     // Lyrics color
                comment : "#666666"     // Comment color
                chorus-bg : "#f9f9f9"   // Chorus background
                chorus-border : "#cccccc"  // Chorus border
            }
        }
    }

### CSS Font Customization

Example:

    html5 {
        css {
            fonts {
                text  : "Georgia, serif"
                chord : "Arial, sans-serif"
                title : "Arial, sans-serif"
                mono  : "Courier New, monospace"  // For tab sections
            }
        }
    }

### CSS Size Customization

Example:

    html5 {
        css {
            sizes {
                base-font-size : "14pt"
                title-size     : "2em"
                subtitle-size  : "1.5em"
                chord-size     : "0.9em"
            }
        }
    }

### CSS Spacing Customization

Example:

    html5 {
        css {
            spacing {
                song-gap      : "2em"    // Between songs
                section-gap   : "1em"    // Between sections
                line-height   : "1.4"    // Line height
                chord-offset  : "0.2em"  // Chord vertical offset
            }
        }
    }

Example:

    html5.css.custom-css-file : "/path/to/extra.css"

## Chord Positioning

The HTML5 backend uses CSS Flexbox for chord positioning, ensuring chords stay aligned above the correct syllable regardless of font size or family.

The key structure is:

```html
<span class="cp-chord-lyric-pair">
  <span class="cp-chord">G</span>
  <span class="cp-lyrics">Hello</span>
</span>
```

This works with any font combination without JavaScript. The flexbox layout keeps chords precisely positioned above their lyrics.

### Chords-Under Mode

Example:

    settings.chords-under : true

This flips the chord/lyric order inside each pair using CSS only.

### Inline Chords Mode

Example:

    settings.inline-chords : "[%s]"

Set it to `true` to use the default `[%s]` format.

Example:

    settings.inline-annotations : "(*%s*)"

Annotations written as `[*text]` are rendered with annotation styling and excluded from chord diagram generation.

## Chord Diagrams

The HTML5 backend supports inline SVG chord diagrams showing fingering positions, including keyboard diagrams for piano-style instruments. Diagrams are automatically generated for chords used in the song.

Example (placement and alignment via PDF/HTML5 settings):

    pdf.diagrams {
        show  : "bottom"  // top, bottom, below, right, or false
        align : "left"    // left, right, center, or spread
    }

Example (selection defaults):

    diagrams {
        show     : all     // all, user, or none
        sorted   : false   // Sort alphabetically
        suppress : []      // List of chords to hide
    }

Diagrams are sized at `4em` width for scalability with font size changes.

HTML5-specific overrides can be set under `html5.diagrams` and fall back to `pdf.diagrams` when unset.

## Songbook Parts (Cover, Front Matter, Back Matter)

Example:

    html5 {
        cover        : "cover.html"
        front-matter : "front.html"
        back-matter  : "back.html"
    }

Supported inputs are HTML/HTM/XHTML or image files. PDF files are ignored with a warning.

## Chorus Recall (Rechorus)

HTML5 honors the chorus recall configuration used by other backends. Example:

    pdf.chorus.recall {
        quote : true
        type  : "comment"
        tag   : "Chorus"
    }

`quote` re-renders the full chorus body. When `quote` is false, the `type` and `tag` fields control how the recall label is shown.

## Table of Contents (Print Mode)

In print mode, a Table of Contents is generated from the global `contents` configuration and only rendered when `--toc` is enabled (or when there is more than one song). Example:

    contents : [
        {
            name   : "toc"
            label  : "Table of Contents"
            fields : [ "title" ]
            line   : "%{title}"
            pageno : "%{page}"
        }
    ]

The `line`, `pageno`, and optional `break` fields use the same `%{...}` substitutions as the PDF backend.

## Song Sorting

Sort songs before rendering with `html5.songbook.sort-songs` (or the PDF equivalents). Supported values are a list of fields or a comma-separated string, with optional `-` for descending order. Example:

    html5.songbook.sort-songs : [ "title" ]
    html5.sortby : "title,-artist"

If `html5.songbook.sort-songs` is not set, HTML5 falls back to `pdf.songbook.sort-songs`, then `html5.sortby`, then `pdf.sortby`.

## PDF Config Compatibility

The HTML5 backend supports PDF configuration options for smooth migration from PDF output. Configuration follows a hybrid precedence model:

* **HTML5 backend**: `html5.*` overrides `pdf.*` overrides defaults
* **HTML5 print mode**: `html5.paged.*` overrides `pdf.*` overrides defaults

This allows you to define settings once under `pdf` and have them work across all backends, with backend-specific overrides when needed.

### Theme Colors

Example:

    pdf {
        theme {
            foreground        : "#000000"  // Primary text
            foreground-medium : "#444444"  // Medium emphasis
            foreground-light  : "#888888"  // Light/subtle elements
            background        : "#FFFFFF"  // Background color
        }
    }

Example:

    html5.paged {
        theme {
            foreground : "#222222"  // Slightly lighter for screen
        }
    }

Theme colors are exposed as CSS variables:
* `--theme-foreground`
* `--theme-foreground-medium`
* `--theme-foreground-light`
* `--theme-background`

### Spacing Multipliers

Example:

    pdf {
        spacing {
            title         : 1.2   // Title line height multiplier
            lyrics        : 1.4   // Lyrics line height
            chords        : 1.0   // Chord lines
            diagramchords : 1.2   // Chord diagram labels
            grid          : 1.5   // Grid sections
            tab           : 1.2   // Tab sections
            toc           : 1.4   // Table of contents
            empty         : 1.0   // Empty lines
        }
    }

Example:

    html5.paged {
        spacing {
            lyrics : 1.6  // More generous spacing for web
            title  : 1.5
        }
    }

Spacing values are exposed as CSS variables:
* `--spacing-title`, `--spacing-lyrics`, `--spacing-chords`, etc.

Usage in CSS: `line-height: calc(var(--spacing-lyrics, 1.2) * 1em);`

### Chorus Bar Styling

Example:

    pdf {
        chorus {
            indent : 4         // Left margin in points
            bar {
                offset : 8     // Distance from left edge to content (pt)
                width  : 2     // Bar thickness (pt)
                color  : "#0066cc"  // Bar color (or "foreground")
            }
        }
    }

The `color` field accepts:
* Hex colors: `"#0066cc"`
* CSS color names: `"blue"`, `"red"`
* Theme references: `"foreground"`, `"foreground-medium"`, `"foreground-light"`

Set `bar.width` to `0` to disable the chorus bar and use default styling.

CSS variables:
* `--chorus-indent`
* `--chorus-bar-offset`
* `--chorus-bar-width`
* `--chorus-bar-color`

### Grid Color Styling

Example:

    pdf {
        grids {
            symbols {
                color : "#FF0000"  // Bar lines and symbols (|, ||, etc.)
            }
            volta {
                color : "#00AA00"  // Volta brackets and repeat markers
            }
        }
    }

CSS variables:
* `--grid-symbols-color`
* `--grid-volta-color`

Applied to `.cp-grid-bar`, `.cp-grid-repeat1`, `.cp-grid-repeat2`, and volta classes.

### Header/Footer Spacing (Print mode only)

Example:

    pdf {
        headspace : 72  // Top margin space for headers (points)
        footspace : 48  // Bottom margin space for footers (points)
    }

These values are added to the `@page` margin-top and margin-bottom CSS properties to ensure adequate space for header/footer content.

### Example: Complete PDF-Compatible Config

```json
{
  "pdf": {
    "theme": {
      "foreground": "#000000",
      "foreground-medium": "#444444",
      "foreground-light": "#999999",
      "background": "#FFFFFF"
    },
    "spacing": {
      "lyrics": 1.4,
      "title": 1.2,
      "chords": 1.0,
      "grid": 1.5,
      "tab": 1.2
    },
    "chorus": {
      "indent": 4,
      "bar": {
        "offset": 8,
        "width": 2,
        "color": "#0066cc"
      }
    },
    "grids": {
      "symbols": { "color": "blue" },
      "volta": { "color": "green" }
    },
    "headspace": 72,
    "footspace": 48
  },
  "html5": {
    "paged": {
      "spacing": {
        "lyrics": 1.6,
        "title": 1.5
      },
      "theme": {
        "foreground": "#222222"
      }
    }
  }
}
```

This configuration:
* Defines PDF theme and spacing once for all backends
* Print mode overrides lyrics spacing (1.6 vs 1.4) for better screen readability
* Print mode overrides foreground color (#222222 vs #000000) for reduced eye strain
* All other PDF settings inherited by print mode

## HTML5 Print Mode (Paged.js)

HTML5 print mode uses [Paged.js](https://pagedjs.org/), a JavaScript library that brings CSS Paged Media features to the browser, enabling professional print layouts with page headers, footers, and page numbers. Example:

    html5.mode : "print"

### Paged.js Integration

Example output:

```html
<script src="https://unpkg.com/pagedjs/dist/paged.polyfill.js"></script>
```

When opened in a browser, Paged.js automatically:
1. Breaks content into pages based on page size
2. Applies page margins
3. Renders headers and footers in margin boxes
4. Handles page numbering and breaks

For complete Paged.js documentation, see [pagedjs.org/documentation](https://pagedjs.org/en/documentation/).

### Paper Size

Example:

    html5.paged {
        papersize : "a4"    // or "letter", "legal", [width, height]
    }

If not specified, inherits from `pdf.papersize`.

Standard paper sizes:
* `a4`: 595 × 842 pt (210 × 297 mm)
* `letter`: 612 × 792 pt (8.5 × 11 in)
* `legal`: 612 × 1008 pt (8.5 × 14 in)

Example:

    html5.paged {
        papersize : [600, 800]  // Width × Height in points
    }

### Page Margins

Example:

    html5.paged {
        margintop    : 80
        marginbottom : 40
        marginleft   : 40
        marginright  : 40
    }

If not specified, inherits from PDF margin settings (`pdf.margintop`, etc.).

### Headers and Footers

Print mode supports configurable headers and footers using CSS @page margin boxes. Configuration reuses the `pdf.formats` structure for consistency with PDF output.

#### Format Configuration

Example:

    pdf {
        formats {
            default {
                title  : ["", "%{title}", ""]
                footer : ["", "Page %{page}", ""]
            }
            title {
                title  : ["", "%{title}", ""]
                footer : ["%{artist}", "", "Page %{page}"]
            }
        }
    }

#### Format Types

* **`default`**: Applied to all pages except where overridden
* **`title`**: Applied to first page of each song
* **`first`**: Applied to very first page only
* **`filler`**: Applied to blank alignment pages
* **`default-even`**: Applied to even (left-facing) pages in duplex printing
* **`default-odd`**: Applied to odd (right-facing) pages in duplex printing

#### Three-Part Format

Each format line has three parts: `[left, center, right]`

```json
"footer": ["Left content", "Center content", "Right content"]
```

These map to CSS @page margin boxes:
* **title** → `@top-left`, `@top-center`, `@top-right`
* **footer** → `@bottom-left`, `@bottom-center`, `@bottom-right`

#### Metadata Placeholders

Use these placeholders in format strings:

* `%{title}` – Song title
* `%{subtitle}` – Song subtitle
* `%{artist}` – Song artist
* `%{album}` – Album name
* `%{page}` – Current page number
* `%{key}` – Song key
* `%{capo}` – Capo value
* `%{year}` – Year

Example:

    html5.paged.format-font-size : "10pt"

If unset, the default is 10pt and the color follows `pdf.theme.foreground-medium` (or `#666`).

Example:

    "Page %{page} - %{title}"

#### Header/Footer Examples

**Simple page numbers in bottom right:**

    pdf.formats.default.footer : ["", "", "Page %{page}"]

**Song title centered at top:**

    pdf.formats.default.title : ["", "%{title}", ""]

**Different footers for title and content pages:**

    pdf {
        formats {
            title {
                footer : ["%{artist}", "", "%{page}"]
            }
            default {
                footer : ["%{title}", "", "%{page}"]
            }
        }
    }

**Duplex printing with mirrored margins:**

    pdf {
        formats {
            default {
                footer : ["%{title}", "", "%{page}"]
            }
            default-even {
                footer : ["%{page}", "", "%{title}"]
            }
        }
    }

On odd pages (right-facing): Title left, page number right  
On even pages (left-facing): Page number left, title right

### CSS @page Rules

Print mode uses CSS @page rules for page styling. You can add custom @page rules by creating a custom CSS template:

```css
@page {
    size: A4;
    margin: 20mm;
}

@page :first {
    margin-top: 30mm;  /* Extra space on first page */
}

@page :left {
    margin-left: 30mm;   /* Extra margin for binding */
    margin-right: 20mm;
}

@page :right {
    margin-left: 20mm;
    margin-right: 30mm;  /* Extra margin for binding */
}
```

For advanced @page features, see the [Paged.js @page documentation](https://pagedjs.org/documentation/5-web-design-for-print/).

### Page Breaks

Control page breaks with ChordPro directives:

* `{new_page}` – Start a new page
* `{new_physical_page}` – Force a physical page break
* `{column_break}` – Break to next column (if using columns)

These are rendered as CSS with appropriate `break-before` properties.

### Print Workflow

To generate print-ready PDFs from HTML5 print mode output:

1. Generate HTML5 output with print mode enabled:
   ```bash
    chordpro --generate=HTML5 --config=print.json songs.cho -o songbook.html
   ```

2. Open `songbook.html` in Chrome or Firefox

3. Wait for Paged.js to finish rendering (status appears in page)

4. Use browser's "Print to PDF" function:
   * Chrome: `File → Print → Save as PDF`
   * Firefox: `File → Print → Save to PDF`
   * Settings: Disable headers/footers, set margins to "None"

5. The resulting PDF will have all headers, footers, and pagination applied

## Metadata Support

The HTML5 backend supports comprehensive metadata display:

* **title** – Song title (required)
* **subtitle** – Subtitle(s) (multiple supported)
* **artist** – Performer(s)
* **composer** – Composer(s)
* **lyricist** – Lyricist(s)
* **arranger** – Arranger(s)
* **album** – Album name
* **copyright** – Copyright notice
* **duration** – Song duration
* **key** – Song key
* **capo** – Capo value
* **year** – Year

Metadata is specified in ChordPro files with directives:

    {title: Amazing Grace}
    {subtitle: Traditional Hymn}
    {artist: John Newton}
    {composer: William Walker}
    {key: G}

All metadata appears in the HTML output and is available for headers/footers in print mode.

## Layout Directives

HTML5 output supports layout control directives:

* `{new_page}` – Start new page
* `{new_physical_page}` – Force physical page break
* `{column_break}` – Break to next column
* `{columns: N}` – Set number of columns

Example:

    {columns: 2}
    [Verse 1]
    ...
    {column_break}
    [Verse 2]
    ...

## Images

Example:

    {image: cover.png align=center}
    {image: chart.png align=right scale=0.8}
    {image: banner.png align=spread}

Supported alignment values are `left`, `center`, `right`, and `spread`.

## Delegates (ABC, LilyPond, Strum Patterns)

Delegate blocks are rendered inline in HTML5 output. SVG output is embedded directly; raster output is rendered as images. This enables ABC and LilyPond notation and strum patterns through the delegate pipeline.

## Advanced Customization

### Custom CSS File

Instead of embedded CSS, you can link to an external stylesheet by creating a custom songbook template:

```html
<!DOCTYPE html>
<html>
<head>
    <title>[% title %]</title>
    <link rel="stylesheet" href="my-custom-style.css">
</head>
<body>
    [% FOREACH song IN songs %]
        [% song %]
    [% END %]
</body>
</html>
```

Then configure it:

    html5.templates.songbook : "my-songbook.tt"

### Responsive Design

The default CSS includes responsive breakpoints for different screen sizes. You can customize these by modifying the CSS template or adding your own media queries.

### Web Font Integration

Include web fonts in custom templates:

```html
<head>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;700&display=swap" rel="stylesheet">
</head>
```

Then reference them in CSS configuration:

    html5.css.fonts.text : "Roboto, sans-serif"

## Usage Examples

### Basic HTML5 Output

Generate single-page HTML for web viewing:

```bash
chordpro --generate=HTML5 song.cho -o song.html
```

### Print Mode Output

Generate print-ready paginated HTML:

```bash
chordpro --generate=HTML5 --config=print.json songbook.cho -o songbook.html
```

Example print.json:

```json
{
    "html5": {
        "mode": "print"
    }
}
```

### Custom Configuration

Use custom config file:

```bash
chordpro --config=myconfig.json --generate=HTML5 songs.cho -o output.html
```

### Multiple Songs

Generate songbook from multiple files:

```bash
chordpro --generate=HTML5 --config=print.json song1.cho song2.cho song3.cho -o songbook.html
```

## Configuration Reference

Complete HTML5 configuration structure:

```json
{
    "html5": {
        "mode": "responsive",
        "cover": false,
        "front-matter": false,
        "back-matter": false,
        "template_include_path": [],
        "templates": {
            "css": "html5/css/base.tt",
            "songbook": "html5/songbook.tt",
            "song": "html5/song.tt",
            "songline": "html5/songline.tt",
            "comment": "html5/comment.tt",
            "image": "html5/image.tt",
            "chord_diagrams": "html5/chord-diagrams.tt"
        },
        "css": {
            "colors": {},
            "fonts": {},
            "sizes": {},
            "spacing": {}
        },
        "paged": {
            "papersize": "a4",
            "margintop": 80,
            "marginbottom": 40,
            "marginleft": 40,
            "marginright": 40,
            "template_include_path": [],
            "templates": {
                "css": "html5/paged/css/base.tt",
                "songbook": "html5/paged/songbook.tt",
                "song": "html5/paged/song.tt",
                "toc": "html5/paged/toc.tt"
            },
            "css": {
                "colors": {},
                "fonts": {},
                "sizes": {},
                "spacing": {}
            }
        }
    },
  "pdf": {
    "theme": {
            "foreground": "black",
            "foreground-medium": "grey70",
            "foreground-light": "grey90",
            "background": "none"
    },
    "spacing": {
      "title": 1.2,
      "lyrics": 1.2,
      "chords": 1.2,
      "diagramchords": 1.2,
      "grid": 1.2,
            "tab": 1,
    "toc": 1.4,
    "empty": 1
    },
    "chorus": {
      "indent": 0,
      "bar": {
        "offset": 8,
        "width": 1,
        "color": "foreground"
      }
    },
    "grids": {
      "symbols": { "color": "blue" },
      "volta": { "color": "blue" }
    },
    "headspace": 60,
    "footspace": 20,
    "formats": {
      "default": {
                "title": ["", "", ""],
                "subtitle": ["", "", ""],
                "footer": ["%{title}", "", "%{page}"]
      }
    }
  },
  "diagrams": {
        "show": "all",
        "sorted": false,
    "suppress": []
  }
}
```

## Resources

* **Paged.js Documentation**: [https://pagedjs.org/en/documentation/](https://pagedjs.org/en/documentation/)
* **Template Toolkit Manual**: [http://www.template-toolkit.org/docs/manual/](http://www.template-toolkit.org/docs/manual/)
* **CSS Paged Media**: [https://www.w3.org/TR/css-page-3/](https://www.w3.org/TR/css-page-3/)
* **ChordPro File Format**: [ChordPro Reference]({{< relref "ChordPro-Introduction" >}})

## Tips and Best Practices

### For Web Viewing (HTML5)

* Use readable font sizes (14pt base recommended)
* Test in multiple browsers for compatibility
* Consider dark mode support with CSS media queries
* Keep chord diagrams visible by setting `diagrams.show: "top"`

### For Printing (HTML5 Print Mode)

* Use A4 or Letter paper size matching your printer
* Set appropriate margins (minimum 10mm for most printers)
* Test "Print to PDF" before printing to paper
* Use headers/footers for page numbers and song titles
* Preview pagination before printing to avoid awkward page breaks
* Consider duplex printing with mirrored margins for binding

### Performance

* For large songbooks (50+ songs), print mode may take 10-30 seconds to render
* Be patient while Paged.js applies pagination
* The status indicator shows rendering progress
* Once rendered, the PDF export is instant

### Customization Workflow

1. Start with default settings
2. Generate sample output to identify what needs changing
3. Create custom config file with only the changes needed
4. Test iteratively with small adjustments
5. Save successful configurations for reuse

## Troubleshooting

**Chords not aligning**: Check font settings; ensure both chord and text fonts are loaded correctly.

**Headers/footers not appearing (print mode)**: Verify `pdf.formats` is configured and Paged.js has finished rendering.

**Custom template not found**: Check `template_include_path` uses absolute paths or valid path variables like `$HOME`.

**CSS not applying**: Ensure CSS template path is correct in `html5.templates.css` and template file exists.

**Paged.js not rendering**: Wait for "Rendering complete" message; check browser console for JavaScript errors.

**Print margins wrong**: Disable browser's default margins in print dialog; set margins to "None".
