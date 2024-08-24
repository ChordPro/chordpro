---
title: "Using ChordPro"
description: "Using ChordPro"
---

# Using ChordPro

First of all, please read the
[Getting Started]({{< relref "ChordPro-Getting-Started" >}}) page.

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
[configuration files]({{< relref "ChordPro-Configuration" >}}). When used on the
command line, the option overrides the corresponding settings in the
configuration files.

## General command line options

### a2crd

`--a2crd`

Selects 'a2crd' functionality, a legacy ascii to chord converter. When
this option is used the input is converted from **crd** (chords on top
of lyrics) to **cho** (chords between lyrics) and the result written to
the output. No further processing takes place.

See also [Legacy ASCII input format]({{< relref
"chordpro-getting-started#legacy-ascii-input-format" >}}).

Note that `--a2crd` is slightly different from `--generate=ChordPro`. In the latter case the inpur data *is* processed
and then written out as a ChordPro file.

See also [`--crd`]({{< relref "#crd" >}}),
 [`--noa2crd`]({{< relref "#no-a2crd" >}}),

### about

`--about` (short: `-A`)

Prints version information about the ChordPro program. No other processing will be done.

### back-matter

`--back-matter=`*FILE*

Appends the contents of the named PDF document to the output. This can
be used to produce documents with cover and back pages.

### cover

Same as [`--front-matter`]({{< relref "#front-matter" >}}).

### crd

`--crd`

ChordPro automatically detects whether the input files are in legacy
**crd** format and if so, internally converts the data to ChordPro
(**cho** format) before processing.

Using the `--crd` option _forces_ the input files to be treated as
**crd** input.

See also [Legacy ASCII input format]({{< relref
"chordpro-getting-started#legacy-ascii-input-format" >}}).

### csv

`--csv`

When generating PDF output, also writes a CSV file with titles and page
numbers. Some tools, e.g., MobileSheets, can use the CSV to process
the PDF as a collection of independent songs.

The CSV has the same name  as the PDF, with extension `.pdf` replaced
by `.csv`.

### decapo

`--decapo`

If a song has a capo directive, do not show the capo setting in the
output but transpose the chords of the song instead. Useful for
musicians that want to play along and do not have capo capabilities,
e.g. a bass player.

### diagrams

`--diagrams=`*WHICH*

Prints diagrams of chords used in a song.

_WHICH_ can be `all` to print all chords used, `user` to only print
the user-defined chords, and `none` to suppress printing of chord
diagrams.

Configuration file setting:
[Printing chord diagrams]({{< relref "ChordPro-Configuration-Generic#printing-chord-diagrams" >}}).

See also: [`--chord-grids`]({{< relref "#chord-grids" >}}),
[`--easy-chord-grids`]({{< relref "#easy-chord-grids" >}}),
[`--user-chord-grids`]({{< relref "#user-chord-grids" >}}),
[`--chord-grids-sorted`]({{< relref "#chord-grids-sorted" >}}).
		
### encoding

`--encoding=`*ENC*

Specifies the encoding for input files. Default is UTF-8. ISO-8859.1
(Latin-1) encoding is automatically sensed.

### filelist

`--filelist=`*FILE*

Reads the names of the files to be processed from the named file. This
is mostly useful when you have a large collection of song files that
you want processed, or when you want them to be processed in a
particular order.

Every line from the named file is taken to be a file name, with the
exception of empty lines and lines that start with a `#` which are ignored.

This option may be specified multiple times.

If the first file from the final filelist is a PDF document (the name
ends with `.pdf`) it is used as [front matter]({{<relref "#front-matter">}}).
Likewise, if the last file from the final filelist is a PDF document
it is used as [back matter]({{<relref "#back-matter">}}).

Song file names listed on the command line are processed _after_ any
files from the filelist arguments.

You can add metadata in the filelist with `--meta`
(see [below]({{< relref "#meta" >}})).
This is useful to create song variants:
````
MySong.cho
MySong.cho  --meta voice=bass
MySong.cho  --meta voice=alto
````

You can override a default song-specific config with `--config`, e.g.
````
MySong.cho  --config=ukulele.json
MySong.cho  --meta voice=bass
MySong.cho  --meta voice=alto --config=ukulele.json
````

Important notice: Filelist lines that have `--meta` and/or `--config`
**must** quote whitespace, e.g.

````
"My New Song.cho" --meta voice=soprano
````

### front-matter

`--front-matter=`*FILE*
`--cover=`*FILE*

Prepends the contents of the named PDF document to the output. This can
be used to produce documents with cover pages.

### lyrics-only

`--lyrics-only` (short: `-l`)

Only prints lyrics. All chords are suppressed in lyrics.
Chord diagrams and grids are also suppressed.

Useful to make prints for singers and other musicians that do not
require chords.

### maximize

`--maximize`

