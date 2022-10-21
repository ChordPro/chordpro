---
title: "Directives: image"
description: "Directives: image"
---

# Directives: image

`{image:` `src=`*filename* _options_ `}`

Includes a bitmap image.

`src=`*filename*  
Specifies the name of the file containing the image. Supported file types are PNG, JPG and GIF.  
Note that the syntax of file names may depend on the platforms and tools used. A simple file name like "myimage.png" is always acceptable. 	

The optional _options_ can be used to control the appearance of the image. Single or double quotes can be used if spaces are to be included in the option values.

`width=`*width*  
Specifies the desired width of the image in typographic points (1/72 inch or 0.3528 mm). If necessary the original image is scaled to fit.

`height=`*height*  
Specifies the desired height of the image. If necessary the original image is scaled to fit.	

`scale=`*factor*  
Scales the image with the factor.	

`center=`*tf*  
`center`  
The image is horizontally centered on the page or column. If _tf_ equals `0`, the image is flushed left.

`border=`*width*  
`border`  
Draws a border around the image. Without an explicit width, the border is one typographic point.

`title=`*text*  
Provides a title for the image.

`spread`=*space*  
Places the image at the top of the page, across the full page width.
The rest of the content will be shifted down by the height of the
image plus *space*.

Note that the top of the page is the top of the paper minus the
top margin, and that the width of the page is the width of the paper
minus the left and right margins.

Example:

    Swing [D]low, sweet [G]chari[D]ot
    {image: src="score.png" center=0}

The result will be similar to:

![]({{< asset "images/ex_image.png" >}})


