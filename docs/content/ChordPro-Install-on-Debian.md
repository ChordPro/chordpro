---
title: "Installation on Debian"
description: "Installation on Debian"
---

# Installation on Debian

For some Debian systems, ChordPro may be available as a standard
package. You can install it with:

````
sudo apt-get update
sudo apt-get install chordpro
````

# Installation on Debian stable and LTS

Debian LTS and Debian based systems like Ubuntu LTS install by default
a subset of the wxWidgets packages. As a result, the ChordPro GUI can
not function fully.

To fully enjoy ChordPro GUI on these systems, perform the following steps.

1. Add the missing wxWidgets components
````
sudo apt-get install libwxgtk-webview3.2-dev libwxgtk-media3.2-dev
````
2. Remove the distributed Alien::wxWidgets and Wx packages
````
sudo apt-get remove libalien-wxwidgets-perl libwx-perl
sudo apt-get purge libalien-wxwidgets-perl libwx-perl
````
3. Install `cpanm`, if you don't already have it
````
sudo apt-get install cpanminus
````
4. Rebuild (not reinstall!) Alien::wxWidgets

   _Consult https://github.com/sciurius/perl-Alien-wxWidgets/releases/
   for the latest release of Alien::wxWidgets. Substitute the actual 
   version number for the "0.000" in the URL below._

````
cpanm --sudo https://github.com/sciurius/perl-Alien-wxWidgets/releases/download/latest/Alien-wxWidgets-0.000.tar.gz
````
5. Rebuild (not reinstall!) Wx

   _Consult https://github.com/sciurius/wxPerl/releases/
   for the latest release of Wx. Substitute the actual version
   number for the "0.000" in the URL below._

````
cpanm --sudo --notest https://github.com/sciurius/wxPerl/releases/download/latest/Wx-0.000.tar.gz
````

6. Install ChordPro

   _Consult https://github.com/chordpro/chordpro/releases/
   for the latest release of ChordPro. Substitute the actual version
   number for the "0.000" in the URL below._

````
cpanm --sudo https://github.com/chordpro/chordpro/releases/download/latest/App-Music-ChordPro-0.000.tar.gz
````

To check for successful install, run `chordpro --version`. That should
return a result similar to

    This is ChordPro version {{< chordpro_version >}}

(The version number may differ.)

# Running Chordpro

Whether using GUI or CLI version, you may proceed to [Getting Started]({{< relref "ChordPro-Getting-Started" >}}).
