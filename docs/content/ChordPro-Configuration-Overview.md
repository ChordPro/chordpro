---
title: "Configuration: Overview"
description: "Configuration: Overview"
---

# Configuration: Overview

The way the output is formatted and some behavioural aspects of the
reference implementation are configurable via configuration files.

ChordPro understands two variants (formats) of configuration files:
PRP and JSON. If both variants of the same config are available, the PRP
variant takes precedence.

[PRP](https://github.com/sciurius/perl-Data-Properties) files have
filenames with extension `.prp` and are based on the [Java properties
files](https://en.wikipedia.org/wiki/.properties), but with structure
and many more extensions. They require much less typing and are much
less prone to errors than JSON. 

[JSON](http://www.json.org/) files have filenames with extension
`.json` and can be created and modified using
any convenient text editor. There are also several JSON editors
available, often in the form of web services. For schema-based
editors, the schema can be downloaded [here]({{< asset
"pub/config60.schema" >}}).

As an example, compare the variants of the following _identical_
definitions:
````
// JSON
"diagrams" : {
    "auto"   :  false,
    "show"   :  "all",
    "sorted" :  false,
},
"tuning" : [ "E2", "A2", "D3", "G3", "B3", "E4" ],
````
````
# Properties
diagrams.auto   =  false
diagrams.show   =  all
diagrams.sorted =  false
tuning = [ E2 A2 D3 G3 B3 E4 ]
````
````
# Properties, structured
diagrams {
    auto   =  false
    show   =  all
    sorted =  false
}
tuning = [ E2 A2 D3 G3 B3 E4 ]
````

All forms of config definitions will be used in the documentation.

## Standard configuration files

ChordPro tries to read several configuration files and combines their contents to form the actual configuration. ChordPro always starts with the built-in default configuration. Then all configuration files are processed in order, and their contents are merged into the existing configuration. So all settings accumulate. Configuration files do not need to be complete (i.e., contain all settings), it is often sufficient to only include the settings that must be changed. See for example the preset configurations [modern1]({{< asset "pub/modern1.json" >}}) and [nashville]({{< asset "pub/nashville.json" >}}), that only contains a few changes.

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

   * In the GUI, select `Preferences...` from the `Edit` menu.  
     Using the configuration dropdown list, choose `Custom`.  
     Click `...` for a file dialog to choose the desired configuration file.
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

The config files are processed in order, and their contents are merged. In general, a config setting from a later file replaces the value from previous files. There are a few exceptions: instrument definitions, hashes and arrays.

### Merging instrument definitions

Instrument definitions, in particular the settings `"tuning"`, `"notes"` and `"chords"`, are handled differently. These are processed immediately after parsing a configuration file and then the setting is removed from the configuration.

For example, assume `"chords_italian.json"` defines a number of chords using italian (latin) note names and `"chords_german.json"` defines some chords using german note names. Then the following sequence of configuration files will work as expected:

    notes::latin          (built-in, enable latin note names)
    chords_italian.json   (defines chords with latin note names)
    notes::german         (built-in, enable german note names)
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

