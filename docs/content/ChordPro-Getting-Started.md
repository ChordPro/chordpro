---
title: "Getting started with ChordPro"
description: "Getting started with ChordPro"
---

# Getting started with ChordPro

For a good understanding it is important to know that ChordPro is
basically a file transformation program. It reads a file containing
lyrics and chords according to the *ChordPro File Standard* and
produces a neatly formatted PDF document that you can view and print.

## The graphical application

![]({{< asset "images/chordpro-gui-main.png" >}})

We hope you don’t have to read this chapter too often because we made a lot effort to make it *intuitive* for you. It gives you a good start to see the power of the `ChordPro` format with a lot of options to tweak it to your needs.

However, this is just *start*. If you **really** want to tweak your songs to your needs you have to get your hands dirty and create your own [configuration]({{< relref "chordpro-configuration-create-gui" >}}) or even dive into the [command line](#the-command-line-usage) for *real* power. 

`ChordPro` has both covered and in this chapter you can learn more about the terminology that is the base of the ChordPro reference application.

### Basic Usage

When you open ChordPro you have several options to get started.

- Create a new song
- Open an existing song
- Create a *Songbook* from a folder with ChordPro files
- Open recent files

### Settings

From the menu bar, choose `Edit` > `Settings…`. This will show the settings dialog.

*On macOS, the Settings are in the `ChordPro` menu.*

![]({{< asset "images/chordpro-gui-settings-notebooks.png" >}})

#### Presets

##### Ignore Default Configuration Files

This prevents ChordPro from processing system wide, user specific and
song specific config files. Checking this will make sure that ChordPro
only uses the configs set in the `Settings`.

##### Preset Configuration

If enabled, you can choose one or more preset configs to be used.

##### Custom Configuration File

If enabled, use the `…` button to choose a custom config file. See
[Create a configuration using the GUI]({{< relref "Chordpro-Configuration-Create-GUI" >}}) how to get started
with a custom config.

##### Custom ChordPro Library

ChordPro has a built-in library with configs and other data. With a `Custom library` you can add an additional location where to look for data.

#### Notations

##### Notation System

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

##### Transpose

Transpose the song from a given key to a new key.

If transposed chords need accidentals, you can choose the desired
behaviour:

* `Auto` (transpose up uses sharps, transpose down uses flats)
* `Sharps` (always use sharps).
* `Flats` (always use flats).

##### Transcode to

Transcode the song to another notation system. See the list of
supported notation systems above.

#### Editor

##### Editor Font

Choose a font and font size for the editor.

##### Wrap Lines

Do you want to wrap lines or scroll? Up to you. *If* you want to  wrap you can *move* the wrapped lines a bit further.

##### Template for new songs

Here you can select a ChordPro song to be used as a template for new songs. Its contents are inserted when you create a new song

##### Editor Colours

Here you can change the *default* highlight colours to your liking.

# The Command Line usage

If you are familiar with working on the *command line*, the basic command to use is:

`chordpro mysong.cho`

This will process `mysong.cho` and produce the PDF document `mysong.pdf`.

`chordpro --help` will give you a list of options that you can pass to the `chordpro` command.

More information can be found in the [User Guide]({{< relref
"Using-ChordPro" >}}).

# Legacy ASCII input format

Before ChordPro it was common to write lead sheets with chords on
separate lines preceding the lyrics. This is often referred to as
**crd** format. For example

          D          G    D
    Swing low, sweet chariot,
                           A7
    Comin’ for to carry me home.

ChordPro tries to detect whether the input files are in this legacy
format and if so, internally converts the data to ChordPro (**cho**
format) before processing.

    Swing [D]low, sweet [G]chari[D]ot,
    Comin’ for to carry me [A7]home.
    
The *Graphical Application* can convert your `cut/pasted` songs from sites like [Ultimate Guitar](https://tabs.ultimate-guitar.com) into **ChordPro** format to tweak it to your needs.

