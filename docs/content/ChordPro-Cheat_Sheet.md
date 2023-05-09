---
# reformat the big table with ../reformat.pl
title: "ChordPro Cheat Sheet"
description: "ChordPro Cheat Sheet"
---

# ChordPro Cheat Sheet

## General

ChordPro input is a file containing song lyrics, chords and annotations.

Chords are placed between brackets `[` and `]`.

Annotations are placed between bracket-star `[*` and `]`.

The input data may be encoded in ASCII, ISO 8859.1, UTF-8, UTF-16 or UTF-32.

_Directives_ control processing and output.
Directives are placed between braces `{` and `}` and must be on a single line.

Example:

````
{title: Twinkle}
[C]Twinkle, twinkle, [F]little [C]star
````

Texts can use [ChordPro Markup]({{< relref "ChordPro_Markup" >}})
and [metadata]({{< relref "ChordPro-Configuration-Format-Strings" >}}).

Lines that start with a hash `#` are ignored.

## Directives

Directives can be [conditionally executed](/chordpro-directives/#conditional-directives) by appending a dash `-` and a _selector_ to the directive name.

Arguments to directives may be separated by a colon `:` and/or whitespace.

| Directive                                                                | Short     | Purpose                                                                                            | Since |
| ---                                                                      | ---       | ---                                                                                                | ---   |
| [chord]({{< relref "Directives-chord" >}}) _name_ ...                    |           | Display diagram in-line.                                                                           | 5.0   |
| ... `base-fret` _base_                                                   |           | Specify base-fret (1 or higher).[^1]                                                               | 5.0   |
| ... `display` _display_                                                  |           | Specify display string.[^1]                                                                        | 6.0   |
| ... `fingers` _pos1_ _pos2_ _pos3_ ...                                   |           | Specify finger postions.[^1]                                                                       | 6.0   |
| ... `frets` _pos1_ _pos2_ _pos3_ ...                                     |           | Specify fret postions.[^1]                                                                         | 5.0   |
| ... `keys` _pos1_ _pos2_ _pos3_ ...                                      |           | Specify keyboard keys.[^1]                                                                         | 6.0   |
| [chordcolour]({{< relref "Directives-props_chord_legacy" >}}) _colour_   |           | Chord colour.                                                                                      | 5.0   |
| [chordfont]({{< relref "Directives-props_chord_legacy" >}}) _font_       | cf[^3]    | Chord font.                                                                                        | 1.0   |
| [chordsize]({{< relref "Directives-props_chord_legacy" >}}) _size_       | cs[^3]    | Chord size.                                                                                        | 1.0   |
| [chorus]({{< relref "Directives-env_chorus" >}})                         |           | Recall chorus. May have a [label]({{< relref "ChordPro-Configuration-PDF#labels" >}}).[^2]         | 5.0   |
| [column_break]({{< relref "Directives-column_break" >}})                 | cb        | New column or page.                                                                                | 3.6   |
| [columns]({{< relref "Directives-columns" >}}) _cols_                    | col       | Number of columns.                                                                                 | 3.6   |
| [comment]({{< relref "Directives-comment" >}})                           | c         | Comment.                                                                                           | 1.0   |
| [comment_box]({{< relref "Directives-comment" >}})                       | cb        | Comment.                                                                                           | 3.6   |
| [comment_italic]({{< relref "Directives-comment" >}})                    | ci        | Comment.                                                                                           | 3.6   |
| [define]({{< relref "Directives-define" >}}) _name_ ...                  |           | Define chord.                                                                                      | 1.0   |
| ... `base-fret` _base_                                                   |           | Specify base-fret (1 or higher).[^1]                                                               | 1.0   |
| ... `fingers` _pos1_ _pos2_ _pos3_ ...                                   |           | Specify finger postions.[^1]                                                                       | 6.0   |
| ... `frets` _pos1_ _pos2_ _pos3_ ...                                     |           | Specify fret postions.[^1]                                                                         | 1.0   |
| ... `keys` _pos1_ _pos2_ _pos3_ ...                                      |           | Specify keyboard keys.[^1]                                                                         | 6.0   |
| [end_of_]({{< relref "Directives-env" >}})_section_                      |           | Ends a specific section.                                                                           | 6.0   |
| [end_of_bridge]({{< relref "Directives-env_bridge" >}})                  | eob       | Ends bridge section.                                                                               | 6.0   |
| [end_of_chorus]({{< relref "Directives-env_chorus" >}})                  | eoc       | Ends chorus section.                                                                               | 1.0   |
| [end_of_grid]({{< relref "Directives-env_grid" >}})                      | eog       | Ends grid section.                                                                                 | 5.0   |
| [end_of_tab]({{< relref "Directives-env_tab" >}})                        | eot       | Ends tab section.                                                                                  | 3.6   |
| [end_of_verse]({{< relref "Directives-env_verse" >}})                    | eov       | Ends verse section.                                                                                | 6.0   |
| [footersize]({{< relref "Directives-props_footer_legacy" >}}) _size_     |           | Footer size.                                                                                       | 5.0   |
| [footercolour]({{< relref "Directives-props_footer_legacy" >}}) _colour_ |           | Footer colour.                                                                                     | 5.0   |
| [footerfont]({{< relref "Directives-props_footer_legacy" >}}) _font_     |           | Footer font.                                                                                       | 5.0   |
| [grid]({{< relref "Directives-grid_legacy" >}})                          | g         | Print diagrams at end.                                                                             | 3.6   |
| [highlight]({{< relref "Directives-comment" >}})                         |           | Same as comment.                                                                                   | 5.0   |
| [image]({{< relref "Directives-image" >}}) ...                           |           | Include image.                                                                                     | 5.0   |
| ... `border`                                                             |           | Draws a 1 point border around the image.                                                           | 5.0   |
| ... `border=` _width_                                                    |           | Draws a border around the image (points).                                                          | 5.0   |
| ... `center`                                                             |           | Center image.                                                                                      | 5.0   |
| ... `center=` _arg_                                                      |           | Center image if _arg_ .                                                                            | 5.0   |
| ... `height=` _height_                                                   |           | Height (points).                                                                                   | 5.0   |
| ... `scale=` _scale_                                                     |           | Scale factor (number).                                                                             | 5.0   |
| ... `src=` _filename_                                                    |           | Image file name                                                                                    | 5.0   |
| ... `title=` _text_                                                      |           | Provides a title (caption) for the image.                                                          | 5.0   |
| ... `width=` _width_                                                     |           | Width (points).                                                                                    | 5.0   |
| [meta]({{< relref "Directives-meta" >}}) _item_                          |           | Metadata.                                                                                          | 5.0   |
| [meta album]({{< relref "Directives-album" >}}) _name_                   | album     | Album name.                                                                                        | 5.0   |
| [meta artist]({{< relref "Directives-artist" >}}) _name_                 | artist    | Artist name.                                                                                       | 5.0   |
| [meta capo]({{< relref "Directives-capo" >}}) _pos_                      | capo      | Capo.                                                                                              | 5.0   |
| [meta composer]({{< relref "Directives-composer" >}}) _name_             | composer  | Composer name.                                                                                     | 5.0   |
| [meta copyright]({{< relref "Directives-copyright" >}}) _text_           | copyright | Copyright.                                                                                         | 5.0   |
| [meta duration]({{< relref "Directives-duration" >}}) ...                | duration  | Duration (_mm:ss_ or seconds).                                                                     | 5.0   |
| [meta key]({{< relref "Directives-key" >}}) _key_                        | key       | Key.                                                                                               | 5.0   |
| [meta lyricist]({{< relref "Directives-lyricist" >}}) _name_             | lyricist  | Lyricist name.                                                                                     | 5.0   |
| [meta sorttitle]({{< relref "Directives-sorttitle" >}}) _text_           | sorttitle | Sort title.                                                                                        | 6.0   |
| [meta tempo]({{< relref "Directives-tempo" >}}) _bpm_                    | tempo     | Tempo (beats per minute).                                                                          | 5.0   |
| [meta time]({{< relref "Directives-time" >}}) _n_ `/` _m_                | time      | Time signature.                                                                                    | 5.0   |
| [meta year]({{< relref "Directives-year" >}}) _text_                     | year      | Release date.                                                                                      | 5.0   |
| [new_page]({{< relref "Directives-new_page" >}})                         | np        | Starts new page.                                                                                   | 3.6   |
| [new_physical_page]({{< relref "Directives-new_page" >}})                | npp       | Starts new page.                                                                                   | 3.6   |
| [new_song]({{< relref "Directives-new_song" >}})                         | ns        | Starts a new song.                                                                                 | 1.0   |
| [no_grid]({{< relref "Directives-grid_legacy" >}})                       | ng        | Disable diagram printing.                                                                          | 3.6   |
| [pagetype]({{< relref "Directives-pagetype_legacy" >}}) ...[^4]          |           | Set page (paper) size.                                                                             | 4.0   |
| [start_of_]({{< relref "Directives-env" >}})_section_                    |           | Starts a specific section. May have a [label]({{< relref "ChordPro-Configuration-PDF#labels" >}}). | 6.0   |
| [start_of_bridge]({{< relref "Directives-env_bridge" >}})                | sob       | Starts bridge section. May have a [label]({{< relref "ChordPro-Configuration-PDF#labels" >}}).     | 6.0   |
| [start_of_chorus]({{< relref "Directives-env_chorus" >}})                | soc       | Starts chorus section. May have a [label]({{< relref "ChordPro-Configuration-PDF#labels" >}}).[^2] | 1.0   |
| [start_of_grid]({{< relref "Directives-env_grid" >}})                    | sog       | Starts grid section. May have a [label]({{< relref "ChordPro-Configuration-PDF#labels" >}}).[^2]   | 5.0   |
| [start_of_tab]({{< relref "Directives-env_tab" >}})                      | sot       | Starts tab section May have a [label]({{< relref "ChordPro-Configuration-PDF#labels" >}}).[^2]     | 3.6   |
| [start_of_verse]({{< relref "Directives-env_verse" >}})                  | sov       | Starts verse section. May have a [label]({{< relref "ChordPro-Configuration-PDF#labels" >}}).      | 6.0   |
| [subtitle]({{< relref "Directives-subtitle" >}}) _text_                  | st        | Subtitle for song.                                                                                 | 1.0   |
| [tabcolour]({{< relref "Directives-props_tab_legacy" >}}) _colour_       |           | Tabs colour.                                                                                       | 5.0   |
| [tabfont]({{< relref "Directives-props_tab_legacy" >}}) _font_           |           | Tabs font.                                                                                         | 5.0   |
| [tabsize]({{< relref "Directives-props_tab_legacy" >}}) _size_           |           | Tabs size.                                                                                         | 5.0   |
| [textcolour]({{< relref "Directives-props_text_legacy" >}}) _colour_     |           | Text colour.                                                                                       | 5.0   |
| [textfont]({{< relref "Directives-props_text_legacy" >}}) _font_         | tf[^3]    | Text font.                                                                                         | 1.0   |
| [textsize]({{< relref "Directives-props_text_legacy" >}}) _size_         | ts[^3]    | Text size.                                                                                         | 1.0   |
| [title]({{< relref "Directives-title" >}}) _text_                        | t         | Title for song.                                                                                    | 1.0   |
| [titlesize]({{< relref "Directives-props_title_legacy" >}}) _size_       |           | Title size.                                                                                        | 5.0   |
| [titlecolour]({{< relref "Directives-props_title_legacy" >}}) _colour_   |           | Title colour.                                                                                      | 5.0   |
| [titlefont]({{< relref "Directives-props_title_legacy" >}}) _font_       |           | Title font.                                                                                        | 5.0   |
| [titles]({{< relref "Directives-titles_legacy" >}}) _flush_              |           | Flush titles (`center`, `left` or `right`).                                                        | 3.6.4 |
| [tocsize]({{< relref "Directives-props_toc_legacy" >}}) _size_           |           | Table of contents font size.                                                                       | 5.0   |
| [toccolour]({{< relref "Directives-props_toc_legacy" >}}) _colour_       |           | Table of contents colour.                                                                          | 5.0   |
| [tocfont]({{< relref "Directives-props_toc_legacy" >}}) _font_           |           | Table of contents font.                                                                            | 5.0   |
| [transpose]({{< relref "Directives-transpose" >}}) _semitones_           |           | Transpose by a number of semitones.                                                                | 5.0   |
| [x_...]({{< relref "Directives-custom" >}})                              |           | Custom directive.                                                                                  | 5.0   |
{ .table .table-striped .table-bordered .table-sm }
 
### Notes

There are no archived releases between 1.2 and 3.6, so unless there
are pre-1.2 proofs 3.6 is taken to be the initial release for a
feature.

There has never been an official [5.0 release]({{< relref  "ChordPro5-RelNotes.md" >}}).
5.0 was mostly an intermediate development target for 6.0.

[^1]: As of [version 6.0]({{< relref "ChordPro6-RelNotes.md" >}}),
all arguments to `chord` and `define` directives are optional.
[^2]: [Section labels]({{< relref "ChordPro-Configuration-PDF#labels" >}}) are a 6.0 feature.
[^3]: The short forms were missing in version 5,0, and re-added in 6.0.
[^4]: Actually, `pagetype` and `pagesize` were never implemented in version 5.0 and higher.

<!---
# Local Variables:
# mode: text
# eval: (auto-fill-mode -1)
# eval: (toggle-truncate-lines 1)
# End:
--->
