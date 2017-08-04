# Directives: meta

This directive defines a meta-data item.

`{meta: `_name_` `_value_`}`

Sets meta-data item _name_ to the specified contents.

Meta-data names can be chosen freely although single lowercase words like `artist` and `composer` are advised. It is left to the ChordPro file processing tools to do something sensible with the meta-data.

For convenience and backward compatibility, the following meta-data are considered standard. They can be defined using the `meta` directive, but also as standalone directives: [[title|Directives title]],
[[subtitle|Directives subtitle]],
[[artist|Directives artist]],
[[composer|Directives composer]],
[[lyricist|Directives lyricist]],
[[arranger|Directives arranger]],
[[copyright|Directives copyright]],
[[album|Directives album]],
[[year|Directives year]],
[[key|Directives key]],
[[time|Directives time]],
[[tempo|Directives tempo]],
[[duration|Directives duration]]
and
[[capo|Directives capo]].

Examples:

    {meta: artist The Beatles}

See also [[Using metadata in texts]].
