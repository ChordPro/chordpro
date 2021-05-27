---
title: "Directives: define"
description: "Directives: define"
---

# Directives: define

See also: [chord]({{< relref "Directives-chord" >}}).

## Defining chords for string instruments

This directive defines a chord in terms of fret/string positions and,
optionally, finger settings.

`{define:` _name_ `base-fret` _offset_ `frets` _pos_ _pos_ … _pos_`}`  
`{define:` _name_ `base-fret` _offset_ `frets` _pos_ _pos_ … _pos_ `fingers` _pos_ _pos_ … _pos_`}`

A fret position is designated with a
number, e.g. 5th position, 7th position, etc, and the number is based
on what fret the first finger would naturally lie on depending on
where you are on the neck. ([see
e.g.](https://www.jazzguitar.be/blog/what-are-guitar-positions/))  
In practice, the term _fret_ is often used to indicate _position_, which is
unfortunate. 

![]({{< asset "images/fretpos.png" >}})

In the left diagram the first (topmost) finger is in position 1, it
presses the string against fret number 1. The finger positions are,
from low to high, x (muted), 3, 2, 3, 1, 0 (open). The corresponding
`define` directive is

    {define: C7 base-fret 1 frets x 3 2 3 1 0}

In the middle diagram, the first finger is in position 3, it presses
the string against fret 3. The finger positions are, from low to high,
x, 5, 4, 5, 3, x.

    {define: D7 base-fret 1 frets x 5 4 5 3 x}

The right diagram shows the same chord as the middle diagram, but it
has been shifted towards the top. The `3` left of the top row
indicates that the top row of the diagram is really the row at
position 3. This can be obtained by adjusting the value of
`base-fret` in the `define` directive:

    {define: D7 base-fret 3 frets x 3 2 3 1 x}

The `define` directive details:

`{define:` _name_ `base-fret` _offset_ `frets` _pos_ _pos_ … _pos_`}`  
`{define:` _name_ `base-fret` _offset_ `frets` _pos_ _pos_ … _pos_ `fingers` _pos_ _pos_ … _pos_`}`

* _name_ is the name to be used for this chord. If it is an already
  known chord the new definition will overwrite the previous one.

* `base-fret` _offset_ defines the offset for the chord, which is
  the position of the topmost finger. The offset must be 1 or higher.

  When printing chord diagrams, the top row of the diagram corresponds
  to the actual row at the indicated position, see the discussion above.

* `frets` _pos_ _pos_ … _pos_ defines the string positions.  
  Strings are enumerated from left (lowest) to right (highest), as they
  appear in the chord diagrams.  
  Fret positions are relative to the offset __minus one__, so with `base-fret 1`
  (the default), the topmost fret position is `1`. With `base-fret 3`,
  fret position `1` indicates the 3rd position.  
  `0` (zero) denotes an open string. Use `N`
  or `x` to denote a non-sounding string.
    
* `fingers` _pos_ _pos_ … _pos_ defines finger settings. This part may
  be omitted.
    
  For the `frets` and the `fingers` positions, there must be exactly
  as many positions as there are strings, which is 6 by default. For
  the `fingers` positions, values corresponding to open or damped
  strings are ignored.

Example:

    {define: Bes base-fret 1 frets 1 1 3 3 3 1 fingers 1 1 2 3 4 1}
    {define: As  base-fret 4 frets 1 3 3 2 1 1 fingers 1 3 4 2 1 1}

The resultant chord diagrams are:

![]({{< asset "images/ex_define.png" >}})

The asterisk after the chord names indiciates that the chords have
been defined in the song, possibly overriding built-in definitions.

## Defining chords for keyboard instruments

For keyboard chords, only the chord notes relative to the root note
must be specified:

`{define:` _name_ `keys` _note_ … _note_`}`

- _name_ is the name to be used for this chord. If it is an already
  known chord the new definition will overwrite the previous one.

- `keys` _note_ … _note_ defines the keys.  
  Key `0` denotes the root note, `7` is the fifth, `11` dominant
  seventh, and so on.

  Chords in the root position always start with note `0`. The first
  inversion starts with `4` (major) or `3` (minor) third. The second
  inversion starts with the fifth `7`.

Example:

    {define: D  keys 0 4 7}
    {define: D² keys 7 12 16}

The resultant chord diagrams are:

![]({{< asset "images/ex_define2.png" >}})

Note that keys that would exceed the diagram are silently wrapped.
