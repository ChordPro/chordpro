#! make

LIB := ../../lib
RES := ${LIB}/App/Music/ChordPro/res
CHORDPRO := perl ${LIB}/../script/chordpro -X
CONVERT := convert -define profile:skip=ICC
GS := gs -q -dNOPAUSE -dBATCH
GSPNG := ${GS} -sDEVICE=png16m -dGraphicsAlphaBits=4 -dTextAlphaBits=4 -r144
GSPNG := ${GS} -sDEVICE=pngalpha -r144
CVT_BORDER := -compose copy -bordercolor black -border 1
CVT_WBORDER := -compose copy -bordercolor white -border 10

default : all

all : pages styles examples pageformats.png

#### Pages.

pages : $(subst .cho,.png,$(wildcard page_*.cho))

page_%.png : page_%.cho
	${CHORDPRO} $< --output=t.pdf
	${CONVERT} -alpha remove ${CVT_BORDER} -density 150 t.pdf $@
	${CONVERT} -resize 300x300 ${CVT_BORDER} $@ $(subst .png,-small.png,$@)

#### Styles.

STYLES := modern1 modern2 modern3 chordii dark roman nashville ukulele keyboard

styles : $(foreach sty,${STYLES},style_${sty}.png)

style_default.png : style_chordpro.png
	cp style_chordpro.png style_default.png
	cp style_chordpro-small.png style_default-small.png

style_%.png : ${RES}/config/%.json
	${CHORDPRO} --config=$< \
	  ${RES}/examples/swinglow.cho --output=t.pdf
	${CONVERT} -alpha remove ${CVT_BORDER} -density 150 t.pdf $@
	${CONVERT} -resize 300x300 ${CVT_BORDER} $@ $(subst .png,-small.png,$@)

#### Examples.

examples : $(subst .cho,.png,$(wildcard ex_*.cho)) ex_clean

ex_%.png : ex_%.cho
	${CHORDPRO} $< --output=t.pdf
	${GSPNG} -r115 -sOutputFile=- t.pdf \
	| ${CONVERT} -trim -alpha remove ${CVT_WBORDER} png:- png:- \
	| ${CONVERT} ${CVT_BORDER} png:- $@

ex_clean :
	rm -f ?.png ?.pdf

pageformats.png : pageformats.cho pageformats.json
	${CHORDPRO} pageformats.cho --no-toc --config pageformats.json --output=x.pdf
	rm -f x-*.png
	${CONVERT} -alpha remove -resize 300x300 ${CVT_BORDER} x.pdf x.png
	${CONVERT} +append x-*.png $@
	rm -f x.pdf x-*.png

#### Publish.

DST := ../../docs/assets/images

publish : all 
	rsync -avHi *.png ${DST}/

clean :: ex_clean
	rm -f ex_*.png page_*.png style_*.png x-*.png *~ 
