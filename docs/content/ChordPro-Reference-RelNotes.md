# Release info

## 6.060

Released: 2024-08-24


### Highlights

* Configuration files are now [Really Relaxed JSON](https://metacpan.org/pod/JSON::Relaxed#REALLY-RELAXED-EXTENSIONS) files. These are much easier to write and maintain than JSON. Don't worry, everything is still backward compatible with the older JSON and slightly relaxed JSON formats. And ChordPro can [convert your config files](https://www.chordpro.org/chordpro/using-chordpro/#convert-config) for you.
* Nick Berendsen kindly offered to create a native GUI for macOS. It looks great and behaves nicely in the way macOS applications should behave. And it doesn't have the restrictions on opening and saving of files that the 'classic' GUI suffers from. Thanks Nick!
* ChordPro bundles free replacement fonts to be used instead of the corefonts. No configs or settings needed.

### Functionality

* (PDF, page sort) Use sorttitle for page sorting.
* Images: Ignore align with x percentage. Issue warning.
* Detection of attributes in labels now requires quoting.
* Handle \u escapes for surrogates and extended chars (\u{...}).
* 'chordpro -A -A -A' will produce runtime info in JSON.
* Add '--convert-config' to convert config to new style.
* Add href property for images.
* New metadata: chordpro, chordpro.version and chordpro.songsource.
* Upgrade JSON::Relaxed to 0.096.
* Upgrade SVGPFG to 0.087. Enables transparant SVG images.
* Add independent horizontal and vertical scaling for images. Requires Text::Layout 0.037_002.
* Upgrade Text::Layout to 0.038.
* Allow fret -1 in {define}, and 'x' in json config for consistency.
* Allow pdf.fonts.foo: bar (short for pdf.fonts.foo { description: bar }).
* Allow label="..." for {chorus} and {grid}.
* Add align property for diagram display.

### Bug fixes

* Fix/update docker build.
* Add missing shortcodes sog and eog (start/end of grid).
* Fix paper anchored images being restricted to page size instead of paper size.
* Fix problem that blocked pdf documents from being processed as songs.
* Fixed problems with labels and embedded newlines.
* Fixed newline issues in TextBlocks.
* Fix issue #353, #367, #371, #372, #384, #388, #399, #410.
* Fix spread image handling.
* Fix diagrams.sorted.
* Fix handling of "display"/"format" in config chords.
* Fix problem that text in a TextBlock did not reset to flush left.
* Fix problem TextBlock textstyle did not copy the background colour.
* Fix colours of keyboard diagrams wrt. theme.
* Fix rootless chords with transcode.
* Fix problem with /~ in grid.
* Upgrade to abc2svg fca05cd348 to fix problem with grid widths.
* Fix problem with TextBlock not correctly using desired spacing.
* Fixed --print-{default,final,delta}-config.

### Internal

* New function to deal with property settings for the config.
* Move pp files to separate MANIFEST so they do not clobber the CPAN.

### Social and support

[User community](https://groups.io/g/ChordPro) for feedback and help.  
Please use the [issue tracker](https://github.com/ChordPro/chordpro/issues) for bugs reports.

## 6.050.9

Released: 2024-04-05

* Allow very relaxed JSON format for config files.
* Run with CHORDPRO_JSON_RELAXED=1 in case of emergency.
* Make times/serif and helvetica/sans soft aliases so they can be redefined individually.
* Remove Verdana and Georgia from the list of core fonts. They're not.
* Fix problem with image aligning (see forum 2179).
* Prevent some SVG diagnostics.

## 6.050.8

Released: 2024-03-21

* Use bublath donated a page reordering feature. See https://chordpro.org/chordpro/chordpro-configuration-pdf/#page-reordering
* Improve error message for open failures.
* Improve ppl packaging; add support for debian (static).
* Upgrade ABC2SVG kit to 1.22.14.

## 6.050.7

Released: 2024-02-27


### Functionality

* ABC support will default to QuickJS, either embedded via JavaScript::QuickJS or via an external interpreter. To use another tool, set delegates.abc.program in the config.    
* Substitute alert image for failed delegates.

### Bugfixes

* (Song) Add col alias for columns.
* Fix issue #349.

### Internal

* Modify delegate API.

## 6.050.6

Released: 2024-02-25


### Internal

* Remove ABC kit from kit. It is not license clean.
* Add cmdline.js for external QuickJS.

## 6.050.5

Released: 2024-02-23


### Internal

* Packaging changes and small typo's.

## 6.050.3

Released: 2024-02-22


### Internal

* Packaging changes.

## 6.050.2

Released: 2024-02-21


### Functionality

* Upgraded ABC files to 1.22.13 and repackaged.

## 6.050.10

Released: 2024-04-06

* Upgrade PDF::API2 to 2.045.

## 6.050.1

Released: 2024-02-19


### Functionality

* Upgrade to SVGPDF 0.086.
* New sample song: Molly Malone.

### Internal

* Repackaged ABC files.

## 6.050

Released: 2024-02-09


### Highlights

* Customize the tables of content by providing a template. The template is processed as a song before the tables and can be used to set title, subtitle, columns, maybe even an introduction text. Since the template it iself a song, it can be associated with its own config file for unlimited customization. [Read more...](https://chordpro.org/chordpro/chordpro-configuration-generic/#customizing-the-table-of-contents)
* New delegated environment: textblock. The text between start_of_textblock and end_of_textblock is formatted normally, but the result is an image that can be placed anywhere. Several attributes are available to control the appearance of the text, e.g. centered and flush right. [Read more...](https://chordpro.org/chordpro/directives-env_textblock/)
* Delegate type may now also be 'omit' to omit the content of the section, and 'none' to treat the section a generic. [Read more...](https://chordpro.org/chordpro/directives-delegates/)

### Functionality

* (Experimental) Add environment textblock.
* (Experimental) Add ToC templates.
* Wrap toc lines.
* (PDF) Allow strwidth and strheight to return both values at once.
* (Config) allow delegate types 'none' and 'omit'; remove 'omit' attribute.

### Bug fixes

* Fix issue #265.
* Fix spread indent with labels.
* Fix issue #343.

## 6.042

Released: 2024-01-09


### This is a bugfix release.


### Important

* To trace problems, the ChordPro 'about' information is included in the PDF. This should not reveal sensitive information, but in case this bothers you, you can disable this by setting debug.runtimeinfo to 0 in the config.

### Functionality

* Report XDG_CONFIG_HOME in runtime info.
* Include 'about' info as PDF metadata.

### Bug fixes

* Post-release typo fixes.
* (Stringdiagram) Fix font size of base fret numeral (issue 337).
* (Stringdiagram) Fix fret number colours.
* Fix handling of XDG_CONFIG_HOME.
* Fix 'spread' images.
* Fix problem finding notes:german et al.
* (MMA) Fix test fail with perl >= 5.39.6.

## 6.040

Released: 2023-12-26


### Highlights

* Images can be [placed everywhere](https://chordpro.org/chordpro/directives-image/). They can be placed relative to the paper, the page, the column, and the lyrics.
* Images can be [embedded](https://chordpro.org/chordpro/directives-image/#inline-images) in text (lyrics) lines, either as part of the text similar to a glyph, or somewhere else on the page relative to a particular place in the text. The latter is most interesting for annotations.
* Delegates are images too. Annotate your lyrics with SVG images and musical notes using ABC or Lilypond.
* Chord and keyboard diagrams are images too. And you can use string and keyboard diagrams simultaneously.
* Resources like configs, tasks and images are now more logically searched using [resource libraries](https://chordpro.org/chordpro/resources/).

### ChordPro functionality

* Rework paths handling for consistent resource handling; eliminate App::Packager.
* Inline images.
* {image} can have label and align properties.
* {define}d chords overrules suppress list.
* (ABC) Use QuickJS XS (JavaScript::QuickJS) as preferred.
* (ABC) ABC embedding no longer uses nodeJS (npx).
* (ABC) Make split work (and enable by default).
* (ABC) Images are left aligned by default.
* (Lilypond) Images are left aligned by default.
* Improve runtime info.
* Suppress songs that do not have content.
* Suppress table of content entry for a song w/ {ns toc=no}.
* (PDF) Image scale strategy change for spread images.
* (PDF/Writer) Add generalized add_object for objects and images.
* (PDF) Prevent case problems when looking up fonts for SVG.
* (PDF) Add aliases for web standard fonts like serif, sans, ...
* (PDF) Ignore leading empty and ignores (was: leading empty only).
* (Windows) ChordPro now installs as a 64-bit application in \Program Files instead of \Program Files (x86). You are adsvised to remove the old 32bits install first.

### Bug fixes

* Prevent warning when parsing {key} and trancode to nashville/roman.
* Fix chord inversion (issue 321).
* Fix comment lines disturbing a consecutive series of {chord}s.
* Fix typo in Wx Preferencesdialog, causing it to crash.
* Fix problem with PDF/SVG caching fonts.
* Fix comment labels for delegates (issue 329.3).
* (Wx) Filter configs on prp ans json.
* Fix memorize/recall/transpose issue 333.
* Fix issue 334.

### Internal

* (ABC) ABC embedding use tohtml instead of toxhtml.
* (PDF) Enhance assets (wip), labels; move grid to separate module.
* Experimental ##include facility.

## 6.030

Released: 2023-09-18


### Highlights

* [ABC](https://www.chordpro.org/chordpro/directives-env_abc/) and [Lilypond](https://www.chordpro.org/chordpro/directives-env_ly/) embedding now use SVG (vector graphics) instead of pixmap images. This is very crisp at all sizes, and greatly reduces the size of the resultant PDF document.  
  No additional tools are required for embedding, except the `abc2svg` and `lilypond` tools. The installer kits for MS Windows and MacOS already include the `abc2svg` tool.
* The ChordPro GUI (`wxchordpro`) has been extended with a Tasks menu that can be used to quickly select presets for a specific task. For example, to produce a PDF with only lyrics, or with keyboard diagrams instead of string diagrams. User presets can be added by placing small config files in a `tasks` folder under the `CHORDPRO_LIB`.

### ChordPro functionality

* Directives and config to change the [chorus appearance](https://www.chordpro.org/chordpro/directives-props_chorus_legacy/).
* Add support for SVG images. Allow `pdf.fonts.XXX` as fonts in SVG.
* Handle ABC and Lilypond embedding via SVG images. No more need for ImageMagick. Add 'staffsep' option for ABC embedding.
* Add 'omit' to delegates config.
* Infer chord inversions for keyboard.
* Use SVGPDF text callback to substitute missing flat/sharp glyphs.
* Trap missing font sizes (should not happen).

### Breaking changes

* The image scale strategy was changed to be more intuitive. See [this forum message](https://groups.io/g/ChordPro/message/1846) for details.

### Experimental

* A primitive but effective docker based web app.

### BugFixes

* Fix issue #297.
* Fix issue #298.
* Fix issue message/1780.
* Fix issue #300.
* Fix issue #301.
* Fix issue #309.
* Fix issue #311.

## 6.020

Released: 2023-07-21


### ChordPro functionality

* New directive diagrams obsoletes grid/no_grid with more possibilities, Based on a suggestion and concept implementation from Jörg Bublath.
* Images without directory can be looked up in CHORDPO_LIB.
* Turn pseudo-chords like | and spaces into annotations.

### BugFixes

* Fix a number of problems with define/copy/copyall.
* Fix issue #293.

### Internal

* Bump minimal perl version to 5.26 and add Object::Pad to dependencies.
* Change namespace App::Music::ChordPro to ChordPro.
* Put VERSION on single line for stupid tools.
* Upgrade ChordPro::Chords::Appearance to class.
* Enhance Parser to use signatures to catch call errors.
* Enhance Config to use signatures to catch call errors.
* Enhance Chords to use signatures to catch call errors.
* Enhance Utils to use signatures to catch call errors.

## 6.010

Released: 2023-06-05


### ChordPro functionality

* Allow line continuation for input lines using a backslash.
* Allow define chord "|" in config.
* Allow graceful handling of rootless chords.
* Allow simple markup in chords. Yes, this includes grid chords.
* Add flags for preprocessor pattern replacements.
* Allow image scale as a percentage.
* Experimental: Absolute placement for images.
* Experimental: Diagram control in {define}.
* Remove diagrams.auto from config.

### BugFixes

* Add Pod::Usage to required modules. Some distros seem to have removed it from the core.
* Add jpeg library to MacOS kit.
* Add some missing files for docs building.
* Fix root relocation when transcoding to a movable system.
* Fix missing parser in {define XX} without frets etc.
* Fix forum 1696 (chord recall with trans{code,pose}).
* Fix issue #269 (problem with page labels).
* Fix issue #270 (PDF outlines issues, 'letter' setting).
* Fix issue #273 (PDF CreationDate string is not conformant, but PDF::API2 2.042+ rejects conformant strings).

## 6.000

Released: 2022-12-28


### ChordPro functionality

* Chord finger settings can be suppressed with pdf.diagrams.fingers.
* (Experimental) Add line selection to preprocessor.
* Remove * for user defined chords.

### BugFixes

* Fix issue 259.
* Fix issue 260 (chords not being handled correctly in comments).
* Fix issue 260 (suppress diagrams and grids when lyrics-only).
* Fix issue 261 (truesf not functional beyond chord root).

## 5.990

Released: 2022-11-03


### BugFixes

* Fix erroneous error message when pdf.formats.default.title (cs) is [].
* Fix compatibility problems with PDF::Builder.
* Fix page labels for PDF::API2 >= 2.041.
* Eliminate potential splice warning with pagealign-songs.
* Fix resize preferences window.
* Fix problem with copied chords not being registered as agnostic.

## 5.989

Released: 2022-10-21


### ChordPro functionality

* Verify configs (and fix if possible).
* Enhance ToC sorting, unlimited keys, numeric and reverse sorting.
* Warn if X: is missing in ABC content.
* Add volta for grid.
* Add display for {define}.
* Replace TAB characters by a single space on input.
* Support building installer with MacOS homebrew perl.
* Allow empty chord defines (just the name) to make the chord known.
* Allow front-matter and back-matter in the config and filelist.
* (Experimental) Allow PDF filenames in the filelist.
* (Experimental) Allow multiple chords in a grid cell.

### Miscellaneous

* Luke Pinner contributed a nice search feature for our doc pages.

### BugFixes

* Fix problem that toc columns overlapped lefter columns.
* Fix some problems with {define}.
* Fix some more problems with {define}.
* Fix automatic replacement of apostroph (prime) by friendly quote.
* Fix crash when auto-adding an unknown chord.
* Only print user chords when diagrams.show=user.
* Make base optional in json chords (part of fix 234).
* Modern3 style now has keyboard diagrams at the right. See issue 236.
* (PDF) Print chorus tag if there's no chorus to rechorus.
* Fix regression with pagealign = 2.
* Fix issue 222.
* Fix issue 223.
* Fix issue 224.
* Fix issue 226.
* Fix issue 234.
* Fix issue 237.
* Fix issue 239.
* Fix issue 250.
* Fix issue 251.
* Fix issue 253.
* Fix issue 255.

## 5.988

Released: 2022-05-17


### ChordPro functionality

* Automatically use real sharps and flats in chord names. Fallback to the ChordProSymbols font if the font doesn't have the appropriate symbols.
* Add settings.truesf (default: false) to enable/disable this.
* Allow settings.* to be used in %{} substitutions.
* Add meta chords and numchords (list/number of chords used).
* Add config pdf.spacing.diagramchords.
* Allow meta values for directive selectors.
* Re-enable agnostic chord lookup.
* (Wx)(MacOS) Improve prefences dialog.
* Several ABC fixes/improvements.
* (PDF) Add support for background document.
* Markdown export (EXPERIMENTAL). Thanks to Johannes Rumpf.
* LaTeX export (EXPERIMENTAL). Thanks to Johannes Rumpf.

### BugFixes

* Fix issue #208.
* (Wx) Fix sharps/flats mixup in PreferencesDialog.

## 5.987

Released: 2022-02-08


### ChordPro functionality

* Conditional directives can be negated with a trailing !
* (Wx)(MacOS) Improve prefences dialog.

### BugFixes

* Add File::HomeDir to dependencies.
* Fix issue #204.

## 5.986

Released: 2022-02-02


### ChordPro functionality

* (Config) Theme colors foreground-medium and foreground-light.
* Show cell bars in grid lines (Config: pdf.grids)
* Suppress warnings for empty chords (i.e., [   ] spacers).
* Add error message when font name is not a built-in.
* Allow custom PDF meta data. Requires PDF::API2 2.042.
* Allow meta split on separator.
* Add settings.inline-annotations.
* Add settings.chords-canonical to use canonical representation for chords.
* Rework chords lookup to always use chordsinfo.
* Use chord objects for show and display.
* (GUI) Allow selection of custom library.
* (PDF) Allow multi-line headings and footers.
* (PDF) Configurable PDF library.
* (PDF) Provide meta %{pages} for headings.
* Allow (uppercase) letters for chord fingers.
* (Wx) Overhaul preferences management.
* Support center and scale for lilypond.
* Add config settings.choruslabels for MSPro convenience.

### BugFixes

* Remove obsolete __EMBEDDING__.
* Bump requirement Text::Layout to 0.024.
* Fix issue #182.
* Fix warning if diagrams.show=user and no chords.
* Fix labels for grid with pdf.labels.comment.
* Fix key_actual and key_from to reflect all keys.
* Fix tilde expansion for font files.
* (PDF) Suppress borders around ToC entries, just in case.
* Fix sorttitles field name in CSV export.
* Fix issue #194.
* Fix issue #195.
* Add workaround for incompatible pagel labels change in PDF::API 2.042.
* Fix placement of finger dots.
* Fix handling of NC chords.
* Fix config loss problem with '{+pdf...}'. 

## 5.985

Released: 2021-09-28


### ChordPro functionality

* Change config preset lookup algorithm and document it.
* (docs) First 'hints and tips' contributed by xeruf.
* (PDF) Suppress empty chorus recall tag.

### BugFixes

* Remove obsolete code from Makefile.PL and GNUmakefile.
* Fix issue #175.

## 5.983

Released: 2021-09-24


### ChordPro Syntax

* (docs) Add transpose directive.

### ChordPro functionality

* (Songbook) Allow whitespace between curly and directive in a2crd detection
* (GUI) Add --maximize command line option.
* Allow song-specific configs to have includes.
* Add --no-songconfig to ignore song specific configs.
* Add --reference to defeat configs and other fun.

### BugFixes

* Prevent wrapping loop with long comment with chords.
* Fix Can't locate object method "reset_parsers" (Songbook).
* Fix colour default with {xxxcolor}.
* Prevent havoc when pdf.chorus.recall.type has illegal values.
* (ChordPro/MSPro) Fix missing meta in substitutions. 
* Fix incomplete chord warning for {chord x}.
* Fix issue #132.
* Fix issue #163.
* Fix issue #165.
* Fix issue #178 (non-ascii filenames on Windows).

## 5.982

Released: 2021-08-31


### ChordPro functionality

* Add --strict option to enforce conformance to ChordPro standard. Enabled by default, may be disabled with --no-strict.
* Add/update misc. files for desktop systems.

### BugFixes

* Incorporate Data::Properties instead of using the CPAN version, since this version is incompatible.

## 5.981

Released: 2021-08-23


### ChordPro Syntax

* Add Cheat Sheet with ChordPro syntax and availability.

### ChordPro functionality

* Document properties for the PDF can be supplied in the config file.

### BugFixes

* Fix issue #159.

## 5.980

Released: 2021-08-14


### ChordPro functionality

* Bump version to 5.xxx moving towards 6.0.
* Setting config value pdf.pagealign-songs to a value greater than 1 will force the resultant PDF to have an even number of pages.
* Add warning when chord diagram exceeds the diagram size.
* Do not complain about unknown meta data.
* Add numbercolor property for chordfingers chord.
* Add baselabeloffset property for chords.
* Config settings that have corresponding command line options are always overridden when the command line option is used.
* Add preprocessing for directives.
* Preprocessing 'all' may result in multiple lines.
* Experimental 'choruslike' property for pdf.chorus.recall.
* Add clo --noa2crd to suppress autoconversion.
* Improve page labeling and aligning.
* Config pdf.csv.songsonly controls whether matter pages are included in the CSV. 
* Add warning if no songs were found in the input.
* Simplify README.md.
* Add ChordPro history doc.

### BugFixes

* Fix crash when no chords.
* Fix case insensitive matching of directive selectors.
* Fix issue #145.
* Allow {define} and {chord} to take multi-digit fret/finger positions.
* Fix background drawing for finger positions.
* Fix "Modification of a read-only value attempted" crash when instrument or user get nulled.
* Fix %{pageno} vs. %{page} confusion.
* Do not tamper with ABC content. E.g., adding K: has side-effects.
* Fix issue #148.
* Fix issue #149.
* Fix issue #158.

## 0.979

Released: 2021-07-09


### ChordPro syntax

* {define ...} can take key definitions for keyboards.
* All directives can be selected out by appending -XXX, where XXX is the type of instrument or a user name.

### ChordPro functionality

* (musejazz) Change font to MuseJazzText.otf as downloadable from GitHub.
* Improve error messages for font files not found.
* Default CHORDPRO_LIB to ~/.config/chordpro, if present.
* Experimental: Allow delegates to specify image type.
* Allow variable expansion on all input lines.
* Experimental support for preprocessing.
* Experimental support for song-specific configs.
* Support for keyboard diagrams.
* Experimental support for metadata in filelist.
* Add --print-delta-config option.
* Suppress outline title if there is only one outline.
* Allow meta data definitions in config.
* Remove support for legacy configs.
* Suppress a directive if its argument is empty as result from %{} expansion.
* Add directive suppression with instrument/user selectors.

### BugFixes

* Fix crash when abc section is the very first thing in a song.
* Fix decapo setting from config file (issue #140).

## 0.978

Released: 2021-03-05


### ChordPro functionality

* Allow array element addressing in --define.
* Retain line numbers for backend diagnostics.
* Experimental support for ABC.
* Experimental support for MacOS.
* New icons.
* Windows: Installer associates ChordPro with .cho files.
* Linux: Support for desktop and app icons.
* Linux: Support building an AppImage.
* Restore section label as comment (config: pdf.labels.comment).
* Add experimental MMA backend.
* Add metadata "today".

### Bugfixes

* Fix chords transpose in comments with output ChordPro.
* Fix detection of grid params in start_of_grid.
* Fix problem with path name in start menu after windows install.

## 0.977

Released: 2020-08-26


### ChordPro functionality

* Add CSV columns for sorttitle artist composer collection key year.

### Bugfixes

* Raise requirement for Text::Layout to 0.019.
* Use only 'name' for chords in the built-in config. 'description' cannot be overridden by the user with 'name'.
* Fix page numbers in CSV.
* Several fixes for font descriptions and sizes.

## 0.976

Released: 2020-08-16


### Bugfixes

* Fix markup defragmentation (#111)
* Fix page numbers in CSV.
* Fix problem that --no-toc was not honoured.
* Fix a2crd crash (#115)

## 0.975

Released: 2020-08-13


### ChordPro syntax

* Support Pango style markup language.
* Add basic support for annotations.
* Add directives start/end_of_verse/bridge and short forms.

### ChordPro functionality

* Add PDF outlines (bookmarks).
* Revamp table of contens (finally).
* Remove section handling (we now have labels).
* Allow ~ expansion in file names.
* Allow relaxed parsing of chords (root name  
  arbitrary).
* Allow parsing of notes (chords with only a lc root name).
* (Wx) Show filename in window title.
* (Wx) Show asterisk if file is modified.

### ChordPro configuration

* Add split marker to be inserted between text phrases when the chord is wider than the phrase.
* Add settings.suppress-empty-lyrics to suppress blank lyrics lines.
* Add display property to chords to control the way they are displayed.
* Add guitar-br.json with Brandt-Roemer compliant chord symbols.
* Add meta variable songindex.
* Add metadata sorttitle.
* Add config settings for HTML backend.
* Add font properties in fontconfig settings.
* Add settings for chordnames and notenames.

### Bugfixes

* Fix interpretation of directives and markup in tab sections.
* Fix bug where some command line arguments did not properly support utf8.
* Fix handling of {chorus: label}.
* Fix problem where using a {chord} directive before any song lines would crash.
* Fix problem where the tag of a grid was ignored.
* Do not indent chorus labels when chorus indenting (issue #81).

### Miscellaneous

* Use Text::Layout to support Pango style markup language.
* Use File::LoadLines.
* Upgrade requirement for PDF::API2 to 2.035, Font::TTF to 1.05, Text::Layout to 0.014.
* Packaged version no longer loads default config from chordpro.json. It is now really built-in.
* Change CHANGES to Changes.

## 0.974

Released: 2019-10-05

* Restructure chord definitions. Default is now an orthogonal set of basic chords. Additional legacy weirdo's are available in "guitar-legacy.json".
* Allow chord definitions with multiple names. See the docs.
* Add chord types add2 and add4.
* Fix erroneous transposing of transcoded chords.
* Fix erroneous recall of chorus from previous song.
* Fix missing fret positions in {chord}.

## 0.973

Released: 2019-03-13

* Integrate a2crd into chordpro. Use "chordpro --a2crd" to invoke.
* Add --decapo option to eliminate {capo} settings by transposing.
* Implement image assets. Requires IO::String and Image::Info.
* Implement a basic form of line wrapping (regular chords+lyrics).
* Implement a basic form of line wrapping (comments and non-chords lyrics).
* Implement user library (env. var. CHORDPRO_LIB). Experimental.
* Allow a2crd as a filter.
* Use label instead of section name, if provided.
* Make instrument and tuning accessible as meta data.
* Fix undefined if no output file was supplied.
* Fix section change detection.
* Fix crash when chordless songline and not suppress-empty-chords.
* Fix misplacement of diagrams when columns and too many {chord} directives.
* Fix printing of auto-added chords.
* Fix issue #63: Labels are lost when a new song is encountered.
* Fix crash when --dump-chords and no meta.
* (PDF) Fix label width.

## 0.972

Released: 2018-11-06

* Add a2crd script.
* Minimize all configs to only override what is necessary.
* Split german notes into scandinavian (..., A, Bb/A#, H, C) and german (..., A, Ais/B, H, C).
* Use String::Interpolate::Named.
* (Experimental) Allow %{..} interpolations on the output file name, e.g. --output="%{artist|%{} - }%{title}.pdf". Command line only.
* Fix memorize problem with the first chord.
* Upgrade WxChordPro to 0.972.

## 0.97.1

Released: 2018-10-24

* Upgrade WxChordPro to 0.970 to fix problem with custom config.

## 0.97

Released: 2018-10-23

* Instrument defintions are now in separate config files. There are no 'built-in' tunings and chords, just defaults. Available instrument configs are guitar, guitar-ly, mandolin-ly, and ukulele-ly. Default is guitar.
* Chords parsing has been completely overhauled.
* Config file handling has been completely overhauled.
* Alternative note naming systems, e.g. Latin (Do Re Mi ...) and Solfege are now supported.
* Experimental: Chords can be transcoded between note naming systems.
* Chords can be shown under the lyrics, controlled by config item settings.chords-under.
* Nashville and Roman chord systems need to be explicitly enabled.
* Allow meta substitutions in title and subtitle.
* Fix {transpose}, --transpose and {key} interaction.
* Experimental: Chords can be recalled from previous sections using [^] or plain ^. Requires config setting settings.memorize.
* Upgrade WxChordPro to 0.960_059.
* Add config settings for ChordPro backend.
* Add slash as grid symbol.
* Allow labels for grids.
* Show durations as hh:mm.
* Fix grey background of comment_italic.
* Add font "label" for section labels. Defaults to text font.
* Fix section labels when the first line is not a song line.
* {chorus} Do not print Chorus tag when quoting.
* {chorus} Allow label.
* Allow empty comment directives.
* Do not print background for empty strings.

## 0.96

Released: 2018-07-11

* (pp/linux/GNUmakefile) Verify we're running the right perl.
* Upgrade to App::Packager 1.43.
* Fix transpose of Asus and Esus chords.
* Fix issue #47 by Increasing base fret limit to 23.
* Fix error handling with illegal chord definitions.
* (wxChordPro) Fix file saving logic.
* Experimental: Markup for song sections.
* Experimental: All fonts can have background and frame.

## 0.95

Released: 2018-06-04

* Add (derived) meta item _key to reflect the actual song key, taking capo setting into account.
* Allow {comment} without background colour.
* Make {comment_box} box the same colour as its text.
* Warn if multiple {capo} settings.
* Fix problem that chords in grids were not transposed.
* Add value "auto" for pdf.labels.width to automatically reserve margin space when labels are used.
* Fix problem that titles-directive-ignore was ignored.
* (PDF) Fix problem that toc entries were not clickable.
* Fix issue #41 - Error in transposition of a recalled chorus.
* Fix issue #42 - Defining Chords Fails for Songbooks. Song chord definitions were lost in multi-song songbooks except for the last (or only) song.
* Fix schema validation for configs.

## 0.94

Released: 2018-01-23

* Allow \ { } and | to be escaped with \ in replacement strings.
* Fix problem that in-song chords caused CANNOT HAPPEN error.
* Add --filelist option to read song file names from files.
* Fix inconsistent handling of --lyrics-only in backends.
* Add html to list of recognized output types (even though experimental). Note that the HTML backend is not yet included.
* Fix Chord/Chordii regression: Base frets in chord diagrams should be arabic numbers, not roman.
* Pass unknown directives through to backends.
* Fix labels handling for ChordPro output.
* Fix problem that bass notes in chords were not transposed.

## 0.930.1

Under development

* (pp/windows) Add PDF::API2::Bundle to make sure all PDF::API2 and TTF::Font modules are included.

## 0.93

Released: 2017-12-07

* Fix transposition of chord diagrams.

## 0.92

Released: 2017-12-07

* Add configurable sort methods for table of contents. Config option: toc.order, values "page" or "alpha". Default is "page". Config option: toc.title, default "Table of Contents". Supersedes pdf.formats.default.toc-title.
* Fix JSON problem with loading UTF8 config files.
* Fix the need for a bogus file argument when dumping chords.
* Experimental support for indenting and margin labels.
* Obsolete pdf.diagramscolumn in favour of pdf.diagrams.show. This can be top, bottom, right of the first page, and below, following the last song line.
* Provide song source for unknown chords message.
* Handle UTF-8 encoded filenames correctly.
* Implement in-line printing of chords, config: settings.inline-chords. Add style 'inline'.
* Fix problem with font restore after {textfont} cs.
* Fix problem that trailing empty lines were discarded.
* Fix final line discard if input is not newline terminated.
* Fix issue#31 (textsize directive with percentage raises error).
* Fix problem where first empty line was inadvertently ignored.

## 0.910.1

Released: 2017-11-09

* Add style 'modern3'.

## 0.91

Released: 2017-11-09

* Add printing of bars in chord diagrams.
* Allow PDF config "fontdir" to take an array of paths. Also, allow the path elements to be a colon-(Windows: semicolon)-separated list of paths.
* Add PDF config "diagramscolumn". This will have the song chord diagrams printed on the first page, in a side column. Experimental.
* Fix problem with misnumbered fingers in non-builtin chords.
* Fix problem with restoring defaults for {textsize} and friends.

## 0.90

Released: 2017-10-17

* Fix dependencies in Makefile.PL.
* Do not mark config defined chords as being user defined.
* Fix some problems with '{chord}' chords.

## 0.89

Released: 2017-09-22

* Add {transpose} directive.
* Transpositions and metadata substitutions are now handled at parse time.
* Update built-in documentation.
* Upgrade WxChordPro to 0.89.
* Fix problem with locating manual page.
* Normalize CHANGES according to CPAN:Changes::Spec.

## 0.88

Released: 2017-09-11

* Put the Table of Contents (if any) at the beginning.
* Fix a bug that caused no TOC to be produced with multiple song input.
* Add --csv command line option to request writing the CSV.
* Add --cover command line option to prepend cover pages.
* Improve JSON config validation.

## 0.87

Released: 2017-09-04

* Fix problem where songlines without chords yielded empty lines in the ChordPro backend after transposition.
* Allow "-" as filename for standard input.
* Handle Byte Order Mark in input files.
* (ChordPro) Do not use {meta} for known meta keys.
* (Windows) Handle version number setting in iss file.

## 0.860.1

Released: 2017-08-18

* Fix test failures with PDF::Builder 3.004, issue https://rt.cpan.org/Ticket/Display.html?id=122815 .

## 0.86

Released: 2017-08-16

* Fix problems with disappearing page titles.
* Fix some packing issues.

## 0.85

Released: 2017-08-15

* Rename config pdf.fonts.diagram_capo to pdf.fonts.diagram_base.
* Fix some (well, several) layout issues with odd/even page printing.
* Fix missing fingers in config defined chords.
* Allow PDF::Builder to be used instead of PDF::API2.
* Improve define/chord parsing and diagnostics.
* (WxChordPro) Update to 0.84.

## 0.84

Released: 2017-07-31

* Emergency fix for PDF font problem.

## 0.83

Released: 2017-07-31

* Supply default '1+4x4+1' for first start_of_grid.
* Supply default straight font for grid lines.
* Allow empty lines in grids.
* Improve WxChordPro integration.
* Change old terminology "chordgrid" to "diagrams".
* (WxChordPro) Update to 0.83.

## 0.82

Released: 2017-07-21

* Add Version.pm.

## 0.81

Released: 2017-07-16

* Fixed problem where wxChordPro couldn't preview.
* Restructured the files for packaging support.

## 0.80

Released: 2017-07-13

* (PDF) Improve terminology in warning about unkown chords.
* Prevent undefined warnings when a song has no chords.
* (pp) Allow resource updating.
* Prevent undefined warnings when the system provides no configs.
* Add missing POD resources for packaged binaries.
* Supply usage info and exit when run without action/file arguments.

## 0.79

Released: 2017-07-12

* Mostly packing/packaging fixes.
* (WxChordPro) Update to 0.79.

## 0.78

Released: 2017-07-12

* Mostly packaging fixes.
* (WxChordPro) Update to 0.78.

## 0.77

Released: 2017-06-26

* Finalize design and implementation of chord grids.
* Add support for chord fingerings, as suggested by Christian
* Erickson (author of the Songsheet Generator).
* Fix meaning of clo -G (was negated).
* Add song examples.
* (WxChordPro) Update to 0.76.

## 0.76

Released: 2017-05-16

* Allow text properties to stack/unstack.
* Suppress empty text line if there's only [Chords].
* Enhance parameter substitution in titles/comments.
* Allow {chord NAME} to designate known chords.
* Some more fix problems with dot-less @INC in newer perls.
* Add schema to verify (and edit) json config files.

## 0.75

Released: 2017-04-13

* Experimental support for Nashville Numbering System and Roman
* Numbered Chords.
* (Config) Add more meta data: lyricist, arranger, copyright, year, duration.
* (PDF) Improve grids drawing: add config for line thickness, add space for the crosses/circles.
* (PDF) Allow PDF to be written to standard output. Output file will now be named after the input file if there's only one.
* Keep track of #-comments in ChordPro input and reproduce in
* ChordPro output.
* (PDF) Fonts are now looked up in a font path consisting of the fontdir config setting, the application's fonts resource
* directory, and the value of environment variable FONTDIR.
* (Packager) Use App::Packager from CPAN.
* (WxChordPro) Update to 0.74.

## 0.74

Released: 2017-04-02

* Fix problems with dot-less @INC in newer perls.

## 0.73

Released: 2017-04-04

* (WxChordPro) Update to 0.710.3.

## 0.72

Released: 2017-01-18

* (WxChordPro) Update to 0.710.2.
* Fix style_chordii sample config.

## 0.71

Released: 2017-01-17

* Produce CSV with PDF and toc.
* Implement {chord...} directive.

## 0.70

Released: 2016-11-10

* (ChordPro) Fix require of Common.
* (Config) Comment example chord definition.
* (ChordPro) Add rechorus handling.
* (ChordPro) Fix --toc/--notoc command line option.
* (PDF) Fix background colour in indented chorus.
* (PDF) Fix wrong headspace on continuation pages.

## 0.69

Released: 2016-09-29

* Add parser tests.
* Prevent nasty errors when transposing unknown chords.
* (PDF) Fix comment decorations that were off due to substituting metadata.
* (ChordPro) Add msp as output variant.

## 0.68

Released: 2016-08-23

* Extend chorus recall. Chorus may be quoted, and/or referred with a tag text.
* Handle {pagesize} in legacy config.
* Minor adjustments to the default configuration to match the documentation.

## 0.67

Released: 2016-08-23

* Overhaul of chord definitions and transpositions.
* Chords may now be parenthesised.
* {defined: name ...} is now preferred.
* "base-fret NN" may be omitted.
* All strings may be omitted to define an unknown chord.

## 0.66

Released: 2016-08-22

* Uploaded to GitHub.
* Added support for {meta} directives.
* Make the list of known metatada configurable.
* Allow using metadata in titles and comments.
* Remove meta-mapping (no longer needed).
* Change the way unknown chords are dealt with, for
* Chord/Chordii compatibility.
* Add res/config/style_chordii.json with as much Chord/Chordii compatibility as can be reasonably achieved.

## 0.65

Released: 2016-07-15

* Add --define to set config items from the command line.
* Smooth some config trickeries.
* Add meta-map config to treat metadata items differently.
* Normalize directives parsing to be (more) Chord/Chordii compatible.
* Handle defining chords with flexible number of strings.

## 0.64

Released: 2016-07-10

* Add support for Chord/Chordii legacy config.
* Add --no-legacy-config to suppress legacy config.
* Add --no-default-configs (-X) to suppress all default configs.
* Do not make "no easy chords" default.
* More pp stuff.

## 0.63

Released: 2016-07-06

* Add support for {grid} and friends.
* More pp stuff.

## 0.62

Released: 2016-07-03

* Improve support for PAR packaging.
* Add Undo/Redo (MSW only?).
* Better viewer launching.
* Use separate PODs for --manual and --help-config.
* Add wxchordpro to the kit.

## 0.61

Released: 2016-06-28

* Improve packaging.
* Add support for PAR packaging.

## 0.60

Released: 2016-06-23

* Bring chorus layout attributes under a single topic.
* Add chordgrid and chordgrid_capo chords.

## 0.59

Released: 2016-06-23

* We have a Ukulele.
* And a GUI.

## 0.58

Released: 2016-06-20

* Handle --chord-grid-size.
* Add chord definitions in configuration.
* Add chords sorting.
* Add user defined chords and tunings.
* Handle --no-easy-chord-grids and --chord-grids-sorted.

## 0.57

Released: 2016-06-19

* Move transpose code to Chords module.
* Default grid font to comment, not font.
* Register user defined fonts.
* First shot at printing chord grids.
* Second shot at printing chord grids.
* Support -D, but use backend to generate the grids.

## 0.56

Released: 2016-06-13

* Handle {titles} directive.
* Add support for head-first-only. Titles are now top-printed.
* Move low-level primitives to PRWriter module.
* Add font and spacing for 'empty' lines.

## 0.55

Released: 2016-06-10

* Detailed page headers/footers control.
* Require perl version v5.10.

## 0.54

Released: 2016-06-08

* Fix bug #115156: Will not build on Mac OSX.
* Fix bug #115159: IO::File is not loaded automatically in older perls ( < 5.12.6 ).

## 0.53.1

Released: 2016-06-08

* Improve Makefile.PL to get indexing right.

## 0.53

Released: 2016-06-07

* Add built-in chords and the --dump-chords-text facility.
* (PDF) Turn missing images into a comment.

## 0.52.6

Released: 2016-06-07

* Fix POD problem in Config.pm.

## 0.52.5

Released: 2016-06-07

* Improve Makefile.PL to get indexing right.

## 0.52.4

Released: 2016-06-06

* Improve Makefile.PL.

## 0.52.3

Released: 2016-06-06

* Move configuration pod to Config.pod. Will it be indexed?
* Add --print-default-config and --print-final-config options.
* Fix problems with songline colours.
* Fix headings.
* Add head-first-only setting.
* Fix page footers.

## 0.52.2

Released: 2016-06-06

* Minor documentation changes.

## 0.52.1

Released: 2016-06-05

* Some fixes for tests on Windows.

## 0.52

Released: 2016-06-05

* Move runnable code from chordpro script to ChordPro.pm module. The script is now a simple wrapper.
* Add documentation.

## 0.51.3

Released: 2016-06-05

* Eliminate Clone as a dependency.
* Eliminate IO::String as an explicit dependency. It's implied by Font::TTF.

## 0.51.2

Released: 2016-06-04

* Better Makefile.PL (no_index of namespace).

## 0.51.1

Released: 2016-06-04

* Better Makefile.PL.

## 0.51

Released: 2016-06-04

* First alpha version released.

