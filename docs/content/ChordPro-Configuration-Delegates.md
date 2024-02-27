---
title: "Configuration file contents - Delegates"
description: "Configuration file contents - Delegates"
---

# Configuration file contents - Delegates

{{< toc >}}

Delegates are interfaces to external tools to turn non-ChordPro
content into something that ChordPro can handle. The non-ChordPro
content is included in the song between `{start_of_...}` and
`{end_of_...}` directives.

ChordPro currently provides two delegates:

* abc, the popular [ABC music notation](https://www.abcnotation.com), and

* ly, the [Lilypond](https://lilypond.org) music typesetter.

Configuration settings for these delegates can be set the config file
under `"delegates"`:

    "delegates" : {
        "abc" : { ... },
        "ly"  : { ... },
     },

## ABC

The ABC delegate collects the ABC music data and prepares it for the
ABC tool to turn it into an SVG image. 

### Selecting the ABC tool

The ABC delegate supports two methods:

* QuickJS, a JavaScript interpreter. 

* A program similar to `abcnode` that comes with some ABC tools.

ChordPro will first try to find an `abc2svg` program in the executable
path. If this is found it will be used to process the ABC data. The
program will be executed with a single argument, the name of a file
that contains the prepared ABC data, and it should produce the SVG
image on standard output.

Alternatively, if the QuickJS program `qjs` can be found in the
executable path, ChordPro will use this internally to produce the SVG
image.

In the ABC configuration the setting `handler` can be use to modify
the tool selection. If set to `"abc2svg"` selection proceeds as
described above. If set to `"abc2svg_qjs"` ChordPro will always use the
QuickJS interpreter.

### ABC configuration

        "abc" : {
            "module"   : "ABC",

            // Default handler "abc2svg" uses program (if set),
            // otherwise embedded QuickJS or external QuickJS.
            // Handler "quickjs_xs" uses embedded QuickJS only.
            // Handler "quickjs_qjs" uses external QuickJS only.
            // Handler "quickjs" uses internal or external QuickJS.
            // Please stick to the default unless you know what you
            // are doing.
            "handler"  : "abc2svg",
            "program"  : "",		// specify program tool

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
  Default value is `"abc2svg"` to let ChordPro decide.  
  Unless `program` is set, ChordPro will use QuickJS, either built-in
  or via an external QuickJS interpreter.

* `program`: The program to use if the handler is `"abc2svg"`.  
  This program should take one argument, the ABC file, and write the
  SVG data to its standard output.

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

### ABC using ChordPro fonts

ABC directives can refer to ChordPro fonts with a `pdf.fonts.` prefix.
See the preamble in the ABC config above for some examples.

### ABC using arbitrary fonts

When arbitrary fonts are used in the ABC data it is important that
ChordPro knows these fonts as well. For each of these fonts an entry
must be made in the font registry.

For example, in the ABC the music font `Bravura` is used. The
corresponding ChordPro font registry would be:

    "pdf" : {
        "fontconfig" : {
            ...
            "bravura" : {
                "" : { "file" : "Bravura.otf" }
            },
            ...
        }
    }

See also [ChordPro Implementation: Fonts]({{<
relref "chordpro-fonts" >}}).

## Lilypond

The Lilypond delegate collects the Lilypond music data and prepares it
for the Lilypond program `lilypond` to turn it into an SVG image.

### Lilypond configuration

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
  the content of `{start_of_ly}` ... `{end_of_ly}` is silently
  ignored.

### Connecting Lilypond and ChordPro fonts

This is similar to [ABC using arbitrary fonts](#abc-using-arbitrary-fonts).
