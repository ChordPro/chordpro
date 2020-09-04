---
title: "Installation on Mac OS/X"
description: "Installation on Mac OS/X"
---

# Installation on Mac OS/X


Modern versions of Mac OS/X come with a pre-installed version of Perl
that is capable of running the command line version of ChordPro. 
It is currently not possible (well, not easy) to run the GUI version.

To install the command line version of ChordPro, open a command
terminal window and type

`sudo xcode-select --install`

You need to do this only once. This may give a final error that the
install failed, this can be ignored.

Then type:

`sudo cpan chordpro`

Make sure you are running the system version of the `cpan` tool. If in doubt, type this instead:

`sudo /usr/bin/cpan chordpro`

ChordPro should now be built and installed, by default in
`/usr/local/bin`.

Try it by typing `chordpro --version`. The result should be similar to
````
This is ChordPro version 0.977
````

(The version number may be different.)

## Personal configuration

The personal configuration is processed every time you run ChordPro,
unless you specify the `--nodefaultconfigs` or `--nouserconfig`
command line option.

If you have a folder `.config` in your home folder, you can create
a subfolder `chordpro` and place your personal configuration file
there:

`/Users/USER/.config/chordpro/chordpro.json`

where _USER_ is your Mac OS/X user name.

If there is no `.config` folder, and you do not want to create it, you
can create a subfolder `.chordpro` in your home and place your
personal config there:

`/Users/USER/.chordpro/chordpro.json`

## System configuration

A global configuration file can be placed in `/etc`:

`/etc/chordpro.json`

This config file is processed every time any user on the system runs
ChordPro, unless the user specifies the `--nodefaultconfigs` or
`--nosystemconfig` command line option.

This may be a good place to set system dependent settings like the
printer paper size and font paths.

![]({{< asset "images/maintenance.png" >}})

Please help to get the GUI version running on Mac OS/X.
