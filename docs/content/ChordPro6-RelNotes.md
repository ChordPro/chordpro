---
title: "ChordPro 6 Release Information"
description: "ChordPro 6 Release Information"
---

# ChordPro 6 Release Information

Release information for the ChordPro __file format__.

For release information for the ChordPro __program__, see
[here]({{< relref "ChordPro-Reference-RelNotes.html" >}}).

Since ChordPro 5 never had an official release, its release notes have
been merged here.

{{< toc >}}

## Markup

In all texts (lyrics, titles, chordnames, comments, etc.) markup
instructions can be used to manipulate the appearance.

The [markup instructions]({{< relref "ChordPro-Markup" >}}) resemble the
[Pango Markup Language](https://docs.gtk.org/Pango/pango_markup.html)
as defined by the [Gnome organisation](https://www.gnome.org/).

For example:

    [C]Roses are <span color="red">red</span>, [G]<b>don't forget!</b>
	
The ChordPro program will produce something similar to:

![Example markup]({{< asset "images/ex_markup.png" >}})

## Annotations

Annotations are arbitrary remarks that go with a song. They are
specified just like chords, but start with an `*` symbol.

For example:

    [Em]This is the [*Rit.]end my [Am]friend.

The ChordPro program will produce something similar to:

![Example annotation]({{< asset "images/ex_annot.png" >}})

Even though they are written using chord-like syntax, it is important
to know that annotations are _not_ chords. In particular:

- ChordPro processing tools may choose to show annotations in a
  different way than chords.
- No attempts will be made to transpose, transcode, or draw chord
  diagrams for annotations.

## Images

Images can be inserted in the song using the [`image`
directive]({{< relref "Directives-image.html" >}}). Useful for logo's
and score fragments.

![Example image]({{< asset "images/ex_image.png" >}})

## Delegates

Delegation is a means to pass arbitrary data to an external program
that will generate an image. The image is then inserted as with the
`{image}` directive.

A popular delegate is [ABC[(https://abcnotation.com/).
The above example image could have been
acquired via delegation:

````
{start_of_abc}
X:1
K:F
M:4/4
[AE]2 | [FC]6 [AC]2 | [FD]3 [FD] [(D(B,] [C)A,)]3 |

{end_of_abc}
````

## Metadata

Metadata can be used to maintain information about the song.
See also [Using metadata in texts]({{< relref "ChordPro-Configuration-Format-Strings" >}}).

All metadata can be specified with a directive named after the
metadatum, or with an explicit [`meta` directive]({{< relref
"Directives-meta.html" >}}).

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

capo
: The position of the capo, if any.

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

sorttitle
: Specifies the title to be used for sorting, e.g. in the table of contents.

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

How selectors are defined depends on the ChordPro processing tool.
The ChordPro program uses the config values for `instrument.type`
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

To modify an existing chord, use `copy`:

    {define Bstar copy B frets x 2 4 4 x}

To change the name as shown, use `display`:

    {define Bstar display B*}

All parts are optional.
It is even possible to define a chord without additional information.

    {define Bstar}
	
For more details, see [Define Directive]({{< relref "directives-define" >}}).

## Chord grids

Not to be confused with chord _diagrams_, chord grids form an easy way
to denote the rhythmic structure of a song part.

![]({{< asset "images/ex_grid2.png" >}})

## New lyrics section directives

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

The ChordPro program treats all sections (except `chorus`,
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

The ChordPro program will add a left margin to the output and
place the label text in this margin.

![Example labels]({{< asset "images/ex_labels.png" >}})

## New directives for fonts, sizes and colours (v5)

You can set fonts, sizes and colours for `text` (lyrics), `chord`,
`title`, `footer`, `toc` (table of contents), and `tab`.

For example:

````
{titlecolour:blue}
{footersize:10}
````

Without argument a setting will revert to its previous value, e.g.

````
{textsize:14}
[A]Lyrics size 14
{textsize:20}
[B]Lyrics size 20
{textsize}
[C]Lyrics size 14
````

## New directive: `highlight` (v5)

This is a synonym to `comment`. It is included for compatibility with
3rd party implementations of the ChordPro file format.


## New directive: `chord` (v5)

This directive is syntactically identical to `define`, but instead of
defining a new chord it displays the chord diagram where it occurs.
