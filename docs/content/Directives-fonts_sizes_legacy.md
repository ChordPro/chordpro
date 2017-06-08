# textfont, textsize, textcolour

Note: If the intention is to change the appearance for the whole song, or collection of songs, it is much better to use [[configuration files|ChordPro Configuration]] instead.

    {textfont: Times-Roman}
    {textsize: 12}
    {textcolour: blue}

These directives change the font, size and colour of the song lyrics that follow.

The font must be a [[known font name|ChordPro Fonts]], or the name of a file containing a TrueType or OpenType font.

The size must be a valid number, like `12` and `10.5`.

The colour must be a [[known colour|ChordPro Colours]], or a hexadecimal colour code like `#4491ff`.

    {textfont}
    {textsize}
    {textcolour}

Change the font, size and colour of the song lyrics that follow back to the previous (or default) value.

Example:

    I [D]looked over Jordan, and [G]what did I [D]see,
    {textcolour: red}
    Comin’ for to carry me [A7]home.
    {textcolour}
    A [D]band of angels [G]comin’ after [D]me,

Assuming default settings, all lyrics lines will be printed in black except the second line that will be red.

![](images/ex_textcolour.png)

# chordfont, chordsize, chordcolour

These directives change the font, size and colour of the song chords that follow.

For valid values, see the description of `textfont` and friends.

Example:

    I [D]looked over Jordan, and [G]what did I [D]see,
    {chordcolour: green}
    Comin’ for to carry me [A7]home.
    {chordcolour}
    A [D]band of angels [G]comin’ after [D]me,

The chords of the second song line will be printed in green.

![](images/ex_chordcolour.png)


