---
title: "Directives: textfont, textsize, textcolour"
description: "Directives: textfont, textsize, textcolour"
---

# Directives: textfont, textsize, textcolour

Note: If the intention is to change the appearance for the whole song,
or collection of songs, it is much better to use [configuration
files]({{< relref "ChordPro-Configuration" >}}) instead.

    {textfont: serif}
    {textsize: 12}
    {textcolour: blue}

These directives change the font, size and colour of the song lyrics
that follow.

The font must be a [known font family]({{< relref "ChordPro-Fonts" >}}),
or the name of a file containing a TrueType or OpenType font.

The size must be a valid number like `12` or `10.5`, or a percentage
like `120%`. If a percentage is given, it is taken relative to the
current value for the size.

The colour must be a [known colour]({{< relref "ChordPro-Colours"
>}}), or a hexadecimal colour code like `#4491ff`.

    {textfont}
    {textsize}
    {textcolour}

Change the font, size and colour of the song lyrics that follow back
to the previous (or default) value.

Example:

    I [D]looked over Jordan, and [G]what did I [D]see,
    {textcolour: red}
    {textsize: 150%}
    Comin’ for to carry me [A7]home.
    {textcolour}
    {textsize}
    A [D]band of angels [G]comin’ after [D]me,

Assuming default settings, all lyrics lines will be printed in black
except the second line that will be bigger and red.

![]({{< asset "images/ex_textcolour.png" >}})

## Relation with chorusfont, chorussize, and choruscolour

The chorus properties depend on the text settings. If you change e.g.
text colour with `{textcolour blue}` this will also affect the colour of the
chorus lyrics. To change a chorus property and a text property, first
change the text property, and then the chorus property.

This will make the chorus lyrics red, and all other lyrics blue:

    {textcolour blue}
    {choruscolour red}

But this will make all lyrics blue, including the chorus:

    {choruscolour red}
    {textcolour blue}
