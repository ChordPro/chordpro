---
title: "Installation on Debian"
description: "Installation on Debian"
---

# Installation on Debian

For current Debian systems, ChordPro is available as a standard
package. You can install it with:

````
sudo apt-get update
sudo apt-get install chordpro
````

# Installation on Debian stable and LTS

Debian LTS and Debian based systems like Ubuntu LTS install by default
a subset of the wxWidgets packages. As a result, the ChordPro GUI can
not use its embedded PDF viewer.

To fully enjoy ChordPro GUI on these systems, perform the following steps.

1. Add the missing wxWidgets component:
````
sudo apt-get install libwxgtk-webview3.2-dev
````
2. Remove the distributed Alien::wxWidgets and Wx packages:
````
sudo apt-get remove libalien-wxwidgets-perl libwx-perl
sudo apt-get purge libalien-wxwidgets-perl libwx-perl
````
3. Install `cpanm`, if you don't already have it:
````
sudo apt-get install cpanminus
````
4. Rebuild (not reinstall!) Alien::wxWidgets:
````
sudo cpanm https://github.com/sciurius/perl-Alien-wxWidgets/releases/download/R0.71/Alien-wxWidgets-0.71.tar.gz
````
5. Rebuild (not reinstall!) Wx from the ChordPro site:
````
sudo cpanm https://github.com/chordpro/chordpro/releases/download/R6.070/Wx-3.005.tar.gz
````

6. Install ChordPro:
````
sudo cpanm https://github.com/chordpro/chordpro/releases/download/R6.070/App-Music-ChordPro-6.070.tar.gz
````

To check for successful install, run `chordpro --version`. That should
return a result similar to

    This is ChordPro version 6.070

(The version number may be higher.)

# Running Chordpro

Whether using GUI or CLI version, you may proceed to [Getting Started]({{< relref "ChordPro-Getting-Started" >}}).
