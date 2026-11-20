---
title: "Guidelines for ChordPro related links"
description: "Guidelines for ChordPro related links"
---

# Guidelines for ChordPro related links

So you have a tool that uses ChordPro formatted song data and you
would like to have it included on the [ChordPro 3Rd Party Links
page]({{< relref "Links" >}})? These are the rules. Note that being
included on the Links page is a privilege, not a right.

## Reference

The tool and its documentation must refer to the ChordPro site as the
community standard for ChordPro song files.

The tool and its documentation may refer to the [ChordPro Community
Forum](https://groups.io/g/ChordPro) as the place to ask questions,
discuss features and share ideas about the ChordPro song file format.

## Conformance

The ChordPro song files your tool uses should mostly conform to the
official standard, as described on the [ChordPro site]({{< relref
"chordpro-introduction" >}}). Mostly, since there is room for custom
features and forgivingness for not dealing with all official ChordPro
features.

The following directives _must_ be dealt with correctly:

* [title]({{< relref "directives-title" >}})
* [key]({{< relref "directives-key" >}})
* [start/end of chorus]({{< relref "directives-env_chorus" >}})
* [chorus]({{< relref "directives-env_chorus" >}})
* [start/end of tab]({{< relref "directives-env_tab" >}})
* [comment]({{< relref "directives-comment" >}})

The following directives _should_ be dealt with correctly:

* [subtitle]({{< relref "directives-subtitle" >}})
* [transpose]({{< relref "directives-transpose" >}})
* [define]({{< relref "directives-define" >}})

Directives that are not handled must be ignored elegantly.

Markup like `<b>` that is not handled must be ignored and not shown.

Note that ChordPro distinguishes two forms of directives: with an argument

    {start_of_chorus: Chorus 1}

and with properties:

    {start_of_chorus label="Chorus 1"}

Although the advised way is shown above, the use of the colon is
optional in either form.

## Free tools

If your tool is free, as in speech, it will get included in the list
of free ChordPro-aware tools on the ChordPro site.

## Non-free tools

If your tool is gratis, but not free, it will get included in the list
of non-free ChordPro-aware tools on the ChordPro site.

## Commercial tools

If your tool requires registration, a web site account, or licence
fees, it will get included in the list of commercial ChordPro-aware
tools on the ChordPro site.

Pricing per year:

* If your tool requires a one-time purchase, 10 x the purchase fee.
* If your tool requires monthly or yearly subscription fees, 10 x the
  subscription costs per year.

