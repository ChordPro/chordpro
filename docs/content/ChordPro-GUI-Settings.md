---
title: "Settings"
description: "ChordPro settings in the GUI"
---

# Settings

From the menu bar, choose `Edit` > `Settings…`. This will show the settings dialog.

*On macOS, the Settings are in the `ChordPro` menu.*

![]({{< asset "images/chordpro-gui-settings-notebooks.png" >}})

## Presets

### Ignore Default Configuration Files

This prevents *ChordPro* from processing system wide, user specific and
song specific config files. Checking this will make sure that *ChordPro*
only uses the configurations set in the `Settings`.

### Preset Configuration

If enabled, you can choose one or more preset configs to be used.

### Custom Configuration File

![]({{< asset "images/chordpro-gui-settings-custom configuration.png" >}})

If enabled, use the `Browse` button to choose your custom configuration file. 

See [Create a configuration using the GUI]({{< relref "Chordpro-Configuration-Create-GUI" >}}) how to get started with a `New` custom config.

### Custom ChordPro Library

ChordPro has a built-in library with configs and other data. With a `Custom library` you can add an additional location where to look for data.

## Notations

### Notation System

ChordPro supports several notation systems for songs. 

Supported values include:

* `common` (C, D, E, F, G, A, B)
* `dutch` (same as `common`)
* `german` (C, ... A, Ais/B, H)
* `latin` (Do, Re, Mi, Fa, Sol, ...)
* `scandinavian` (C, ... A, A#/Bb, H)
* `solfège` (Do, Re, Mi, Fa, So, ...)
* `nashville` (1, 2, 3, ...)
* `roman` (I, II, III, ...)

### Transpose

Transpose the song from a given key to a new key.

If transposed chords need accidentals, you can choose the desired
behaviour:

* `Auto` (transpose up uses sharps, transpose down uses flats)
* `Sharps` (always use sharps).
* `Flats` (always use flats).

### Transcode to

Transcode the song to another notation system. See the list of
supported notation systems above.

## Editor

### Editor Font

Choose a font and font size for the editor.

### Wrap Lines

Do you want to wrap lines or scroll? Up to you. *If* you want to  wrap you can *move* the wrapped lines a bit further.

### Template for new songs

Here you can select a ChordPro song to be used as a template for new songs. Its contents are inserted when you create a new song

### Editor Colours

Here you can change the *highlight* colours of the editor to your liking and makes the editor looks *Light* or *Dark*. Just what *you* prefer.

![Colours]({{< asset "images/chordpro-gui-colours.png" >}})
