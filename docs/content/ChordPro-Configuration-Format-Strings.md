# Using metadata in texts

Metadata can be used in header/footer texts and comments. The general format of a metadata value in a text is `%{`_name_`}`, where _name_ is the name of the metadata item.

It is also possible to conditionally substitute texts depending on the value of metadata items.

`%{`_name_`|`_true-text_`|`_false-text_`}`  
`%{`_name_`|`_true-text_`}`

If metadata item _name_, the controling item, has a value, the _true-text_ is substituted. If metadata item _name_ has no value, the _false-text_ is substituted. Both alternatives may be left out.

For even more power, _true-text_ and _false-text_ may contain other metadata subtitutions. The special `%{}` can be used to substitute the value of the controling item.

For example, if metadata item `album` has the value "Yes", `%{album|Album: %{}}` expands to "Album: Yes". If `album` did not have a value, the expansion would be empty.