---
title: "Strawberry Perl on Microsoft Windows"
description: "Strawberry Perl on Microsoft Windows"
---

# Strawberry Perl on Microsoft Windows

_This information may be sub-optimal and/or incomplete. Please help improving it._

Download Strawberry Perl from <http://strawberryperl.com/releases.html>.
Install according to the directions on the site.

Open a command prompt window and type:

`cpan install App::Music::ChordPro::Wx`

This will download and install the ChordPro program `wxchordpro` and
its dependencies. It may take a while. [It may fail](https://rt.cpan.org/Public/Bug/Display.html?id=129768).
Upon completion, it can be
executed from the command prompt. Alternatively, you can add a
shortcut icon to the desktop.

You may now proceed to [Getting Started]({{< relref "ChordPro-Getting-Started" >}}).
