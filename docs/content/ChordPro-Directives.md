# ChordPro Directives

ChordPro directives are used to control the appearance of the printed output. They define meta-data like titles, add new chords, control page and column breaks. Therefore it is not always easy to make a distinction between the semantics of a directive, and the way these semantics are implemented in the ChordPro processing program, the _formatter_.

For example, the `title` directive.

    {title: Swing Low Sweet Chariot}

The directive _name_ is ‘title’, and its _argument_ is the text ‘Swing Low Sweet Chariot’. This directive defines meta-data, the song title. That is the semantic part. What the formatter does with this meta-data is up to the program and _not part of the ChordPro File Format Specification_. You can consider directives to be a friendly request, or suggestion, but the actual implementation is left to the formatter. For a meta-data item like the song title it will probably be printed on top of the page and be included in a table of contents, if any.

The [[Chordpro Reference Implementation]] provides a default implementation in the style of the original `chord` program. It can be used as a reference to what a directive is assumed to do. It must however be emphasised that the reference implementation can be configured to use different page styles, fonts, sizes, colours, and so on. Where appropriate, this document refers to the default style.

Many directives have long and short names. For example, the long (full) name for the directive `title` is ‘title’,
and the short (abbreviated) name is ‘t’. It is, however, advised to use the full name whenever possible, since the abbreviations may lead to confusion or ambiguity if new directives are added.

For directives that take arguments, the arguments are separated from the directive name by a colon `:` and/or whitespace.

## Preamble directives

* [[new_song|Directives new_song]] (short: ns)

## Meta-data directives

Each song can have meta-data associated, for example the song title. Meta-data are mostly used by programs that help
organizing collections of ChordPro songs.

* [[title|Directives title]]
* [[subtitle|Directives subtitle]]
* [[artist|Directives artist]]
* [[composer|Directives composer]]
* [[lyricist|Directives lyricist]]
* [[copyright|Directives copyright]]
* [[album|Directives album]]
* [[year|Directives year]]
* [[key|Directives key]]
* [[time|Directives time]]
* [[tempo|Directives tempo]]
* [[duration|Directives duration]]
* [[capo|Directives capo]]
* [[meta|Directives meta]]

## Formatting directives

* [[comment|Directives comment]] (short: c)
* [[comment_italic|Directives comment]] (short: ci)
* [[comment_box|Directives comment]] (short: cb)
* [[chorus|Directives chorus]]
* [[image|Directives image]]

## Environment directives

Environment directives always come in pairs, one to start the environment and one to end the environment.

* [[start_of_chorus|Directives env_chorus]] (short: soc)
* [[end_of_chorus|Directives env_chorus]] (short: eoc)
* [[start_of_verse|Directives env_verse]]
* [[end_of_verse|Directives env_verse]]
* [[start_of_tab|Directives env_tab]] (short: sot)
* [[end_of_tab|Directives env_tab]] (short: eot)
* [[start_of_grid|Directives env_grid]]
* [[end_of_grid|Directives env_grid]]

## Chord diagrams

* [[define|Directives define]]
* [[chord|Directives chord]]

## Fonts, sizes and colours

These directives can be used to temporarily change the font, size and/or colour for lyrics and chords. To permanently change these the reference implementation uses much more powerful [[configuration files|ChordPro Configuration]].

* [[textfont|Directives fonts_sizes_legacy]]
* [[textsize|Directives fonts_sizes_legacy]]
* [[textcolour|Directives fonts_sizes_legacy]]
* [[chordfont|Directives fonts_sizes_legacy]]
* [[chordsize|Directives fonts_sizes_legacy]]
* [[chordcolour|Directives fonts_sizes_legacy]]

## Output related directives

* [[new_page|Directives new_page]] (short: np)
* [[new_physical_page|Directives new_physical_page]] (short: npp)
* [[column_break|Directives column_break]] (short: cb)

The following directives are legacy from the old `chord` program. The modern reference implementation uses much more powerful configuration files for this purpose.

* [[grid|Directives grid_lecacy]] (short: g)
* [[no_grid|Directives grid_lecacy]] (short: ng)
* [[titles|Directives titles_legacy]]
* [[columns|Directives columns]] (short: col)

## Custom extensions

To facilitate using custom extensions for application specific purposes, any directive with a name starting with `x_` should be completely ignored by applications that do not handle this directive. In particular, no warning should be generated when an unsupported `x_`directive is encountered.

It is advised to follow the `x_` prefix by a tag that identifies the application (namespace). For example, a directive  to control a specific pedal setting for the MobilsSheetsPro program could be named `x_mspro_pedal_setting`.
