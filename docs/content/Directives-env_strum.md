---
title: "Directives: start_of_strum"
description: "Directives: start_of_strum"
---

# Directives: start_of_strum

This directive indicates that the lines that follow define a strum pattern.

For example

    {start_of_strum}
	... syntax to be determined ...
    {end_of_strum}

The result could look like:

![]({{< asset "images/ex_strum1.png" >}})

The arrow indicates the direction of the strum, up or down. 

A dashed arrow indicates a arpeggio (slow) strum.

A cross above the arrow indicates that the strum is muted.

A `>` above the arrow indicates an accented (emphasised) strum.

The numbers denote the beat in the measure. If there are more strums
to a beat (one-and two-and etc.), see `tuplet` below.

## Attributes

The strum directive may contain the same formatting attributes as the
image directive, for example:

    {start_of_strum label="Alert" align="left"}

See [Directives: Image]({{< relref "Directives-Image" >}}) for all
possible attributes.

Attributes specific to the strum section:

##### `bpm=`*n*  
The beats per measure for this strum. If not specified, ChordPro tries
to derive the value from a `{time}` directive.

Default value = 4.

##### `color=`*col*  
The colour of the strum. Default is to use the current background colour.

##### `size=`*n*  
The size of the strum. Default value = 20.

##### `tuplet=`*n*  
If greater than 1, the beats are divided into *n* sub-beats.

For example, with `bpm="4" tuplet="2"`:

![]({{< asset "images/ex_strum2.png" >}})

# Directives: end_of_strum

This directive indicates the end of the strum section.


