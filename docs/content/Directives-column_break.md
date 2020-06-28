---
title: "Directives: column_break"
description: "Directives: column_break"
---

# Directives: column_break

Abbreviation: `cb`.

When printing songs in multiple columns, this directive forces printing to continue in the next column. When in the last (or only) column, this directive forces a page break just like the `new_page` directive.

Example:

    {column_break}
    {cb}

See also: [columns]({{< relref "Directives-columns" >}}).
