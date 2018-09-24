# Defining an instrument

ChordPro deals with chords. To do so, it needs to know how chords are
named, how they are ordered, and how they are played.

## How are chords named

The usual convention for chord names consists of three parts: the
_root_, the _quality_, and the _extension_.

For example, in the chord `Dm7`, the root is `D`, the quality is
`m` (minor), and the extension is `7`. A chord always has a root, the
quality and/or the extension may be omitted if it is not needed. `C`
names a C major chord, `D7` a D dominant 7 chord, and `Em` a E minor
chord.

### Root

The most widely spread convention for root names is the use of _Dutch_
or _common_ note names: the letters `C`, `D`, `E`, `F`, `G`, `A`, and `B`. 
To raise a note by a semitone, it is postfixed with the musical sharp
symbol `♯`. To lower a note by a semitone, it is postfixed with the
musical flat symbol `♭`. For convenience the symbols `#` and `b` are
often used instead.

Likewise, to raise a note it can be postfixed with `is`, e.g. `Cis`,
or with `es`, e.g. `Des`. In the latter case, `Ees` and `Aes` are
usually shortened to respectively `Es` and `As`.

Root notes are defined in the configuration files:

    "notes" : {

      "system" : "common",

      "sharp" : [ "C", [ "C#", "Cis", "C♯" ],
                  "D", [ "D#", "Dis", "D♯" ],
                  "E",
                  "F", [ "F#", "Fis", "F♯" ],
                  "G", [ "G#", "Gis", "G♯" ],
                  "A", [ "A#", "Ais", "A♯" ],
                  "B",
      ],
  
      "flat" :  [                               "C",
                  [ "Db", "Des",        "D♭" ], "D",
                  [ "Eb", "Es",  "Ees", "E♭" ], "E",
                                                "F",
                  [ "Gb", "Ges",        "G♭" ], "G",
                  [ "Ab", "As",  "Aes", "A♭" ], "A",
                  [ "Bb", "Bes",        "B♭" ], "B",
        ],
    }

`"system"` sets the name of the system used.

`"sharp"` and `"flat"` are two lists of note names, the first list has
notes and raised notes, the second has notes and lowered notes. Where
there are multiple alternative forms for a note they are in a list.
Note that the first of a list of alternatives is the preferred way to
show a note in diagrams and other places. The choice for the
non-unicode variant is deliberate since many fonts do not have the
appropriate symbols to show `♯` and `♭`.

## How are the chords ordered

To transpose chords, it must know the order of the chords

## How are chords played

To produce chord diagrams, ChordPro must know the number of strings of
the instrument, how they are tuned, and where the fingers must be
placed when playing the chord.
