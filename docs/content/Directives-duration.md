---
title: "Directives: duration"
description: "Directives: duration"
---

# Directives: duration

This directive specifies the duration of the song. This can be a number
indicating seconds, or a time specification conforming to the extended
ordinal time format as defined in
[ISO 8601](https://en.wikipedia.org/wiki/ISO_8601#Times). For example,
durations `268` (seconds) and `4:28` (readable) are the same.

Duration will always be shown in readable format.

Examples:

    {duration: 268}
    {meta: duration 4:28}

See also: [meta]({{< relref "Directives-meta" >}}).
