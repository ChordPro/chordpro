---
title: "Configuration for ChordPro output"
description: "Configuration for ChordPro output"
---

# Configuration for ChordPro output

*Note that the ChordPro output backend is still experimental.*

Layout definitions for HTML output are stored in the configuration under the key `"chordpro"`.

    {
       // ... generic part ...
       "chordpro" : {
         // ... layout definitions ...
       },
    }

## Chorus

Specifies the recall style for chorus.

  	  // Style of chorus.
  	  "chorus" : {
         // Recall style: Print the tag using the type.
         // Alternatively quote the lines of the preceding chorus.
         // If no tag+type or quote: use {chorus}.
         // Note: Variant 'msp' always uses {chorus}.
         "recall" : {
           // "tag"   : "Chorus", "type"  : "comment",
           "tag"   : "", "type"  : "",
           "quote" : false,
         }
       }
