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
dst.familyname = "ChordProSymbols"
dst.fullname = "Musical Symbols For ChordPro"
dst.copyright = "Open Font License"
dst.version = "000.400"
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
gcopy( "uniE043", 0xe043 )
# Copy repeat symbols.
tf = psMat.compose(psMat.translate(0,600),psMat.scale(1.5))
gcopy( "uni1D10F", 0x1d10f, tf )
gcopy( "uni1D10E", 0x1d10e, tf )

src = fontforge.open("Cadman.ttf")
gcopy( "delta", 0x25b3 )

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

# Inkscape export >>selection<<

ind = 0x2190    # arrows
tf = psMat.compose(psMat.scale(0.71),psMat.translate(150,291))
# Custom location.
arrow = dst.createChar( ind, 'strumarrow-up' )
arrow.importOutlines('arrow-up.svg')
arrow.transform(tf)
arrow.width = 1150
ind += 1
# Accented
arrow = dst.createChar( ind, 'strumarrow-up-acc' )
arrow.importOutlines('arrow-up-acc.svg')
arrow.transform(tf)
arrow.width = 1150
ind += 1
# Arpeggio
arrow = dst.createChar( ind, 'strumarrow-up-arp' )
arrow.importOutlines('arrow-up-arp.svg')
arrow.transform(tf)
arrow.width = 1150
ind += 1
# Muted
arrow = dst.createChar( ind, 'strumarrow-up-mut' )
arrow.importOutlines('arrow-up-mut.svg')
arrow.transform(tf)
arrow.width = 1150
ind += 1
arrow = dst.createChar( ind, 'strumarrow-up-mxt' )
arrow.importOutlines('arrow-up-mxt.svg')
arrow.transform(tf)
arrow.width = 1150
ind += 1
arrow = dst.createChar( ind, 'strumarrow-up-dot' )
arrow.importOutlines('arrow-up-dot.svg')
arrow.transform(tf)
arrow.width = 1150
ind += 1
arrow = dst.createChar( ind, 'strumarrow-up-dot-acc' )
arrow.importOutlines('arrow-up-dot-acc.svg')
arrow.transform(tf)
arrow.width = 1150
ind += 1
arrow = dst.createChar( ind, 'strumarrow-up-mut-acc' )
arrow.importOutlines('arrow-up-mut-acc.svg')
arrow.transform(tf)
arrow.width = 1150
ind += 1
arrow = dst.createChar( ind, 'strumarrow-up-mxt-acc' )
arrow.importOutlines('arrow-up-mxt-acc.svg')
arrow.transform(tf)
arrow.width = 1150
ind += 1
arrow = dst.createChar( ind, 'strumarrow-up-arp-acc' )
arrow.importOutlines('arrow-up-arp-acc.svg')
arrow.transform(tf)
arrow.width = 1150
ind += 1

ind = 0x21a0
tf = psMat.compose(psMat.scale(0.71),psMat.translate(150,270))
arrow = dst.createChar( ind, 'strumarrow-down' )
arrow.importOutlines('arrow-down.svg')
arrow.transform(tf)
arrow.width = 1150
ind += 1
arrow = dst.createChar( ind, 'strumarrow-down-acc' )
arrow.importOutlines('arrow-down-acc.svg')
arrow.transform(tf)
arrow.width = 1150
ind += 1
arrow = dst.createChar( ind, 'strumarrow-down-arp' )
arrow.importOutlines('arrow-down-arp.svg')
arrow.transform(tf)
arrow.width = 1150
ind += 1
arrow = dst.createChar( ind, 'strumarrow-down-mut' )
arrow.importOutlines('arrow-down-mut.svg')
arrow.transform(tf)
arrow.width = 1150
ind += 1
arrow = dst.createChar( ind, 'strumarrow-down-mxt' )
arrow.importOutlines('arrow-down-mxt.svg')
arrow.transform(tf)
arrow.width = 1150
ind += 1
arrow = dst.createChar( ind, 'strumarrow-down-dot' )
arrow.importOutlines('arrow-down-dot.svg')
arrow.transform(tf)
arrow.width = 1150
ind += 1
arrow = dst.createChar( ind, 'strumarrow-down-dot-acc' )
arrow.importOutlines('arrow-down-dot-acc.svg')
arrow.transform(tf)
arrow.width = 1150
ind += 1
arrow = dst.createChar( ind, 'strumarrow-down-mut-acc' )
arrow.importOutlines('arrow-down-mut-acc.svg')
arrow.transform(tf)
arrow.width = 1150
ind += 1
arrow = dst.createChar( ind, 'strumarrow-down-mxt-acc' )
arrow.importOutlines('arrow-down-mxt-acc.svg')
arrow.transform(tf)
arrow.width = 1150
ind += 1
arrow = dst.createChar( ind, 'strumarrow-down-arp-acc' )
arrow.importOutlines('arrow-down-arp-acc.svg')
arrow.transform(tf)
arrow.width = 1150
ind += 1

# Generate new font.
dst.generate("ChordProSymbols.ttf")
