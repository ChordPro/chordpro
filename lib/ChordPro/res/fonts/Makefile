#!/bin/make -f

LIB = ../../..

publish :: ChordProSymbols.ttf
	cp -p $< ${LIB}/../docs/assets/pub/

ChordProSymbols.ttf :: makefont.pl ${LIB}/ChordPro/Symbols.pm strumarrow-*.svg
	perl -Mlib=${LIB} makefont.pl | python -


