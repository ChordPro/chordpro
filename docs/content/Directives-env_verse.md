# Directives: start_of_verse

Abbreviation: `sov`.

Specifies that the following lines form a verse of the song.

Lines that are outside any `start_of_…`/`end_of_…` part will also be interpreted as song lines in a verse, but it may be advantageous to explicitly specify it.

This directive may include an optional label to identify the section.
For example:,

    {start_of_verse: Verse 1}

The label could be printed before the chorus, or in the left margin.

See also [[labels|ChordPro Configuration PDF#labels]].

# Directives: end_of_verse

Abbreviation: `eov`.

Specifies the end of the verse.

