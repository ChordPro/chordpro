## start_of_grid

This directive indicates that the lines that follow define a chord grid in the style of [Jazz Grilles](https://fr.wikipedia.org/wiki/Grille_harmonique).

In a grid only chords are used, no lyrics, and the chords are arranged in a rectangular pattern for a quick view on the 
structure of the song. Symbols for bar lines and repeats can also be included in a grid.

For example, to create a grid for ‘The House of the Rising Sun’:

    {start_of_grid}
    || Am . . . | C . . . | D  . . . | F  . . . |
    |  Am . . . | C . . . | E  . . . | E  . . . |
    |  Am . . . | C . . . | D  . . . | F  . . . |
    |  Am . . . | E . . . | Am . . . | Am . . . ||
    {end_of_grid}

The result could look like:

![](images/ex_grid1.png)

The grid consists of a number of cells that can contain chords. If a cell does not need to show a chord, the placeholder `.` (period) can be used to designate an empty cell.
Between the cells bar lines can be placed. In the above example, each line contains 16 cells and the bar lines divide the cells into 4 groups (measures) of 4 cells (beats).


## end_of_grid

This directive indicates the end of the grid.
