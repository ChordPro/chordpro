---
title: "Configuration: Overview"
description: "Configuration: Overview"
---

# Configuration: Overview

The way the output is formatted and some behavioural aspects of the
reference implementation are configurable via configuration files.

{{< toc >}}

## Configuration file format

ChordPro configuration files are JSON files. However, since JSON can
be tedious and error prone to maintain, ChordPro uses a special
relaxed version of JSON: Really Relaxed JSON (RRJSON).

[RRJSON](https://github.com/sciurius/perl-Json-Relaxed) files have
filenames with extension `.json` and can be created and modified using
any convenient text editor.

As an example, compare the variants of the following _identical_
definitions. First strict JSON:
````
{
  "diagrams" : {
    "auto"   :  true,
    "show"   :  "all",
    "sorted" :  false
  },
  "dates" : {
    "today" : {
      "format" : "%A, %B %e, %Y"
    }
  },
  "tuning" : [ "E2", "A2", "D3", "G3", "B3", "E4" ]
}
````

Note that there are no comments, and there may be no commas
after `false` and the closing `]`.
	
````
// Relaxed JSON
{
  diagrams : {
    auto   :  false,
    show   :  all
    sorted :  false,
  },
  dates : {
    today : {
      format: /* for diagnostics */ "%A, %B %e, %Y"
    },
  },
  tuning : [ E2 A2 D3 G3 B3 E4 ],
}
````

Relaxed JSON has comments, doesn't require most of the quotes, and 
doesn't care much about the commas.

````
// Really Relaxed JSON
diagrams {
  auto   :  false
  show   :  all
  sorted :  false
}
dates.today.format: "%A, %B %e, %Y"
tuning : [ E2 A2 D3 G3 B3 E4 ]
````

No need for the outer braces, no need for colons before braces, and
keys of nested data can be combined into a compact, period-separated
format. It is not only much shorter, but also much easier to write and
maintain.

In this documentation we will preferably use RRJSON format, although
the stricter JSON format can be still be seen in several places for
legacy reasons.

### Converting configuration files

Config files in JSON, RJSON, RRJSON and PRP formats can easily be
converted to RRJSON format:

````
chordpro --convert-config=myconf.json --output=newconf.json
````

As an additional benefit, the converted config will have comments.
For example, this trivial config:
````
settings.chordnames=strict
````
becomes, after conversion:
````
// Configuration for ChordPro
// 
// This is a really relaxed JSON document, see
// https://metacpan.org/pod/JSON::Relaxed#REALLY-RELAXED-EXTENSIONS

// General settings, often changed by configs and command line.
settings.chordnames : strict

// End of Config.
````

## Configuration types

Configuration files can have `config` properties to designate the
purpose of the file. For example,

````
config.title       : ChordPro
config.description : "Main ChordPro config."
config.type        : style
````

The `title` and `description` are used by the ChordPro GUI to show in
the menus and choice lists, as you can see on [The Presets tab]({{<
relref "/chordpro-gui-settings/#the-presets-tab" >}}),

### `config.type: instrument`

This config defines an instrument, e.g. a guitar or a keyboard.
From the GUI, you must select one instrument.

Instrument config must set the properties `instrument.type`,
`instrument.description` and `tuning`. It may contain `chords`.

````
instrument.description : "Guitar, 6 strings, standard tuning"
instrument.type        : guitar
tuning                 : [ E2 A2 D3 G3 B3 E4 ]
````

If an instrument has chords, ChordPro will try to provide chord
diagrams.
These will be string diagrams for all instruments except keyboard.
The instrument config may contain other settings specific for the
diagrams, e.g.
````
pdf.diagrams.vcells : 4
````

### `config.type: style`

This type of configuration file defines the style and layout of the
generated output document. This includes settings for paper formats,
page margins, columns and fonts.
From the GUI, you must select one style.

ChordPro always uses its built-in style as a default, so anything that
is default does not need to be specified in a style. For example, this
is the complete `Modern 1` style (excluding comments):
````
config.title : "Modern 1"
config.description : "Nice, modern look with sans-serif fonts."
config.type : style
pdf.chorus.indent : 12
pdf.chorus.bar.width : 0.5
pdf.fonts.title : "sans-serif bold"
pdf.fonts.text : sans-serif
pdf.fonts.toc : sans-serif
````

### `config.type: stylemod`

Stylemods are intended to make one or more functionally related
changes to the selected style.
From the GUI, you can select zero or more stylemods from the choice
list.

For example, a stylemod to show chords in-line:
````
config.type : stylemod
config.title : "Inline Chords"
config.description : "Chords are placed within the lyrics."
settings.suppress-empty-chords : true
settings.inline-chords : true
pdf.fonts.chord.description : "sans 10"
pdf.fonts.annotation.description : "sans 10"
````

### `config.type: task`

Tasks are functionally similar to stylemods, but instead of being
permanently selected from the Settings dialog, they can be invoked
ad-hoc from the `Tasks` menu.

You can designate a stylemod to be used as a task as well with:
````
config.type : [ stylemod task ]
````

## Standard configuration files

ChordPro tries to read several configuration files and combines their
contents to form the actual configuration. ChordPro always starts with
the built-in default configuration. Then all configuration files are
processed in order, and their contents are merged into the existing
configuration. So all settings accumulate. Configuration files do not
need to be complete (i.e., contain all settings), it is often
sufficient to only include the settings that must be changed. See for
example the preset configurations [modern1]({{< asset
"pub/modern1.json" >}}) and [nashville]({{< asset "pub/nashville.json"
>}}), that only contains a few changes.

In the examples below the symbol `~` denotes the user's home directory. Windows users may need to change the forward slashes to backward slashes.

1. On systems that support it, a system-wide configuration file is read. On Linux systems, this is `/etc/chordpro.json`.

2. A user specific configuration file is read from either:

    `$XDG_CONFIG_HOME/chordpro/chordpro.json`
	
	or:
	
    `~/.config/chordpro/chordpro.json`  
    `~/.chordpro/chordpro.json`  
  Note that if you have a `~/.config` directory ChordPro expects the configs to be there and the latter alternative will be ignored.

3. A project specific configuration file is read from the current directory, either:

    `chordpro.json`  
    `.chordpro.json`

   Instead of a project specific configuration file you can specify arbitrary configuration files.

   * In the GUI, select `Settings...` from the `Edit` menu.  
     *(On macOS, the Settings are in the `ChordPro` menu)*  
     On the `Presets` tab, choose `Custom Configuration File`.  
     Click `Browse` for a file dialog to choose the desired configuration file.
   * On the command line, pass the name of the configuration file with
     `--config`, for example `--config=myconfig.json`.

4. A song specific configuration file is read if it exists. The name
   of the configuration file is the same as the song file name, with
   the extension replaced by `prp` or `json` (in that order).  

   Note that the scope of the song specific configuration file is the
   song only. Every song will start with an initial config that results from
   steps 1 through 3, and then its song specific configuration file if
   it exists.

   **Important** A song specific configuration file may **not**
   contain an `"include"` or `"tuning"` item.

## How config files are combined

The config files are processed in order, and their contents are
merged. In general, a config setting from a later file replaces the
value from previous files. There are a few exceptions: instrument
definitions, hashes and arrays.

### Merging instrument definitions

Instrument definitions, in particular the settings `"tuning"`,
`"notes"` and `"chords"`, are handled differently. These are processed
immediately after parsing a configuration file and then the setting is
removed from the configuration.

For example, assume `"chords_italian.json"` defines a number of chords
using italian (latin) note names and `"chords_german.json"` defines
some chords using german note names. Then the following sequence of
configuration files will work as expected:

    notes:latin           (built-in, enable latin note names)
    chords_italian.json   (defines chords with latin note names)
    notes:german          (built-in, enable german note names)
    chords_german.json    (defines chords with german note names)

### Merging hash valued items

Hashes are merged by key. For example, assume:

    { "settings" : { "titles" : "center", "columns" : 1 } }

when merged with:

    { "settings" : { "columns" : 2 } }

the result will be:

    { "settings" : { "titles" : "center", "columns" : 2 } }

### Merging array values items

Arrays are either overwritten or appended/prepended. This is
controlled by the first element of the new array. If this first
element is the string `"append"` then the new contents are appended, if it
is `"prepend"` then the new contents are prepended. Otherwise the new
contents replace the existing contents.

For example:

    { "keys" : [ "title", "subtitle" ] }

when merged with:

    { "keys" : [ "composer" ] }

will result in:

    { "keys" : [ "composer" ] }

If, however, this was merged with:

    { "keys" : [ "append", "composer" ] }

the result would have been:

    { "keys" : [ "title", "subtitle", "composer" ] }

Likewise, use `"prepend"` to prepend items.

## How the config can be adjusted

ChordPro supports two methods to make simple adjustments to the config
at runtime.

* The command line option `define`:

````
--define diagrams.auto=true
````

* The magic `{+ ...}` directive in a song:

````
{+diagrams.auto:true}
````

In either method a *key* and a *value* is specified. In the above
examples, the key is `diagrams.auto` and the value is `true`.

Note that not all config items can be adjusted this way.

## Property files

_Property files are obsolete. Please convert them as described
[above]({{< relref "#converting-configuration-files" >}})._

ChordPro also provides support for
[PRP](https://github.com/sciurius/perl-Json-Relaxed) files.
These were an early attempt at providing easier 
maintainable configs.
PRP files have a number of shortcomings, in
particular with regard to array data.
Although still supported, please use the newer RRJSON format instead.
As you may have noticed this is very close to the PRP format.
The main difference is that non-trivial strings must be quoted.
For example, in PRP:

    toc.title : Table of Contents
    toc.line: %{line}
	
These must be changed to:

    toc.title : "Table of Contents"
    toc.line: "%{line}"


