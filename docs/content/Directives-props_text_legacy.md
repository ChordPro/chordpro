---
title: "Directives: textfont, textsize, textcolour"
description: "Directives: textfont, textsize, textcolour"
---

# Directives: textfont, textsize, textcolour

Note: If the intention is to change the appearance for the whole song, or collection of songs, it is much better to use [configuration files]({{< relref "ChordPro-Configuration" >}}) instead.

    {textfont: Times-Roman}
    {textsize: 12}
    {textcolour: blue}

These directives change the font, size and colour of the song lyrics that follow.

The font must be a [known font name]({{< relref "ChordPro-Fonts" >}}), or the name of a file containing a TrueType or OpenType font.

The size must be a valid number like `12` or `10.5`, or a percentage like `120%`. If a percentage is given, it is taken relative to the current value for the size.

The colour must be a [known colour]({{< relref "ChordPro-Colours" >}}), or a hexadecimal colour code like `#4491ff`.

    {textfont}
    {textsize}
    {textcolour}

Change the font, size and colour of the song lyrics that follow back to the previous (or default) value.

Example:

    I [D]looked over Jordan, and [G]what did I [D]see,
    {textcolour: red}
    {textsize: 150%}
    Comin’ for to carry me [A7]home.
    {textcolour}
    {textsize}
    A [D]band of angels [G]comin’ after [D]me,

Assuming default settings, all lyrics lines will be printed in black except the second line that will be red.

![]({{< asset "images/ex_textcolour.png" >}})
