# Using ChordPro

First of all, please read the
[[Getting Started|ChordPro-Getting-Started]] page.

## Command line options

ChordPro recognises a vast number of command line options.

* Short options  
Short options are in the form `-A`, a dash (minus) followed by a
letter.

* Long options  
Long options are in the form `--about`, a double-dash followed by the
option name.

Some options can have arguments. For example, to specify `song.pdf` as
the name of the output file for ChordPro, the following options are
equivalent:

    --output=song.pdf
    --output song.pdf
    -o song.pdf

Most options have corresponding settings in the
[[configuration files|ChordPro-Configuration]]. When used on the
command line, the option overrides the corresponding settings in the
configuration files.

## General command line options

### about

`--about` (short: `-A`)

Prints version information about the ChordPro program. No other processing will be done.

### cover

`--cover=`_FILE_

Prepends the contents of the named PDF document to the output. This can
be used to produce documents with cover pages.

### csv

`--csv`

When generating PDF output, also writes a CSV file with titles and page
numbers. Some tools, e.g., MobileSheets, can use the CSV to process
the PDF as a collection of independent songs.

The CSV has the same name  as the PDF, with extension `.pdf` replaced
by `.csv`.

### diagrams

`--diagrams=`_WHICH_

Prints diagrams of chords used in a song.

_WHICH_ can be `all` to print all chords used, `user` to only print
the user-defined chords, and `none` to suppress printing of chord
diagrams.

