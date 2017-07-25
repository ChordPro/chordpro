# Configuration file contents

As already mentioned, the configuration file is a [JSON](https://json.org) document. The JSON format is very strict, but ChordPro allows the JSON documents to be slightly relaxed. This means that the ChordPro configuration files may contain comments and that the requirement that the last item of a list may not be followed by a comma is lifted.

For example, this JSON document is accepted by ChordPro:

    // Configuration to suppress printing of chord diagrams.
    {
        // Printing chord grids.
        "chordgrid" : {
            "show"     :  "none",
        },
    }

In its strict form, this must be:

    {
        "chordgrid" : {
            "show"     :  "none"
        }
    }

The relaxed format is much easier to maintain.

Layout doesn't matter, this document might as well have been written as:

    {"chordgrid":{"show":"none"}}

The ChordPro configuration file consists of two parts, all optional. The first part is for generic settings, the second part is for output specific settings.

## The Generic Part

### General settings

These settings control global behaviour of the ChordPro program and can be changed from the command line.

    // General settings, to be changed by legacy configs and
    // command line.
    "settings" : {
        // Titles flush: default center.
        "titles" : "center",
        // Columns, default one.
        "columns" : 1,
        // Suppress empty chord lines.
        // Overrides the -a (--single-space) command line options.
        "suppress-empty-chords" : true,
        // Suppress chords.
        // Overrides --lyrics-only command line option.
        "lyrics-only" : false,
    },

### Metadata

The `metadata` setting contains three items:

* `keys`: The list of recognized metadata keys.  
For these keys you can use `{meta` _key_ ...`}` as well as `{`_key_ ...`}`.
* `strict`: If zero, `{meta` ...`}` will accept any key.  
If nonzero, only the keys named in the `keys` here are allowed.
* `separator`: To concatenate multiple values when metadata are used in title fields.

Important: the keys `title` and `subtitle` must always be in this list.

    "metadata" : {
        "keys" : [ "title", "subtitle",
                   "artist", "composer", "lyricist", "arranger",
                   "album", "copyright", "year",
                   "key", "time", "tempo", "capo", "duration" ],
        "strict" : true,
        "separator" : "; ",
    },

### Strings and Tuning

Setting the tuning to any value except `"null"` will discard all built-in chords!

    "tuning" : null,

For example to specify tuning for a 4-string ukulele:

    "tuning" : [ "G4", "C4", "E4", "A4" ],

