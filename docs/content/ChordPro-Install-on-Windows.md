---
title: "Installation on Microsoft Windows"
description: "Installation on Microsoft Windows"
---

# Installation on Microsoft Windows

_This information may be sub-optimal and/or incomplete. Please help improving it._

## Binaries

If you're not sure which option to take, use the
[Native install kit]({{< relref "Install-Windows-Native" >}}) (reported to run on
64-bit Windows 7, 8 and 10) and download the installer.

To support ABC embedding, you must also install [ImageMagick](https://imagemagick.org).

## Using Perl

Microsoft Windows systems are not standard equipped with the Perl application environment. You need to download and install Perl yourself.

Currently, there are some easy options (and several harder ones that will not be discussed here).

* [Strawberry Perl]({{< relref "Install-Windows-Strawberry" >}})  
This is also an open source Perl distribution, but it needs some manual work to get everything going.
* [Citrus Perl]({{< relref "Install-Windows-Citrus" >}})  
This is an open source Perl distribution which includes many tools.
Unfortunately, it seems to be abandoned.
* [ActiveState Perl]({{< relref "Install-Windows-ActiveState" >}})  
This is a commercial Perl implementation but it provides a Community
Edition that is free to use for individuals.  
**ActiveState repository is currently having problems distributing
recent Perl modules. You may wish to try [Strawberry Perl]({{< relref "Install-Windows-Strawberry" >}}) instead.**

To support ABC embedding, you must also install
[abcm2ps](http://abcplus.sourceforge.net/) and 
[ImageMagick](https://imagemagick.org).
