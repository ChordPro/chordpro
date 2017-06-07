# ChordPro Chords

In ChordPro files, lyrics are interspersed with chords between brackets `[` and `]`. Strictly speaking it doesn't matter what you put between the `[]`, it is put on top of the syllable whatever it is. But there are situations where it **does** matter: for chord diagrams and transpositions.

Many ChordPro implementations (formatters) provide chord diagrams at the end of a song, using a built-in list of known chords and fingerings. Clearly, this can only work when the chords in the ChordPro file can be recognized.

For transposition it is slightly easier. For example, when you're transposing from A to C, you can replace everything chord-like that starts with ‘A’ by ‘C’ and whatever follows the ‘A’. ‘Am7’ becomes ‘Cm7’ and ‘Alpha’ would become ‘Clpha’, who cares?

Although the ChordPro File Format Specification deliberately doesn't say anything about valid chords, it is advised to stick to commonly accepted chords and chord forms. The ChordPro Reference Implementation supports:
* A, B, C, …, G (European/Dutch)
* I, II, III, …, VII (Roman)
* 1, 2, 3, …, 7 (Nashville)
* `b` for flat, and `#` for sharp
* Common postfixes like `m`, `7`, `dim`, etc.
