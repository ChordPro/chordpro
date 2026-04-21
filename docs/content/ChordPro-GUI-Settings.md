---
title: "Settings"
description: "ChordPro settings in the GUI"
---

# Settings

To open the Settings dialog, press the `Settings` button or 
choose `Edit` > `Settings…` from the menu.

*On macOS, the Settings are in the `ChordPro` menu.*


The dialog has a number of tabs, each for a different category of
settings.

## The Presets tab

![]({{< asset "images/chordpro-gui-settings-p4.png" >}})

### Instrument

Here you can choose the instrument for your songs. This is relevant
for printing chord diagrams.

Default is a 6-string guitar in standard tuning. Other instruments
distributed with ChordPro are keyboard, mandolin and ukulele.

### Style

The style (layout) of the output for the songs. The default style is
usually good to begin with, later you may want to try the other styles
provided. Or add your own styles.

### Style Modifiers

Style modifiers, as the name implies, make usually small
modifications to the selected style. In the above example, two
modifiers are selected: 'Inline Chords' and 'Two Columns'. A
description of the selected modifiers can be seen at the right of the
list.

### Custom Configuration File

If enabled, you can use the `Browse` button to choose your custom
configuration file.

If you don't have a custom configuration file and you want to create
one, see [Create a configuration using the GUI]({{< relref "Chordpro-Configuration-Create-GUI" >}}).

### Custom ChordPro Library

*ChordPro* has a built-in library with configurations and other data.
With a `Custom library` you can add an additional location where to
look for configuration data.

### Use Default Configuration Files

This enables *ChordPro* to process system wide, user specific and
song specific configuration files. Note that checking this may result
in ChordPro using configuration settings different from what you can
control in the GUI, so it is best to leave this unchecked until you
are familiar with ChordPro's configuration files.

## The Notations tab

![]({{< asset "images/chordpro-gui-settings-p5.png" >}})

### Notation System

ChordPro supports several notation systems for songs. 

Supported values include:

* `common` (C, D, E, F, G, A, B)
* `dutch` (an other name for `common`)
* `german` (C, ... A, Ais/B, H)
* `latin` (Do, Re, Mi, Fa, Sol, ...)
* `scandinavian` (C, ... A, A#/Bb, H)
* `solfège` (Do, Re, Mi, Fa, So, ...)
* `nashville` (1, 2, 3, ...)
* `roman` (I, II, III, ...)

**Only change this if your ChordPro songs are written using one of these notations.**

### Transcode to

If enabled, ChordPro will transcode the song to another notation
system. See the list of supported notation systems above.

## The Editor tab

![]({{< asset "images/chordpro-gui-settings-p6.png" >}})

### Editor Font

Choose a font and font size for the editor.

### Wrap Lines

If the song contains lines that are too long to show in the window, do
you want to wrap then, or scroll using a horizontal scrollbar?
If you choose wrapping, you can specify the amount of indentation for
wrapped lines.

### Template for new songs

Here you can select a ChordPro song to be used as a template for new
songs.
Its contents are inserted when you create a new song. Very useful to
create songs that have standard directives for artist names or copyrights.

### Editor Colours

Here you can change the *highlight* colours of the editor to your
liking and makes the editor looks *Light* or *Dark*. Just what *you*
prefer.

![Colours]({{< asset "images/chordpro-gui-colours.png" >}})

On some systems the program can detect the system setting for 'Dark
Mode' and act accordingly.

## The Messages tab

![]({{< asset "images/chordpro-gui-settings-p7.png" >}})

Choose a font and font size for the messages window.

## The Preview tab

![]({{< asset "images/chordpro-gui-settings-p8.png" >}})

This is a left-over from older versions of the ChordPro application
that used an external program to show preview PDFs. A PDF viewer is
now included in the application so it is safe to disable the external
viewer.

If you remove the viewer string first and then disable it, the Preview
tab will no longer be shown.
