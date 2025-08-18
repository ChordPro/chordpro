---
title: "Directives: sortartist"
description: "Directives: sortartist"
---

# Directives: sortartist

This directive defines the sort name for an artist.

The main purpose of the `sortartist` metadata is to provide a sort order
for artists in the Table of Contents (ToC).
If no `sortartist` is specified, the ToC will use the value of
`artist`. So it is not necessary to specify `sortartist` if `artist`
would already be sorted correctly.

If a song has multiple artists, there must
be a `sortartist` for each `artist`, and in the same order.

Examples:

    {sortartist: Beatles, The}
    {meta: sortartist Cohen, Leonard}

See also [artist]({{< relref "Directives-artist" >}}),
[Table of Contents]({{< relref "Table_Of_Contents" >}}),
and [meta]({{< relref "Directives-meta" >}}).
