---
title: "Directives: title"
description: "Directives: title"
---

# Directives: title

Abbreviation: `t`.

This directive defines the title of the song.

Examples:

    {title: Swing Low Sweet Chariot}
    {meta: title Swing Low Sweet Chariot}
    {t: Swing Low Sweet Chariot}

Although `{meta: title ...}` is semantically equivalent to 
`{title: ...}`, it is good practice to always use the latter. 
Many external tools will only recognize the `{title: ...}` directive.

See also [sorttitle]({{< relref "Directives-sorttitle" >}}),
[Table of Contents]({{< relref "Table_Of_Contents" >}}),
and [meta]({{< relref "Directives-meta" >}}).
