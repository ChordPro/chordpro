---
title: "Directives: diagrams"
description: "Directives: diagrams"
---

# Directives: diagrams

`{diagrams}`  
`{diagrams: off}`  
`{diagrams: ` *ctl* `}`

Enables printing of the list of chord diagrams used in the current song.

The `diagrams` directive can take a single argument, either `on`
(default) or `off`, or the position where the diagrams must be placed:
`bottom` (default), `top`, `right` and `below`.

For persistent use this can better be set in the [configuration
files]({{< relref "ChordPro-Configuration" >}}).

Diagrams printing is enabled by default, and diagrams are printed on
the bottom of the first page. The `diagrams` directive can be used to
modify printing chord diagrams for the current song when
printing the diagrams has been disabled globally, or to change the
position where the diagrams must be placed.

See also the [chord]({{< relref "Directives-chord" >}}) directive.

