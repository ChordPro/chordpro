---
title: "Configuration file contents - Delegates"
description: "Configuration file contents - Delegates"
---

# Configuration file contents - Delegates

    "delegates" : {
     },

## ABC

        "abc" : {
            "module"   : "ABC",
            "handler"  : "abc2svg",
            "type"     : "image",

            // The preamble is a list of lines inserted before the ABC data.
            // DO NOT MODIFY unless you know what you are doing!
            "preamble" : [
               // Get rid of as much space as possible.
               "%%topspace 0",
               "%%titlespace 0",
               "%%musicspace 0",
               "%%composerspace 0",
               "%%infospace 0",
               "%%textspace 0",
               "%%leftmargin 0cm",
               "%%rightmargin 0cm",
               "%%staffsep 0",
               // Use ChordPro fonts for lyrics and chords.
               "%%textfont pdf.fonts.text",
               "%%gchordfont pdf.fonts.chord",
            ],

            "preprocess" : { "abc" : [] },
            "omit"     : false,
        },

* `module`: The (perl) module that implements this delegate.  
  This must be `"ABC"`.

* `handler`: The module function that handles this delegation.  
  Valid values are `"abc2svg"` and `"abc2svg_qjs"`.  
  See [Tools, below](#selecting-the-abc-tool).

* `type`: The result produced by the delegate handler.  
  This must be `"image"`, this delegate
  produces an image that will be embedded in the ChordPro output.

* `preamble`: A series of ABC directives that are prepended to the ABC
  data to make sure that the generated image can be nicely embedded in
  the ChordPro output.

* `preprocess`: A preprocessor of the ABC data.  
  See [Parser]({{< relref "ChordPro-Configuration-Parser" >}}) for
  a description of preprocessors.
  
* `omit`: If `true`, no delegation will be handled. In other words,
  the contents of `{start_of_abc}` ... `{end_of_abc}` is silently
  ignored.

### Selecting the ABC tool


### Connecting ABC and ChordPro fonts

TBD
  
## Lilypond

        "ly" : {
            "module"   : "Lilypond",
            "handler"  : "ly2svg",
            "type"     : "image",

            // The preamble is a list of lines inserted before the lilipond data.
            // This is a good place to set the version and global customizations.
            "preamble" : [
                "\\version \"2.21.0\"",
                "\\header { tagline = ##f }",
            ],

            "omit"     : false,
        },

* `module`: The (perl) module that implements this delegate.  
  This must be `"Lilypond"`.

* `handler`: The module function that handles this delegation.  
  This must be `"ly2svg"`.

* `type`: The result produced by the delegate handler.  
  This must be `"image"`, this delegate
  produces an image that will be embedded in the ChordPro output.

* `preamble`: A series of Lilypond directives that are prepended to
  the Lilypond data to make sure that the generated image can be
  nicely embedded in the ChordPro output.  
  Note that Lilypond directives start with a backslash, which has a
  special meaning in JSON data. Two consecutive backslashes will be
  interpretated as a single backslash without special meaning.

* `omit`: If `true`, no delegation will be handled. In other words,
  the contents of `{start_of_ly}` ... `{end_of_ly}` is silently
  ignored.

# The Lilypond tool
