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

## Trouble shooting

A Windows GUI application can not display error messages except with
dialogs. That means that if there is something wrong during the
initial program setup phase, before message dialogs can be displayed,
the program crashes (or just doesn't show up) without warning.

To troubleshoot such a case you can do the following.

1. remove installed ChordPro
2. install ChordPro into your `Documents` folder
3. start the powershell
4. `cd Documents\ChordPro`
5. `copy chordpro.exe perl.exe`
6. `.\perl.exe script\wxchordpro.pl`

Most likely you will get a warning that the application does not use a
correct manifest, and several SendMessage(BCM_SETIMAGELIST) failed
messages, these can all be ignored.

If the program crashes there should be error messages in the
command line window. Please report them to the [error tracker](https://github.com/ChordPro/chordpro/issues).
