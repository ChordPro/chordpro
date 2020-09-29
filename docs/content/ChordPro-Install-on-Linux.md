---
title: "Installation on Linux"
description: "Installation on Linux"
---

# Installation on Linux

Assuming your Linux systems has the Perl environment correctly installed (standard on nearly all distros), there will be an administrator command `cpan`. In a terminal, simply run the appropriate command from the options below for the version you want to install. It will ask the administrator (super user) password and then install everything necessary to run ChordPro.

## GUI (graphical) interface version

Use your system package manager to install the Perl Wx library. For
Debian/Ubuntu type systems:

`sudo apt-get install libwx-perl`

For RPM based systems like Fedora:

`sudo dnf install perl-Wx`

After installing the Wx library, you can install `chordpro` with:

`sudo cpan install chordpro`

This will install the command line version `chordpro` as well as the
GUI version `wxchordpro`.

Then, to open the program, run `wxchordpro` at a terminal prompt. 
You will get a file open dialog. To close the program, you can press `Cancel` and terminate the program with `File` > `Exit`.

If your system uses Open Desktop compliant desktop icons, you can set
up a start icon for ChordPro on the Desktop and in the system
applications menu by executing the script `setup_desktop.sh` in the
[ChordPro resource directory]({{< relref "chordpro-resource-directory.md" >}}).
This will also associate files with extension `.cho`, `.chordpro`,
`.chopro`, and `.crd` with the ChordPro program.

## CLI (command-line) interface version

`sudo cpan install chordpro`

To check for successful install, run `chordpro --version`. That should return a result like `This is ChordPro version 5.00.00`.

# Running Chordpro

Whether using GUI or CLI version, you may proceed to [Getting Started]({{< relref "ChordPro-Getting-Started" >}}).
