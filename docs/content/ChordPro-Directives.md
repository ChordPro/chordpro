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
* [highlight]({{< relref "Directives-comment" >}})
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

## Delegate environment directives

These environment directives are experimental: they turn their content into
something else, usually an image, and embed the result in the ChordPro
output.

* [start_of_abc]({{< relref "Directives-env_abc" >}}) / [end_of_abc]({{< relref "Directives-env_abc" >}})
* [start_of_ly]({{< relref "Directives-env_ly" >}}) / [end_of_ly]({{< relref "Directives-env_ly" >}})

## Chord diagrams

* [define]({{< relref "Directives-define" >}})
* [chord]({{< relref "Directives-chord" >}})

## Fonts, sizes and colours

These directives can be used to temporarily change the font, size and/or colour for lyrics and chords. To permanently change these the reference implementation uses much more powerful [configuration files]({{< relref "ChordPro-Configuration" >}}).

* [textfont]({{< relref "Directives-props_text_legacy" >}}) (short: tf)
* [textsize]({{< relref "Directives-props_text_legacy" >}}) (short: ts)
* [textcolour]({{< relref "Directives-props_text_legacy" >}})
* [titlefont]({{< relref "Directives-props_title_legacy" >}})
* [titlesize]({{< relref "Directives-props_title_legacy" >}})
* [titlecolour]({{< relref "Directives-props_title_legacy" >}})
* [footerfont]({{< relref "Directives-props_footer_legacy" >}})
* [footersize]({{< relref "Directives-props_footer_legacy" >}})
* [footercolour]({{< relref "Directives-props_footer_legacy" >}})
* [chordfont]({{< relref "Directives-props_chord_legacy" >}}) (short: cf)
* [chordsize]({{< relref "Directives-props_chord_legacy" >}}) (short: cs)
* [chordcolour]({{< relref "Directives-props_chord_legacy" >}})
* [tabfont]({{< relref "Directives-props_tab_legacy" >}})
* [tabsize]({{< relref "Directives-props_tab_legacy" >}})
* [tabcolour]({{< relref "Directives-props_tab_legacy" >}})
* [tocfont]({{< relref "Directives-props_toc_legacy" >}})
* [tocsize]({{< relref "Directives-props_toc_legacy" >}})
* [toccolour]({{< relref "Directives-props_toc_legacy" >}})

## Output related directives

* [new_page]({{< relref "Directives-new_page" >}}) (short: np)
* [new_physical_page]({{< relref "Directives-new_physical_page" >}}) (short: npp)
* [column_break]({{< relref "Directives-column_break" >}}) (short: cb)
* [pagetype]({{< relref "Directives-pagetype_legacy" >}})

The following directives are legacy from the old `chord` program. The modern reference implementation uses much more powerful configuration files for this purpose.

* [grid]({{< relref "Directives-grid_legacy" >}}) (short: g)
* [no_grid]({{< relref "Directives-grid_legacy" >}}) (short: ng)
* [titles]({{< relref "Directives-titles_legacy" >}})
* [columns]({{< relref "Directives-columns" >}}) (short: col)

## Custom extensions

To facilitate using custom extensions for application specific purposes, any directive with a name starting with `x_` should be completely ignored by applications that do not handle this directive. In particular, no warning should be generated when an unsupported `x_`directive is encountered.

It is advised to follow the `x_` prefix by a tag that identifies the application (namespace). For example, a directive  to control a specific pedal setting for the MobilsSheetsPro program could be named `x_mspro_pedal_setting`.

# Conditional directives

All directives can be conditionally selected by postfixing the
directive with a dash (hyphen) and a _selector_.

If a selector is used, ChordPro first tries to match it with the
instrument type (as defined in the [config file]({{< relref "chordpro-configuration-generic#instrument-description" >}})).
If this fails, it
tries to match it with the user name (as defined in the [config file]({{< relref "chordpro-configuration-generic#user" >}})).

For example, to
define chords depending on the instrument used:

````
{define-guitar:  Am base-fret 1 frets 0 2 2 1 0 0}
{define-ukulele: Am base-fret 1 frets 2 0 0 0}
````
An example of comments depending on voices:
````
{comment-alto:  Very softly!}
{comment-tenor: Sing this with power}
````
When used with sections, selection applies to _everything_ in the
section, up to and including the final section end directive:
````
{start_of_verse-soprano}
...anything goes, including other directives...
{end_of_verse}
````
Note that the section end must **not** include the selector.
