---
title: "Easy installation on Microsoft Windows"
description: "Easy installation on Microsoft Windows"
---

# Easy installation on Microsoft Windows

Download ChordPro-Installer-xxxx-msw-x64.exe from
[GitHub](https://github.com/ChordPro/chordpro/releases/latest) and
execute it. You can choose to install the GUI version of ChordPro
and/or the command line program. Installing the GUI will also install
the command line program.

If you intend to use only the GUI, as most Window user will, proceed
to [Getting Started]({{< relref "ChordPro-Getting-Started" >}}).

The command line program needs to be run from a _command window_. So
you must first open a command window (PowerShell) from the Windows
system menu.

In the command window you must type the **full** path name of the
ChordPro program at the command prompt.
Assuming a default install location:

````
C:\Program Files\ChordPro.ORG\ChordPro\chordpro.exe
````

If you want to run ChordPro often it is be convenient to add the
install location to the system search path for programs so you don't
have to type the full path over and over again.

To _temporarily_ add the default install location using the PowerShell:
````
$ENV:PATH="$ENV:PATH;C:\Program Files\ChordPro.ORG\ChordPro"
````

To _permanently_ add the default install location using the PowerShell:
````
$reg = 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment'
$oldpath = (Get-ItemProperty -Path $reg -Name PATH).path
$newpath = “$oldpath;C:\Program Files\ChordPro.ORG\ChordPro”
Set-ItemProperty -Path $reg -Name PATH -Value $newpath
````

You can now run ChordPro by simply typing
````
chordpro
````
at the command prompt.

You may now proceed to [Getting Started]({{< relref "ChordPro-Getting-Started" >}}).
