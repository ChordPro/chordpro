---
title: >
  "Unknown chord" for valid chords
description: >
  "Unknown chord" for valid chords
---

# "Unknown chord" for valid chords

By default ChordPro uses a built-in set of chord diagrams.
These include all major chords, minor, seventh and most other common chords.
Not included are chords like B5, Badd9, and slash chords.
These are uncommon, and often opinions on how to finger these chords vary.

If you want to use chords that are not included by default,
you need to define them first, either in your song file, e.g.:

````
{define: B13 frets x 2 1 2 2 4 fingers 0 2 1 3 3 4}
{define: C/B frets x 2 2 0 1 0 fingers 0 2 3 0 1 0}
````

or in a config file.

See also [define directive]({{< relref "Directives-define" >}}).

