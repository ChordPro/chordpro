---
title: "Configuration for HTML5 output"
description: "Configuration for HTML5 and HTML5Paged output"
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

ChordPro provides two HTML5-based output backends:

* **HTML5**: Single-page continuous HTML output suitable for web viewing or basic printing
* **HTML5Paged**: Professional paginated output using [Paged.js](https://pagedjs.org/) for print-ready PDFs

Both backends share the same configuration structure with `html5.paged` providing additional settings for pagination.

## Template System

Both HTML5 backends use [Template Toolkit](http://www.template-toolkit.org/) for generating HTML output, providing maximum flexibility and customization without modifying the backend code.

### Template Configuration

Templates are specified in the configuration:

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

### Template Include Paths

You can add custom template directories to the search path:

    html5 {
        template_include_path : [
            "/path/to/my/templates",
            "$HOME/.config/chordpro/templates"
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

Then point to your custom templates in the configuration:

    html5 {
        templates {
            song : "my-custom-song.tt"
        }
    }

Template variables available include `title`, `subtitle`, `meta` (artist, composer, album, etc.), `body` (song content), and `chord_diagrams` (SVG diagrams).

## CSS Customization

The HTML5 backends generate embedded CSS for single-file output. CSS can be customized through configuration.

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

Define custom colors in the configuration:

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

Specify fonts for different elements:

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

Control sizing with `em` units for scalability:

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

Adjust spacing between elements:

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

## Chord Positioning

The HTML5 backends use CSS Flexbox for chord positioning, ensuring chords stay aligned above the correct syllable regardless of font size or family.

The key structure is:

```html
<span class="cp-chord-lyric-pair">
  <span class="cp-chord">G</span>
  <span class="cp-lyrics">Hello</span>
</span>
```

This works with any font combination without JavaScript. The flexbox layout keeps chords precisely positioned above their lyrics.

## Chord Diagrams

Both HTML5 backends support inline SVG chord diagrams showing fingering positions. Diagrams are automatically generated for chords used in the song.

Configuration follows the same structure as PDF output:

    diagrams {
        show     : "bottom"  // or "top", "false"
        sorted   : true      // Sort alphabetically
        suppress : []        // List of chords to hide
    }

Diagrams are sized at `4em` width for scalability with font size changes.

## PDF Config Compatibility

Both HTML5 and HTML5Paged backends support PDF configuration options for smooth migration from PDF output. Configuration follows a hybrid precedence model:

* **HTML5 backend**: `html5.*` overrides `pdf.*` overrides defaults
* **HTML5Paged backend**: `html5.paged.*` overrides `pdf.*` overrides defaults

This allows you to define settings once under `pdf` and have them work across all backends, with backend-specific overrides when needed.

### Theme Colors

Define a color theme that applies to all elements:

    pdf {
        theme {
            foreground        : "#000000"  // Primary text
            foreground-medium : "#444444"  // Medium emphasis
            foreground-light  : "#888888"  // Light/subtle elements
            background        : "#FFFFFF"  // Background color
        }
    }

HTML5Paged can override specific colors:

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

Control line spacing for different elements with multipliers applied to base line height:

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

HTML5Paged overrides for better screen readability:

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

Customize the visual indicator for chorus sections:

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

Customize colors for grid sections (chord charts):

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

### Header/Footer Spacing (HTML5Paged only)

Control space reserved for headers and footers:

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
* HTML5Paged overrides lyrics spacing (1.6 vs 1.4) for better screen readability
* HTML5Paged overrides foreground color (#222222 vs #000000) for reduced eye strain
* All other PDF settings inherited by HTML5Paged

## HTML5Paged: Paginated Output

The HTML5Paged backend uses [Paged.js](https://pagedjs.org/), a JavaScript library that brings CSS Paged Media features to the browser, enabling professional print layouts with page headers, footers, and page numbers.

### Paged.js Integration

HTML5Paged output includes the Paged.js library via CDN:

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

Configure page size for pagination:

    html5.paged {
        papersize : "a4"    // or "letter", "legal", [width, height]
    }

If not specified, inherits from `pdf.papersize`.

Standard paper sizes:
* `a4`: 595 × 842 pt (210 × 297 mm)
* `letter`: 612 × 792 pt (8.5 × 11 in)
* `legal`: 612 × 1008 pt (8.5 × 14 in)

You can also specify custom dimensions in points:

    html5.paged {
        papersize : [600, 800]  // Width × Height in points
    }

### Page Margins

Control page margins in points (1/72 inch):

    html5.paged {
        margintop    : 80
        marginbottom : 40
        marginleft   : 40
        marginright  : 40
    }

If not specified, inherits from PDF margin settings (`pdf.margintop`, etc.).

### Headers and Footers

HTML5Paged supports configurable headers and footers using CSS @page margin boxes. Configuration reuses the `pdf.formats` structure for consistency with PDF output.

#### Format Configuration

Define page formats in your configuration:

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

Example format string:

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

HTML5Paged uses CSS @page rules for page styling. You can add custom @page rules by creating a custom CSS template:

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

To generate print-ready PDFs from HTML5Paged output:

1. Generate HTML5Paged output:
   ```bash
   chordpro --generate=HTML5Paged songs.cho -o songbook.html
   ```

2. Open `songbook.html` in Chrome or Firefox

3. Wait for Paged.js to finish rendering (status appears in page)

4. Use browser's "Print to PDF" function:
   * Chrome: `File → Print → Save as PDF`
   * Firefox: `File → Print → Save to PDF`
   * Settings: Disable headers/footers, set margins to "None"

5. The resulting PDF will have all headers, footers, and pagination applied

## Metadata Support

Both HTML5 backends support comprehensive metadata display:

* **title** – Song title (required)
* **subtitle** – Subtitle(s) (multiple supported)
* **artist** – Performer(s)
* **composer** – Composer(s)
* **lyricist** – Lyricist(s)
* **arranger** – Arranger(s)
* **album** – Album name
* **copyright** – Copyright notice
* **duration** – Song duration

Metadata is specified in ChordPro files with directives:

    {title: Amazing Grace}
    {subtitle: Traditional Hymn}
    {artist: John Newton}
    {composer: William Walker}
    {key: G}

All metadata appears in the HTML output and is available for headers/footers in HTML5Paged.

## Layout Directives

HTML5 backends support layout control directives:

* `{new_page}` – Start new page (HTML5Paged only)
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

### Paginated Output

Generate print-ready paginated HTML:

```bash
chordpro --generate=HTML5Paged songbook.cho -o songbook.html
```

### Custom Configuration

Use custom config file:

```bash
chordpro --config=myconfig.json --generate=HTML5Paged songs.cho -o output.html
```

### Multiple Songs

Generate songbook from multiple files:

```bash
chordpro --generate=HTML5Paged song1.cho song2.cho song3.cho -o songbook.html
```

## Configuration Reference

Complete HTML5 configuration structure:

```json
{
  "html5": {
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
        "css": "html5paged/css/base.tt",
        "songbook": "html5paged/songbook.tt",
        "song": "html5paged/song.tt"
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
      "foreground": "#000000",
      "foreground-medium": "#444444",
      "foreground-light": "#888888",
      "background": "#FFFFFF"
    },
    "spacing": {
      "title": 1.2,
      "lyrics": 1.2,
      "chords": 1.2,
      "diagramchords": 1.2,
      "grid": 1.2,
      "tab": 1.0,
      "toc": 1.4,
      "empty": 1.0
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
    "headspace": 0,
    "footspace": 0,
    "formats": {
      "default": {
        "title": ["", "", ""],
        "footer": ["", "", ""]
      }
    }
  },
  "diagrams": {
    "show": "bottom",
    "sorted": true,
    "suppress": []
  }
}
```

## Resources

* **Paged.js Documentation**: [https://pagedjs.org/en/documentation/](https://pagedjs.org/en/documentation/)
* **Template Toolkit Manual**: [http://www.template-toolkit.org/docs/manual/](http://www.template-toolkit.org/docs/manual/)
* **CSS Paged Media**: [https://www.w3.org/TR/css-page-3/](https://www.w3.org/TR/css-page-3/)
* **ChordPro File Format**: [ChordPro Reference]({{< relref "chordpro-file-format-specification" >}})

## Tips and Best Practices

### For Web Viewing (HTML5)

* Use readable font sizes (14pt base recommended)
* Test in multiple browsers for compatibility
* Consider dark mode support with CSS media queries
* Keep chord diagrams visible by setting `diagrams.show: "top"`

### For Printing (HTML5Paged)

* Use A4 or Letter paper size matching your printer
* Set appropriate margins (minimum 10mm for most printers)
* Test "Print to PDF" before printing to paper
* Use headers/footers for page numbers and song titles
* Preview pagination before printing to avoid awkward page breaks
* Consider duplex printing with mirrored margins for binding

### Performance

* For large songbooks (50+ songs), HTML5Paged may take 10-30 seconds to render
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

**Headers/footers not appearing (HTML5Paged)**: Verify `pdf.formats` is configured and Paged.js has finished rendering.

**Custom template not found**: Check `template_include_path` uses absolute paths or valid path variables like `$HOME`.

**CSS not applying**: Ensure CSS template path is correct in `html5.templates.css` and template file exists.

**Paged.js not rendering**: Wait for "Rendering complete" message; check browser console for JavaScript errors.

**Print margins wrong**: Disable browser's default margins in print dialog; set margins to "None".
