# Environment directives

Environments, also called _sections_, group series of input lines into
meaningful units. For example, one of the most used environments is
`chorus`, to indicate the chorus of a song.

Environments start with a `start_of` directive, e.g.
`{start_of_chorus}`, and end with a corresponding `end_of` directive,
e.g. `{end_of_chorus}`. As with every ChordPro directive, these
directives should be alone on a line.

You are free to choose names for sections as long as the names only
consists of letters, digits and underscores. All environments are
considered to be part of the song lyrics, except for `chorus`, `tab`,
and `grid`. These environments get a predefined special treatment.

All environment directives may include an optional label to identify
the section. For example:,

    {start_of_verse: Verse 1}

The ChordPro reference implementation prints the label in the left
margin, see [[labels|ChordPro Configuration PDF#labels]].

For legacy reasons, the following environments have a short directive
to start and end them:

* [[start_of_chorus|Directives env_chorus]] (short: soc)
* [[end_of_chorus|Directives env_chorus]] (short: eoc)
* [[chorus|Directives env_chorus]]
* [[start_of_verse|Directives env_verse]] (short: sov)
* [[end_of_verse|Directives env_verse]] (short: eov)
* [[start_of_bridge|Directives env_bridge]] (short: sob)
* [[end_of_bridge|Directives env_bridge]] (short: eob)
* [[start_of_tab|Directives env_tab]] (short: sot)
* [[end_of_tab|Directives env_tab]] (short: eot)
* [[start_of_grid|Directives env_grid]] (short: sog)
* [[end_of_grid|Directives env_grid]] (short: eog)
