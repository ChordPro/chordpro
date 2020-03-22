# Configuration: Overview

The way the output is formatted and some behavioural aspects of the reference implementation are configurable via configuration files. These are [JSON](http://www.json.org/) files that can be created and modified using any convenient text editor. There are also several JSON editors available, often in the form of web services. For schema-based editors, the schema can be downloaded [here](config50.schema).

ChordPro tries to read several configuration files and combines their contents to form the actual configuration. ChordPro always starts with the built-in default configuration. Then all configuration files are processed in order, and their contents are merged into the existing configuration. So all settings accumulate. Configuration files do not need to be complete (i.e., contain all settings), it is often sufficient to only include the settings that must be changed. See for example the preset configurations [modern1](modern1.json), which is complete, and [nashville](nashville.json), which only contains a few changes.

In the examples below the symbol `~` denotes the user's home directory. Windows users may need to change the forward slashes to backward slashes.

1. On systems that support it, a system-wide configuration file is read. On Linux systems, this is `/etc/chordpro.json`.

2. A legacy config file from the older _Chord_<sub>ii</sub> program is processed. By default this is `~/.chordrc` but this can be changed using environment variables `CHORDIIRC` or `CHORDRC`.

3. A user specific configuration file is read from either:

    `~/.config/chordpro/chordpro.json`  
    `~/.chordpro/chordpro.json`  
  Note that if you have a `~/.config` directory ChordPro expects the configs to be there and the latter alternative will be ignored.

4. A project specific configuration file is read from the current directory, either:

    `chordpro.json`  
    `.chordpro.json`

Instead of a project specific configuration file you can specify arbitrary configuration files.

* In the GUI, select `Preferences...` from the `Edit` menu.  
Using the configuration dropdown list, choose `Custom`.  
Click `...` for a file dialog to choose the desired configuration file.
* On the command line, pass the name of the configuration file with `--config`, for example `--config=myconfig.json`. 

## How config files are combined

The config files are processed in order, and their contents are merged. In general, a config setting from a later file replaces the value from previous files. There are a few exceptions: instrument definitions, hashes and arrays.

### Merging instrument definitions

Instrument definitions, in particular the settings `"tuning"`, `"notes"` and `"chords"`, are handled differently. These are processed immedeately after parsing a configuration file and then the setting is removed from the configuration.

For example, assume `"chords_italian.json"` defines a number of chords using italian (latin) note names and `"chords_german.json"` defines some chords using german note names. Then the following sequence of configuration files will work as expected:

    notes_latin           (built-in, enable latin note names)
    chords_italian.json   (defines chords with latin note names)
    notes_german          (built-in, enable german note names)
    chords_german.json    (defines chords with german note names)

### Merging hash valued items

Hashes are merged by key. For example, assume:

    { "settings" : { "titles" : "center", "columns" : 1 } }

when merged with:

    { "settings" : { "columns" : 2 } }

the result will be:

    { "settings" : { "titles" : "center", "columns" : 2 } }

### Merging array values items

Arrays are either overwritten or appended. This is controlled by the first element of the new array. If this first element is the string `"append"` then the content are appended, otherwise it is overwritten.

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

