# Directives: start_of_verse

Specifies that the following lines form a verse of the song.

Lines that are outside any `start_of_…`/`end_of_…` part will also be interpreted as song lines in a verse, but it may be advantageous to explicitly specify it.

This directive may include an optional label, to be printed in the
left margin. For example:,

    {start_of_verse: Verse 1}

See also [[labels|ChordPro Configuration PDF#labels]].

# Directives: end_of_verse

Specifies the end of the verse.

