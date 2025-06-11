---
title: "Configuration file contents - Parser"
description: "Configuration file contents - Parser"
---

# Configuration file contents - Parser

## Preprocessing

**WARNING: THIS IS EXPERIMENTAL**

The ChordPro parser has a built-in preprocessor that can be used to
modify input lines on the fly.

	parser.preprocess {
	  all       : []
	  directive : []
	  songline  : []
	}

The preprocessor can act on all lines, and/or the directive and song
lines (lyrics).

To act on the content of a specific section (environment) only, for
example the `abc` environment:

	  env-abc  : []

Each preprocessor is a list of items each having the following keys:

* `target`: a string that may occur in the line;
* `replace`: each target string is replaced by this value.
* `flags`: replacement flags. Default is `g` (global - replace all
  occurrences). An other useful
  value is `gi` (global, case insensitive).

For example, this will replace every occurrence of the string `[Bes]`
by `[Bb]`:

	{ target  : "[Bes]"
	  replace : "[Bb]" }

Instead of string replacement, patterns can be used. This requires
basic knowledge of the [regular expression
patterns](https://perldoc.perl.org/perlre) that are used by Perl.

To use patterns, use the key `pattern` instead of `target`.
For example, this is like the above but applies to Bes, Des and Ges
chords:

    { pattern : "\\[([BDG])es\\]"
	  replace : "[$1b]" }

In particular when preprocessing directives it is convenient to
restrict processing to some lines only. For this you can add a
selector pattern:

	parser.preprocess.directives : [
	  {
		select  : "^c(omment(_(italic|box))?|i|b)?(-\\w+!?)?[:\\s]"
		target  : ":)"
		replace : ":smiley:"
	  }
	]
	
This will replace the string `:)` by `:smiley:` on comment directives
only.

Note that the selector is always a pattern.

See also [Unicode escape characters in input]({{<relref
"Support-Hints-And-Tips#unicode-escape-characters-in-input">}}) in the 
[Hints and Tips]({{< relref "Support-Hints-And-Tips" >}}).

## Alternative chord brackets

In the exceptional case you really need chord brackets `[` `]` in your
lyrics or annotations, you can set `parser.altbrackets` to a
string of two characters.
These characters will be  replaced by normal brackets **after**
chord analysis.

For example:

    parser.altbrackets: "«»"

Now the lyrics line

    [A]A beautifull «B»day
	
Will result in

    A
	A beautifull [B]day

Use wisely. Better still, do not use this.
