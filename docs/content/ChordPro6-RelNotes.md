---
title: "ChordPro 6 Release Information"
description: "ChordPro 6 Release Information"
---

# ChordPro 6 Release Information

Release information for the ChordPro __file format__.

For release information for the ChordPro __reference implementation__, see
[here]({{< relref "ChordPro-Reference-RelNotes.html" >}}).

Since ChordPro 5 never had an official release, its release notes have
been merged here.

{{< toc >}}

## Markup

In all texts (lyrics, titles, chordnames, comments, etc.) markup
instructions can be used to manipulate the appearance.

The markup instructions conform to the [Pango Markup
Language]({{< relref "Pango_Markup" >}}).

For example:

    [C]Roses are <span color="red">red</span>, [G]<b>don't forget!</b>
	
The reference implementation will produce something similar to:

![Example markup]({{< asset "images/ex_markup.png" >}})

## Annotations

Annotations are arbitrary remarks that go with a song. They are
specified just like chords, but start with an `*` symbol.

For example:

    [Em]This is the [*Rit.]end my [Am]friend.

The reference implementation will produce something similar to:

![Example annotation]({{< asset "images/ex_annot.png" >}})

Even though they are written using chord-like syntax, it is important
to know that annotations are _not_ chords. In particular:

- ChordPro processing tools may choose to show annotations in a
  different way than chords.
- No attempts will be made to transpose, transcode, or draw chord
  diagrams for annotations.

## Metadata (v5)

Metadata can be used to maintain information about the song.
See also [Using metadata in texts]({{< relref "ChordPro-Configuration-Format-Strings" >}}).

The following metadata are supported:

album
: Specifies the album that contains the song.
Multiple titles can be specified using multiple directives.

arranger
: Specifies the arranger of the song.
Multiple arrangers can be specified using multiple directives.

artist
: Specifies the artist.
Multiple artists can be specified using multiple directives.

composer
: Specifies the composer of the song.
Multiple composers can be specified using multiple directives.

copyright
: Copyright information for the song in the form year rights holder.

duration
: Specifies the duration of the song. This can be a number indicating seconds, or a time specification conforming to the extended ordinal time format as defined in ISO 8601.
For example, durations 268 and 4:28 are the same.

key
: Specifies the key the song is written in, e.g. C or Dm.
Multiple specifications are possible, each specification applies from where it appears in the song.

lyricist
: Specifies the writer of the lyrics of the song.
Multiple lyricists can be specified using multiple directives.
If no lyricist is specified, it is assumed that the composer did all the work.

tempo
: Specifies the tempo in number of beats per minute for the song, e.g 80.
Multiple specifications are possible, each specification applies from where it appears in the song.

time
: Specifies the time signature for the song, e.g 4/4 or 6/8.
Multiple specifications are possible, each specification applies from where it appears in the song.

year
: The year this song was first published, as a four-digit number.

## Conditional directives

All directives can be equipped with a _selector_ by appending a
selector name to the name of the directive, separated by a dash (hyphen) `-`.
If the selector fails, the directive is skipped.

For example:

    {define-ukulele Dm base-fret 1 frets 2 2 1 0}
    {define-guitar  Dm base-fret 1 frets x 0 3 2 3 1}

This will define the appropriate Dm chord for either ukulele or
guitar.

Selection can be reversed by appending a `!` to the selector.

How selectors are defined depends on the ChordPro processing tool. The
reference implementation uses the config values for `instrument.type`
and `user.name`.

## Enhanced chord definitions

The `define` and `chord` directives have been enhanced to understand
finger positions (for string instruments) and keyboard keys (for
keyboards).

For example, for guitar:

    {define  Dm base-fret 1 frets x 0 3 2 3 1 fingers 0 0 3 2 1 4}

For a keyboard:

    {define  Dm keys 0 3 7 12}

Note that the keys are _relative_. `0` is the root, `3` the minor
third, `7` the fifth and so on.

For more details, see [Define Directive]({{< relref "directives-define" >}}).

## New section directives

The following directives are added:

* start_of_verse (short: sov)
* end_of_verse (short: eov)
* start_of_bridge (short: sob)
* end_of_bridge (short: eob)

The purpose of these directives is to be able to identify portions of
the song. ChordPro processing tools may choose to use this
information, e.g. to show a bridge in a different way than a verse.

In addition to these directives it is possible to add your own section
directives, for example `{start_of_lead}` or `{start_of_coda}`. All
sections must be closed with the corresponding `{end_of_`*section*`}`.

The reference implementation treats all sections (except `chorus`,
`tab`, `grid`, `abc` and `ly`) as lyrics.

## Modified section directives

In a tab section (`{start_of_tab}` or `{sot}` the lines that follow
are taken as literally as possible. The lines will not be folded or
changed. Markup is left as is, and directives are considered literal
text except for `{end_of_tab}` and `{eot}`.

## Section labels

All section directives can take an optional label, which can be used
to tag individual sections. For example:

````
{start_of_verse: Verse 1}
[A]Hello there!
{end_of_verse}
 
{start_of_verse: Verse 2}
[B]Nice seeing you.
{end_of_verse}
````

The reference implementation will add a left margin to the output and
place the label text in this margin.

![Example labels]({{< asset "images/ex_labels.png" >}})

## New directives for fonts and sizes (v5)

You can set fonts and font sizes for `title, `footer`, `toc`
(table of contents), and `tab`.

For example: `{footersize:10}`.

## New directives for colours (v5)

You can set colours for `title`, `footer`, `toc`
(table of contents), `tab`, `text` and `chords`.

For example: `{titlecolour:blue}`.

## New directive: `highlight` (v5)

This is a synonym to `comment`. It is included for compatibility with
3rd party implementations of the ChordPro file format.


## New directive: `chord` (v5)

This directive is syntactically identical to `define`, but instead of
defining a new chord it displays the chord diagram where it occurs.
