---
title: "Configuration for CSV output"
description: "Configuration for CSV output"
---

# Configuration for CSV output

Definitions for CSV output are stored in the configuration under the
key `"csv"` under the key `"pdf"`.

    {
       "pdf" : {

         // CSV generation for MobileSheetsPro. Adapt for other tools.
         // Note that the resultant file will conform to RFC 4180.
         "csv" : {
             "fields" : [
                 { "name" : "title",        "meta" : "title"      },
                 { "name" : "pages",        "meta" : "pagerange"  },
                 { "name" : "sorttitles",   "meta" : "sorttitle"  },
                 { "name" : "artists",      "meta" : "artist"     },
                 { "name" : "composers",    "meta" : "composer"   },
                 { "name" : "collections",  "meta" : "collection" },
                 { "name" : "keys",         "meta" : "key_actual" },
                 { "name" : "years",        "meta" : "year"       },
                 // Add "omit" : true to omit a field.
                 // To add fields with fixed values, use "value":
                 { "name" : "my_field", "value" : "text", "omit" : true },
             ],
             // Field separator.
             "separator" : ";",
             // Values separator.
             "vseparator" : "|",
             // Restrict CSV to song pages only (do not include matter pages).
             "songsonly" : true,
         },
       },
    }

`"fields"` enumerate the fields that are to be stored in the CSV. Each
field definition has a `"name"` property that is used to idenitfy the
field in the first line of the CSV, and either a `"meta"` or
`"value"` property. Optionally property `"omit"` can be used to 
(temporarily) suppress fields.

The `"meta"` property refers, as the name suggests, to one of the
metadata items of the song. If the metadata item has multiple values they are
joined using the `"vseparator"` property.

The `"value"` property, if supplied, can be used to specify a given
value to be inserted instead of a metadata item. The given value may
use metadata as described in [Using metadata in texts]({{< relref
"chordpro-configuration-format-strings" >}}).

Other properties of `"csv"`:

`"separator"`
: The separator used to join the individual fields into CSV lines.  
  If a field contains the separator as part of its value, the field
  will be quoted according to RFC 4180.

`"vseparator"`
: The separator used to join the values of metadata into a field
  value.  
  No special action is taken if the metadata values contain the separator.

`"songsonly"`
: Restricts the content of the CSV to the actual songs. 
This is enabled by default.
When set to `false`, the CSV will also
contain information for cover pages, table of contents, and so on.



## Example of a CSV

````
title;pages;sorttitles;artists;composers;collections;keys;years
Back Home In Derry;3-4;;The Davitts;Bobby Sands;Mojore;;
Fiddler’s Green;5-6;;;;Mojore;;
Isle Of Hope, Isle Of Tears;7-8;;Seán Keane;Brendan Graham;Mojore;;
Kilkelly Ireland 1860;9-10;;;Peter Jones;Mojore;;1860|2018
May Morning Dew;11;;The Chieftains;;Mojore;;
Nancy Spain;12-13;;Christy Moore;Barney Rush;Mojore;;
One Way Journey Home;14-15;;Gregory Page;;Mojore;;2019
Only Our Rivers;16;;Christy Moore;Michael McConnell;Mojore;;
On Raglan Road;17-18;;;Sinéad O’Connor;Mojore;;
Peat Bog Soldiers;19-20;;Lankum;"Johann Esser;Wolfgang Langhoff;Rudi Goguel";Mojore;;1933
````
