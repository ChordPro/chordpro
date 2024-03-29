---
title: "Directives: meta"
description: "Directives: meta"
---

# Directives: meta

This directive defines a meta-data item.

`{meta: `*name*` `*value*`}`

Sets meta-data item _name_ to the specified contents.
_name_ must be a single word but may include underscores.

Meta-data names can be chosen freely although single lowercase words
like `artist` and `composer` are advised.
It is left to the ChordPro file processing tools to do something
sensible with the meta-data.

For convenience and backward compatibility, the following meta-data
are considered standard.
They can be defined using the `meta` directive, but also as
standalone directives:
[title]({{< relref "Directives-title" >}}),
[sorttitle]({{< relref "Directives-sorttitle" >}}),
[subtitle]({{< relref "Directives-subtitle" >}}),
[artist]({{< relref "Directives-artist" >}}),
[composer]({{< relref "Directives-composer" >}}),
[lyricist]({{< relref "Directives-lyricist" >}}),
[arranger]({{< relref "Directives-arranger" >}}),
[copyright]({{< relref "Directives-copyright" >}}),
[album]({{< relref "Directives-album" >}}),
[year]({{< relref "Directives-year" >}}),
[key]({{< relref "Directives-key" >}}),
[time]({{< relref "Directives-time" >}}),
[tempo]({{< relref "Directives-tempo" >}}),
[duration]({{< relref "Directives-duration" >}})
and
[capo]({{< relref "Directives-capo" >}}).

Examples:

    {meta: artist The Beatles}

Multiple values can be set by multiple meta-directives. For example:

    {meta: composer John Lennon}
    {meta: composer Paul McCartney}

See also [autosplit]({{< relref
"ChordPro-Configuration-Generic#metadata" >}}).

See also [Using metadata in texts]({{< relref
"ChordPro-Configuration-Format-Strings" >}}).
