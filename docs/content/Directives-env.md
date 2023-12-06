---
title: "Environment directives"
description: "Environment directives"
---

# Environment directives

Environments, also called _sections_, group series of input lines into
meaningful units. For example, one of the most used environments is
`chorus`, to indicate the chorus of a song.

Environments start with a `start_of` directive, e.g.
`{start_of_chorus}`, and end with a corresponding `end_of` directive,
e.g. `{end_of_chorus}`. As with every ChordPro directive, these
directives should be alone on a line.

You can choose arbitrary names for sections as long as the names only
consists of letters, digits and underscores. Environments `chorus`,
`tab`, and `grid` get a predefined special treatment.

Implementations are free to add special treatment to specific
environments, but unknown (unhandled) environments should always be
treated as part of the song lyrics.

All environment directives may include an optional [label]({{< relref
"ChordPro-Configuration-PDF#labels" >}}) to identify the section. For
example:,

    {start_of_verse: label="Verse 1"}

For backward compatibility, this also works:

    {start_of_verse: Verse 1}

The label text may contain `\n` sequences to produce multi--line
labels:

    {start_of_verse: label="Verse 1\nAll"}

For legacy reasons, the following environments have a short directive
to start and end them:

* [start_of_chorus]({{< relref "Directives-env_chorus" >}}) (short: soc)
* [end_of_chorus]({{< relref "Directives-env_chorus" >}}) (short: eoc)
* [start_of_verse]({{< relref "Directives-env_verse" >}}) (short: sov)
* [end_of_verse]({{< relref "Directives-env_verse" >}}) (short: eov)
* [start_of_bridge]({{< relref "Directives-env_bridge" >}}) (short: sob)
* [end_of_bridge]({{< relref "Directives-env_bridge" >}}) (short: eob)
* [start_of_tab]({{< relref "Directives-env_tab" >}}) (short: sot)
* [end_of_tab]({{< relref "Directives-env_tab" >}}) (short: eot)
* [start_of_grid]({{< relref "Directives-env_grid" >}}) (short: sog)
* [end_of_grid]({{< relref "Directives-env_grid" >}}) (short: eog)
