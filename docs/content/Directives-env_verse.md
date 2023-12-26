---
title: "Directives: start_of_verse"
description: "Directives: start_of_verse"
---

# Directives: start_of_verse

Abbreviation: `sov`.

Specifies that the following lines form a verse of the song.

Lines that are outside any `start_of_…`/`end_of_…` part will also be
interpreted as song lines in a verse, but it may be advantageous to
explicitly specify it.

This directive may include an optional label to identify the section.

    {start_of_verse: Verse 1}

To be future proof it is advised to use _key_`=`_value_ syntax:

    {start_of_verse: label="Verse 1"}

The ChordPro reference implementation prints the label in the left
margin, see [labels]({{< relref "ChordPro-Configuration-PDF#labels" >}}).

# Directives: end_of_verse

Abbreviation: `eov`.

Specifies the end of the verse.

