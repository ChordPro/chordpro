---
title: "Configuration file contents - Generic"
description: "Configuration file contents - Generic"
---

# Configuration file contents - Generic

## User

These (optional) settings can be used to add user information.

    "user" : {
	    "name"     : "john",
		"fullname" : "John Brooke",
	}

ChordPro will try to establish initial values from the environment.

The value of `name` can be used for [directive selection]({{< relref
"chordpro-directives#conditional-directives" >}})

## General settings

These settings control global behaviour of the ChordPro program and can be changed from the command line.

    // General settings, to be changed by configs and command line.
    "settings" : {
      // Strict behaviour.
      "strict" : true,
      // Add line info for backend diagnostics.
      "lineinfo" : true,
      // Titles flush: default center.
      "titles" : "center",
      // Columns, default one.
      "columns" : 1,
      // Suppress empty chord lines.
      // Overrides the -a (--single-space) command line options.
      "suppress-empty-chords" : true,
      // Suppress blank lyrics lines.
      "suppress-empty-lyrics" : true,
      // Suppress chords.
      // Overrides --lyrics-only command line option.
      "lyrics-only" : false,
      // Memorize chords in sections, to be recalled by [^].
      "memorize" : false,
      // Chords inline.
      // May be a string containing pretext %s posttext.
      // Defaults to "[%s]" if set to a value that doesn't contain "%s".
      "inline-chords" : false,
      // Same, for annotations. Ignored unless inline-chords is set.
      // Must be a string containing pretext %s posttext.
      // Default is "%s".
      "inline-annotations" : "%s",
      // Chords under the lyrics.
      "chords-under" : false,
      // Transposing.
      "transpose" : 0,
      // Transcoding.
      "transcode" : "",
      // Always decapoize.
      "decapo" : false,
      // Chords parsing strategy.
      // Strict (only known) or relaxed (anything that looks sane).
      "chordnames": "strict",
      // Allow note names in [].
      "notenames" : false,
      // Always replace chords by their canonical form.
      "chords-canonical" : false,
      // If false, chorus labels are used as tags.
      "choruslabels" : true,
      // Substitute Unicode sharp/flats in chord names.
      // Will fallback to ChordProSymbols the font doesn't have the glyphs.
      "truesf" : false,
    },

Note that settings `decapo`, `lyrics-only`, `strict`, `transcode` and
`transpose` have corresponding command line options. The command line
option, if used, overrides the config setting.

## Columns

`columns` in `settings` can also be set to an array with column widths.
Column widths can be a number (PDF points),
a percentage of the total width,
or `0` (or `*`) to distribute the available width.

These are the same:

````
"columns": 2
"columns": [ "50%", "50%" ]
"columns": [ 0, 0 ]
"columns": [ "50%", "*" ]
````

Note that the final columns always uses the remaining width. Its value
is therefore bogus unless you have columns with `0` (or `*`).

## Metadata

The `metadata` setting contains three items:

* `keys`: The list of metadata keys.  
For these keys you can use `{meta` _key_ ...`}` as well as `{`*key* ...`}`.
* `strict`: If false, `{meta` ...`}` will accept any key.  
Otherwise, only the keys named in the `keys` here are allowed.  
`strict` is true by default.
* `separator`: To concatenate multiple values when metadata are used in title fields.
* `autosplit`: If enabled, metadata will be split on the separator to
provide multiple values.

Important: the keys `title` and `subtitle` must always be in this list.

    "metadata" : {
        "keys" : [ "title", "subtitle",
                   "artist", "composer", "lyricist", "arranger",
                   "album", "copyright", "year",
				   "sorttitle",
                   "key", "time", "tempo", "capo", "duration" ],
        "strict" : true,
        "separator" : "; ",
        "autosplit" : true,
    },

See also [Using metadata in texts]({{< relref
"ChordPro-Configuration-Format-Strings" >}}).

## Dates and Times

Defines the date format used by the metadata value `today`.

    "dates" : {
        "today" : {
            "format" : "%A, %B %e, %Y"
        }
    },

