---
title: "Configuration for HTML output"
description: "Configuration for HTML output"
---

# Configuration for HTML output

*Note that the HTML output backend is still experimental.*

Layout definitions for HTML output are stored in the configuration under the key `"html"`.

    {
       // ... generic part ...
       "html" : {
         // ... layout definitions ...
       },
    }

## Styles

Specify stylesheets for display and printing.

  	  // Stylesheet links.
  	  "styles" : {
  	      "display" : "chordpro.css",
  	      "print"   : "chordpro_print.css",
      }

The sylesheet URLs will be included as `rel="stylesheet"` links in the
`<head>` of each generated HTML document, for example:

	<head>
	<link rel="stylesheet" href="chordpro.css">
	<link rel="stylesheet" href="chordpro_print.css" media="printer">
	</head>

