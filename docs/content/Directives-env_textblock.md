---
title: "Directives: start_of_textblock"
description: "Directives: start_of_textblock"
---

# Directives: start_of_textblock

This directive indicates that the lines that follow define a piece of
text that is combined into a single object that can be placed as an
image.

For example

	{start_of_textblock align=right flush=right}
	She died of the fever,
	and nothing could save her
	And that was the end of sweet Molly Malone
	{end_of_textblock}

The result could look like:

![]({{< asset "images/ex_textblock1.png" >}})

(The text at the left are ordinary chords and lyrics.)

## Attributes

The textblock directive may contain the same formatting attributes as the
image directive, for example:

    {start_of_textblock label="Verse 2" align="left"}

See [Directives: Image]({{< relref "Directives-Image" >}}) for all
possible attributes.

Additionally, the following attributes may be used:

* `width="`_n_`"`  
   The width of the resultant object.  
   Defaults to the actual width (tight fit) of the texts.  
   Note that the object can only be made wider, not smaller.

* `height="`_n_`"`  
   The height of the resultant object.  
   Defaults to the actual height of the text, including
   the advance of the last line (non-tight fit).  
   Note that the object can only be made higher, not smaller.  
   When `height` or `padding` is set, a tight fit is used.

* `padding="`_n_`"`  
   Provides padding between the object and the inner text.  
   When height or padding is set, a tight fit is used.

* `flush="`_flush_`"`  
   Horizontal text flush (`left`, `center`, `right`).
   
* `vflush="`_vflush_`"`  
   Vertical text flush (`top`, `middle`, `bottom`).

* `textstyle="`_style_`"`  
   Style (font) to be used. Must be one of the printable items as defined
   in the [config]({{< relref "chordpro-configuration-pdf/#fonts"
   >}}).  
   Default style is `text`.
   
* `textsize="`_n_`"`  
   Initial value for the text size.
   This may be relative to the size specified in the config using `%`, `em`,
   and `ex`.

* `textcolor="`_colour_`"`  
   Initial value for the text colour.

* `background="`_colour_`"`  
   The background color of the object.
