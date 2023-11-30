---
title: "Directives: start_of_svg"
description: "Directives: start_of_svg"
---

# Directives: start_of_svg

This directive indicates that the lines that follow define an image
described in [Scalable Vector Graphics](https://...).

For example

    {start_of_svg}
    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="18" viewBox="0 0 20 18">
      <g stroke="red" fill="none" stroke-width="2">
        <polygon points="1 17 19 17 10 1" stroke-linejoin="round"/>
        <rect x="9" y="13" width="2" height="2" stroke="none" fill="red"/>
        <polygon points="9 12 8.5 7 11.5 7 11 12" stroke="none" fill="red"/>
      </g>
    </svg>
    {end_of_svg}

The result could look like:

![]({{< asset "images/ex_svg1.png" >}})

## Attributes

The SVG directive may contain the same formatting attributes as the
image directive, for example:

    {start_of_svg label="Alert" align="left"}

See [Directives: Image]({{< relref "Directives-Image" >}}) for all
possible attributes.

# Directives: end_of_svg

This directive indicates the end of the svg section.


