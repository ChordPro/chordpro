---
title: "Resources"
description: "Resources"
---

# Resources

ChordPro makes use of _resources_, usually small files 
that contain information like images or fonts.

All resources can be accessed using either a full filename or a short
filename. 

An example of a full filename resource for a font is
`"/usr/share/fonts/liberation-sans/LiberationSans-Regular.ttf"`. 
A resource specified with a full filename will always be used as such.

When a resource is needed and it is not specified with a full
filename, ChordPro will search for it using a different strategies
depending on the resource.

The first strategy is to look next to the song being processed.
If for example you are processing song file `blues/ballad.cho`
and this song requires resource `alert.svg`,
ChordPro will try `blues/alert.svg`.

The second strategy is to perform a search for the resource in a number of
places, often referred to as _resource libraries_.

The list of resource libraries is constructed as follows.

* The directories specified as a
colon-separated (semi-colon on Windows systems) list in
the `CHORDPRO_LIB` environment setting.

* The platform dependent user specific resource library.  
On Linux systems
there is an environment variable `HOME` that is usually something like
`/home/`_username_. On Windows this may be something like
`C:\Users\`_username_ or `C:\Documents and Settings\`_username_. The
home directory is conventionally specified with a tilde, `~`.
If the user's home directory contains a subdirectory
`.config/chordpro` this will be added to the resource libraries.

* The ChordPro resource library that comes with the ChordPro installation.

Running `chordpro --about` and the ChordPro GUI 'About' information
will show what libraries and locations will be used.

## Configuration resources (presets)

Preset configurations are searched for only in the resource libraries. 

## Tasks

_Tasks are available in the GUI only._

Tasks are just like config files but they are also presented in the
GUI 'Tasks' menu.

Tasks are searched for in all resource libraries that have a `tasks`
folder.

The tasks are shown under a neatified form of the file that contains
the task. For example, a task file `Blue_Chords.prp` will be shown as
`Blue Chords`. You can change the title with a specially formatted
first line in the file:  
`// chordpro task: `_desired title_ (for JSON files), and  
`# chordpro task: `_desired title_ (for property files).

## Images

Images are searched for next to the song being processed, and, if not
found, in all resource libraries that have an `images` folder.

## Fonts

First, the font is looked up in all the directories specified in the
config setting `fontdir`.

If not found, it is searched for in all resource libraries that have a
`fonts` folder.

Finally, a left-over from early implementations, is the location of a
directory specified in the environment variable `FONTDIR`.

## Includes

_Note: This applies to the experimental `##include` feature and is not
related to config `"include"`._

Includes are searched for next to the song being processed, and, if not
found, in all resource libraries that have an `include` folder.


