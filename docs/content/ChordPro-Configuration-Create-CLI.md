---
title: "Creating a config (CLI)"
description: "Creating a config (CLI)"
---

# Creating a config (CLI)

## Create a sample configuration using the command line

_Note that the syntax of file names may differ between systems._

From the command prompt, type

`chordpro --print-template-config > myconfig.json`

The generated file contains most of the ChordPro configuration
items, **all commented out**. It is easy to get started with configuring
ChordPro by enabling and modifying just a few items at a time.

For a full config, with everything set to default values, type

`chordpro --print-default-config > myconfig.json`

