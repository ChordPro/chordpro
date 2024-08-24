---
title: "Installation on Linux"
description: "Installation on Linux"
---

# Installation on Linux

First of all, check if there is a prebuilt package available for your
system.

On RPM-based systems (RedHat, Fedora, Suze) packages can be
installed with `dnf` or `yum`. On Debian/Ubuntu-based systems use the
`apt-get` tool. For example on a Ubuntu system:

````
$ sudo apt-get install chordpro
````

## CPAN install

Assuming your Linux systems has the Perl environment correctly
installed (standard on nearly all distros), there will be an
administrator command `cpan`. In a terminal, simply run the
appropriate command from the options below for the version you want to
install. It will ask the administrator (super user) password and then
install everything necessary to run ChordPro.

## Prerequisites

ChordPro requires a number of Perl modules to run. These will be
installed automatically by the `cpan` tool if necessary. However, it
is strongly advised to install platform supplied packages if
available.
On RPM-based systems (RedHat, Fedora, Suze) packages can be
installed with `dnf` or `yum`. On Debian/Ubuntu-based systems use the
`apt-get` tool.

The `cpan` tool requires build tools `make`, `gcc` and `g++`.
Traditionally these were always installed on Linux systems but
on some modern Linux distributions these must be installed explicitly.
So check this first!

These modules should be available as prebuilt packages:

| Module          | RPM                 | Debian                 |
|-----------------|---------------------|------------------------|
| `PDF::API2`     | `perl-PDF-API2`     | `libpdf-api2-perl`     |
| `Object::Pad`   | `perl-Object-Pad`   | `libobject-pad-perl`   |
| `Image::Info`   | `perl-Image-Info`   | `libimage-info-perl`   |
| `JSON::PP`      | `perl-JSON-PP`      | `libjson-pp-perl`      |
| `JSON::XS`      | `perl-JSON-XS`      | `libjson-xs-perl`      |
| `File::HomeDir` | `perl-File-HomeDir` | `libfile-homedir-perl` |
| `Data::Printer` | `perl-Data-Printer` | `libdata-printer-perl` |
| `Storable`      | `perl-Storable`     | `libstorable-perl`     |
| `Pod::Usage`    | `perl-Pod-Usage`    | `libpod-usage-perl`    |
{ .table .table-striped .table-bordered .table-sm }

These modules may be available as prebuilt packages:

| Module                       | RPM                             | Debian                             |
|------------------------------|---------------------------------|------------------------------------|
| `Text::Layout`               | `perl-Text-Layout`              | `libtext-layout-perl`              |
| `JavaScript::QuickJS`        | `perl-JavaScript-QuickJS`       | `libjavascript-quickjs-perl`       |
| `File::LoadLines`            | `perl-File-LoadLines`           | `libfile-loadlines-perl`           |
| `String::Interpolate::Named` | `perl-String-Interpolate-Named` | `libstring-interpolate-named-perl` |
{ .table .table-striped .table-bordered .table-sm }

Do not worry if some of these packages are not available, the `cpan`
install process will build them if necessary.

## GUI (graphical) interface version

If you are going to use ChordPro on the command line only, you can
skip to the next section.

For the GUI version, there is one critical prerequisite that must be
installed manually: the perl wxWidgets library.

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

    This is ChordPro version 6.000

(The version number may be higher.)

# Running Chordpro

Whether using GUI or CLI version, you may proceed to [Getting Started]({{< relref "ChordPro-Getting-Started" >}}).
