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
