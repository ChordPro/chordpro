---
title: "Delegated environment directives"
description: "Delegated environment directives"
---

# Delegated environment directives

Delegated environments are similar to ordinary environments.

* They are extensions to the ChordPro environments and 
  often implemented using external tools or libraries.
  **Therefore they may not be available in all implementations of ChordPro.**

* In general, they produce an image that can be placed anywhere in the song.

* They have their own section in the configuration and can be
  customized.
  
## Configuration

Delegated environments are configured in the `delegates` section of
the config. For example:

    "delegates" : {
        "textblock" : {
            "type"     : "image",
            "module"   : "TextBlock",
            "handler"  : "txt2xform",
        },
    }

This configures a delegated environment called `textblock` and adds
`start_of_textblock` and `end_of_textblock` directives. `module`
and `handler` specify the plugin module that handles this environment,
and its entry point. You should never need to change these. `type`
specifies what the delegated environment produces, usually an `image`.

When `type` is set to `omit`, the environment is parsed but not processed,
i.e., it does not produce anything. 

When `image` is `none`, there will be no `start_of` and `end_of`
directives, effectively removing the delegated environment from
ChordPro. As a result, the environment will be treated as a generic
environment.

## ABC

* [start_of_abc]({{< relref "Directives-env_abc" >}}) / [end_of_abc]({{< relref "Directives-env_abc" >}})

## Lilypond

* [start_of_ly]({{< relref "Directives-env_ly" >}}) / [end_of_ly]({{< relref "Directives-env_ly" >}})

## SVG

* [start_of_svg]({{< relref "Directives-env_svg" >}}) / [end_of_svg]({{< relref "Directives-env_svg" >}})

## Textblock

* [start_of_textblock]({{< relref "Directives-env_textblock" >}}) / [end_of_textblock]({{< relref "Directives-env_textblock" >}})
