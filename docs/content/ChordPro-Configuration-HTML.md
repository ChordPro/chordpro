---
title: "Configuration for HTML output (Legacy)"
description: "Configuration for legacy HTML output backend"
---

# Configuration for HTML output (Legacy)

**Note:** This document describes the legacy HTML backend. For modern HTML output with full feature support, see [Configuration for HTML5 output]({{< relref "ChordPro-Configuration-HTML5" >}}).

The legacy HTML backend is still available but is no longer actively developed. It does not support:
* Template-based customization
* PDF config compatibility (theme, spacing, chorus bars)
* Inline SVG chord diagrams
* Paginated output

Consider using the **HTML5** or **HTML5Paged** backends for new projects.

Layout definitions for HTML output are stored in the configuration under the key `"html"`.

    // Settings for HTML output.
    html {
        // The actual backend module.
        module: HTML

        // Styles.
        styles {
            // Default style.
            default : chordpro.css
            // Additional style for screen display.
            screen  : ""
            // Additional style for printing.
            print   : chordpro_print.css

            // Embed the styles instead of linking.
            embed   : false
        }
    }

## Styles

Specify stylesheets for display and printing.


The stylesheet URLs will be included as `rel="stylesheet"` links in the
`<head>` of each generated HTML document, for example:

    <head>
    <link rel="stylesheet" href="chordpro.css">
    <link rel="stylesheet" href="chordpro_print.css" media="printer">
    </head>

