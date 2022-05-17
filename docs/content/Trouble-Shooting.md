---
title: "Trouble Shooting"
description: "Trouble Shooting"
---

# Trouble Shooting

If you encounter problems that you are unable to solve, please contact
the [user community]({{< relref "support-user-forum" >}}).

## Installation problems

If your preferred way of installing programs does not work for
ChordPro report this on the [user community]({{< relref
"support-user-forum" >}}).

If your platform provides a vendor kit (e.g. Fedora), did you try
that?

Did you try the binary install kit from the [release site](https://github.com/ChordPro/chordpro/releases)?

## Build problems

ChordPro should be able to build and run on any recent (and decent)
system that supports Perl. The lowest Perl version is 5.10.1, but it
is better to use 5.24 or later.

The required Perl modules are available from CPAN and can be
built/installed with the `cpan` tool. Most platforms have prebuilt
install kits for these modules, so please try these first.

Building the Perl `Wx` component, required for ChordPro GUI may be tricky.
Google may be helpful.

## ChordPro doesn't run

Assuming you are trying to run ChordPro GUI, try running it from the
command line to see if there are any messages generated.

## ChordPro produces unexpected results

File a bug report to the [issue
tracker](https://github.com/ChordPro/chordpro/issues). Include the
song you are trying to process, and any custom configuration files involved.

Make sure to include the output of running the ChordPro command with
`--about` options, and/or a screenshot of the 'About' screen.

If a PDF document is produced, run ChordPro again with the `--debug`
command line option and include the resultant PDF with the bug report.

When running from the GUI, check Help > Enable debug info in PDF and
try again. _You will get a "Problems Found" dialog with diagnostic
information, this can be ignored._. Save the PDF document and add it
to be bug report.

## ChordPro output looks okay, but ABC parts are missing or wrong

To process ABC data, ChordPro relies on a couple of external tools:
`abcm2ps` and `convert`. These tools should be easily added to your
system if not already there.

For `abcm2ps` version 8.12.14 or later is advised, although earlier
versions usually work okay in most cases.

`convert` is part of ImageMagick. Version 7 is advised, but 6.9.12 or
later will also work okay in most cases. For `convert` it is
imperative that it can handle SVG image files. Some system vendors
find it necessary to build ImageMagick without SVG support in which
case you'll get crippled or no output.

See also https://github.com/ChordPro/chordpro/issues/217 .
