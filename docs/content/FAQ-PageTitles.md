---
title: "Why do I not get metadata in my page headers"
description: "Why do I not get metadata in my page headers"
---

# Why do I not get metadata in my page headers

Also known as...

# I’ve added a Copyright (Artist, ...) directive but I do not see it in the output]

By default ChordPro only includes the song title and subtitle in the
headers/footers of the PDF output.

You can configure the headers and footers in the config file.

See [Page headers and footers](
{{< relref "Chordpro-Configuration-PDF/#page-headers-and-footers" >}}).

For example, to get the copyright in the footer on the title pages:

````
{ "pdf" : {
    "formats" : {
        // The first page of a song has:
        "title" : {
            // Footer with copyright and page number.
            "footer"    : [ "%{copyright}", "", "%{page}" ],
        },
        // The very first page of a songbook has:
        "first" : {
            // Footer with copyright.
            "footer"    : [ "%{copyright}", "", "" ],
        },
     }
} }
````

