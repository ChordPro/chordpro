---
title: "Easy installation on Microsoft Windows"
description: "Easy installation on Microsoft Windows"
---

# Easy installation on Microsoft Windows

Download ChordPro-installer-xxxx-msw-x64.exe from
[GitHub](https://github.com/ChordPro/chordpro/releases/latest) and
execute it. You can choose to install the GUI version of ChordPro
and/or the command line program.

For the command line program it may be convenient to add the install
location to the system path so you don't have to type the full path
name.

To temporarily add the default install location using the PowerShell:
````
$ENV:PATH="$ENV:PATH;C:\Program Files (x86)\ChordPro.ORG\ChordPro"
````

To permanently add the default install location using the PowerShell:
````
$reg = 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment'
$oldpath = (Get-ItemProperty -Path $reg -Name PATH).path
$newpath = “$oldpath;C:\Program Files (x86)\ChordPro.ORG\ChordPro”
Set-ItemProperty -Path $reg -Name PATH -Value $newpath
````

You may now proceed to [Getting Started]({{< relref "ChordPro-Getting-Started" >}}).
