---
title: "Directives: start_of_grid"
description: "Directives: start_of_grid"
---

# Directives: start_of_grid

Abbreviation: `sog`.

This directive indicates that the lines that follow define a chord
grid in the style of [Jazz
Grilles](https://fr.wikipedia.org/wiki/Grille_harmonique).

Note: Grids must not be confused with _chord diagrams_ that,
unfortunately, in some parts of the documentation and implementation
also are referred to as ‘chord grids’.

In a grid only chords are used, no lyrics, and the chords are arranged
in a rectangular pattern for a quick view on the structure of the
song. Symbols for bar lines and repeats can also be included in a
grid. The chords are subject to transposition.

For example, to create a grid for ‘The House of the Rising Sun’:

    {start_of_grid}
    || Am . . . | C . . . | D  . . . | F  . . . |
    |  Am . . . | C . . . | E  . . . | E  . . . |
    |  Am . . . | C . . . | D  . . . | F  . . . |
    |  Am . . . | E . . . | Am . . . | Am . . . ||
    {end_of_grid}

The result could look like:

![]({{< asset "images/ex_grid1.png" >}})

The grid consists of a number of cells that can contain chords. The
desired number of cells per line can be specified as a `shape`
property to the `start_of_grid` directive:

`{start_of_grid shape="`_cells_`"}`  
`{start_of_grid shape="`_measures_`x`_beats_`"}`

There is no semantic difference between the two forms, just pick the
one that is most convenient.

_For legacy purposes you can leave out the `shape` property and just
include the shape, optionally followed by label text:_

`{start_of_grid:` _cells_`}`  
`{start_of_grid:` _measures_`x`_beats_`}`

_However, in this form you cannot use other properties._

It is possible to specify room for margin notes, both left side and
right side, by adding the desired number of cells in the shape:

_left_`+`_cells_`+`_right_  
_left_`+`_measures_`x`_beats_`+`_right_

Both margins are optional and may be omitted together with their `+` symbols.

If no shape is supplied to `start_of_grid` then the values from the
preceding grid, if any, are used. If the first `start_of_grid` does
not have a shape, a default value `1+4x4+1` is used.

The grid input lines consist of space-separated tokens, which are
either valid chords or special symbols. Spaces are not significant but
can be used e.g. to align chords in the input lines.

Chords are put into the cells. If a cell does not need to contain a
chord, the placeholder `.` (period) can be used to designate an empty
cell.

Alternatively, a slash `/` can be used to designate that a
chord must be played here.
Multiple chords can be put in a single cell by separating the chord
names with a `~` (tilde).

Between the cells bar lines can be placed. In the above example, each line contains 16 cells and the bar lines divide the cells into 4 groups (measures) of 4 cells (beats). 

The following bar line symbols are valid:

* `|` single bar line
* `||` double bar line
* `|.` end bar line
* `|:` start repeat bar line
* `:|` stop repeat bar line
* `:|:` combined stop/start repeat bar line
* `|1`, `:|2`, etc, start of a volta. The colon is optional.
* `:|2>` start of a volta, align under the first volta of the previous line

Each line should contain at least one bar line symbol. Everything
before the first bar line will be put in the left margin, and
everything following the last bar symbol will be put in the right
margin. If the line doesn't contain a bar symbol it is printed
completely in the left margin.

Other symbols that can be used:

* `%` denotes that this measure should be played just like the previous measure. The rest of the measure must remain blank.
* `%%` denotes that the last two measures must be repeated. The rest of this measure and the following measure must remain blank.

Example:

    {start_of_grid shape="1+4x2+4"}
    A    || G7 . | % . | %% . | . . |
         | C7 . | %  . || G7 . | % . ||
         |: C7 . | %  . :|: G7 . | % . :| repeat 4 times
    Coda | D7 . | Eb7 | D7 | G7 . | % . |.
    {end_of_grid}

The result will be similar to:

![]({{< asset "images/ex_grid2.png" >}})

See [PDF configuration - grid lines]({{< relref "chordpro-configuration-pdf/#grid-lines" >}}) for more configuration settings.

This directive may include an optional label, to be printed in the
left margin. For example:,

    {start_of_grid label="Intro"}

The ChordPro reference implementation prints the label in the left
margin, see [labels]({{< relref "ChordPro-Configuration-PDF#labels" >}}).

## Strums

Strums are a special kind of grid lines. Beside chords they also
recognize some pseudo-chords that show arrows to indicate strum
patterns.

A grid line becomes a strum by putting `S` (uppercase `s`)
**immediately after** the first bar symbol. When using `s` (lowercase
`s`) the bar symbols and cell lines will be omitted.

The following pseudo-chords can be used:
 
| arrow           | up          |                                   | down        |                                   |
|-----------------|-------------|:---------------------------------:|-------------|:---------------------------------:|
| normal          | `up` or `u` | <span class="sym">&#x2190;</span> | `dn` or `d` <sup>(see below)</sup> | <span class="sym">&#x21a0;</span> |
| accent          | `u+`        | <span class="sym">&#x2193;</span> | `d+`        | <span class="sym">&#x21a3;</span> |
| arpeggio        | `ua`        | <span class="sym">&#x2191;</span> | `da`        | <span class="sym">&#x21a1;</span> |
| arpeggio accent | `ua+`       | <span class="sym">&#x2194;</span> | `da+`       | <span class="sym">&#x21a4;</span> |
| muted           | `ux`        | <span class="sym">&#x2196;</span> | `dx`        | <span class="sym">&#x21a6;</span> |
| muted accent    | `ux+`       | <span class="sym">&#x2199;</span> | `dx+`       | <span class="sym">&#x21a9;</span> |
| staccato        | `us`        | <span class="sym">&#x2192;</span> | `ds`        | <span class="sym">&#x21a2;</span> |
| staccato accent | `us+`       | <span class="sym">&#x2195;</span> | `ds+`       | <span class="sym">&#x21a5;</span> |
{ .table .table-striped .table-bordered .table-sm }

If you are using notenames (`settings.notenames`) then you can
not use `d` if that would be a valid chord. Use `dn` instead.

There is also `x` to denote that nothing is strummed and sound is
muted: <span class="sym">&#x21b0;</span>.


For example:

````
{start_of_grid shape="0+2x4+4"}
| C ~A . . | C ~A . . |
|s dn~up dn~up ~up dn~up | dn~up dn~up ~up dn~up |
| C ~A ~G ~F | . ~F6 F D |
|s dn~up dn~up ~da ~ua | ~up ~up dn dn |
| D . . . | % . . . |
|s d+~u+ ~up d+~u+ ~up | d+~u+ ~up d+~u+ ~ux |
{end_of_grid}
````

This will produce a grid similar to:

![]({{< asset "images/ex_grid3.png" >}})

# Directives: end_of_grid

Abbreviation: `eog`.

This directive indicates the end of the grid.
