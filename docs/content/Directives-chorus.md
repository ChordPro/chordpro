---
title: "Directives: chorus"
description: "Directives: chorus"
---

# Directives: chorus

This directive indicates that the song chorus must be played here. 

Examples:

    {chorus}
    {chorus: label="Final"}

In the second form, if config setting `settings.choruslabels` is true (default)
the argument is used as a label for the chorus. 

If `settings.choruslabels` is false, the argument is used _instead_ of
the normal `Chorus` tag.

_For legacy purposes you can leave out the `label` property and just
include the label text_

    {chorus: Final}

See also: [start_of_chorus]({{< relref "Directives-env_chorus" >}}),
	[Chorus style]({{< relref "ChordPro-Configuration-PDF#chorus-style" >}}).
