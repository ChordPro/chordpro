---
title: "Preset configurations"
description: "Preset configurations"
---

# Preset configurations

ChordPro comes with a number of standard configurations.

It is important to know that ChordPro always loads the
[default configuration]({{< asset "pub/chordpro_json.txt" >}})
and then adds the other configurations.

* In the GUI, there is a selection list for the presets in the `Presets` tab of the `Settings` dialog.
* On the command line, use `--config`, e.g., `--config=modern1`.

Some of the presets define a full style, e.g., `chordii` and `modern1`. Other
presets modify the current style, e.g., `nashville` and `ukulele`. So
you can combine presets to form new styles. For example, `--config=modern1,nashville`

## Standard configurations

_Click on the page thumbnails to see the full size version._

### Default
As the name implies, this is the default configuration.

{{< showpage "style_default" >}}

### Chordii
This preset configuration makes the output look as closely as possible to the output of the Chord<sub>ii</sub> program.

{{< showpage "style_chordii" >}}

### Modern1
A nice, modern style.

{{< showpage "style_modern1" >}}

### Modern2
An alternative modern style.

{{< showpage "style_modern2" >}}

### Modern3
A style with chord diagrams in a right column on the first page instead of at the end of the song.

{{< showpage "style_modern3" >}}

### Dark
A dark 'theme'.

{{< showpage "style_dark" >}}

This style only sets colours, so it can be used in combination with other styles.

### Nashville
A special style for songs that use Nashville numbering notation.

{{< showpage "style_nashville" >}}

This style only sets the font for the chords, so it can be used in combination with other styles.

### Roman
A special style for songs that use Roman numbering notation.

{{< showpage "style_roman" >}}

This style only sets the font for the chords, so it can be used in combination with other styles.

### Keyboard
This preset sets the instrument to keyboard. It doesn't define
chords since keyboard chords can be determined from their names.

{{< showpage "style_keyboard" >}}

This style only sets the instrument, so it can be used in combination with other styles.

### Ukulele
This preset adds ukulele tuning and chords.

{{< showpage "style_ukulele" >}}

This style only sets the instrument and defines the ukulele chords, so it can be used in combination with other styles.

# User library

Presets are looked up in the folders where ChordPro is installed. It
is possible to add a custom folder presets by using environment
variable `CHORDPRO_LIB`.

`CHORDPRO_LIB` should have the name of the custom folder, and a
subfolder `config` where the custom configs can be placed. For
example, assume `CONFIG_LIB` is `~/lib/ChordPro` and this folder
contains `config/mspro.json`, then this config can be used as

    --config mspro
	
Note that currently the name of the config file must be **all lowercase
characters**. It may be referred in any case, e.g

    --config Mspro
    --config MSPro

* In the GUI, in the `Presets` tab of the `Settings` dialog there is an option to select a folder as your *Custom ChordPro Library*.
