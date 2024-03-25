#! /bin/make -f

ROOT	 := ../..
RES      := ${ROOT}/lib/ChordPro/res
EXAMPLES := ${EXAMPLES}
DOCS     := ${ROOT}/docs/assets/images

DEST     := ${HOME}/src/ChordPro-Frontpage/src/img/chordpro

CHORDPRO := CHORDPRO_LIB=. chordpro --nouserconfig

CONVERT  := convert -density 192 -quality 100 -alpha remove

default :
	@echo No default

EX := mollymalone background armenian nepali

examples : $(addsuffix .png,${EX})

%.png : %.pdf
	${CONVERT} $< $@
	cp -p $@ ${DEST}/examples-$@

%.pdf : %.cho
	${CHORDPRO} -o $@ $<


xx:
	${CONVERT} ${RES}/examples/mollymalone.pdf ${DEST}/examples-mollymalone.png
	${CONVERT} ${DOCS}/style_chordii.png ${DEST}/examples-chordii.png
	${CONVERT} ${DOCS}/style_dark.png ${DEST}/examples-dark.png
	${CONVERT} ${DOCS}/style_default.png ${DEST}/examples-default.png
	${CONVERT} ${DOCS}/style_keyboard.png ${DEST}/examples-keyboard.png
	${CONVERT} ${DOCS}/style_modern1.png ${DEST}/examples-modern1.png
	${CONVERT} ${DOCS}/style_modern2.png ${DEST}/examples-modern2.png
	${CONVERT} ${DOCS}/style_modern3.png ${DEST}/examples-modern3.png
	${CONVERT} ${DOCS}/style_ukulele.png ${DEST}/examples-ukulele.png
	${CONVERT} Cases/Devanagari/Come_To_Christ_Friend.pdf ${DEST}/examples-nepali.png
