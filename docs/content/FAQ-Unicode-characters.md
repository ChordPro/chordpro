# Why can't I see my russian (vietnamese, greek, ...) characters?

ChordPro supports UNICODE and can handle songs written in ASCII, ISO-8859.1 (Latin-1), and UTF-8. But when it comes to producing PDF output, the actual characters (glyphs) that can be shown are limited to the glyphs that are included in the font that is used. By default, ChordPro uses PDF core fonts and these contain only glyphs for Western languages.

To show other characters, you need to use fonts that have them. Fortunately, these fonts are already installed on your system. Just point ChordPro to the correct font files as documented [here](ChordPro-Configuration-PDF#fonts).

Note: Songs encoded in UTF-16 and UTF-32 can also be handled, provided the file starts with a [Byte Order Mark](https://en.wikipedia.org/wiki/Byte_order_mark). Editors that write files in these encodings should be configured to include the Byte Order Mark.
