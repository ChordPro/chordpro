---
title: "Preview Tasks"
description: "Preview Tasks"
---

# Preview Tasks

When you press the `Preview` button, ChordPro will generate a preview
using default settings. The `Tasks` menu can be used for customized
previews.

![]({{< asset "images/chordpro-gui-tasks-p1.png" >}})

You can choose between the normal, default preview, a preview without
chord diagrams, and a lyrics only preview for singers.

Choosing `More…` gives access to more possibilities.

![]({{< asset "images/chordpro-gui-tasks-p2.png" >}})

An important difference is that now you can *combine* multiple
settings.

## Transpose

If enabled, the song or all songs from the songbook will be transposed
by the specified amount of semitones. For example, to transpose a song
from key `C` to `D` requires two semitones.

If you transpose `B` up two semitones the result can be either `C♯` or `D♭`.
You can choose the desired behaviour from the dropdown list:

 * Sharps when transposing up, flats when transposing down
 * Always use sharps
 * Always use flats

## Custom Tasks

The real power comes with custom tasks — you can add your own presets
in the form of tasks. We'll explain 
[later]({{< relref "#how-to-create-custom-tasks" >}}) how to do this.

In the example below there is one custom task, `Chords on top`. 

![]({{< asset "images/chordpro-gui-tasks-p3.png" >}})

Not surprisingly, this will create a preview with the chord diagrams
on top of the page.

![]({{< asset "images/chordpro-gui-tasks-p4.png" >}})

## How to create custom tasks

A 'quick and dirty' guide to creating custom tasks. If you are
familiar with creating folders and files you can skip most of this.

1. You need to have a custom library. This can be an arbitrary,
   preferably empty folder. In this guide we use `ChordProLib` in the
   home folder. Consult your system documentation on how to create
   this folder.
   
2. In this folder, create a subfolder `tasks`.

3. In the `Preferences`, set `ChordProLib` as your `Custom ChordPro
   Library`.
   
4. ChordPro will inform you that it needs restarting. **Don't do this
   yet**.
   
5. Use the `File` > `New` menu to create a new song. Remove everything
   that is in the song so it is completely empty.
   
6. Type `pdf.diagrams.show: top` followed by Enter. 

   ![]({{< asset "images/chordpro-gui-tasks-p5.png" >}})

7. Use `File` > `Save As…` to get the `save` dialog. Navigate to your
   tasks folder and save with filename `Chords_on_top.json`. You need
   to manually type the filename.
   
8. Restart ChordPro. If everything went well there will be a task
   `Chords on top` added to the `Tasks` menu.
