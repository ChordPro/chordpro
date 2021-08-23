---
title: "ChordPro 5 Release Information"
description: "ChordPro 5 Release Information"
---

# ChordPro 5 Release Information

Release information for the ChordPro __file format__.

For release information for the ChordPro __reference implementation__, see
[here]({{< relref "ChordPro-Reference-RelNotes.html" >}}).

{{< toc >}}

## Metadata

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

## New directives for fonts and sizes

You can set fonts and font sizes for `title, `footer`, `toc`
(table of contents), and `tab`.

For example: `{footersize:10}`.

## New directives for colours

You can set colours for `title`, `footer`, `toc`
(table of contents), `tab`, `text` and `chords`.

For example: `{titlecolour:blue}`.

## New directive: `highlight`

This is a synonym to `comment`. It is included for compatibility with
3rd party implementations of the ChordPro file format.


## New directive: `chord`

This directive is syntactically identical to `define`, but instead of
defining a new chord it displays the chord diagram where it occurred.
