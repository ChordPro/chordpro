# Directives transpose

`{transpose:` _value_`}`

This directive indicates that the remainder of the song should be transposed the number of semitones according to the given _value_, which is a positive or negative number. When used at the beginning of a song, the whole song will be transposed. When used somewhere in the song it can be used to achieve modulation.

For example:

    [C]A song [D] line with [E]chords   [F]
    {transpose: 2}
    [C]A song [D] line with [E]chords   [F]

This will print:

    C      D         E       F 
    A song line with chords
    D      E         F#      G
    A song line with chords

As can be seen above, when transposing with a positive value sharp signs will be used if necessary. Transposing with a negative value will use flat signs:

    [C]A song [D] line with [E]chords   [F]
    {transpose: -10}
    [C]A song [D] line with [E]chords   [F]

This will print:

    C      D         E       F 
    A song line with chords
    D      E         Gb      G
    A song line with chords

A `{transpose}` directive without a value will cancel the current transposition, possibly restoring a preceding transposition.

## Transposition and the `key` metadata

Transposition will not affect the metadata item `key`, unless the `transpose` directive precedes the `key` directive.

If a song has a key, a metadata item `key_actual` is automatically added and contains the actual key including transpositions. If a transposition is in effect, there is also an item `key_from` that contains the actual key _before_ the transposition.
