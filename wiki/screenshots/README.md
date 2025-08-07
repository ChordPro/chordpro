# Creating screenshots

Virtualbox with Rawhide, Gnome, white background.

Install ~/.config/wxchordpro/wxchordpro.

Run wxchordpro and hide the terminal window. Wxchordpro should be in
the center of the screen.

Before taking a screenshot, move the pointer out of the chordpro
window!

User Host+E for a screenshot.

Or
````
VBoxManage controlvm Rawhide screenshotpng orig.png
````

# Processing the screenshots

For a full-window shot:

````
magick orig.png -shave 50x50 -define "trim:percent-background=0%" -trim new.png
````

The result is a 900x600 image.

(Note: the shave is to get rid of the top bar.)

# ssget

The script `ssget` takes a screenshot and prepares it:

````
ssget new.png
````

Note: For screenshots that show focus-active content (e.g. drop down
menu's) the Host + E approach is required.

# Prepared data

Unpack the zip in $HOME.

.config/wxchordpro/wxchordpro
lib/ChordPro/config/myconfig.json
lib/ChordPro/tasks/Chords_On_Top.json
Music/Irish_Ballads/Kilkelly.cho
Music/Irish_Ballads/May_Morning_Dew.cho
Music/Irish_Ballads/My_Donald.cho
Music/Irish_Ballads/Nancy_Spain.cho
Music/Irish_Ballads/One_Way_Journey_Home.cho
Music/Irish_Ballads/Only_Our_Rivers.cho
Music/Irish_Ballads/On_Raglan_Road.cho
Music/Irish_Ballads/Peat_Bog_Soldiers.cho
Music/Irish_Ballads/CustomCover.pdf
Music/examples/swinglow.cho
Music/examples/mollymalone.cho


