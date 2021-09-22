---
title: "Directives: new_physical_page"
description: "Directives: new_physical_page"
---

# Directives: new_physical_page

Abbreviation: `npp`.

This directive is legacy from the original `chord` program. This program had the ability to print multiple song pages on a physical paper, so called [N-up printing](https://en.wikipedia.org/wiki/N-up).

With N-up printing, a `new_page` directive generates a new song page. The `new_physical_page` directive would force printing on a new sheet of paper.

N-up printing is no longer supported by ChordPro. PDF viewing and printing tools can handle this should you need it.

Example:

    {new_physical_page}
    {npp}

