---
title: "Installation on Linux"
description: "Installation on Linux"
---

# Installation on Linux

Assuming your Linux systems has the Perl environment correctly
installed (standard on nearly all distros), there will be an
administrator command `cpan`. In a terminal, simply run the
appropriate command from the options below for the version you want to
install. It will ask the administrator (super user) password and then
install everything necessary to run ChordPro.

## Prerequisites

ChordPro requires a number of Perl modules to run. These will be
installed automatically by the `cpan` tool if necessary. However, it
may be advantageous to install platform supplied packages if
available. On RPM-based systems (RedHat, Fedora, Suze) packages can be
installed with `dnf` or `yum`. On Debian/Ubuntu-based systems use the
`apt-get` tool.

Module | RPM | Debian
--|--|--
`PDF::API2` | `perl-PDF-API2` | `libpdf-api2-perl`
`Text::Layout` | `perl-Text-Layout` | `libtext-layout-perl`
`App::Packager` | `perl-App-Packager` | `libapp-packager-perl`
`File::LoadLines` | `perl-File-LoadLines` | `libfile-loadlines-perl`
`String::Interpolate::Named` | `perl-String-Interpolate-Named` | `libstring-interpolate-named-perl`
`Image::Info` | `perl-Image-Info` | `libimage-info-perl`
{ .table .table-striped .table-bordered .table-sm }

Do not worry if any of these packages are not available, the `cpan`
install process will build them if necessary.

## Helper programs

To support ABC embedding, ChordPro requires two helper programs:

* `abcm2ps`  
This proram is used to convert ABC to a vector image.  
Most Linux distributions have prebuilt packages available.  
Otherwise, you can find it on [SourceForge](http://abcplus.sourceforge.net/).

* `convert`  
This is part of the ImageMagick suite of graphical manipulation
tools. It is used to convert the vector image to a suitable bitmapped
format for embedding.  
Most Linux distributions have prebuilt packages available.  
Otherwise, you can download it from the [ImageMagick web
site](https://imagemagick.org/).

## GUI (graphical) interface version

There is one critical prerequisite that must be installed manually:
the perl wxWidgets library.

For Debian/Ubuntu-based systems:

`sudo apt-get install libwx-perl`

For RPM-based systems:

`sudo dnf install perl-Wx`

After installing the Wx library, you can install `chordpro` with:

`sudo cpan install chordpro`

This will install the command line version `chordpro` as well as the
GUI version `wxchordpro`.

Next, to open the program, run `wxchordpro` at a terminal prompt. 
You will get a file open dialog. To close the program, you can press `Cancel` and terminate the program with `File` > `Exit`.

If your system uses Open Desktop compliant desktop icons, you can set
up a start icon for ChordPro on the Desktop and in the system
applications menu by executing the script `setup_desktop.sh` in the
[ChordPro resource directory]({{< relref "chordpro-resource-directory.md" >}}).
This will also associate files with extension `.cho`, `.chordpro`,
`.chopro`, and `.crd` with the ChordPro program.

## CLI (command-line) interface version

`sudo cpan install chordpro`

To check for successful install, run `chordpro --version`. That should
return a result similar to

    This is ChordPro version 0.977

(The version number may be different.)

# Running Chordpro

Whether using GUI or CLI version, you may proceed to [Getting Started]({{< relref "ChordPro-Getting-Started" >}}).
