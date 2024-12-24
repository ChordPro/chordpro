---
title: "How to get multiline titles / subtitles in my page headers"
description: "How to get multiline titles / subtitles in my page headers"
---

# How to get multiline titles / subtitles in my page headers

You can configure the headers and footers in the config file.

See [Page headers and footers](
{{< relref "Chordpro-Configuration-PDF/#page-headers-and-footers" >}}).

By default, title, subtitle and footer are set to an array of three
format strings, to be printed left, centered and right. These may also
be set to an array of three part format strings, which will be printed
on separate lines.

For example, to get multiple subtitle lines:

````
pdf.formats.title {
    title :    [ "" "%{title}" "" ]
    subtitle : [ [ "" "%{subtitle.1}" "" ]
                 [ "" "%{subtitle.2}" "" ] ]
    footer :   [ "" "" "%{page}" ]
}

````

If you have a single `{subtitle: ...}` this will be the same as the
default case. An additional `{subtitle: ...}` will be printed on the
second subtitle line.

If you have multiple `{title: ...}` lines, they may be printed too
close to each other. You can increase `pdf.spacing.title` to get more
space for the title lines, shifting the subtitle lines down.

You may also need to adjust `pdf.headspace` and `pdf.margintop`, see 
[Page margins](https://www.chordpro.org/chordpro/chordpro-configuration-pdf/#page-margins).
