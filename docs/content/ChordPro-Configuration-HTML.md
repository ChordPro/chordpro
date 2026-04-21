---
title: "Configuration for HTML output"
description: "Configuration for HTML output"
---

# Configuration for HTML output

*Note that the HTML output backend is experimental.*

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

