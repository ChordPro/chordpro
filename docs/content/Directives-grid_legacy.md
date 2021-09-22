---
title: "Directives: grid"
description: "Directives: grid"
---

# Directives: grid

Abbreviation: `g`.

Enables printing of the list of chord diagrams at the end of the current song.

For persistent use, this can better be set in the [configuration files]({{< relref "ChordPro-Configuration" >}}). However, it is already set by default. The only use for the `grid` directive is to enable printing chord diagrams for the current song when printing the diagrams has been disabled globally.

You may consider the [chord]({{< relref "Directives-chord" >}}) directive as an alternative.

The name `grid` is an unfortunate legacy from the original chord program and must not be confused with the [chord grids]({{< relref "Directives-env_grid" >}}) facility.

# Directives: no_grid

Abbreviation: `ng`.

Disables printing of the list of chord diagrams at the end of the current song.

For persistent use, this can better be set in the [configuration files]({{< relref "ChordPro-Configuration" >}}). The only use for the `no_grid` directive is to disable printing chord diagrams for the current song when printing the diagrams has been enabled globally.

The name `grid` is an unfortunate legacy from the original chord program and must not be confused with the [chord grids]({{< relref "Directives-env_grid" >}}) facility.
