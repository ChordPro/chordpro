---
title: "Binary installation on macOS"
description: "Binary installation on macOS"
---

# Binary installation on macOS

We provide an installer package (dmg) for macOS 10.15 and higher.

There are separate versions for the *Intel* and *Apple Silicon* architecture.

Download ChordPro-xxxx.dmg from
[GitHub](https://github.com/ChordPro/chordpro/releases/latest) and
open it.

Once the `.dmg` is open, you will see a **READ ME FIRST** document.

Please read it; do to macOS safety restrictions you cannot just run the program.

## The 'command line' program

The ChordPro application is not just the *graphical interface*, it also contains the command line program; it is inside the package.

For the command line program it may be convenient to add the app
location to the system path so you don't have to type the full path
every time.

To temporarily add the command line program to the system path issue the
following command in the Terminal window:
````
export PATH="/Applications/ChordPro.app/Contents/Resources/cli":$PATH
````

The `.dmg` contains also an installation script that you can use to install 
the application and it will add the the command line program permanently to your PATH as well.

Its usage is explained in the **READ ME FIRST** document as well.

You may now proceed to [Getting Started]({{< relref "ChordPro-Getting-Started" >}}).

It is probably a good idea to read the section [Personal and System
configuration files]({{<
relref "chordpro-install-on-macos#personal-configuration" >}}).
