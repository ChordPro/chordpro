---
title: "Table of Contents"
description: "Table of Contents"
---

# Table of Contents

When ChordPro generates a PDF for printing or viewing, it can include
one or more automatically generated table of contents (ToC).

By default ToCs are generated if there is more than one song involved.
This can be forced for a single song with the `--toc` command line
option. Likewise, all ToCs can be suppressed with the `--no-toc`
command line option.

See [Using the ChordPro CLI]({{< relref
"using-chordpro/#command-line-options" >}}) for details on command
line options.

## Configuration

The appearance of the Table of Contents is specified in the ChordPro
configuration file.

````
contents : [
  {
    // The metadata for this toc. One or two items.
	// This is used for sorting the ToC.
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
but only contains *content lines*, lines that have a left part,
specified by `line`, and a right part, specified by `pageno`.

The default ChordPro configuration provides two ToCs, one as described
above and a similar ToC that sorts on song title and artist.

## The Table of Content properties

### `fields`

A list of one or two metadata items to sort this ToC on.

All metadata can be used for sorting, but most relevant are:

* `title` — the song title,
* `artist` — the artist name, and
* `songindex` — the ordinal of appearance in the list of songs.

If a song has set a value for the `sorttitle` metadatum, this value
will be used for sorting instead of `title`. 
Likewise, a value for `sortartist`, if set, will be used instead of `artist`.

### `label`

The title for this ToC.

### `break`

A string that is used to group entries.  
This string may contain
[metadata substitutions]({{< relref
"ChordPro-configuration-format-strings" >}}).

If the break value for a content line changes, the break value is
printed before the content line.

The break value may contain `\n` sequences to obtain empty lines, e.g.

     break : "\\nSongs by %{artist}"


### `line`

The format for the left part of the content lines.  
This string may contain
[metadata substitutions]({{< relref
"ChordPro-configuration-format-strings" >}}).

### `pageno`

The format for the right part of the content lines, which is usually
the page number for the song.  
This string may contain
[metadata substitutions]({{< relref
"ChordPro-configuration-format-strings" >}}).

### `omit`

If true, this ToC will not be included in the output.

### `template`

The name of a template.
[See below]({{< relref "#templates" >}}).
  
## Templates

As stated earlier, is it easiest to consider the ToC to be just like a
song. It has a page layout as defined in the configuration file. It
has page headings and footers.

The `template` field in the ToC specification may contain the name of
a ChordPro song file, which is then used as a template for the ToC.
This way you can
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
