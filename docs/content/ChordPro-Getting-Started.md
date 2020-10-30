---
title: "Getting started with ChordPro"
description: "Getting started with ChordPro"
---

# Getting started with ChordPro

For a good understanding it is important to know that ChordPro is
basically a file transformation program. It reads a file containing
lyrics and chords according to the ChordPro File Standard, and
produces a neatly formatted PDF document that you can view and print.

## Linux

When you start the `wxchordpro` program it will show a _File
Open_ dialog where you can designate an existing ChordPro file.

* If you have one, select it and its contents will be shown in a new window.
* If you don't have one, press `Cancel` and a (basically empty) window
 will be shown.  
 From the menu bar, choose `Help` > `Insert song example`. A small
 song will appear in the editor window.

## Windows

The `wxchordpro` app is capable of handling documents with filename
extensions `.cho` and `.crd`. If you have
such a document you can double-click it from the Explorer and ChordPro
will be started with the document opened. You can also drag a ChordPro
document to the `ChordPro` desktop icon.

When you start the `wxchordpro` program it will show a _File
Open_ dialog where you can designate an existing ChordPro file.

* If you have one, select it and its contents will be shown in a new window.
* If you don't have one, press `Cancel` and a (basically empty) window
 will be shown.  
 From the menu bar, choose `Help` > `Insert song example`. A small song will appear in the editor window.

## MacOS

The `ChordPro` app is capable of handling documents with filename
extensions `.cho`, `.chordpro`, `.chopro`, and `.crd`. If you have
such a document you can double-click it from the Finder and ChordPro
will be started with the document opened. You can also drag a ChordPro
document to the `ChordPro` app icon.

When you start the `ChordPro` app without document it will show a
(basically empty) song in its window.

* If you have existing ChordPro files, choose `File` from the menu
  bar, select `Open`, and navigate to a ChordPro document.
* If you don't have one, from the menu bar, choose `Help` > `Insert
  song example`. A small song will appear in the editor window.

## All

From the menu bar, choose `File` > `Preview`. If all goes well, a preview window will open showing the formatted PDF document. From the preview window you can print and save the PDF document.

Note that you need to have a PDF file viewer application installed, and the system must be configured to use this viewer to open files with `.pdf` extension.

# Legacy ASCII input format

Before ChordPro it was common to write lead sheets with chords on
seperate lines preceding the lyrics. This is often referred to as
**crd** format. For example

          D          G    D
    Swing low, sweet chariot,
                           A7
    Comin’ for to carry me home.

ChordPro tries to detect whether the input files are in this legacy
format and if so, internally converts the data to ChordPro (**cho**
format) before processing.

    Swing [D]low, sweet [G]chari[D]ot,
    Comin’ for to carry me [A7]home.

# Command Line operation

If you are familiar with working on the command line, the basic command to use is:

`chordpro mysong.cho`

This will process `mysong.cho` and produce the PDF document `mysong.pdf`.

`chordpro --help` will give you a list of options that you can pass to the `chordpro` command.

More information can be found in the [User Guide]({{< relref
"Using-ChordPro" >}}).
