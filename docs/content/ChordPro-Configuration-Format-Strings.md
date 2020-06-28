---
title: "Using metadata in texts"
description: "Using metadata in texts"
---

# Using metadata in texts

Metadata can be used in header/footer texts and comments. The general format of a metadata value in a text is `%{`*name*`}`, where _name_ is the name of the metadata item.

It is also possible to conditionally substitute texts depending on the value of metadata items.

`%{`*name*`|`*true-text*`|`*false-text*`}`  
`%{`*name*`|`*true-text*`}`

If metadata item _name_, the controling item, has a value, the _true-text_ is substituted. If metadata item _name_ has no value, the _false-text_ is substituted. Both alternatives may be left out.

It is possible to test for specific values using the `=` (equality) operator:

`%{`*name*`=`*value*`|`*true-text*`|`*false-text*`}`

For even more power, _true-text_ and _false-text_ may contain other metadata subtitutions. The special `%{}` can be used to substitute the value of the controling item.

For example, if metadata item `album` has the value "Yes", `%{album|Album: %{}}` expands to "Album: Yes". If `album` did not have a value, the expansion would be empty.

All metadata items can have multiple values. To get multiple values, just issue multiple directives. For example:

    {album: Cover Stories}
    {album: Greatest Hits}

Now `album` has two values. When substituted, the values are concatenated using the configuration setting [`metadata.separator`]({{< relref "ChordPro-Configuration-Generic#metadata" >}}). To access the individual values, use `album.1` for the first value, `album.2` for the second value, and so on. Negative numbers count from the end, e.g. `album.-1` will give the last value.

Metadata values passed on the command line [(`--meta`)]({{< relref "Using-ChordPro#meta" >}}) are always inserted first.

If necessary, the special meaning of the characters `\`, `{`, `}`, and `|` can be escaped by preceding it a `\`. Note that in the configuration files the strings are JSON strings and each `\` must be doubled: `"\\{"` is an escaped `{`. `"\\\\"` is an escaped backslash.
