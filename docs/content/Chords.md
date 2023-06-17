---
title: "Chords"
description: "Chords"
---

# Defining Chords

## Common use

`    {define: A frets 0 0 2 2 2 0 base_fret 1}`

This is the most common use of the define directive. It defines a
chord with name `A` and its fret positions. The chord properties
(`root`, `qual`, `ext` and `bass`) are derived from the given name.

You can include the chord in a song by using its name:

    I [A]woke up this morning

## Using a boilerplate

`    {define:` _A_ `copy` _B_  ... `}`

This defines chord _A_ and copies the diagram properties (`base_fret`,
`frets`, `fingers` and `keys`) from chord _B_, which must be a chord
from the config (or earlier definition).

You can (re)define these properties in the define directive.

## Adjust the appearance of the chord diagram

`    {define:` ... `diagram off` ... `}`

With `diagram off` ChordPro will not include a chord diagram for this
chord. 

Possible values for `diagram` are `on` and `off`, and the name of a
colour. In the latter case the diagram will be shown in the specified
colour.

## Change the chord name

`    {define:` _A_ ... `display` _C_ ... `}`

This sets the displayed chord name (in song body and diagram) to _C_,
and also derives the chord properties from _C_. Note that to include
the chord in your song you still have to use the given name _A_.

## Adjust the appearance of the chord name

`    {define:` ... `format` _fmt_ ... `}`

Defines the format string (see [below](#formatting)) for this chord.

## Using a boilerplate (revisited)

`    {define:` _A_ `copyall` _B_  ... `}`

With `copyall` instead of `copy` the `display` and `format` properties
of _B_, if present, are also copied.

## Examples

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

# Canonical representations

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

# Formatting

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

**Important:** When using a format string in a define directive, you
**must** put a backslash `\` before each occurrence of `%{` to prevent
the substitution to happen 'too early', i.e. when the directive itself
is processed.

# Document Revision

20230617.2
