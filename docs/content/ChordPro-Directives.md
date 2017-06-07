# ChordPro Directives

ChordPro directives are used to control the appearance of the printed output. They define meta-data like titles, add new chords, control page and column breaks. Therefore it is not always easy to make a distinction between the semantics of a directive, and the way these semantics are implemented in the ChordPro processing program, the _formatter_.

For example, the `title` directive.

    {title: Swing Low Sweet Chariot}

This directive defines meta-data, the song title. That is the semantic part. What the formatter does with this meta-data is up to the program and _not part of the ChordPro File Format Specification_. You can consider directives to be a friendly request, or suggestion, but the actual implementation is left to the formatter. For a meta-data item like the song title it will probably be printed on top of the page and be included in a table of contents, if any.

The [[Chordpro Reference Implementation]] provides a default implementation in the style of the original `chord` program. It can be used as a reference to what a directive is assumed to do. It must however be noticed that the reference implementation can be configured to use different page styles, fonts, sizes, colours, and so on. Where appropriate, this document refers to the default style.