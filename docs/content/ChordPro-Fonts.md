# ChordPro Implementation: Fonts

ChordPro uses _fonts_ for typesetting chords, lyrics, titles and so on.

There are several ways to specify fonts, depending on the software
libraries that are available to ChordPro to use.

## Using a font filename

A font filename must be either and absolute filename, or a relative
filename which is interpreted relative to the _font path_, which
consists of [[configuration setting|ChordPro Configuration]]
`fontdir`, the `fonts` resource dir, and the contents of environment
variable `FONTDIR`. In any case, the filename should point to a valid
TrueType (`.ttf`) or OpenType (`.otf`) font.

## Using a font specification

A font specification is a flexible and system independent way to
select a font. It is a string containing four identifying items: the
font *family*, the *style*, the *weight* and the *size*. A font family
**must** be provided, the other parts are optional.

For example, to select the bold version of Arial at 14 point size, the
font specification to be used is `"arial bold 14"`. The system will
then provide a font file for this font, e.g. `Arial-Bold.ttf` or a
suitable replacement if this font could not be found.

Generic family names (*aliases*) can used instead of existing family
names. So you can use `"serif"` for a serif font, and leave it to the
system to find an appropriate font for it. Other frequently used
aliases are `"sans"` and `"mono"`.

## Using a built-in font

The ChordPro Reference Implementation supports the following built-in
font names:

* Courier, Courier-Bold, Courier-BoldOblique, Courier-Oblique
* Georgia, Georgia-Bold, Georgia-BoldItalic, Georgia-Italic
* Helvetica, Helvetica-Bold, Helvetica-BoldOblique, Helvetica-Oblique
* Verdana, Verdana-Bold, Verdana-BoldItalic, Verdana-Italic
* Times-Roman, Times-Bold, Times-BoldItalic, Times-Italic 
* Symbol, Webdings, Wingdings, ZapfDingbats

**Note** that using built-in font names has some disadvantages. The
fonts have only a limited number of characters (glyphs) and may not be
suitable for anything but English and Western European languages. The
quality of the output is less, since the built-in fonts do not support
kerning. Since real versions of these fonts are [easily
available](http://mscorefonts2.sourceforge.net/), if not already
installed, it is **strongly advised** to not use built-in fonts unless
you can deal with the limitations.

If you have quality PostScript Type1 fonts (pfa, pfb, with afm and/or
pfm files) they are easily converted to TrueType or OpenType using a
tool like [FontForge](https://fontforge.github.io/).
