---
title: "Directives: sortartist"
description: "Directives: sortartist"
---

# Directives: sortartist

This directive defines the sortname for the artist of the song.

Examples:

    {artist: Tia Blake}
    {sortartist: Blake, Tia}
    {meta: sortartist Blake, Tia}

If a song has multiple artists, there must
be a `sortartist` for each `artist`, and in the same order.

The reference implementation uses `sortartist` to sort the table of
contents and the PDF outlines.

See also: [meta]({{< relref "Directives-meta" >}}).
