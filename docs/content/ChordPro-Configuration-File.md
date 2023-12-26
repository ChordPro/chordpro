---
title: "Configuration file contents"
description: "Configuration file contents"
---

# Configuration file contents

As already mentioned, the configuration file is a [JSON](https://json.org) document. The JSON format is very strict, but ChordPro allows the JSON documents to be slightly relaxed. This means that the ChordPro configuration files may contain comments and that the requirement that the last item of a list may not be followed by a comma is lifted.

For example, this JSON document is accepted by ChordPro:

    // Configuration to suppress printing of chord diagrams.
    {
        // Printing chord diagrams.
        "diagrams" : {
            "show"     :  "none",
        },
    }

In its strict form, this must be:

    {
        "diagrams" : {
            "show"     :  "none"
        }
    }

The relaxed format is much easier to maintain.

Layout doesn't matter, this document might as well have been written as:

    {"diagrams":{"show":"none"}}

The ChordPro configuration file consists of the following parts, all optional.

* [The Generic Part]({{< relref "ChordPro-Configuration-Generic" >}})  
Settings for the song parser and output backends.

* [PDF Output]({{< relref "ChordPro-Configuration-PDF" >}})  
Specific settings for PDF output.

* [HTML Output]({{< relref "ChordPro-Configuration-HTML" >}})  
Specific settings for HTML output.

* [ChordPro Output]({{< relref "ChordPro-Configuration-ChordPro" >}})  
Specific settings for ChordPro output.

* [Delegate Configuration]({{< relref "ChordPro-Configuration-Delegates" >}})  
Settings for _delegates_, e.g. ABC and Lilypond.

* [ASCII text to ChordPro converter]({{< relref "ChordPro-Configuration-A2Crd" >}})  
Settings for the ASCII text to ChordPro converter.

