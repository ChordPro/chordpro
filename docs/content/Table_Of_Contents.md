---
title: "Table of Contents"
description: "Table of Contents"
---

# Table of Contents

When ChordPro generates a PDF for printing or viewing, it can include
an automatically generated table of contents (ToC).

## Configuration

The appearance of the Table of Contents is specified in the ChordPro
configuration file.

````
contents : [
  {
    // The metadata for this toc. One or two items.
    fields : [ title ]
  
    // The label (title) for this toc.
    label : "Table of Contents"
  
    // The format for the toc lines.
    line : "%{title}"
  
    // The format for the page numbers in the toc.
    pageno : "%{page}"
  
    // Omit this toc.
    omit : false
  
    // Template song for the toc.
    template : stdtoc
  }
]
````

Is it easiest to consider the ToC to be just like a song, one that is
inserted before the other songs. It has a title, specified by `label`,
and only contains *content lines*, lines that have a left part,
specified by `line`, and a right part, specified by `pageno`.

A description of the properties:

* `fields`  
  A list of one or two metadata items to sort this ToC on.  
  `title` is the song title, but there is some magic,
  [see below]({{< relref "#magic-sorting" >}}).  
  `artist` is the artist name, also with magic.  
  `songindex` is the ordinal of appearance in the list of songs.  
  All metadata can be used for sorting, but the above items are most
  commonly used.
* `label`  
  The title for this ToC.
* `line`  
  The format for the entries in the ToC. This string may contain
  [metadata substitutions]({{< relref
  "ChordPro-configuration-format-strings" >}}).
* `pageno`  
  The format for the page numbers in the toc.
* `omit`  
  If true, this ToC will not be included in the output.
* `template`  
  The name of a template.
  More magic, [see below]({{< relref "#templates" >}}).
  
The default ChordPro configuration provides two ToCs, one as described
above and a similar ToC that sorts on song title and artist.

## Magic sorting

ChordPro has `sorttitle` and `sortartist` directives to set a specific
sort-version for `title` and `artist`.

For example:
````
{title: The Long And Winding Road}
{artist: The Beatles}
{sorttitle: Long And Winding Road, The}
{sortartist: Beatles, The}
````

When a ToC is sorted on the `title` metadatum, and the song has a
`sorttitle`, ChordPro will use the value of `sorttitle` instead of
`title`.

Also, when a ToC is sorted on the `sorttitle` metadatum, and the song has no
`sorttitle`, ChordPro will use the value of `title` instead.

This magic applies for all sort fields, even though only `title` and
`artist` have official sort variants.

## Templates

As stated earlier, is it easiest to consider the ToC to be just like a
song. More than that: it **is** a song. And you can define your own.

The `template` field in the ToC specification may contain the name of
a ChordPro song file, which is then used as a ToC. This way you can
add introduction text, logo's etc.. The content lines that form the
actual ToC are appended to the song contents.

You can put templates in a `templates` directory in your ChordPro
library, and designate them by name. I.e., using
````
    template: mytoc
````
will search for `mytoc.cho` in the libraries.

## See also

[title]({{< relref "Directives-title" >}}),
[sorttitle]({{< relref "Directives-sorttitle" >}}),
[artist]({{< relref "Directives-artist" >}}) and
[sortartist]({{< relref "Directives-sortartist" >}}).
