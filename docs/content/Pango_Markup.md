---
title: "ChordPro markup language"
description: "ChordPro markup language"
---

# ChordPro markup language

The ChordPro markup language provides a means for text
formatting using a subset of the Pango markup language as developed by
the Gnome organisation.

The Pango markup language is a very simple SGML-like language that
allows you specify attributes with the text they are applied to by
using a small set of markup tags. A simple example of a string using
markup is:

    <span foreground="blue" size="100">Blue text</span> is <i>cool</i>!

ChordPro implements a variant of a subset of the Pango markup
language, more suitable for the needs of musicians.

## `<span>` tags

The most general markup tag is `<span>`, shown above. The `<span>` tag
takes attributes in the form `name="value"` or `name='value'`.

Unrecognized and invalid attributes are ignored.
The following attributes are recognized:

* `font_desc`  
A font description string, such as "Sans Italic 12"; note that any
other span attributes will override this description. So if you have
`"Sans Italic"` and also a `style="normal"` attribute, you will get Sans
normal, not italic.

  Portability note: Selecting fonts using description strings is
  inherently dependent on the ChordPro implementation and the system it
  runs on.
  Do not use this if you want to share songs with other ChordPro supporting tools.

* `font_family`  
A font family name such as `normal`, `sans`, `serif` or
`monospace`.

  Portability note: The family names listed above should be safe to
  use since they can be supported by all ChordPro implementations.

* `face`  
A synonym for `font_family`.

* `size`  
The font size in points, a percentage, or one of the 
sizes `xx-small`, `x-small`, `small`, `medium`, `large`, `x-large`,
`xx-large`, or one of the relative sizes `smaller` or `larger`.

  The symbolic sizes are all interpreted relative to the current font
  size. From `xx-large` to `xx-small` each step is approx. 80%.
  `smaller` is the same as `small`, `larger` is the same as `large`.
  
  Portability note: Actual font sizes depend on the ChordPro
  implementation. For portability only use percentages or symbolic
  sizes.

* `style`  
The slant style, one of `normal`, `oblique`, or `italic`.

* `weight`  
The font weight - one of `normal` or `bold`.

* `foreground`  
An RGB colour specification such as `#00FF00` or a colour name such
as `red`.

  Portability note: Colour names and codes depend on the ChordPro
  implementation. The following should be portable across all
  implementations: `#RRGGBB` where RR, GG and BB denote the red, green
  and blue components of the colour in hexadeximal notation, and the
  colour names `red`, `green`, `blue`, `yellow`, `magenta`, `cyan`,
  `white`, `grey`, and `black`.

* `background`  
An colour to use for the background. See `foreground` for details on colours.

* `underline`  
The underline style - one of `single`, `double`, or `none`.

* `underline_colour`  
The colour to be used for underlines.
See `foreground` for details on colours.

* `overline`  
The overline style - one of `single`, `double`, or `none`.

* `overline_colour`  
The colour to be used for overlines.
See `foreground` for details on colours.

* `rise`  
The vertical displacement from the baseline, in points or a
percentage.
Can be negative for subscript, positive for superscript.

  Portability note: Use percentages only.

* `strikethrough`  
`true` or `false` whether to strike through the text.

* `strikethrough_colour`  
The colour to be used for strikes.
See `foreground` for details on colours.

* `href`  
The URL for a hyperlink.  

## Convenience tags

There are a number of convenience tags that encapsulate specific span
options:

* `b`  
Make the text bold.

* `big`  
Makes font relatively larger, equivalent to `<span size="larger">`.

* `i`  
Make the text italic.

* `s`  
Strikethrough the text.

* `sub`  
Subscript the text.
Equivalent to `<span size="smaller" rise="-30%">`.

* `sup`  
Superscript the text.
Equivalent to `<span size="smaller" rise="30%">`.

* `small`  
Makes font relatively smaller, equivalent to `<span size="smaller">`.

* `tt`  
Use a monospace font.

* `u`  
Underline the text.

## Credits

Parts of this information is derived from the official [Pango documentation](https://docs.gtk.org/Pango/pango_markup.html#pango-markup).
