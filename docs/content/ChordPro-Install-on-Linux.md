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
applications menu with the following commands:

    desktop-file-edit \
        --set-icon="`pwd`/lib/App/Music/ChordPro/res/icons/chordpro.svg" \
	    chordpro.desktop
    desktop-file-install --mode=0755 --dir=$HOME/Desktop chordpro.desktop
    desktop-file-validate $HOME/Desktop/chordpro.desktop
	desktop-file-install --dir=$HOME/.local/share/applications \
		--rebuild-mime-info-cache chordpro.desktop
	update-desktop-database $HOME/.local/share/applications 
	cp -p chordpro.xml ~/.local/share/mime/packages/
	update-mime-database ~/.local/share/mime

This will also associate files with extension `.cho`, `.chordpro`,
`.chopro`, and `.crd` with the ChordPro program.

## CLI (command-line) interface version

`sudo cpan install chordpro`

To check for successful install, run `chordpro --version`. That should return a result like `This is ChordPro version 5.00.00`.

# Running Chordpro

Whether using GUI or CLI version, you may proceed to [Getting Started]({{< relref "ChordPro-Getting-Started" >}}).
