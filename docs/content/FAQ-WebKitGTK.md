---
title: 'Preview does not show, and I get “Failed to get GBM device”'
description: 'Preview does not show, and I get “Failed to get GBM device”'
---

# Preview does not show, and I get “Failed to get GBM device”

This is most likely a problem with your video driver. 

Try setting environment variable `WEBKIT_DISABLE_COMPOSITING_MODE` to
`1` before starting ChordPro.

For more details, see [this issue](https://github.com/QubesOS/qubes-issues/issues/9595).
