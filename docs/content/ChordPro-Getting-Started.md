---
title: "Getting started with ChordPro"
description: "Getting started with ChordPro"
---

# Getting started with ChordPro

For a good understanding it is important to know that **ChordPro**
(the program) is basically a file transformation program. It reads a
file containing lyrics and chords according to the *ChordPro File
Standard* and produces a neatly formatted PDF document that you can
view and print.

Actually, there are *two* **ChordPro** programs, a graphical
application and a command line program.

## The graphical application

The graphical (GUI) application is an easy to use application to learn
how to use the *ChordPro File Standard* and create beautiful PDF's.
However, not just for single songs, but it can also create great
[songbooks]({{< relref "ChordPro-GUI-Songbook" >}}) from any 
collection of *ChordPro* files.

[![ChordPro GUI]({{< asset "images/chordpro-gui-main.png" >}})]({{< relref "ChordPro-Getting-Started-GUI" >}})

[Read more]({{< relref "ChordPro-Getting-Started-GUI" >}}) about using
the GUI.

## The Command Line program

The command line (CLI) application can do everything the GUI can, and
adds some additional features for finetuning the output and, most
important, scripted (batch) processing. If you are familiar with
(power)shell scripts and Makefiles you will love it. If not — no
worry.

[![ChordPro CLI]({{< asset "images/chordpro-cli-main.png" >}})]({{< relref "ChordPro-Getting-Started-CLI" >}})

[Read more]({{< relref "ChordPro-Getting-Started-CLI" >}}) about using
the command line program.

## Chords over Lyrics

Before ChordPro it was common to write lead sheets with chords on
separate lines above the lyrics. This is often referred to as
**crd** format.
ChordPro can [convert this style]({{< relref "Chords-over-Lyrics" >}})
into its native format.
