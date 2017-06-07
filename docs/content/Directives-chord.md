## chord

This directive is similar to [[define|Directives define]] but it also displays the chord immedeately in the song where the directive occurs.

`{chord:` _name_`}`  
`{chord:` _name_ `base-fret` _offset_ `frets` _pos_ _pos_ … _pos_`}`  
`{chord:` _name_ `base-fret` _offset_ `frets` _pos_ _pos_ … _pos_ `fingers` _pos_ _pos_ … _pos_`}`

* _name_ is the name to be used for this chord. If the directive is used to show a known chord the rest of the arguments may be omitted.

* `base-fret`, `frets` and `fingers` are identical to the [[define|Directives define]] directive.

Example:

    {chord: Am}
    {chord: Bes offset 1 frets 1 1 3 3 3 1 fingers 1 1 2 3 4 1}
    {chord: As  offset 4 frets 1 3 3 2 1 1 fingers 1 3 4 2 1 1}

The resultant will be similar to:

![](http://www.chordpro.org/wiki/images/ex_chord.png)

See also: [[define|Directives define]].
