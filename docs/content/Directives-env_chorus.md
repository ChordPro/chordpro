---
title: "Directives: start_of_chorus"
description: "Directives: start_of_chorus"
---

# Directives: start_of_chorus

Abbreviation: `soc`.

This directive indicates that the lines that follow form the song's chorus. These lines are normal song lines, but will be shown in an outstanding manner.

This directive may include an optional label, to identify the chorus.
For example:,

    {start_of_chorus: Chorus 2}

The ChordPro reference implementation prints the label in the left
margin, see [labels]({{< relref "ChordPro-Configuration-PDF#labels" >}}).

# Directives: end_of_chorus

Abbreviation: `eoc`.

This directive indicates the end of the chorus.

# Directives: chorus

This directive indicates that the song chorus must be played here. 

Examples:

    {chorus}
    {chorus: Final}

In the second form, the argument is used as a label for the chorus. 

If multiple choruses are defined in a song, `{chorus}` applies to the
last definition that precedes this directive.

See also: [labels]({{< relref "ChordPro-Configuration-PDF#labels" >}}),
	[Chorus style]({{< relref "ChordPro-Configuration-PDF#chorus-style" >}}).
