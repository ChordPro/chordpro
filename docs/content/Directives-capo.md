# Directives: capo

This directive specifies the [capo](https://en.wikipedia.org/wiki/Capo) setting for the song. 

Examples:

    {capo: 2}
    {meta: capo 2}

Note that if a capo setting is in effect, the key of the song does not change. This is because guitar players consider the key relative to the chord shapes they play. The actual key as perceived by the listener (sounding key, concert key) would be modified according to the capo settings.

For example:

    {key: C}
    {capo: 2}

Now the key for the player is still `C`, but the key for fellow musicians and listeners is `D`.

See also: [[key|Directives key]] and [[meta|Directives meta]].
