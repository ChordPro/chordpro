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
* `strict`: If true, `{meta` ...`}` will accept any key.  
Otherwise, only the keys named in the `keys` here are allowed.
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

For example, to specify tuning for a 4-string [soprano ukulele](https://en.wikipedia.org/wiki/Ukulele#Tuning):

    "tuning" : [ "G4", "C4", "E4", "A4" ],

### User defined chords

The configuration file can hold any number of predefined chords.

    // "base" defaults to 1.
    // "easy" defaults to 0.
    // Use 0 for an empty string, and -1 for a muted string.
    "chords" : [
        {
            "name"  : "Bb",
            "base"  : 1,
            "frets" : [ 1, 1, 3, 3, 3, 1 ],
            "fingers" : [ 1, 1, 2, 3, 4, 1 ],
            "easy"  : true,
        },
    ],

### Printing chord diagrams

By default, ChordPro will include diagrams for all known chords that have been used in a song.

    // "auto": automatically add unknown chords as empty grids.
    // "show": prints the chords used in the song.
    //         "all": all chords used.
    //         "user": only prints user defined chords.
    // "sorted": order the chords by key.
    "chordgrid" : {
        "auto"     :  false,
        "show"     :  "all",
        "sorted"   :  false,
    },

### Diagnostic message format

When ChordPro detects errors while analyzing a song, it will use this format to show diagnostic messages.

In the format, `%f` will be replaced by the song file name, `%n` by the line number in the file where the error was detected, `%m` by the diagnostig message, and `%l` will be replaced by the original content of the line.

    "diagnostics" : {
        "format" : "\"%f\", line %n, %m\n\t%l",
    },
