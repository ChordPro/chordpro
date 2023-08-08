#!/usr/bin/python

import fontforge
import sys
import os
import struct
import psMat

dst = None
src = None

# Copy a glyph from f to the next slot, optionally tranforming
# it using the matrix tf.

def gcopy(name, f, tf = 0 ):
    global src, dst
    global ind
    src.selection.select(f)
    src.copy()
    dst.selection.select(ind)
    ind += 1
    dst.paste()
    for glyph in dst.selection.byGlyphs:
        glyph.glyphname = name
        if tf:
            glyph.transform(tf)
    
# Create new font, set some properties.
dst  = fontforge.font()
dst.fontname = "ChordProSymbols"
dst.familyname = "MusicalSymbolsForChordPro"
dst.fullname = "Musical Symbols For ChordPro"
dst.copyright = "Open Font License"
dst.version = "000.300"
dst.em = 2048;

# Next slot for glyphs.
ind = 33;

# Copy glyphs from Symbols font.
src = fontforge.open("Cadman.ttf")
gcopy( "Flat",    0x266d )
gcopy( "Natural", 0x266e )
gcopy( "Sharp",   0x266f )

# Copy bar symbols.
src = fontforge.open("Bravura.otf")
src.em = dst.em
gcopy( "uniE040", 0xe040 )
gcopy( "uniE041", 0xe041 )
gcopy( "uniE042", 0xe042 )

# We're missing a fullly filled circle for unfingered strings.
# MANUALLY CHANGED /slash -> black circle.
src = fontforge.open("ChordProSymbolsBase.ttf")
src.em = dst.em
ind = 47
gcopy( "slash", ind )

src = fontforge.open("NotoSansSymbols-Regular.ttf")
src.em = dst.em
ind = 48
gcopy( chr(ord("0")),  0x24ff )
for i in range(1,10):
    gcopy( chr(ord("0")+i),  0x2789+i )

ind = 65
xdst = 0x1F150
for i in range(0,26):
    gcopy( chr(ord("A")+i),  xdst+i )

# Generate new font.
dst.generate("ChordProSymbols.ttf")