Configuration file setting:
[[Printing chord diagrams|ChordPro-Configuration-Generic#configuration-file-contents-generic_printing-chord-diagrams]].

See also: [`--chord-grids`](#chordii-compatibility-options_chord-grids),
[`--easy-chord-grids`](#chordii-compatibility-options_easy-chord-grids),
[`--user-chord-grids`](#chordii-compatibility-options_user-chord-grids),
[`--chord-grids-sorted`](#chordii-compatibility-options_chord-grids-sorted).
		
### encoding

`--encoding=`_ENC_

Specifies the encoding for input files. Default is UTF-8. ISO-8859.1
(Latin-1) encoding is automatically sensed.

### lyrics-only

`--lyrics-only` (short: `-l`)

Only prints lyrics. All chords are suppressed.

Useful to make prints for singers and other musicians that do not
require chords.

### no-csv

`--no-csv`

Suppresses the generation of a CSV file.

See [`--csv`](#general-command-line-options_csv).

### no-toc

`--no-toc`

Suppresses the table of contents.

See [`--toc`](#general-command-line-options_toc).

### output

`--output=`_FILE_ (short: `-o`)

Designates the name of the output file where the results are written
to.

The filename extension determines the type of the output. It should
correspond to one of the backends that are currently supported:

* pdf  
Portable document format (PDF).

If a table of contents is generated with the PDF, ChordPro also writes
a CSV file containing titles and page numbers. This CSV file has the
same name as the PDF, with extenstion "pdf" replaced by <csv>.

* txt  
A textual representation of the input, mostly for visual
inspection.

* cho  
A functional equivalent version of the ChordPro input.

### start-page-number

`--start-page-number=`_N_ (short: `-p`)

Sets the starting page number for the output.

### toc

`--toc` (short: `-i`)

Includes a table of contents.

By default a table of contents is included in the PDF output when it
contains more than one song.

### transpose

`--transpose=`_N_ (short: `-x`)

Transposes all songs by _N_ semi-tones. Note that _N_ may be specified
as `+`_N_ to transpose upward, using sharps, or as `-`_N_ to transpose
downward, using flats.

See also the [[transpose|Directives transpose]] directive.

### version

`--version` (short: `-V`)

Prints the program version and exits.

## Chordii compatibility options

The original Chordii program did not have configuration files, so it
had a large number of command line options to control the appearance
of the output.

For compatibility, ChordPro recognizes most Chordii command line
options. Note that not all of them actually do something.

*Note:* Chordii used the term _grid_ for chord diagrams. It
should not be confused with ChordPro grids.

### chord-font

`--chord-font=`_FONT_ (short: `-C`)

Sets the font used to print the chord names.

See also [[ChordPro Fonts|ChordPro-Fonts]].

Configuration file setting: [`pdf.fonts.chord`](ChordPro-Configuration-PDF#fonts).

### chord-grid-size

`--chord-grid-size=`_N_ (short: `-s`)

Sets the total width of a chord diagram.

Configuration file setting:
[`pdf.diagram`](ChordPro-Configuration-PDF#chord-diagrams).

### chord-grids

`--chord-grids`

Prints chord diagrams of all chords used in a song.

Configuration file setting:
[`diagrams.show`](ChordPro-Configuration-Generic#printing-chord-diagrams).

### chord-grids-sorted

`--chord-grids-sorted` (short: `-S`)

Prints chord diagrams of the chords used in a song, ordered by key and
type.

Configuration file setting:
[`diagrams.sorted`](ChordPro-Configuration-Generic#printing-chord-diagrams).

### chord-size

`--chord-size=`_N_ (short: `-c`)

Sets the font size for the chord names.

Configuration file setting: [`pdf.fonts.chord`](ChordPro-Configuration-PDF#fonts).

### dump-chords

`--dump-chords` (short: `-D`)

Dumps a list of all built-in chords in a form dependent of the backend
used. The PDF backend will produce neat pages of chord diagrams. The
ChordPro backend will produce a list of `define` directives.

### dump-chords-text

`--dump-chords-text` (short: `-d`)

Dumps a list of all built-in chords in the form of `define` directives,
and exits.

### easy-chord-grids

`--easy-chord-grids`

Not supported.

### even-pages-number-left

`--even-pages-number-left` (short `-L`)

Prints even/odd pages with pages numbers left on even pages.

Configuration file settings:
[`pdf.even-odd-pages`](ChordPro-Configuration-PDF#even-odd-page-printing)
and [[Page headers and footers|ChordPro-Configuration-PDF#page-headers-and-footers]].

### no-easy-chord-grids

`--no-easy-chord-grids` (short: `-g`)

Not supported.

### no-chord-grids

`--no-chord-grids` (short: `-G`)

Disables printing of chord diagrams of the chords used in a song.

Configuration file setting:
[`diagrams.show`](ChordPro-Configuration-Generic#printing-chord-diagrams).

### no-chord-grids-sorted

`--no-chord-grids-sorted`

Prints chord grids in the order they appear in the song.

Configuration file setting:
[`diagrams.sorted`](ChordPro-Configuration-Generic#printing-chord-diagrams).

### odd-pages-number-left

`--odd-pages-number-left`

Prints even/odd pages with pages numbers left on odd pages.

Configuration file settings:
[`pdf.even-odd-pages`](ChordPro-Configuration-PDF#even-odd-page-printing)
and [[Page headers and footers|ChordPro-Configuration-PDF#page-headers-and-footers]].

### page-number-logical

`--page-number-logical` (short: `-n`)

Not supported.

### page-size

`--page-size=`_FMT_ (short: `-P`)

Specifies the page size for the PDF output, e.g. `a4` (default), `letter`.

Configuration file setting:
[`pdf.papersize`](ChordPro-Configuration-PDF#papersize).

### single-space

`--single-space` (short `-a`))

When a lyrics line has no chords associated, suppresses the vertical
space normally occupied by the chords.

Configuration file setting:
[`settings.suppress-empty-chords`](ChordPro-Configuration-Generic#general-settings).

### text-font

`--text-font=`_FONT_ (short: `-T`)

Sets the font used to print lyrics and comments.

See also [[ChordPro Fonts|ChordPro-Fonts]].

Configuration file setting: [`pdf.fonts.text`](ChordPro-Configuration-PDF#fonts).

### text-size

`--text-size=`_N_ (short: `-t`)

Sets the font size for lyrics and comments.

Configuration file setting: [`pdf.fonts.text`](ChordPro-Configuration-PDF#fonts).

### user-chord-grids

`--user-chord-grids`

Prints chord grids of all user defined chords used in a song.

Configuration file setting:
[`diagrams.show`](ChordPro-Configuration-Generic#printing-chord-diagrams).

### vertical-space

`--vertical-space`=_N_ (short: `-w`)

Adds some extra vertical space between the lines.

Configuration file setting:
[Spacing](ChordPro-Configuration-PDF#spacing).

### 2-up

`--2-up` (short: `-2`)

Not supported.

### 4-up

`--4-up` (short: `-4`)

Not supported.

## Configuration options

See [[Configuration Files Overview|ChordPro Configuration Overview]]
for details about the configuration files.

Note that missing default configuration files are silently ignored.
ChordPro will never create nor modify configuration files.

### config

`--config=`_JSON_ (shorter: `--cfg`)

A JSON file that defines the behaviour of the program and the layout
of the output. See [[Configuration Files|ChordPro-Configuration]] for details.

This option may be specified more than once. Each additional config
file overrides the corresponding definitions that are currently
active.

### define

`--define=`_item_

Sets a configuration item. _item_ must be in the format of
period-separated configuration keys, an equal sign, and the value.

For example, the equivalent of command line option `--no-chord-grids` is
`--define=chordgrid.show=0`.

You can also use colons to separate the keys, e.g., `chordgrid:show`.

`--define` may be used more than once to set multiple items.

### no-default-configs

`--no-default-configs` (short: `-X`)

Do not use any config files except the ones mentioned explicitly on
the command line.

This guarantees that the program is running with the default
configuration.

### noconfig

`--noconfig`

Don't use the specific config file, even if it exists.

### nolegacyconfig

`--nolegacyconfig`

Don't use a legacy config file, even if it exists.

### nosysconfig

`--nosysconfig`

Don't use the system specific config file, even if it exists.

### nouserconfig

`--nouserconfig`

Don't use the user specific config file, even if it exists.

### print-default-config

`--print-default-config`

Prints the default configuration to standard output, and exits.

The default configuration is fully commented to explain its contents.

### print-final-config

`--print-final-config`

Prints the final configuration (after processing all system, user
and other config files) to standard output, and exits.

The final configuration is not commented. Sorry.

### sysconfig

`--sysconfig=`_CFG_

Designates a system specific config file.

### userconfig

`--userconfig=`_CFG_

Designates the config file for the user.

## Miscellaneous options

### help

`--help` (short: `-h`)

Prints a help message. No other output is produced.

### ident

`--ident`

Shows the program name and version.

### manual

`--manual`

Prints the manual page. No other output is produced.

### verbose

`--verbose`

Provides more verbose information of what is going on.

In particular, ChordPro will print the names of the configuration
files that it processed. This may be revealing information.

