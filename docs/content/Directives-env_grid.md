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

`{start_of_grid: shape="`_cells_`"}`  
`{start_of_grid: shape="`_measures_`x`_beats_`"}`

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
* `|1`, `|2`, etc, start of a volta
* `|2>` start of a volta, align under the first volta of the previous line

Each line should contain at least one bar line symbol. Everything
before the first bar line will be put in the left margin, and
everything following the last bar symbol will be put in the right
margin. If the line doesn't contain a bar symbol it is printed
completely in the left margin.

Other symbols that can be used:

* `%` denotes that this measure should be played just like the previous measure. The rest of the measure must remain blank.
* `%%` denotes that the last two measures must be repeated. The rest of this measure and the following measure must remain blank.

Example:

    {start_of_grid: shape="1+4x2+4"}
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

    {start_of_grid: label="Intro"}

The ChordPro reference implementation prints the label in the left
margin, see [labels]({{< relref "ChordPro-Configuration-PDF#labels" >}}).

# Directives: end_of_grid

Abbreviation: `eog`.

This directive indicates the end of the grid.
