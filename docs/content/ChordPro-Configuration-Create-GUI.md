---
title: "Create a new configuration using the GUI"
description: "Create a new configuration using the GUI"
---

# Create a new configuration using the GUI

From the `Edit` menu choose `Settings…` and select the `Presets` tab.  

*On macOS, the Settings are in the `ChordPro` menu.*

Here you will find the option for a new *Custom Configuration File*.


![]({{< asset "images/chordpro-gui-settings-custom configuration.png" >}})


To create a *new configuration file*, filled with *the default configuration*; just click '**New**'.

A file-dialog will give you the opportunity the give your new configuration a name, save it and select it. Alter it to your [needs]({{< relref "ChordPro-Configuration-Overview" >}}).

### Important

The configuration file contains most of the ChordPro configuration
items, **all commented out** with a leading `#` symbol. It is easy to
get started with configuring ChordPro by enabling and modifying just a
few items at a time.

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