Starts with a maximized window.
GUI version only.

### meta

`--meta=`*KEY*`=`*VALUE*

Presets metadata item _KEY_ to have the value _VALUE_.

This option may be specified multiple times. Additional values for the
same _KEY_ will overwrite the previous value.

### no-a2crd

Do not automatically attempt to convert non-ChordPro input to ChordPro format.

### no-csv

`--no-csv`

Suppresses the generation of a CSV file.

See [`--csv`]({{< relref "#csv" >}}).

### no-strict

`--no-strict`

Enables liberal interpretation of the input with regard to the
ChordPro standard. Most notably, unknown directives will not
not flagged as warnings but silently ignored.

This makes it more convenient to process ChordPro files the have custom
directives.

See [`--strict`]({{< relref "#strict" >}}).

### no-toc

`--no-toc`

Suppresses the table of contents.

See [`--toc`]({{< relref "#toc" >}}).

### output

`--output=`*FILE* (short: `-o`)

Designates the name of the output file where the results are written
to.

The filename extension determines the type of the output. It should
correspond to one of the backends that are currently supported.
Alternatively you can explicitly designate the requested output format
with a `--generate` option:

* `pdf` (`--generate=PDF`)

  Portable document format (PDF).

  If a table of contents is generated with the PDF, ChordPro also writes
  a CSV file containing the following metadata:
  title, pages, sorttitle, artist, composer, collection, key and year.

  This CSV file has the same name as the PDF, with extenstion `pdf`
  replaced by `csv`. The contents conform to the RFC4180
  recommendations. The column separator is a semicolon. When a
  metadata has multiple values, these are separated with a vertical
  bar. The CSV file is intended to be used when importing PDF documents
  into the MobileSheetsPro application, but can be used for other
  purposes as well.
  
  An example:
  
  ````
  title;pages;sort title;artists;composers;collections;keys;years
  "Throw It Away";9-10;;September;"Abbey Lincoln";September;Am;
  ````
  Metadata without values can leave the corresponding columns empty, but
  the number of separators must be the same in all lines.

* txt (`--generate=Text`)

  A textual representation of the input, mostly for visual
  inspection.

* cho (`--generate=ChordPro`)

  A functional equivalent version of the ChordPro input.

* html (`--generate=HTML`)

  An experimental html representation of the songs.

### start-page-number

`--start-page-number=`*N* (short: `-p`)

Sets the starting page number for the output.

### strict

`--strict`

Enforces strict interpretation of the input with regard to the
ChordPro standard.

Enabled by default.

See [`--no-strict`]({{< relref "#no-strict" >}}).

### toc

`--toc` (short: `-i`)

Includes a table of contents.

By default a table of contents is included in the PDF output when it
contains more than one song.

### transcode

`--transcode=`*notation*

Transcode all songs to the named notation system. Supported values
are:

* `common` (C, D, E, F, G, A, B)
* `dutch` (same as `common`)
* `german` (C, ... A, Ais/B, H)
* `latin` (Do, Re, Mi, Fa, Sol, ...)
* `scandinavian` (C, ... A, A#/Bb, H)
* `solfège` (Do, Re, Mi, Fa, So, ...)*
* `solfege` (same as `solfège`)*
* `nashville` (1, 2, 3, ...)*
* `roman` (I, II, III, ...)*

The systems marked with * are key-relative. For example, when a song
is in the key of `D` and transcoded to `nashville`, `D` becomes `1`,
`G` becomes `4` and so on.

### transpose

`--transpose=`*N* (short: `-x`)

Transposes all songs by _N_ semi-tones. Note that _N_ may be specified
as `+`*N* to transpose upward, using sharps, or as `-`*N* to transpose
downward, using flats.

See also the [transpose]({{< relref "Directives-transpose" >}}) directive.

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

`--chord-font=`*FONT* (short: `-C`)

Sets the font used to print the chord names.

See also [ChordPro Fonts]({{< relref "ChordPro-Fonts" >}}).

Configuration file setting: [`pdf.fonts.chord`]({{< relref "ChordPro-Configuration-PDF#fonts" >}}).

### chord-grid-size

`--chord-grid-size=`*N* (short: `-s`)

Sets the total width of a chord diagram.

Configuration file setting:
[`pdf.diagram`]({{< relref "ChordPro-Configuration-PDF#chord-diagrams" >}}).

### chord-grids

`--chord-grids`

Prints chord diagrams of all chords used in a song.

Configuration file setting:
[`diagrams.show`]({{< relref "ChordPro-Configuration-Generic#printing-chord-diagrams" >}}).

### chord-grids-sorted

`--chord-grids-sorted` (short: `-S`)

Prints chord diagrams of the chords used in a song, ordered by key and
type.

Configuration file setting:
[`diagrams.sorted`]({{< relref "ChordPro-Configuration-Generic#printing-chord-diagrams" >}}).

### chord-size

`--chord-size=`*N* (short: `-c`)

Sets the font size for the chord names.

Configuration file setting: [`pdf.fonts.chord`]({{< relref "ChordPro-Configuration-PDF#fonts" >}}).

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
[`pdf.even-odd-pages`]({{< relref "ChordPro-Configuration-PDF#even-odd-page-printing" >}})
and [Page headers and footers]({{< relref "ChordPro-Configuration-PDF#page-headers-and-footers" >}}).

### no-easy-chord-grids

`--no-easy-chord-grids` (short: `-g`)

Not supported.

### no-chord-grids

`--no-chord-grids` (short: `-G`)

Disables printing of chord diagrams of the chords used in a song.

Configuration file setting:
[`diagrams.show`]({{< relref "ChordPro-Configuration-Generic#printing-chord-diagrams" >}}).

### no-chord-grids-sorted

`--no-chord-grids-sorted`

Prints chord grids in the order they appear in the song.

Configuration file setting:
[`diagrams.sorted`]({{< relref "ChordPro-Configuration-Generic#printing-chord-diagrams" >}}).

### odd-pages-number-left

`--odd-pages-number-left`

Prints even/odd pages with pages numbers left on odd pages.

Configuration file settings:
[`pdf.even-odd-pages`]({{< relref "ChordPro-Configuration-PDF#even-odd-page-printing" >}})
and [Page headers and footers]({{< relref "ChordPro-Configuration-PDF#page-headers-and-footers" >}}).

### page-number-logical

`--page-number-logical` (short: `-n`)

Not supported.

### page-size

`--page-size=`*FMT* (short: `-P`)

Specifies the page size for the PDF output, e.g. `a4` (default), `letter`.

Configuration file setting:
[`pdf.papersize`]({{< relref "ChordPro-Configuration-PDF#papersize" >}}).

### single-space

`--single-space` (short `-a`))

