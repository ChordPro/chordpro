---
title: "Defining an instrument"
description: "Defining an instrument"
---

# Defining the instrument

    "instrument" : {
	    "type" : "guitar",
		"description" : "Guitar, 6 strings, standard tuning",
	}

The value of `type` can be used for [directive selection]({{< relref
"chordpro-directives#conditional-directives" >}})

# Defining chords

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
diatonic notes and raised notes, the second has diatonic notes and
lowered notes. Where there are multiple alternative forms for a note
they are in a sublist.

ChordPro will attempt to reproduce the chord name the way it was
input, but in case of transposition or transcoding it uses the first
of the sublist of alternatives, if any. Note that the choice for the
non-unicode variant is deliberate since many fonts do not yet have the
appropriate symbols to show `♯` and `♭`.

By default ChordPro uses the Common (a.k.a. Dutch) note naming system
according to the definition shown above. Some other note naming
systems are provided:

* German  
This is a variant of Dutch where `H` is used instead of `B`, and `B`
is used instead of `B♭`. Flats and sharps are denoted by `is` and `es`
suffixes, not symbols.  
This definition is contained in the preset configuration
`notes:german`.

* Scandinavian  
This is a variant of German where `H` means `B`, and `B♭`
means B flat. Flats and sharps are denoted by the appropriate symbols.  
This definition is contained in the preset configuration
`notes:scandinavian`.

* Latin  
This system consists of the diatonic note names `Do`, `Re`, `Mi`,
`Fa`, `Sol`, `La`, and `Si`. Flats and sharps are denoted by the
appropriate symbols. It is often used in Italian, French,
Spanish and Portuguese speaking countries.  
This definition is contained in the preset configuration
`notes:latin`.

For more information, see [Key signature names and translations](https://en.wikipedia.org/wiki/Key_signature_names_and_translations) on Wikipedia.

## How are the chords ordered

To transpose chords, it must know the order of the chords, in
particular the chord roots. This order is defined by the order the
definitions appear in the `"flat"` and `"sharp"` lists above.  
ChordPro uses the convention that when transposing up it chooses the
note names from the `"sharp"` list. Notes from the `"flat"` list are
used when transposing down.

## How are chords played (string instruments)

To produce chord diagrams, ChordPro must know the number of strings of
the instrument, how they are tuned, and where the fingers must be
placed when playing the chord. This can all be defined in the
configuration files.

    "instrument" : {
		"type" : "guitar",
		"description" : "Guitar, 6-strings, EADGBE tuning",
	},
  
    // Strings and tuning.
    "tuning" : [ "E2", "A2", "D3", "G3", "B3", "E4" ],

    // Chords.
    "chords" : [
        {
          "name"  : "Bb",
		  "display" : "B♭",
          "base"  : 1,
          "frets" : [ 1, 1, 3, 3, 3, 1 ],
          "fingers" : [ 1, 1, 2, 3, 4, 1 ],
        },
    ],

`"instrument"` is a descriptive name of the instrument defined.

`"tuning"` defines the tuning of the instrument as a list of note
names, optionally followed by the octave number
([Scientific pitch notation](https://en.wikipedia.org/wiki/Scientific_pitch_notation)).

`"chords"` is a list of chords to be defined for this tuning. For each
chord, `"base"` specifies the topmost position of the chord diagram.
It must be 1 or higher. The `"frets"` positions are the positions in
the chord diagram. `"fingers"` is optional and denotes which fingers
are used for the chord. `"display"` is optional and defines the way
the chord name must be shown, if different from `"name"`.

For convenience, `"instrument.type"`, `"instrument.description"` and `"tuning"` can be used as
substitution variables in texts, see [Using metadata in texts]({{< relref "ChordPro-Configuration-Format-Strings" >}}).

ChordPro comes with a couple of predefined instrument configs:

- `guitar-br`  
  Guitar with common chords (see `guitar-ly`) using Brandt-Roemer chord notation.
- `guitar`  
  Guitar with lots of chords.
- `guitar-legacy`  
  Guitar with the chords originaly included in Chordii.
- `guitar-ly`  
  Guitar with common chords derived from [Lilypond](https://lilypond.org) data.
- `mandolin-ly`  
  Mandolin with common chords derived from [Lilypond](https://lilypond.org) data.
- `ukulele`  
  Ukulele with lots of chords.
- `ukulele-ly`  
  Ukulele with common chords derived from [Lilypond](https://lilypond.org) data.

## How are chords played (keyboard instruments)

To produce chord diagrams, ChordPro must know the notes that make the chord.
This can be defined in the configuration files.

    "instrument" : {
		"type" : "keyboard",
		"description" : "Guitar, 6-strings, EADGBE tuning",
	},
  
    // Tuning is not relevant. By setting the tuning to [ 0 ] all
	// existing definitions are flushed.
    "tuning" : [ 0 ],

    // Chords.
    "chords" : [
        {
          "name"  : "Bb",
          "keys" : [ 0, 4, 7 ],
        },
    ],

`"instrument"` is a descriptive name of the instrument defined.

`"chords"` is a list of chords to be defined for this tuning. For each
chord, `"keys"` specifies notes of the chord, relative to the root note.

As opposed to string instruments, the notes of a chord are only
dependent on the _quality_ and _extension_ of the chord. For example,
all major chords have keys `[ 0, 4, 7 ]`. A minor7 chord will have
`[ 0, 3, 7, 10 ]`. This implies that for most (common) chords no definitions
are necessary.

ChordPro comes with a single predefined keyboard instrument config, `keyboard`.

## Special: Nashville Number System

The Nashville Number System is a method of transcribing music by
denoting the scale degree on which a chord is built. Instead of
absolute note names like `C`, `D`, `E` it uses numbers `1`, `2`, `3`
and so on.

No configuration settings are needed. When a song has its chords in
Nashville Number System this is automatically detected, and
transposition and the printing of chord diagrams is disabled.

For more information, see [Nashville number system](https://en.wikipedia.org/wiki/Nashville_number_system) on Wikipedia.

## Special: Roman Numeral Analysis

This is like the Nashville Number System but uses roman numbers `I`,
`II`, `III` and so on. Minor chords are written using lowercase
letters.

No configuration settings are needed. When a song has its chords in
Roman Number System this is automatically detected, and
transposition and the printing of chord diagrams is disabled.

For more information, see [Roman Numeral Analysis](https://en.wikipedia.org/wiki/Roman_numeral_analysis) on Wikipedia.
