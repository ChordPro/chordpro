---
title: "Directives: image"
description: "Directives: image"
---

# Directives: image

`{image:` `src=`*filename* _options_ `}`

Includes an image.

## Simple use

    {image: "score.png"}
    {image: src="score.png"}

##### `{image: `*filename*`}`
##### `{image: src=`*filename*`}`
Specifies the name of the file containing the image.
Supported file types may depend on the platforms and
tools used, but PNG, JPG and GIF should always be valid.
Most likely, ABC and SVG will also be acceptable.
The syntax of file names also depends on the platforms and
tools used.

In general, a simple file name like `"myimage.png"` should always
be acceptable. The image must then reside in the same directory as the
song, or in an `images` subdirectory of one of the ChordPro resource
paths.

A full (absolute) filename like `"/home/me/images/myimage.png"` or
`"C:\Users\Me\Documents\myimage.png"` is acceptable but not portable.

Avoid relative filenames like `"images/myimage.png"`. They may or may not work,
do not count on it.

Example:

    Swing [D]low, sweet [G]chari[D]ot
    {image: src="score.png" center="0"}

The result will be similar to:

![]({{< asset "images/ex_image.png" >}})

## Using options

The optional _options_ can be used to control the appearance of the
image. Single or double quotes can be used if spaces are to be
included in the option values.

##### `width=`*width*  
Specifies the desired width of the image in typographic points (1/72
inch or 0.3528 mm), or a percentage of the available width.
If necessary the original image is scaled to fit.

##### `height=`*height*  
Specifies the desired height of the image. If necessary the original
image is scaled to fit.

##### `scale=`*factor*  
Scales the image with the factor.
This may be a floating point number, e.g. `0.2`, or a percentage, e.g. `20%`.

Two comma-separated factors cen be used to specify independent
horizontal and vertical scaling.

##### `align=`*aa*  
Aligns the image on the page. The argument may be `"left"`,
`"center"` or `"right"`.
Default alignment is `"center"`.

##### `center=`*tf*  
##### `center`  
(Deprecated)
The image is horizontally centered on the page or column.
If _tf_ equals `0`, the image is flushed left.

##### `border=`*width*  
##### `border`  
Draws a border around the image.
Without an explicit width, the border is one typographic point.

## Advanced features

##### `spread`=*space*  
Places the image at the top of the page, across the full page width.
The rest of the content will be shifted down by the height of the
image plus *space*.

Note that the top of the page is the top of the paper minus the
top margin, and that the width of the page is the width of the paper
minus the left and right margins.

##### `href=`*url*

Provides a URL to open when the image is clicked.
Most likely this will leave the PDF viewer and transfer to a web browser.

## Static (stationary) images

##### `x=`*offset*
##### `y=`*offset*
Offsets the image from its default position.
The offset values are in typographic points or a percentage.

##### `anchor=`*anchor*  
Controls where the image will be placed.
All cases except the default (no anchor, or anchor is `"float"`) the
image is placed on the background of the page and does not occupy space.
Lyrics and other objects will appear on top of the images.

Valid values for *anchor* are:

`paper`
: Placement is relative to the paper boundaries, starting top left.

 Negative values will offset left/up from the
right/bottom side of the paper, and adjust for the image size.
In other words,

    anchor="paper" x="0" y="0"

will place the image in the top left corner of the paper, while

    anchor="paper" x="-0" y="-0"

will place the image in the bottom right corner of the paper.

When the offset is a percentage, it is adjusted for the image size.
For example, with `x="0%"` the left side of the image is at the left
edge of the paper. With `x="100%"` the right side of the image is at
the right edge of the paper. With `x="50%"` the center of the image is
at the center of the paper.

So this is another way to get an image in the bottom right corner of
the paper: 

    anchor="paper" x="100%" y="100%"

`page`
: Placement is relative to the page boundaries, i.e. the paper
boundaries minus top, bottom, left and right margins.

Negative values will move beyond the left and top margins.

When the offset is a percentage, it is adjusted for the image size.

This is the way to get an image in the bottom right corner of
the page: 

    anchor="page" x="100%" y="100%"

`column`
: Same as page boundaries, but taking column layout into account.

`line`
: Images are placed relative to the lyrics lines.

`float`
: This is default behaviour.
Images are placed between the lyrics lines.

## Assets

It is possible to define an image as an asset. This means that it gets
an `id` that can be used to refer to it later.
This is particularly useful if you want to use the same image multiple
times, and when you want to use images as annotations.

For example,

````
{image: id="im01" src="image1.jpg"}
...
{image: id="im01" scale="80%" center}
````

The first occurrence has an `id` and a `src` (nothing else allowed).
This loads the image an assigns it asset id `im01`.

The second occurrence places an image but instead of specifying the
source of the image, it uses the asset with the given id.

## Assets from delegates

Delegates, e.g. ABC, can produce assets.
Simply prepend the contents with a line `id=`_XXX_ to supply the id.
Note that you need an `{image}` directive to show it.

# Inline images

Images can also be placed inside texts using a special markup element
`<img>`.

The img element takes several attributes.

First, and most important, is the source of the image. This can be the
name of a file containing an image, e.g.

    src="image.jpg"
	
Alternatively, an asset id can be used:

    id="im01"
	
Finally, chord diagrams are images too:

    chord="Am7"
	
Other attributes are:

`width=`_NNN_
: The desired width for the image.
The value must be a size (in points), `em` or `ex`.
The image is scaled if necessary.

`height=`_NNN_
: The desired height for the image.

`dx=`_NNN_
: A horizontal offset for the image, wrt. the current location in the text.
The value must be a size (in points), `em` or `ex`.

`dy=`_NNN_
: Same, but vertical. Positive amounts move up.

Note the direction is opposite to the markup `<rise>`.

`scale=`_NNN_
: A scaling factor, to be applied _after_ width/height scaling.
The value may be expressed as a percentage.

Two comma-separated factors cen be used to specify independent
horizontal and vertical scaling.

`align="left"`  `align="right"`  `align="center"`
: Align the image in the width given by the `w` attribute.

`bbox=1`   `bbox=0`
: If true, the actual bounding box of an object is used for placement.

By default the bounding box is only used to obtain the width and height.

This attribute has no effect on image objects.

`w=`_NNN_
: The advance width of the image.
This is the **actual** space occupied by the image.
If the image is wider it will overlap the text it is embedded in.

Default advance is the image width plus horizontal offset.
This overrides the advance and may be zero.

`h=`_NNN_
: The advance height of the image.
Similar to `w` but vertically.

