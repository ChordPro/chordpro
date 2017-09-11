# Using ChordPro

First of all, please read the
[[Getting Started|ChordPro-Getting-Started]] page.

![](images/maintenance.png)

## General command line options

### about

`--about` (short: `-A`)

Prints version information about the ChordPro program. No other processing will be done.

### config

`--config=`_JSON_ (shorter: `--cfg`)

A JSON file that defines the behaviour of the program and the layout
        of the output. See App::Music::ChordPro::Config for details.

This option may be specified more than once. Each additional config
        file overrides the corresponding definitions that are currently
        active.

### encoding

`--encoding=`_ENC_

Specifies the encoding for input files. Default is UTF-8. ISO-8859.1
        (Latin-1) encoding is automatically sensed.

### lyrics-only

`--lyrics-only` (short: `-l`)

Only prints lyrics. All chords are suppressed.

Useful to make prints for singers and other musicians that do not
        require chords.

### no-toc

`--no-toc`

Suppresses the table of contents.

See [`toc`](#toc).

### output

`--output=`_FILE_ (short: `-o`)

Designates the name of the output file where the results are written
        to.

The filename extension determines the type of the output. It should
        correspond to one of the backends that are currently supported:

* pdf  
Portable document format (PDF).

If a table of contents is generated with the PDF, ChordPro
              also writes a CSV file containing titles and page numbers.
              This CSV file has the same name as the PDF, with extenstion
              "pdf" replaced by <csv>.

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

    --transpose=*N* (short: -x)
        Transposes all songs by *N* semi-tones. Note that *N* may be
        specified as +*N* to transpose upward, using sharps, or as -*N* to
        transpose downward, using flats.

    --user-chord-grids
        Prints chord grids of all user defined chords used in a song.

    --version (short: -V)
        Prints the program version and exits.

## Chordii compatibility options

    The following Chordii command line options are recognized. Note that not
    all of them actually do something.

    Options marked with * are better specified in the config file.

    --text-font=*FONT* (short: -T) *
        Sets the font used to print lyrics and comments.

        *FONT* can be either a full path name to a TrueType font file, or
        the name of one of the standard fonts. See section "FONTS" for more
        details.

    --text-size=*N* (short: -t) *
        Sets the font size for lyrics and comments.

    --chord-font=*FONT* (short: -C) *
        Sets the font used to print the chord names.

        *FONT* can be either a full path name to a TrueType font file, or
        the name of one of the standard fonts. See section "FONTS" for more
        details.

    --chord-size=*N* (short: -c) *
        Sets the font size for the chord names.

    --chord-grid-size=*N* (short: -s) *
        Sets chord grid size (the total width of a chord grid).

    --chord-grids
        Prints chord grids of all chords used in a song.

    --no-chord-grids (short: -G) *
        Disables printing of chord grids of the chords used in a song.

    --easy-chord-grids
        Not supported.

    --no-easy-chord-grids (short: -g)
        Not supported.

    --chord-grids-sorted (short: -S) *
        Prints chord grids of the chords used in a song, ordered by key and
        type.

    --no-chord-grids-sorted *
        Prints chord grids in the order they appear in the song.

    --even-pages-number-left (short -L)
        Prints even/odd pages with pages numbers left on even pages.

    --odd-pages-number-left
        Prints even/odd pages with pages numbers left on odd pages.

    --page-size=*FMT* (short: -P) *
        Specifies page size, e.g. "a4" (default), "letter".

    --single-space (short -a)) *
        When a lyrics line has no chords associated, suppresses the vertical
        space normally occupied by the chords.

    --vertical-space=*N* (short: -w) *
        Adds some extra vertical space between the lines.

    --2-up (short: -2)
        Not supported.

    --4-up (short: -4)
        Not supported.

    --page-number-logical (short: -n)
        Not supported.

    --dump-chords (short: -D)
        Dumps a list of built-in chords in a form dependent of the backend
        used. The PDF backend will produce neat pages of chord diagrams. The
        ChordPro backend will produce a list of "define" directives.

    --dump-chords-text (short: -d)
        Dumps a list of built-in chords in the form of "define" directives,
        and exits.

## Configuration options

    See App::Music::ChordPro::Config for details about the configuration
    files.

    Note that missing default configuration files are silently ignored.
    Also, chordpro will never create nor write configuration files.

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

