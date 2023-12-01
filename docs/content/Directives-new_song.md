---
title: "Directives: new_song"
description: "Directives: new_song"
---

# Directives: new_song

Abbreviation: `ns`.

This directive indicates that the current song, if any, is complete and that a new song will follow. This is implied at the start of a ChordPro file.

Examples:

    {new_song}
    {ns}

Attributes may be added using [key/value pairs]({{< relref
"Key_Value_Pairs" >}}).

* `toc=` _arg_  
Add the song title to the table of contents if _arg_. This is the
default case. Use `toc=no` to suppress this song from appearing
the in the table of contents.
