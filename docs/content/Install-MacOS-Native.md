---
title: "Binary installation on MacOS"
description: "Binary installation on MacOS"
---

# Binary installation on MacOS

Download ChordPro-installer-xxxx-macos-x64.dmg from
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
once, then the app is unlocked and usable

For the command line program it may be convenient to add the app
location to the system path so you don't have to type the full path
name.

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
