---
title: "Directives: sorttitle"
description: "Directives: sorttitle"
---

# Directives: sorttitle

This directive defines the sorting title of the song.

The main purpose of the `sorttitle` metadata is to provide a sort order
for song titles in the Table of Contents (ToC).
If no `sorttitle` is specified, the ToC will use the value of
`title`. So it is not necessary to specify `sorttitle` if `title`
would already be sorted correctly.

Examples:

    {title: The Last Farwell}
    {sorttitle: Last Farwell, The}
    {meta: sorttitle Last Farwell, The}

If a song has multiple titles, there must
be a `sorttitle` for each `title`, and in the same order.

See also [title]({{< relref "Directives-title" >}}),
[Table of Contents]({{< relref "Table_Of_Contents" >}}),
and [meta]({{< relref "Directives-meta" >}}).
