---
title: "Directives: image"
description: "Directives: image"
---

# Directives: image

`{image:` `src=`*filename* _options_ `}`

Includes a bitmap image.

## Simple use

    {image: "score.png"}
    {image: src="score.png"}

##### `{image: `*filename*`}`
##### `{image: src=`*filename*`}`
Specifies the name of the file containing the image.
Supported file types may depend on the platforms and
tools used, but PNG, JPG and GIF should always be valid.
The syntax of file names also depends on the platforms and
tools used. A simple file name like `"myimage.png"` should always
be acceptable. The image must then reside in the same directory as the
song, or in an `images` subdirectory of `CHORDPRO_LIB`.

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

##### `center=`*tf*  
##### `center`  
The image is horizontally centered on the page or column.
If _tf_ equals `0`, the image is flushed left.

##### `border=`*width*  
##### `border`  
Draws a border around the image.
Without an explicit width, the border is one typographic point.

##### `title=`*text*  
Provides a title for the image.

## Advanced features

##### `spread`=*space*  
Places the image at the top of the page, across the full page width.
The rest of the content will be shifted down by the height of the
image plus *space*.

Note that the top of the page is the top of the paper minus the
top margin, and that the width of the page is the width of the paper
minus the left and right margins.

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

will place the image in the top left corner of the paper.

When the offset is a percentage, it is adjusted for the image size.
For example, with `x="0%"` the left side of the image is at the left
edge of the paper. With `x="100%"` the right side of the image is at
the right edge of the paper. With `x="50%"` the center of the image is
at the center of the paper.

So this is the way to get an image in the bottom right corner of
the paper: 

    anchor="paper" x="100%" y="100%"

`page`
: Placement is relative to the page boundaries, i.e. the paper
boundaries minus top, bottom, left and right margins.

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

### Annotation with assets

**TDB**

````
[A]Swing low, Sweet <img id="im01" scale="10%">Chariot.
````

Asset with the given id is placed in the line, top aligned. "Chariot"
is shifted to the right.

````
[A]Swing low, Sweet <img id="im01" y=12 scale="10%">Chariot.
````

Asset with the given id is placed in the line, shifted 12pt up from
top aligned. "Chariot" is **not** shifted to the right.

**TBD** Align bottom of image with the baseline instead?
