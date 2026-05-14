---
title: "Installation on Microsoft Windows"
description: "Installation on Microsoft Windows"
---

# Installation on Microsoft Windows

## Binaries

Please use the [easy installer]({{< relref "Install-Windows-Native" >}}),
reported to run on 64-bit Windows 7, 8, 10 and 11.

## Using Perl

Microsoft Windows systems are not standard equipped with the Perl
application environment. You need to download and install Perl
yourself.

* [Strawberry Perl]({{< relref "Install-Windows-Strawberry" >}})  
This is also an open source Perl distribution, but it needs some
manual work to get everything going.

_Citrus Perl_ and _ActiveState Perl_ are no longer supported.

## ChordPro does not start

Nothing happens when clicking the ChordPro desktop icon.

Please try the following. 
* Open a command (powershell) window
* Find the location where you installed ChordPro. By default this is
  one of
  - `C:\Program Files\ChordPro.ORG\ChordPro`
  - `C:\Program Files (x86)\ChordPro.ORG\ChordPro`
* Type: `&'` _location_ `\xxchordpro.exe'`
* Report the problem and the output on the [issue
  tracker](https://github.com/ChordPro/chordpro/issues).
