---
title: "Directives: sorttitle"
description: "Directives: sorttitle"
---

# Directives: sorttitle

This directive defines the sorting title of the song.

Examples:

    {title: The Last Farwell}
    {sorttitle: Last Farwell, The}
    {meta: sorttitle Last Farwell, The}

If a song has multiple titles, there must
be a `sorttitle` for each `title`, and in the same order.

The reference implementation uses `sorttitle` to sort the table of
contents and the PDF outlines.

See also: [meta]({{< relref "Directives-meta" >}}).
