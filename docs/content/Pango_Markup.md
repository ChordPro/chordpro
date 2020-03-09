# Pango style markup

_This information is derived from the official [Pango documentation](https://developer.gnome.org/pygtk/stable/pango-markup-language.html)._

The Pango markup language is a very simple SGML-like language that
allows you specify attributes with the text they are applied to by
using a small set of markup tags. A simple example of a string using
markup is:

    <span foreground="blue" size="100">Blue text</span> is <i>cool</i>!

The most general markup tag is `<span>`. The `<span>` tag has the
following attributes:

<dl>
<dt>font_desc</dt>
<dd>A font description string, such as "Sans Italic 12"; note that any
other span attributes will override this description. So if you have
`"Sans Italic"` and also a `style="normal"` attribute, you will get Sans
normal, not italic.</dd>

<dt>font_family</dt>
<dd>A font family name such as `normal`, `sans`, `serif` or
`monospace`.</dd>

<dt>face</dt>
<dd>A synonym for `font_family`</dd>

<dt>size</dt>
<dd>The font size in thousandths of a point, or one of the absolute
sizes `xx-small`, `x-small`, `small`, `medium`, `large`, `x-large`,
`xx-large`, or one of the relative sizes `smaller` or `larger`.</dd>

<dt>style</dt>
<dd>The slant style - one of `normal`, `oblique`, or `italic`</dd>

<dt>weight</dt>
<dd>The font weight - one of `ultralight`, `light`, `normal`, `bold`,
`ultrabold`, `heavy`, or a numeric weight.__
Note: Only `normal` and `bold` are supported.</dd>

<dt>variant</dt>
<dd>The font variant - either `normal` or `smallcaps`.  
Note: Not (yet) supported.
</dd>

<dt>stretch</dt>
<dd>The font width - one of `ultracondensed`, `extracondensed`,
`condensed`, `semicondensed`, `normal`, `semiexpanded`, `expanded`,
`extraexpanded`, `ultraexpanded`.  
Note: Not (yet) supported.
</dd>

<dt>foreground</dt>
<dd>An RGB color specification such as `#00FF00` or a color name such
as `red`.</dd>

<dt>background</dt>
<dd>An RGB color specification such as `#00FF00` or a color name such
as `red`.  
Note: Not (yet) supported.
</dd>

<dt>underline</dt>
<dd>The underline style - one of `single`, `double`, `low`, or
`none`.</dd>

<dt>rise</dt>
<dd>The vertical displacement from the baseline, in ten thousandths of
an em. Can be negative for subscript, positive for superscript.</dd>

<dt>strikethrough</dt>
<dd>`true` or `false` whether to strike through the text.  
Note: Not (yet) supported.
</dd>

<dt>fallback</dt>
<dd>If True enable fallback to other fonts of characters are missing
from the current font. If disabled, then characters will only be used
from the closest matching font on the system. No fallback will be done
to other fonts on the system that might contain the characters in the
text. Fallback is enabled by default. Most applications should not
disable fallback.  
Note: Not (yet) supported.
</dd>

<dt>lang</dt>
<dd>A language code, indicating the text language.  
Note: Not (yet) supported.
</dd>

</dl>

There are a number of convenience tags that encapsulate specific span
options:

<dl>

<dt>b</dt>
<dd>Make the text bold.</dd>

<dt>big</dt>
<dd>Makes font relatively larger, equivalent to `<span size="larger">`.</dd>

<dt>i</dt>
<dd>Make the text italic.</dd>

<dt>s</dt>
<dd>Strikethrough the text.  
Note: Not (yet) supported.
</dd>

<dt>sub</dt>
<dd>Subscript the text.</dd>

<dt>sup</dt>
<dd>Superscript the text.</dd>

<dt>small</dt>
<dd>Makes font relatively smaller, equivalent to `<span size="smaller">`.</dd>

<dt>tt</dt>
<dd>Use a monospace font.</dd>

<dt>u</dt>
<dd>Underline the text.  
Note: Not (yet) supported.
</dd>

</dl>
