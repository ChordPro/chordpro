# Using ChordPro

First of all, please read the
[[Getting Started|ChordPro-Getting-Started]] page.

![](images/maintenance.png)

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

### config

`--config=`_JSON_ (shorter: `--cfg`)

A JSON file that defines the behaviour of the program and the layout
of the output. See [[configuration files|ChordPro-Configuration]] for details.

This option may be specified more than once. Each additional config
file overrides the corresponding definitions that are currently
active.

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

See also: [`--chord-grids`](#using-chordpro_general-command-line-options_chord-grids),
[`--easy-chord-grids`](#using-chordpro_general-command-line-options_easy-chord-grids),
[`--user-chord-grids`](#using-chordpro_general-command-line-options_user-chord-grids),
[`--chord-grids-sorted`](#using-chordpro_general-command-line-options_chord-grids-sorted).
		
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

See [`--csv`](#using-chordpro_general-command-line-options_csv).

### no-toc

`--no-toc`

Suppresses the table of contents.

See [`--toc`](#using-chordpro_general-command-line-options_toc).

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

Configuration file setting: [`pdf.fonts.chord`](ChordPro-Configuration-PDF#configuration-for-pdf-output_fonts).

### chord-grid-size

`--chord-grid-size=`_N_ (short: `-s`)

Sets the total width of a chord diagram.

Configuration file setting:
[`pdf.diagram`](ChordPro-Configuration-PDF#configuration-for-pdf-output_chord-diagrams).

### chord-grids

`--chord-grids`

Prints chord diagrams of all chords used in a song.

Configuration file setting:
[[`diagrams.show`|ChordPro-Configuration-Generic#configuration-file-contents-generic_printing-chord-diagrams]].

### chord-grids-sorted

`--chord-grids-sorted` (short: `-S`)

Prints chord diagrams of the chords used in a song, ordered by key and
type.

Configuration file setting:
[[`diagrams.sorted`|ChordPro-Configuration-Generic#configuration-file-contents-generic_printing-chord-diagrams]].

### chord-size

`--chord-size=`_N_ (short: `-c`)

Sets the font size for the chord names.

Configuration file setting: [`pdf.fonts.chord`](ChordPro-Configuration-PDF#configuration-for-pdf-output_fonts).

### dump-chords

`--dump-chords` (short: `-D`)

Dumps a list of built-in chords in a form dependent of the backend
used. The PDF backend will produce neat pages of chord diagrams. The
ChordPro backend will produce a list of `define` directives.

### dump-chords-text

`--dump-chords-text` (short: `-d`)

Dumps a list of built-in chords in the form of `define` directives,
and exits.

### easy-chord-grids

`--easy-chord-grids`

Not supported.

### even-pages-number-left

`--even-pages-number-left` (short `-L`)

Prints even/odd pages with pages numbers left on even pages.

Configuration file settings:
[[`pdf.even-odd-pages`|ChordPro-Configuration-PDF#configuration-for-pdf-output_even-odd-page-printing]]
and [[Page headers and footers|ChordPro-Configuration-PDF#configuration-for-pdf-output_page-headers-and-footers]].

### no-easy-chord-grids

`--no-easy-chord-grids` (short: `-g`)

Not supported.

### no-chord-grids

`--no-chord-grids` (short: `-G`)

Disables printing of chord diagrams of the chords used in a song.

Configuration file setting:
[[`diagrams.show`|ChordPro-Configuration-Generic#configuration-file-contents-generic_printing-chord-diagrams]].

### no-chord-grids-sorted

`--no-chord-grids-sorted`

Prints chord grids in the order they appear in the song.

Configuration file setting:
[[`diagrams.sorted`|ChordPro-Configuration-Generic#configuration-file-contents-generic_printing-chord-diagrams]].

### odd-pages-number-left

`--odd-pages-number-left`

Prints even/odd pages with pages numbers left on odd pages.

Configuration file settings:
[[`pdf.even-odd-pages`|ChordPro-Configuration-PDF#configuration-for-pdf-output_even-odd-page-printing]]
and [[Page headers and footers|ChordPro-Configuration-PDF#configuration-for-pdf-output_page-headers-and-footers]].

### page-number-logical

`--page-number-logical` (short: `-n`)

Not supported.

### page-size

`--page-size=`_FMT_ (short: `-P`)

Specifies the page size for the PDF output, e.g. `a4` (default), `letter`.

Configuration file setting:
[[`pdf.papersize`|ChordPro-Configuration-PDF#configuration-for-pdf-output_papersize]].

### single-space

`--single-space` (short `-a`))

When a lyrics line has no chords associated, suppresses the vertical
space normally occupied by the chords.

Configuration file setting:
[[`settings.suppress-empty-chords`|ChordPro-Configuration-Generic#configuration-file-contents-generic_general-settings]].

### text-font

`--text-font=`_FONT_ (short: `-T`)

Sets the font used to print lyrics and comments.

See also [[ChordPro Fonts|ChordPro-Fonts]].

Configuration file setting: [`pdf.fonts.text`](ChordPro-Configuration-PDF#configuration-for-pdf-output_fonts).

### text-size

`--text-size=`_N_ (short: `-t`)

Sets the font size for lyrics and comments.

Configuration file setting: [`pdf.fonts.text`](ChordPro-Configuration-PDF#configuration-for-pdf-output_fonts).

### user-chord-grids

`--user-chord-grids`

Prints chord grids of all user defined chords used in a song.

Configuration file setting:
[[`diagrams.show`|ChordPro-Configuration-Generic#configuration-file-contents-generic_printing-chord-diagrams]].

### vertical-space

`--vertical-space`=_N_ (short: `-w`)

Adds some extra vertical space between the lines.

Configuration file setting:
[[Spacing|ChordPro-Configuration-PDF#configuration-for-pdf-output_spacing]].

### 2-up

`--2-up` (short: `-2`)

Not supported.

### 4-up

`--4-up` (short: `-4`)

Not supported.

## Configuration options

See [[Configuration files|ChordPro Config]] for details about the configuration
files.

Note that missing default configuration files are silently ignored.
ChordPro will never create nor modify configuration files.

    --sysconfig=*CFG*
        Designates a system specific config file.

        The default system config file depends on the operating system and
        user environment. A common value is "/etc/chordpro.json" on Linux
        systems.

        This is the place where the system manager can put settings like the
        paper size, assuming that all printers use the same size.

    --nosysconfig
        Don't use the system specific config file, even if it exists.

    --nolegacyconfig
        Don't use a legacy config file, even if it exists.

    --userconfig=*CFG*
        Designates the config file for the user.

        The default user config file depends on the operating system and
        user environment. Common values are
        "$HOME/.config/chordpro/chordpro.json" and
        "$HOME/.chordpro/chordpro.json", where $HOME indicates the user home
        directory.

        Here you can put settings for your preferred fonts and other layout
        parameters that you want to apply to all chordpro runs.

    --nouserconfig
        Don't use the user specific config file, even if it exists.

    --config=*CFG* (shorter: --cfg)
        Designates the config file specific for this run.

        Default is a file named "chordpro.json" in the current directory.

        Here you can put settings that apply to the files in this directory
        only.

        You can specify multiple config files. The settings are accumulated.

    --noconfig
        Don't use the specific config file, even if it exists.

    --define=*item*
        Sets a configuration item. *item* must be in the format of
        colon-separated configuration keys, an equal sign, and the value.
        For example, the equivalent of --no-chord-grids is
        --define=chordgrid:show=0.

        --define may be used multiple times to set multiple items.

    --no-default-configs (short: -X)
        Do not use any config files except the ones mentioned explicitly on
        the command line.

        This guarantees that the program is running with the default
        configuration.

    --print-default-config
        Prints the default configuration, and exits.

        The default configuration is commented to explain its contents.

    --print-final-config
        Prints the final configuration (after processing all system, user
        and other config files), and exits.

        The final configuration is not commented. Sorry.

## Miscellaneous options

    --help (short: -h)
        Prints help message. No other output is produced.

    --manual
        Prints the manual. No other output is produced.

    --ident
        Shows the program name and version.

    --verbose
        Provides more verbose information of what is going on.