The POSIX library function `strftime` is used to render the date, so
the format string can use anything that `strftime` understands.
See its documentation as specified by [The Open Group](https://pubs.opengroup.org/onlinepubs/007908799/xsh/strftime.html).

## Instrument description

Describes the instrument used. For example:

    "instrument" : {
	    "type"        : "guitar",
		"description" : "Guitar, 6 strings, standard tuning",
	}

Other properties of an instrument are its [tuning]({{< relref "#strings-and-tuning" >}}) and [chord definitions]({{< relref "#user-defined-chords" >}}). Usually the instrument definition is maintained in a separate configuration file for maximum flexibility.

See [Defining an instrument]({{< relref "Chordpro-Configuration-Instrument" >}}) for details.

The value of `type` can be used for [directive selection]({{< relref
"chordpro-directives#conditional-directives" >}})

## Strings and Tuning

Define the instrument tuning as a list of notes in [scientific pitch notation](https://en.wikipedia.org/wiki/Scientific_pitch_notation).

For example, to specify tuning for a 4-string [soprano ukulele](https://en.wikipedia.org/wiki/Ukulele#Tuning):

    "tuning" : [ "G4", "C4", "E4", "A4" ],

Setting the tuning to any value except `null` will discard all built-in chords!

For keyboard, use

    "tuning" : [ 0 ],

## User defined chords (string instruments)

The configuration file can hold any number of predefined chords.

    // "base" defaults to 1.
    // Use 0 for an empty string, and -1 for a muted string.
    "chords" : [
        {
            "name"  : "Bb(low)",
            "base"  : 1,
            "frets" : [ 1, 1, 3, 3, 3, 1 ],
            "fingers" : [ 1, 1, 2, 3, 4, 1 ],
        },
        {
            "name"  : "Bb(high)",
            "base"  : 6,
            "baselabelofset"  : 1,
            "frets" : [ 1, 3, 3, 2, 1, 1 ],
            "fingers" : [ 1, 3, 4, 2, 1, 1 ],
			"display" : "%{root}<sup>high</sup>",
        },
    ],

`base` specifies the topmost position of the chord diagram. It must be
1 or higher. If `base` is greater than 1 its value is printed at the
side the diagram, as can be seen in the illustration below. If
`baselabelofset` has been defined and is greater than zero, the base value is
printed `baselabelofset` frets higher.

![]({{< asset "images/ex_chords.png" >}})

The `frets` positions are the positions in the chord diagram as shown.
The following two definitions are the same chord, shown in two
different positions:

    { "name" : "F#", "base" : 1, "frets" : [ 2, 4, 4, 3, 2, 2 ] },
    { "name" : "F#", "base" : 2, "frets" : [ 1, 3, 3, 2, 1, 1 ] },

Use `0` for open strings, and `-1` or `"x"` for muted strings.

![]({{< asset "images/ex_chords2.png" >}})

The `"fingers"` part is optional.
You can use digits `0` .. `9` and letters `A` .. `Z` for finger
symbols. A negative value denotes a string without finger information.

The `display` part specifies the way the chord must be shown. Note the
use of `%{root}` to show the root name.  
See file `brandtroemer.json` in the config directory for an example of
using `display` to get customized chord names.

It is possible to define a new chord based upon an existing
definition, e.g.

    { "name" : "Bmin"      , "copy" : "Bm" },
    { "name" : "F#"        , "copy" : "F", "base" : 2 },
	

## User defined chords (keyboard instruments)

For keyboard instruments only the keys (notes) that form the chord are
necessary.

    "chords" : [
        {
            "name"  : "Eb(low)",
            "keys" : [ 0, 4, 7 ],
        },
        {
            "name"     : "Eb(inv)",
            "display"  : "E♭¹",
            "keys"     : [ 4, 7, 12 ],
        },
    ],

Chord keys only depend on the chord type (quality + extension). So all
major chords have `[0, 4, 7]`, etc. For most common chords no
defintions are necessary, ChordPro can derive the notes from the chord type.

## Printing chord diagrams

By default, ChordPro will include diagrams for all known chords that
have been used in a song.

    // "show": prints the chords used in the song.
    //         "all": all chords used.
    //         "user": only prints user defined chords.
    //         "none": no song chords will ne printed.
    // "sorted": order the chords by key.
    // "suppress": a series of chord (names) thet will not generate
    //         diagrams, e.g. if they are considered trivial.
    // Note: The type of diagram (string or keyboard) is determined
    // by the value of "instrument.type".
    "diagrams" : {
        "show"     :  "all",
        "sorted"   :  false,
        "suppress" :  [],
    },

The `suppress` list can be used to filter chords from showing
diagrams, for example for chords that you consider trivial.

## Table of Contents

Multiple tables of contents can be produced, controlled by settings in
the config file.

      // Table of contents.
      "contents" : [
          { "fields"   : [ "songindex" ],
            "label"    : "Table of Contents",
            "line"     : "%{title}",
            "pageno"   : "%{page},
            "omit"     : false,
            "template" : "stdtoc",
          },
          { "fields"   : [ "sorttitle", "artist" ],
            "label"    : "Contents by Title",
            "line"     : "%{title}%{artist| - %{}}",
            "pageno"   : "%{page},
            "omit"     : false,
            "template" : "stdtoc",
          },
          { "fields"   : [ "artist", "sorttitle" ],
            "label"    : "Contents by Artist",
            "line"     : "%{artist|%{} - }%{title}",
            "pageno"   : "%{page},
            "omit"     : true,
            "template" : "stdtoc",
          },
      ],

The default configuration generates two tables, one labelled `Table of
Contents` and one labelled `Contents by Title`.
The table with title `Contents by Artist` will be omitted (see `omit`) below.

Each table is ordered according to the meta data specified in
`"fields"`.
The format of the content lines is specified in `"line"`.

* `fields`  
The ordering of the table.  
Prefix the sort key with `+` to force numeric sorting. Likewise, a
`-` prefix reverses sort order.  
When you specify a metadata item that has multiple values they are
split out in the table.  
`songindex` is a built-in meta data item that yields the sequence
number of the song in the songbook. Sorting on `songindex` will
produce the songs in songbook order.
* `label`  
The label (title) for this table.
* `line`  
The format of the table lines.  
You can use all song metadata, see [here]({{< relref "ChordPro-Configuration-Format-Strings" >}}).
* `pageno`  
The format for the page number.  
You can use all song metadata, see [here]({{< relref "ChordPro-Configuration-Format-Strings" >}}).
* `omit`  
If true, this table is omitted.
* `template`  
The template for this table.

### Customizing the table of contents

It is possible to customize the tables of content by providing a
template.
The template is processed as a song before the table
and can be used to set title, subtitle, columns, maybe even an
introduction text.
Since the template iself a song, it can be
associated with its own config file for unlimited customization.

A template can be specified with a name, e.g. `"stdtoc"` or with a file
name, e.g. `"mytoc.cho"`. Default is `"stdtoc"`.

Named templates are lookedp up with extension `.cho` in the `template`
directories of the ChordPro library. 
Template files are looked up relative to the _first_ song of the songbook.

Note that the first table in the default configuration is equivalent to
the legacy table of contents.

## Table of Contents (legacy)

*The legacy config settings will be ignored if a new style
specification (see above) is present*

    // Table of contents.
    "toc" : {
        // Title for ToC.
        "title" : "Table of Contents",
        // ToC lines.
        "line" : "%{title}",
        // Sorting order.
        // Currently only sorting by page number and alpha is implemented.
        "order" : "page",
    },

* `title`  
Defines the title text for the table of contents. By default
this is the string `"Table of Contents"`.

* `line`  
Defines the content of the table of contents lines.  
You can use all song metadata, see [here]({{< relref "ChordPro-Configuration-Format-Strings" >}}).

* `order`  
The entries in the table of contents are in the same order as in
the document. By setting `order` to `"alpha"`, the entries are sorted
alphabetically by title.

## Includes

A config file can specify a list of other config files that are to be processed *before* the contents of the current file. This makes it straightforward to create config files that extend existing config files.

For example:

    { "include" : [ "modern1" ],
      "settings" : {
          "colums" : 2
      }
    }

This config file would first load the preset config `modern1`, and then set the number of output columns to 2.

`include` takes a list of preset configs like `modern1`, or file names. If a file name is not absolute, it is taken relative to the location of the including config file.

## Diagnostic message format

When ChordPro detects errors while analyzing a song, it will use this format to show diagnostic messages.

In the format, `%f` will be replaced by the song file name, `%n` by the line number in the file where the error was detected, `%m` by the diagnostig message, and `%l` will be replaced by the original content of the line.

    "diagnostics" : {
        "format" : "\"%f\", line %n, %m\n\t%l",
    },

Note you cannot use song metadata here.
