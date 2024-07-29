---
title: "Directives: define"
description: "Directives: define"
---

# Directives: define

{{< toc >}}

## Common usage

See also: [chord]({{< relref "Directives-chord" >}}).

### Defining chords for string instruments

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
  `0` (zero) denotes an open string. Use `-1`, `N`
  or `x` to denote a non-sounding string.
    
* `fingers` _pos_ _pos_ … _pos_ defines finger settings. This part may
  be omitted.
    
  For the `frets` and the `fingers` positions, there must be exactly
  as many positions as there are strings, which is 6 by default. For
  the `fingers` positions, values corresponding to open or damped
  strings are ignored.  
  Finger settings may be numeric (`0` .. `9`) or uppercase letters
  (`A` .. `Z`). Note that the values `-`, `x`, `X`, and `N` are used
  to designate a string without finger setting.

Example:

    {define: Bes base-fret 1 frets 1 1 3 3 3 1 fingers 1 1 2 3 4 1}
    {define: As  base-fret 4 frets 1 3 3 2 1 1 fingers 1 3 4 2 1 1}

The resultant chord diagrams are:

![]({{< asset "images/ex_define.png" >}})

### Defining chords for keyboard instruments

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

## Advanced usage

### Common use (revisited)

`    {define: A frets 0 0 2 2 2 0 base_fret 1}`

This is the most common use of the define directive. It defines a
chord with name `A` and its fret positions.
If `A` is a known chord its chord properties
(`root`, `qual`, `ext` and `bass`) are used, otherwise these
properties are derived from the given name.

You can include the chord in a song by using its name:

    I [A]woke up this morning

### Using a boilerplate

`    {define:` _A_ `copy` _B_  ... `}`

This defines chord _A_ and copies the diagram properties (`base_fret`,
`frets`, `fingers` and `keys`) from chord _B_, which must be a chord
from the config (or earlier definition).

You can (re)define these properties in the define directive.

### Adjust the appearance of the chord diagram

`    {define:` ... `diagram off` ... `}`

With `diagram off` ChordPro will not include a chord diagram for this
chord. 

Possible values for `diagram` are `on` and `off`, and the name of a
colour. In the latter case the diagram will be shown in the specified
colour.

### Change the chord name

`    {define:` _A_ ... `display` _C_ ... `}`

This sets the displayed chord name (in song body and diagram) to _C_.
To show the chord the chord properties from _C_ will be used.
Note that to include
the chord in your song you still have to use the given name _A_.

### Adjust the appearance of the chord name

`    {define:` ... `format` _fmt_ ... `}`

Defines the format string (see [below](#formatting)) for this chord.

### Using a boilerplate (revisited)

`    {define:` _A_ `copyall` _B_  ... `}`

With `copyall` instead of `copy` the `display` and `format` properties
of _B_, if present, are also copied.

### Examples

    {define: Am7}
	
Defines the `Am7` chord. Chord properties are derived from the given
name `Am7`:

| name   | root | qual | ext | bass |
|--------|------|------|-----|------|
| `Am7`  | `A`  | `m`  | `7` |      |
{ .table .table-striped .table-bordered .table-sm }

There are no diagram properties, so no chord diagram will be included
in the output. 

    {define: Am7 frets 0 0 2 0 1 0}
	
Defines the `Am7` chord. Chord properties are derived from the given
name `Am7`. Diagram property `frets` is provided and therefore
`base_fret` is implied.

| name  | root | qual | ext | bass | base | frets       |
|-------|------|------|-----|------|------|-------------|
| `Am7` | `A`  | `m`  | `7` |      | 1    | 0 0 2 0 1 0 |
{ .table .table-striped .table-bordered .table-sm }

There are usable diagram properties, so a chord diagram will be included
in the output. 

    {define: Am7 copy Am7 frets x 0 2 0 1 3}
	
Defines a variant of the `Am7` chord. Chord properties are derived
from the given name `Am7`. Diagram properties are copied from the
existing definition of chord `Am7` and the `frets` property is modified.

| name  | root | qual | ext | bass | base | frets       | fingers     |
|-------|------|------|-----|------|------|-------------|-------------|
| `Am7` | `A`  | `m`  | `7` |      | 1    | x 0 2 0 1 3 | x x 2 3 1 x |
|       |      |      |     |      |      |             |             |
{ .table .table-striped .table-bordered .table-sm }

Note that the `fingers` property is copied from the existing
definition of chord and therefore does not correspond to the
modified fret positions.

## Canonical representations

The chord properties have a companion set with `_canon` appended to
the property names. These are the _canonical_ representations of the
properties. In general the canonical version is the same as the
corresponding property. They will differ if alternative variants of
the properties are used.

For example, for the chord root:

| name  | root  | root_canon |
|-------|-------|------------|
| `Bes` | `Bes` | `Bb`       |
| `Bb`  | `Bb`  | `Bb`       |
| `B♭`  | `B♭`  | `Bb`       |
{ .table .table-striped .table-bordered .table-sm }


For the chord quality:

| name   | qual  | qual_canon |
|--------|-------|------------|
| `A+`   | `+`   | `+`        |
| `Aaug` | `aug` | `+`        |
{ .table .table-striped .table-bordered .table-sm }

Alternatives for root names are defined in the `notes` section of
the [config file]({{< relref "Chordpro-Configuration-Instrument/#root" >}}).  
Alternatives for chord qualities and extensions are currently
built-in.

ChordPro will use the chord properties to show a chord
name in the output. If config item `settings.chords-canonical` is set,
the canonical set of chord properties will be used instead.

It is important to realise that when transposing or transcoding the
resultant `root` and `root_canon` will both have the same, canonical value.

## Formatting

When it comes to formatting the chord for output purposes, ChordPro
uses a format string to control how the output must look like. The
format string is subject to [metadata substitution]({{< relref
"Chordpro-Configuration-Format-Strings" >}}). This does, however, not
use the usual set of metadata but uses the chord properties instead.

Since the chord properties are derived from the given name, 
`%{root}%{qual}%{ext}%{bass|/%{}}` will yield the given name again.

The default chord format string is the value of config
item `settings.chord-format`, and its default value is:

    %{root|%{}%{qual}%{ext}%{bass|/%{}}|%{name}}
	
If property `root` is not empty this indicates that the chord was
successfully parsed. The format will then use the chord properties
`root`, `qual`, `ext` and `bass`. Otherwise it uses the `name`
property. 

**Important 1:** Do not leave out the alternative to show the `name`
property otherwise unparsable chords, including `NC`, will not show in
the output.

**Important 2:** When using a format string in a define directive, you
**must** put a backslash `\` before each occurrence of `%{` to prevent
the substitution to happen 'too early', i.e. when the directive itself
is processed.
The default format string, when used in a define directive, looks
like:

    {define ... format "\%{root|\%{}\%{qual}\%{ext}\%{bass|/\%{}}|\%{name}}"}
