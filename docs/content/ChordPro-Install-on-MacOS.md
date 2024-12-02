---
title: "Installation on macOS"
description: "Installation on macOS"
---

# Installation on macOS

There are currently no reports that ChordPro can be successfully built 
using the pre-installed version of Perl that comes with macOS.

The command line version of ChordPro can be built with HomeBrew Perl.
It is currently not possible (well, not easy) to build the GUI version.

Unless you are a seasoned macOS Perl developer, please use the [binary
install kit]({{< relref
"Install-MacOS-Native" >}}).
This kit includes both the GUI and the command line version of ChordPro.

## Using HomeBrew

Still here?

To install the command line version of ChordPro, open a command
terminal window and type

    sudo xcode-select --install

You need to do this only once. This may give a final error that the
install failed, this can be ignored.

First, install `homebrew` if it is not yet installed. Directions can
be found [here](https://brew.sh/).

Then install perl:

    brew install perl

Note that this will install perl in a subdirectory of
`/usr/local/Cellar`, e.g. `/usr/local/Cellar/perl/5.32.0/bin`. It is
advised to add this to the front of your `PATH`.

Finally, install ChordPro:

    /usr/local/Cellar/perl/5.32.0/bin/cpan chordpro
	
This will give you the `chordpro` command.

    % chordpro --version
    This is ChordPro core 6.050

## Personal configuration

The personal configuration is processed every time you run ChordPro,
unless you specify the `--nodefaultconfigs` or `--nouserconfig`
command line option.

If you have a folder `.config` in your home folder, you can create
a subfolder `chordpro` and place your personal configuration file
there:

`/Users/USER/.config/chordpro/chordpro.json`

where _USER_ is your macOS user name.

If there is no `.config` folder, and you do not want to create it, you
can create a subfolder `.chordpro` in your home and place your
personal config there:

`/Users/USER/.chordpro/chordpro.json`

## System configuration

A global configuration file can be placed in `/etc`:

`/etc/chordpro.json`

This config file is processed every time any user on the system runs
ChordPro, unless the user specifies the `--nodefaultconfigs` or
`--nosysconfig` command line option.

This may be a good place to set system dependent settings like the
printer paper size and font paths.

