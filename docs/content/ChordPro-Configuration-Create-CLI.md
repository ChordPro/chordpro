---
title: "Creating a config (CLI)"
description: "Creating a config (CLI)"
---

# Creating a config (CLI)

## Create a sample configuration using the command line

_Note that the syntax of file names may differ between systems._

From the command prompt, type

`chordpro --print-default-config > myconfig.json`

The generated file `myconfig.json` contains most of the ChordPro
configuration items, **all commented out** with a leading `#` symbol.
It is easy to get started
with configuring ChordPro by enabling and modifying just a few items
at a time.

For example, if you want your chords to show at the right side instead
of at the bottom, locate

````
// Diagrams for all chords of the song can be shown at the
// "top", "bottom" or "right" side of the first page,
// or "below" the last song line.
# pdf.diagrams.show : bottom
````

Remove the comment symbol `#` and change `bottom` to `right`:

````
// Diagrams for all chords of the song can be shown at the
// "top", "bottom" or "right" side of the first page,
// or "below" the last song line.
pdf.diagrams.show : right
````

For a full config, with everything set to default values, type

`chordpro --print-default-config --print-default-config > myconfig.json`

Use this for informational purposes only! In particular, do not use
this as a starting point for your customized config unless you really
know what you are doing.
