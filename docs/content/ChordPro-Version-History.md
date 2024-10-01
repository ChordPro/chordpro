## The Stone Age

Due to its simplicity and popularity, many users and tools adopted the ChordPro file format for transcribing songs. Unavoidable, many tools added their own extensions, thus creating several ChordPro ‘dialects’. Fortunately songs written in most of these dialects were exchangeable, which means that they still produced useful results even though parts of the commands in the file were not understood or dealt with correctly.

## ChordPro version 5.0

Published in 2017, this is a first attempt to gather the best of several existing dialects and merge this into a more or less formal specification of the ChordPro file format. With the specification came a brand new reference implementation of a ChordPro processing tool.

Some of the newer features:

* [Verse environment]({{< relref "Directives-env_verse" >}})  
  This environment can be used to mark a verse. It may be omitted.

* [Transposition]({{< relref "Directives-transpose" >}})  
  The `transpose` directive can be used to transpose a song, or parts of a song.

* [Meta-data directives]({{< relref "Directives-meta" >}})  
  Directives like `composer`, `album` and so on can be used for administrative purposes.

## ChordPro version 5.1

Published in 2018, the following features were added.

* [Labels]({{< relref "Directives-env_verse" >}})  
  Sections like verse, chorus, grid and tab can have a label assigned by following the directive name with the desired text. For example:

    `{start_of_verse: Verse 1}`