When a lyrics line has no chords associated, suppresses the vertical
space normally occupied by the chords.

Configuration file setting:
[`settings.suppress-empty-chords`]({{< relref "ChordPro-Configuration-Generic#general-settings" >}}).

### text-font

`--text-font=`*FONT* (short: `-T`)

Sets the font used to print lyrics and comments.

See also [ChordPro Fonts]({{< relref "ChordPro-Fonts" >}}).

Configuration file setting: [`pdf.fonts.text`]({{< relref "ChordPro-Configuration-PDF#fonts" >}}).

### text-size

`--text-size=`*N* (short: `-t`)

Sets the font size for lyrics and comments.

Configuration file setting: [`pdf.fonts.text`]({{< relref "ChordPro-Configuration-PDF#fonts" >}}).

### user-chord-grids

`--user-chord-grids`

Prints chord grids of all user defined chords used in a song.

Configuration file setting:
[`diagrams.show`]({{< relref "ChordPro-Configuration-Generic#printing-chord-diagrams" >}}).

### vertical-space

`--vertical-space`=_N_ (short: `-w`)

Adds some extra vertical space between the lines.

Configuration file setting:
[Spacing]({{< relref "ChordPro-Configuration-PDF#spacing" >}}).

### 2-up

`--2-up` (short: `-2`)

Not supported.

### 4-up

`--4-up` (short: `-4`)

Not supported.

## Configuration options

See [Configuration Files Overview]({{< relref "ChordPro-Configuration-Overview" >}})
for details about the configuration files.

Note that missing default configuration files are silently ignored.
ChordPro will never create nor modify configuration files.

### config

`--config=`*JSON* (shorter: `--cfg`)

A JSON file that defines the behaviour of the program and the layout
of the output. See [Configuration Files]({{< relref "ChordPro-Configuration" >}}) for details.

This option may be specified more than once. Each additional config
file overrides the corresponding definitions that are currently
active.

### convert-config

`--convert-config=`*file*

Converts the config in *file* to RRJSON format, writes the result
to standard output, and exits. No songs are processed.

You can use `--output=`*newfile* to designate an output file instead
of standard output.

### define

`--define=`*item*

**Warning:** This is not intended for general use. There is no guarantee
that it will always yield the results you expect.

Sets a configuration item. _item_ must be in the format of
period-separated configuration keys, an equal sign, and the value.

For example, the equivalent of command line option `--no-chord-grids` is
`--define=diagrams.show=0`.

You can also use colons to separate the keys, e.g., `diagrams:show`.

`--define` may be used more than once to set multiple items.

Array items can be addressed with a (final) numeric key, e,g,
`pdf.formats.default.footer.2` refers to the 3rd element from
`pdf.formats.default.footer`.

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

### nosongconfig

`--nosongconfig`

Don't use song specific config files, even if they exist.

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

`--sysconfig=`*CFG*

Designates a system specific config file.

### userconfig

`--userconfig=`*CFG*

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

