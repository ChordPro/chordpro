---
title: "ChordPro directives"
description: "ChordPro directives"
---

# ChordPro directives

ChordPro directives are used to control the appearance of the printed output. They define meta-data like titles, add new chords, control page and column breaks. Therefore it is not always easy to make a distinction between the semantics of a directive, and the way these semantics are implemented in the ChordPro processing program, the _formatter_.

For example, the `title` directive.

    {title: Swing Low Sweet Chariot}

The directive _name_ is ‘title’, and its _argument_ is the text ‘Swing Low Sweet Chariot’. This directive defines meta-data, the song title. That is the semantic part. What the formatter does with this meta-data is up to the program and _not part of the ChordPro File Format Specification_. You can consider directives to be a friendly request, or suggestion, but the actual implementation is left to the formatter. For a meta-data item like the song title it will probably be printed on top of the page and be included in a table of contents, if any.

The [Chordpro Reference Implementation]({{< relref "Chordpro-Reference-Implementation" >}}) provides a default implementation in the style of the original `chord` program. It can be used as a reference to what a directive is assumed to do. It must however be emphasised that the reference implementation can be configured to use different page styles, fonts, sizes, colours, and so on. Where appropriate, this document refers to the default style.

Many directives have long and short names. For example, the long (full) name for the directive `title` is ‘title’,
and the short (abbreviated) name is ‘t’. It is, however, advised to use the full name whenever possible, since the abbreviations may lead to confusion or ambiguity if new directives are added.

For directives that take arguments, the arguments are separated from the directive name by a colon `:` and/or whitespace.

## Preamble directives

* [new_song]({{< relref "Directives-new_song" >}}) (short: ns)

## Meta-data directives

Each song can have meta-data associated, for example the song title. Meta-data are mostly used by programs that help
organizing collections of ChordPro songs.

* [title]({{< relref "Directives-title" >}}) (short: t)
* [sorttitle]({{< relref "Directives-sorttitle" >}})
* [subtitle]({{< relref "Directives-subtitle" >}}) (short: st)
* [artist]({{< relref "Directives-artist" >}})
* [composer]({{< relref "Directives-composer" >}})
* [lyricist]({{< relref "Directives-lyricist" >}})
* [copyright]({{< relref "Directives-copyright" >}})
* [album]({{< relref "Directives-album" >}})
* [year]({{< relref "Directives-year" >}})
* [key]({{< relref "Directives-key" >}})
* [time]({{< relref "Directives-time" >}})
* [tempo]({{< relref "Directives-tempo" >}})
* [duration]({{< relref "Directives-duration" >}})
* [capo]({{< relref "Directives-capo" >}})
* [meta]({{< relref "Directives-meta" >}})

See also [Using metadata in texts]({{< relref "ChordPro-Configuration-Format-Strings" >}}).

## Formatting directives

* [comment]({{< relref "Directives-comment" >}}) (short: c)
* [comment_italic]({{< relref "Directives-comment" >}}) (short: ci)
* [comment_box]({{< relref "Directives-comment" >}}) (short: cb)
* [image]({{< relref "Directives-image" >}})

## Environment directives

Environment directives always come in pairs, one to start the
environment and one to end it.

* [Introduction to environments]({{< relref "Directives-env" >}})
* [start_of_chorus]({{< relref "Directives-env_chorus" >}}) (short: soc)
* [end_of_chorus]({{< relref "Directives-env_chorus" >}}) (short: eoc)
* [chorus]({{< relref "Directives-env_chorus" >}})
* [start_of_verse]({{< relref "Directives-env_verse" >}}) (short: sov)
* [end_of_verse]({{< relref "Directives-env_verse" >}}) (short: eov)
* [start_of_bridge]({{< relref "Directives-env_bridge" >}}) (short: sob)
* [end_of_bridge]({{< relref "Directives-env_bridge" >}}) (short: eob)
* [start_of_tab]({{< relref "Directives-env_tab" >}}) (short: sot)
* [end_of_tab]({{< relref "Directives-env_tab" >}}) (short: eot)
* [start_of_grid]({{< relref "Directives-env_grid" >}}) (short: sog)
* [end_of_grid]({{< relref "Directives-env_grid" >}}) (short: eog)

## Chord diagrams

* [define]({{< relref "Directives-define" >}})
* [chord]({{< relref "Directives-chord" >}})

## Fonts, sizes and colours

These directives can be used to temporarily change the font, size and/or colour for lyrics and chords. To permanently change these the reference implementation uses much more powerful [configuration files]({{< relref "ChordPro-Configuration" >}}).

* [textfont]({{< relref "Directives-props_text_legacy" >}})
* [textsize]({{< relref "Directives-props_text_legacy" >}})
* [textcolour]({{< relref "Directives-props_text_legacy" >}})
* [chordfont]({{< relref "Directives-props_chord_legacy" >}})
* [chordsize]({{< relref "Directives-props_chord_legacy" >}})
* [chordcolour]({{< relref "Directives-props_chord_legacy" >}})
* [tabfont]({{< relref "Directives-props_tab_legacy" >}})
* [tabsize]({{< relref "Directives-props_tab_legacy" >}})
* [tabcolour]({{< relref "Directives-props_tab_legacy" >}})

## Output related directives

* [new_page]({{< relref "Directives-new_page" >}}) (short: np)
* [new_physical_page]({{< relref "Directives-new_physical_page" >}}) (short: npp)
* [column_break]({{< relref "Directives-column_break" >}}) (short: cb)

The following directives are legacy from the old `chord` program. The modern reference implementation uses much more powerful configuration files for this purpose.

* [grid]({{< relref "Directives-grid_legacy" >}}) (short: g)
* [no_grid]({{< relref "Directives-grid_legacy" >}}) (short: ng)
* [titles]({{< relref "Directives-titles_legacy" >}})
* [columns]({{< relref "Directives-columns" >}}) (short: col)

## Custom extensions

To facilitate using custom extensions for application specific purposes, any directive with a name starting with `x_` should be completely ignored by applications that do not handle this directive. In particular, no warning should be generated when an unsupported `x_`directive is encountered.

It is advised to follow the `x_` prefix by a tag that identifies the application (namespace). For example, a directive  to control a specific pedal setting for the MobilsSheetsPro program could be named `x_mspro_pedal_setting`.
