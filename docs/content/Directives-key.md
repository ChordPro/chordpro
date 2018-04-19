# Directives: key

This directive specifies the key the song is written in. Multiple key specifications are possible, each specification is assumed to apply from where it was specified.

Examples:

    {key: C}
    {meta: key C}

Note that if a [[capo|Directives capo]] setting is in effect, the key does not change. This is because guitar players consider the key relative to the chord shapes they play. The actual key as perceived by the listener (sounding key, concert key) would be modified according to the capo settings.

For example:

    {key: C}
    {capo: 2}

Now the key for the player is still `C`, but the key for fellow musicians and listeners is `D`.

See also: [[capo|Directives capo]], [[meta|Directives meta]] and [[transpose|Directives transpose]].
