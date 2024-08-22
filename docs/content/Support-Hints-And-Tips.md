---
title: "Hints and Tips"
description: "Hints and Tips"
---

# Hints and Tips

## Unicode escape characters in input

ChordPro allows using Unicode escape sequence in the form `\u`_XXXX_.
In case you need more (or less) hexadecimal digits, 
you can use the following preprocessor directive
to replace `\u{`_XXXX_`}` (with an arbitrary number of hex digits)
by the corresponding unicode character.

````
parser {
  preprocess {
    all : [
      { pattern : "\\\\u\\{([0-9a-f]+)\\}"
        replace : "chr(hex(\"0x$1\"))"
        flags   : "gie"
      }
    ]
} }
````


## Bold chorus

A common style nowadays puts the chorus in bold.
You need two modifications to achieve this.

First off, set some config keys:

````
pdf.chorus {
  indent: 0
  bar.width: 0
  recall.quote: true
  recall.choruslike: true
}
````

Secondly, wrap the chorus in `textfont` directives:

````
{soc}
{textfont serif bold}
[E]Dreaming, [A]Dreaming, [B]Just go on
[E]Dreaming, [A]Dreaming, [B]Just go on
{textfont}
{eoc}
````

## Chords too close to the lyrics

The distance between the chords and the lyrics is determined by the
properties of the font used for the chords. Some fonts use the size of
the font as distance, which results in chords being placed too close,
and other fonts use the distance to the next line, resulting in chords
being higher above the lyrics.

You can adjust the chord spacing in the PDF config:

````
pdf {
  spacing {
    chords : 1.2
	...
````

The value specified is a factor, it is multiplied by the font size to
obtain the distance between baseline of the chords and the baseline of
the lyrics.

## Conditional chords

You can use the following preprocessor directive
to suffix chords with an instrument name
and thus generate versions of different difficulty or specificity.
````
// Settings for the parser/preprocessor.
// Replaces all instrument-specific chords with conditional directives
parser {
  preprocess {
    songline : [
      { pattern : "\\[([^-\\]]+)-(\\w+)\\]"
        replace : "%{instrument=$2|[$1]}"
      }
    ]
  }
}
````

An example of how to use it:
````
{comment This is the %{instrument} variant}
{begin_of_verse}
[A]He[A7-piano]llo, [Bm]World![C-keyboard]
[A]Swe[A7-piano]et [Bm]Home![C-keyboard]
{end_of_verse}
````

## MacOS _Quick Action_ to create PDFs from within the Finder

_Contributed by Daniel Saunders_

1. Create a new Quick Action in Automator.
2. Make the top line read: 'Workflow receives current Files or Folders
   in Finder
3. The only 'action' is to Run Shell Script.
4. Select /bin/bash as the Scripting language.
5. Then enter the following script

````
export PATH=/usr/local/bin:$PATH
for f in "$@"
do
	name=$(echo "$f" | cut -f 1 -d '.')
	chordpro "$f" -o="$name".pdf
done
````

![]({{< asset "images/macos-quick-action.png" >}})

The result is a Quick Action in the 'right click' menu. When you run
the action on a ChordPro text file, the script will run ChordPro and
output a PDF in the same directory, with the same name, but with .pdf
as the extension.
