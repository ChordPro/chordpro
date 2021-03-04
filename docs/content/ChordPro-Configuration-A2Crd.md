---
title: "Configuration for ASCII to ChordPro converter"
description: "Configuration for ASCII (text) to ChordPro converter"
---

# Configuration for ASCII (text) to ChordPro converter

Settings for the A2Crd converter are stored in the configuration under
the key `"a2crd"`.

    {
       // ... generic part ...
       "a2crd" : {
         // ... a2crd settings ...
       },
    }

## Strategy

Several strategies to recognize chords and lyrics lines are
implemented by classifiers. 

	// Classification algorithm.
	"classifier" : "pct_chords",

The following classifiers are currently provided:

* `"pct_chords"`  
Strategy is based on the percentage of chords recognized.

* `"classic"`  
The legacy strategy.

Feel free to choose the strategy that yields the best results for your
date.

Hint: You can do this on the command line with

    chordpro --a2crd --define a2crd.classifier=classic ...

## Tab stop width

Tabs in the input source are replaced by an appropriate amount of
spaces.

	// Tab stop width for tab expansion. Set to zero to disable.
	"tabstop" : 8,

## Infer titles and subtitles

The first non-empty, non-chord, non-directive
lines are taken to be the song title and subtitle.

	// Treat leading lyrics lines as title/subtitle lines.
	"infer-titles" : true,

This is enabled by default, unless command line option `--fragment`
is used.
