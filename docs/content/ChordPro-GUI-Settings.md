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

### Ignore Default Configuration Files

This prevents *ChordPro* from processing system wide, user specific and
song specific configuration files.
Checking this will make sure that *ChordPro*
only uses the configurations set in the `Settings`.

### Preset Configuration

If enabled, you can choose one or more preset configurations to be used.

### Custom Configuration File

If enabled, you can use the `Browse` button to choose your custom
configuration file.

If you don't have a custom configuration file and you want to create
one, see [Create a configuration using the GUI]({{< relref "Chordpro-Configuration-Create-GUI" >}}).

### Custom ChordPro Library

ChordPro has a built-in library with configurations and other data.
With a `Custom library` you can add an additional location where to
look for data.

Changing the `Custom library` requires a restart of the ChordPro program.
A message will appear as a reminder.

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

### Transpose

If enabled, transpose the song from a given key to a new key.

If transposed chords need accidentals, you can choose the desired
behaviour:

* `Auto` (transpose up uses sharps, transpose down uses flats)
* `Sharps` (always use sharps).
* `Flats` (always use flats).

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
