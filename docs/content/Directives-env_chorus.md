# Directives: start_of_chorus

Abbreviation: `soc`.

This directive indicates that the lines that follow form the song's chorus. These lines are normal song lines, but will be shown in an outstanding manner.

This directive may include an optional label, to identify the chorus.
For example:,

    {start_of_chorus: Chorus 2}

The label may be printed before the chorus, or in the left margin.

See also [[labels|ChordPro Configuration PDF#labels]].

# Directives: end_of_chorus

Abbreviation: `eoc`.

This directive indicates the end of the chorus.

# Directives: chorus

This directive indicates that the song chorus must be played here. 

Examples:

    {chorus}
    {chorus: Final}

In the second form, the argument is used as a label for the chorus. 

See also: [[labels|ChordPro Configuration PDF#labels]],
	[[Chorus style|ChordPro Configuration PDF#chorus-style]].
