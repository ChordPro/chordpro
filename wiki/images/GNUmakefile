#! make

LIB := ../../lib
RES := ${LIB}/App/Music/ChordPro/res
CHORDPRO := perl ${LIB}/../script/chordpro -X
CONVERT := convert
GS := gs -q -dNOPAUSE -dBATCH
GSPNG := ${GS} -sDEVICE=png16m -dGraphicsAlphaBits=4 -dTextAlphaBits=4 -r144
GSPNG := ${GS} -sDEVICE=pngalpha -r144
CVT_BORDER := -compose copy -bordercolor black -border 1
CVT_WBORDER := -compose copy -bordercolor white -border 10

default : all

all : styles examples simple.png labels.png pageformats.png

#### Styles.

STYLES := modern1 modern2 modern3 chordii default roman nashville ukulele

define STYLE_template =
 style_${1}.png :
	${CHORDPRO} \
	  --config=${RES}/config/${1}.json \
	  ${RES}/examples/swinglow.cho --output=style_${1}.pdf
	${CONVERT} -alpha remove -resize 300x300 ${CVT_BORDER} style_${1}.pdf style_${1}.png
endef

$(foreach sty,${STYLES},$(eval $(call STYLE_template,$(sty))))

styles : $(foreach sty,${STYLES},style_${sty}.png)

#### Examples.

EXAMPLES := chordcolour chord chords chords2 define grid1 grid2 image tabcolour textcolour

examples : $(foreach ex,${EXAMPLES},ex_${ex}.png) ex_clean

ex_chordcolour.png : ex_chordcolour.cho
	${CHORDPRO} $< --output=t.pdf
	${GSPNG} -sOutputFile=- t.pdf \
	| ${CONVERT} -trim -alpha remove -resize 50% ${CVT_WBORDER} png:- png:- \
	| ${CONVERT} ${CVT_BORDER} png:- $@

ex_chord.png : ex_chord.cho
	${CHORDPRO} $< --output=t.pdf
	${GSPNG} -r200 -sOutputFile=- t.pdf \
	| ${CONVERT} -trim -alpha remove ${CVT_WBORDER} png:- png:- \
	| ${CONVERT} ${CVT_BORDER} png:- $@

ex_chords.png : ex_chords.cho
	${CHORDPRO} $< --output=t.pdf
	${GSPNG} -r200 -sOutputFile=- t.pdf \
	| ${CONVERT} -trim -alpha remove ${CVT_WBORDER} png:- png:- \
	| ${CONVERT} ${CVT_BORDER} png:- $@

ex_chords2.png : ex_chords2.cho
	${CHORDPRO} $< --output=t.pdf
	${GSPNG} -r200 -sOutputFile=- t.pdf \
	| ${CONVERT} -trim -alpha remove ${CVT_WBORDER} png:- png:- \
	| ${CONVERT} ${CVT_BORDER} png:- $@

ex_kbdiagram.png : ex_kbdiagram.cho
	${CHORDPRO} --def diagrams.type=keyboard $< --output=t.pdf
	${GSPNG} -r200 -sOutputFile=- t.pdf \
	| ${CONVERT} -trim -alpha remove ${CVT_WBORDER} png:- png:- \
	| ${CONVERT} ${CVT_BORDER} png:- $@

ex_define.png : ex_define.cho
	${CHORDPRO} $< --output=t.pdf
	${GSPNG} -r200 -sOutputFile=- t.pdf \
	| ${CONVERT} -trim -alpha remove ${CVT_WBORDER} png:- png:- \
	| ${CONVERT} ${CVT_BORDER} png:- $@

ex_grid1.png : ex_grid1.cho
	${CHORDPRO} $< --output=t.pdf
	${GSPNG} -r115 -sOutputFile=- t.pdf \
	| ${CONVERT} -trim -alpha remove ${CVT_WBORDER} png:- png:- \
	| ${CONVERT} ${CVT_BORDER} png:- $@

ex_grid2.png : ex_grid2.cho
	${CHORDPRO} $< --output=t.pdf
	${GSPNG} -r115 -sOutputFile=- t.pdf \
	| ${CONVERT} -trim -alpha remove ${CVT_WBORDER} png:- png:- \
	| ${CONVERT} ${CVT_BORDER} png:- $@

ex_image.png : ex_image.cho score.jpg
	${CHORDPRO} $< --output=t.pdf
	${GSPNG} -sOutputFile=- t.pdf \
	| ${CONVERT} -trim -alpha remove -resize 50% ${CVT_WBORDER} png:- png:- \
	| ${CONVERT} ${CVT_BORDER} png:- $@

ex_tabcolour.png : ex_tabcolour.cho
	${CHORDPRO} $< --output=t.pdf
	${GSPNG} -r200 -sOutputFile=- t.pdf \
	| ${CONVERT} -trim -alpha remove -resize 50% ${CVT_WBORDER} png:- png:- \
	| ${CONVERT} ${CVT_BORDER} png:- $@

ex_textcolour.png : ex_textcolour.cho
	${CHORDPRO} $< --output=t.pdf
	${GSPNG} -sOutputFile=- t.pdf \
	| ${CONVERT} -trim -alpha remove ${CVT_WBORDER} png:- png:- \
	| ${CONVERT} ${CVT_BORDER} png:- $@

ex_clean :
	rm -f ?.png ?.pdf

simple.png : ${RES}/examples/swinglow.cho 
	${CHORDPRO} ${RES}/examples/swinglow.cho --output=simple.pdf
	${CONVERT} -alpha remove -resize 300x300 ${CVT_BORDER} simple.pdf $@

labels.png : labels.cho 
	${CHORDPRO} labels.cho --output=labels.pdf \
	  --define pdf.indent=70
	${CONVERT} -alpha remove -resize 300x300 ${CVT_BORDER} labels.pdf $@

pageformats.png : pageformats.cho pageformats.json
	${CHORDPRO} pageformats.cho --no-toc --config pageformats.json --output=x.pdf
	rm -f x-*.png
	${CONVERT} -alpha remove -resize 300x300 ${CVT_BORDER} x.pdf x.png
	${CONVERT} +append x-*.png $@
	rm -f x.pdf x-*.png

#### Publish.

DST := ../../docs/assets/images

publish : all 
	rsync -avHi *.pdf *.png ${DST}/

clean :: ex_clean
	rm -f ex_*.png style_*.pdf style_*.png simple.png x-*.png *~ 
