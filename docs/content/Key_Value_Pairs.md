---
title: Key/Value pairs
description: Key/Value pairs
---

# Key/Value pairs

Many directives take additional attributes in the form of key/value
pairs.

For example,

    label=Chorus
    label="Chorus"

Either will assign the value `"Chorus"` to attribute `label`.

Using quotes is optional unless the value contains spaces.

    label="Verse 1"

## To be or not to be

Often an attribute takes a _logical_ value to enable or disable
something.

    diagram=no

The attribute is considered enabled when the value is any of:

    1
	on
	true

To disable, use:

    0
	off
	false
	null
	no
	none

In most cases, an empty value is also considered _false_, and everything else
not enumerated above is considered _true_. But best is to stick to the
values shown above.

## Numeric values

If an attribute requires a _numeric_ value, this can be an optionally
signed number, optionally followed by a fraction.

    1
	-42
	3.14

Degenerate cases like `.1` and `2.` are not recognized.

Depending on the context a numeric value can have a _unit_, e.g. `60%`
or `1.4em`.

| Unit | Value                                  |
|------|----------------------------------------|
| `%`  | Percentage, `60%` is the same as `0.6` |
| `em` | Fraction of the current font size      |
| `ex` | Fraction of half the current font size |
| `pt` | Typographical point, `1/72` inch       |
| `px` | Pixel, `1/96` inch, `0.75pt`           |
| `in` | Inch, `2.54cm`, `72pt`, `96px`         |
| `cm` | Centimeter, `10mm`                     |
| `mm` | Millimeter                             |
{ .table .table-striped .table-bordered .table-sm }

Default for dimensions is points. For example, the following are
equivalent:

    width=515
	width=515pt
