# ROADMAP for ChordPro

This roadmap contains changes and enhacements that are likely to take
place in the future.

Feel free to feedback on the [community forum](https://groups.io/g/ChordPro).

## Planned for 6.x

### Placement of images

A way to place images on a specific place on the page. Any other text
will appear on top of the image.

Status: Experimental.

A way to place images relative to a part of the song. To be used for
annotations.

Status: Development.

### Rootless chords

Support rootless chords, e.g. `/B`.

Status: Completed.

### Deprecate/remove `diagrams.auto`

Automatically adding unknown chords as empty diagrams was flawed and
not used according to a survey on the community forum.

Status: Removed from config settings and documentation.

Todo: Code cleanup.

## Planned for ChordPro 7

### Alternative syntax for directives

An alternative syntax with keyword parameters and decent quoting.

Multiple directives per line.

### Flow

Provide an identification for song sections that can be used to
recall the section at arbitrary places. 

Useful to change parts order for different voices or instruments.

### HTML support

HTML support is currently limited. With the power of modern CSS HTML
output should be as perfect as the PDF.

## Not yet planned

### MacOS

A new wrapper program that provides real MacOS GUI.

Requires a MacOS developer.

### Libraries

Currently ChordPro operates on files. This should be extended (at
least in the GUI) to work with libraries.

### Per-section config

Designate style or properties for selected sections.

Issue #174.

### Strumming patterns

Issue #85.
