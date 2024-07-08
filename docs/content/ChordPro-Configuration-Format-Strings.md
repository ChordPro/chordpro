---
title: "Using metadata in texts"
description: "Using metadata in texts"
---

# Using metadata in texts

Metadata can be used in header/footer texts and comments. The general
format of a metadata value in a text is `%{`*name*`}`, where _name_ is
the name of the metadata item.

It is also possible to conditionally substitute texts depending on the
value of metadata items.

`%{`*name*`|`*true-text*`|`*false-text*`}`  
`%{`*name*`|`*true-text*`}`

If metadata item _name_, the controling item, has a value, the
_true-text_ is substituted. If metadata item _name_ has no value, the
_false-text_ is substituted. Both alternatives may be left out.

It is possible to test for specific values using the `=` (equality) operator:

`%{`*name*`=`*value*`|`*true-text*`|`*false-text*`}`

For even more power, _true-text_ and _false-text_ may contain other
metadata subtitutions. The special `%{}` can be used to substitute the
value of the controling item. See. however, [nested substitutions]({{<
relref "#nested-substitutions" >}}) below.

For example, if metadata item `album` has the value "Yes",
`%{album|Album: %{}}` expands to "Album: Yes". If `album` did not have
a value, the expansion would be empty.

All metadata items can have multiple values. To get multiple values,
just issue multiple directives. For example:

    {album: Cover Stories}
    {album: Greatest Hits}

Now `album` has two values. When substituted, the values are
concatenated using the configuration setting
[`metadata.separator`]({{< relref
"ChordPro-Configuration-Generic#metadata" >}}). To access the
individual values, use `album.1` for the first value, `album.2` for
the second value, and so on. Negative numbers count from the end, e.g.
`album.-1` will give the last value.

Metadata values passed on the command line [(`--meta`)]({{< relref
"Using-ChordPro#meta" >}}) are always inserted first.

If necessary, the special meaning of the characters `\`, `{`, `}`, and
`|` can be escaped by preceding it a `\`. Note that in the
configuration files the strings are JSON strings and each `\` must be
doubled: `"\\{"` is an escaped `{`. `"\\\\"` is an escaped backslash.

## Nested substitutions

Care must be taken if substituted values contain special characters.
For example:

    {year: 1939|1967}

When used in a substitution `%{year}` this will yield, as expected,
`1939|1967`.

However, when used in `%{anything|%{year}}` first `%{year}` is
expanded, resulting in `%{anything|1939|1967}}`.
This accidentaly introduces an 'else' part.
Then `anything` is examined.
It is empty so it expands to the 'else' part... `1967`.

This can be considered a bug or a feature, depending on how you look at it.

A better way to supply multiple values is by using multiple directives
as shown above.

## Standard metadata

See [meta directive]({{< relref "Directives-meta" >}}) for the standard
metadata items.

The ChordPro reference implementation provides additional metadata:

 * `chords`: A comma-separated list of chords used in this song.

 * `chordpro`: The string `"ChordPro"`.

 * `chordpro.songsource`: The input file name for the song.

 * `chordpro.version`: The ChordPro version.
 
 * `instrument`: Short for `instrument.type`.

 * `instrument.description`: Set by instrument configs.
   For the default guitar config this is `"Guitar, 6
   strings, standard tuning"`.
   
 * `instrument.type`: The name of the instrument as set by instrument
   configs. Default `"guitar"`.

 * `numchords`: The number of chords used in this song.

 * `page`: The starting page number of the song.

 * `pages`: The number of pages of the current song.
   Only meaningful in headings and footers.

 * `songindex`: The index (serial number) of the song in the songbook.
 
 * `today`: The current date in the format defined in the config file.
   See [Dates and Times]({{< relref
   "ChordPro-Configuration-Generic#dates-and-times" >}}).
 
 * `tuning`: The tuning of the instrument.
   For the default guitar config this is `"E2 A2 D3 G3 B3 E4"`.
 
 * `user`: Short for `user.name`.
 
 * `user.fullname`: The full name of the user running ChordPro.
   Initial value is derived from the environment, if possible.

 * `user.name`: The (login) name of the user running ChordPro.
   Initial value is derived from the environment.
   
The values of `instrument` and `user` can be used for [directive
selection]({{< relref "chordpro-directives#conditional-directives"
>}})

## Command line metadata

Additional metadata can be provided on the [command line]({{< relref
"Using-ChordPro#meta" >}}).

## Song key

As can be expected, `%{key}` yields the song key as specified with the
[key]({{< relref "Directives-key" >}}) directive.

ChordPro provides two additonal metadata for substitution:

 * `key_actual`: The actual key, which is initially identical to `key`
   but will change when [transpositions]({{< relref
   "Directives-transpose" >}}) are in effect.
 
 * `key_from`: If a transposition is in effect, the key _before_ the
   transposition.

## Additional metadata for CSV generation

See [Configuration for CSV output]({{< relref "chordpro-configuration-csv" >}}).

 * `pagerange`: The pages of the song, either a single page number or
   a range like `3-7`.

## Chord format string

[Chord format strings]({{< relref
"Directives-define#chord-format-strings" >}}) support a limited set
of metadata for substitutions.

 * `name`: The given name of the chord.
 
 * `root`: The root of the chord.
 
 * `qual`: The quality of the chord. Qualities are `m`, `min`, `-`
   (minor), `maj` (major), `aug`, `+` (augmented) and `dim`, `o`, `0`
   (diminished).
   
 * `ext`: The rest, e.g. `7sus4`.
 
 * `bass`: The bass part, if the chord has a bass note separated by a
   slash `/`.

In all cases, `%{root}%{qual}%{ext}%{bass|/%{}}` yields the full chord name.

The default chord format string is the value of config
item `chord-formats` with a format string for each of the supported chord
formats.

    "chord-formats" : {
        "common" :    "%{root|%{}%{qual|%{}}%{ext|%{}}%{bass|/%{}}|%{name}}",
        "roman" :     "%{root|%{}%{qual|<sup>%{}</sup>}%{ext|<sup>%{}</sup>}%{bass|/<sub>%{}</sub>}|%{name}}",
        "nashville" : "%{root|%{}%{qual|<sup>%{}</sup>}%{ext|<sup>%{}</sup>}%{bass|/<sub>%{}</sub>}|%{name}}",
    },
	
If property `root` is known this means that the chord was successfully
parsed. The format will use the chord properties `root`,
`qual`, `ext` and `bass`. Otherwise it uses the `name` property.

**Experimental:** If a chord has been transposed and/or transcoded
there will be additional metadata:

 * `xp`: The metadata for the chord _before_ transposing.
 
 * `xc`: The metadata for the chord _before_ transcoding.
 
These have all the metadata for chords (i.e. `root`, `qual` etc.), and
in additon:
 
 * `formatted`: The formatted chord name.

For example, when you transcode a song to Roman and want to show the
roman notation alongside the original (common) notation, you can use
the following value for `chord-formats.roman`:

    %{root|%{}%{qual|<sup>%{}%{ext|%{}}</sup>}%{bass|/<sub>%{}</sub>}|%{name}}%{xc.root| (%{xc.formatted})}

The first part is the normal format for Roman notation. To this, the
following is appended:

    %{xc.root| (%{xc.formatted})}

When the chord was transcoded there is an `xc.root` and the formatted
chord name `xc.formatted` is appended between parentheses.
