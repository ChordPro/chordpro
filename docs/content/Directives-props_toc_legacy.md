---
toc: "Directives: tocfont, tocsize, toccolour"
description: "Directives: tocfont, tocsize, toccolour"
---

# Directives: tocfont, tocsize, toccolour

Note: If the intention is to change the appearance for the whole song, or collection of songs, it is much better to use [configuration files]({{< relref "ChordPro-Configuration" >}}) instead.

These directives change the font, size and colour of the table of
contents.

The font must be a [known font name]({{< relref "ChordPro-Fonts" >}}), or the name of a file containing a TrueType or OpenType font.

The size must be a valid number like `12` or `10.5`, or a percentage like `120%`. If a percentage is given, it is taken relative to the current value for the size.

The colour must be a [known colour]({{< relref "ChordPro-Colours" >}}), or a hexadecimal colour code like `#4491ff`.

