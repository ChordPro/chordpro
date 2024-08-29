---
title: "Binary installation on MacOS"
description: "Binary installation on MacOS"
---

# Binary installation on MacOS

The ChordPro volunteers provide two distinct kits for macOS.

## ChordPro for macOS

This kit is based on the macOS Swift UI and requires macOS 12 or
later. It is an Intel build and users of ARM based Macs will need to
use Rosetta.

Download ChordPro-xxxx.dmg from
[GitHub](https://github.com/ChordPro/chordpro/releases/latest) and
open it. You may get some warnings about opening files from an unknown
sources or undefined developer.

Once the `.dmg` is open, you can run the program and open
documents. For permanent install, drag the application from the DMG
window into `/Applications` (may need an administrator
password).

For the command line program it may be convenient to add the app
location to the system path so you don't have to type the full path
every time.

To temporarily add the default *uninstalled* location issue the
following command in the Terminal window:
````
export PATH="/Volumes/ChordPro/ChordPro.app/Contents/Resources":$PATH
````

To temporarily add the *installed* location issue the
following command in the Terminal window:
````
export PATH="/Applications/ChordPro.app/Contents/Resources":$PATH
````

## ChordPro Classic

This kit is based on the wxWidgets UI and requires macOS 10.15 or later.
It is an Intel build and users of ARM based Macs will need to
use Rosetta.

Download ChordPro-Classic-xxxx.dmg from
[GitHub](https://github.com/ChordPro/chordpro/releases/latest) and
open it. You may get some warnings about opening files from an unknown
sources or undefined developer.

Once the `.dmg` is open, you can already run the program and open
documents. For permanent install, drag the application from the DMG
window into `/Applications` (may need an administrator
password).

If you try to open the app and get a dialog that the app
cannot be opened because "the developer could not be verified", then
click the small question mark button (bottom-left) to get a help
screen. Scroll to the bottom, there is "Open an app by overriding
security settings". Follow the instructions. You need to do that only
once, then the app is unlocked and usable.

For the command line program it may be convenient to add the app
location to the system path so you don't have to type the full path
every time.

To temporarily add the default *uninstalled* location issue the
following command in the Terminal window:
````
export PATH="/Volumes/ChordPro Installer/ChordPro.app/Contents/MacOS":$PATH
````

To temporarily add the *installed* location issue the
following command in the Terminal window:
````
export PATH="/Applications/ChordPro.app/Contents/MacOS":$PATH
````

You may now proceed to [Getting Started]({{< relref "ChordPro-Getting-Started" >}}).

It is probably a good idea to read the section [Personal and System
configuration files]({{<
relref "chordpro-install-on-macos#personal-configuration" >}}).
