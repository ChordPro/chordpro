---
title: "Pango markup language"
description: "Pango markup language"
---

# Pango markup language

_This information is derived from the official [Pango documentation](https://developer.gnome.org/pygtk/stable/pango-markup-language.html)._

The Pango markup language is a very simple SGML-like language that
allows you specify attributes with the text they are applied to by
using a small set of markup tags. A simple example of a string using
markup is:

    <span foreground="blue" size="100">Blue text</span> is <i>cool</i>!

The ChordPro reference implementation provides almost complete support
for the Pango markup language.

The most general markup tag is `<span>`. The `<span>` tag has the
following attributes:

* `font_desc`  
A font description string, such as "Sans Italic 12"; note that any
other span attributes will override this description. So if you have
`"Sans Italic"` and also a `style="normal"` attribute, you will get Sans
normal, not italic.

* `font_family`  
A font family name such as `normal`, `sans`, `serif` or
`monospace`.

* `face`  
A synonym for `font_family`

* `size`  
The font size in thousandths of a point, or one of the absolute
sizes `xx-small`, `x-small`, `small`, `medium`, `large`, `x-large`,
`xx-large`, or one of the relative sizes `smaller` or `larger`.

* `style`  
The slant style - one of `normal`, `oblique`, or `italic`

* `weight`  
The font weight - one of `ultralight`, `light`, `normal`, `bold`,
`ultrabold`, `heavy`, or a numeric weight.__
Note: Only `normal` and `bold` are supported.

* `variant`  
The font variant - either `normal` or `smallcaps`.  
Note: Not (yet) supported.


* `stretch`  
The font width - one of `ultracondensed`, `extracondensed`,
`condensed`, `semicondensed`, `normal`, `semiexpanded`, `expanded`,
`extraexpanded`, `ultraexpanded`.  
Note: Not (yet) supported.


* `foreground`  
An RGB color specification such as `#00FF00` or a color name such
as `red`.

* `background`  
An RGB color specification such as `#00FF00` or a color name such
as `red`.  
Note: Not (yet) supported.


* `underline`  
The underline style - one of `single`, `double`, `low`, or
`none`.

* `rise`  
The vertical displacement from the baseline, in ten thousandths of
an em. Can be negative for subscript, positive for superscript.

* `strikethrough`  
`true` or `false` whether to strike through the text.  
Note: Not (yet) supported.


* `fallback`  
If True enable fallback to other fonts of characters are missing
from the current font. If disabled, then characters will only be used
from the closest matching font on the system. No fallback will be done
to other fonts on the system that might contain the characters in the
text. Fallback is enabled by default. Most applications should not
disable fallback.  
Note: Not (yet) supported.


* `lang`  
A language code, indicating the text language.  
Note: Not (yet) supported.


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
Note: Not (yet) supported.


* `sub`  
Subscript the text.

* `sup`  
Superscript the text.

* `small`  
Makes font relatively smaller, equivalent to `<span size="smaller">`.

* `tt`  
Use a monospace font.

* `u`  
Underline the text.  
Note: Not (yet) supported.
