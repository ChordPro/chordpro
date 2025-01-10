---
title: "Encodings, or why do I see `PU2` in my source?"
description: "Encodings, or why do I see `PU2` in my source?"
---

# Encodings, or why do I see `PU2` in my source

![]({{< asset "images/faq_encoding.png" >}})

Short answer: Your song file is in Windows CP1252 (ANSI) encoding
which is not understood by ChordPro.

### Longer answer

ISO 8859-1 is the ISO standard Latin-1 character set and encoding
format. CP1252 is what Microsoft defined as a superset of ISO 8859-1.
There are approximately 27 extra characters that are not included in
the standard ISO 8859-1.

ChordPro takes its input files in UTF-8 encoding, and falls back to
ISO-8859.1 (Latin-1) if the input doesn't appear to be valid UTF-8.
Your song file contains octal characters 0222 that are not part of
Latin-1. They represent the right single quotation mark in the CP1252
encoding.

Unicode calls this a 'Private Use' character, meaning that you can use
it for any purpose but do not expect it to be understood by anyone
else. Octal 0222 is the second in the range of Private Use characters,
hence the display `PU2`.

The best solution is to convert the file to UTF-8. If you open the
file in Notepad, you'll see bottom right `ANSI`. When you do `File` > `Save
As...` you can specify the desired encoding next to the `Save` button.

How come the generated output from ChordPro looks okay nevertheless?
Let's say that the ChordPro PDF formatter is slightly more forgiving
when it comes to Latin-1 versus CP1252 encodings.
