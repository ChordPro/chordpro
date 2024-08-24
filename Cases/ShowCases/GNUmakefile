#! /bin/make -f

ROOT	 := ../..
RES      := ${ROOT}/lib/ChordPro/res
EXAMPLES := ${EXAMPLES}
DOCS     := ${ROOT}/docs/assets/images

DEST     := ${HOME}/src/ChordPro-Frontpage/src/img/chordpro

CHORDPRO := CHORDPRO_LIB=. chordpro --noa2crd --nouserconfig

CONVERT  := convert -density 192 -quality 100 -alpha remove

default :
	@echo No default

################ Examples ################

EXAMPLES := mollymalone background twelvedays armenian nepali \
	    biscuit1 biscuit2

examples : $(addprefix example-,$(addsuffix .png,${EXAMPLES}))

example-biscuit1.pdf : prefab-biscuit1.pdf
	cp -p $< $@

example-biscuit2.pdf : prefab-biscuit2.pdf
	cp -p $< $@

clean_examples ::
	rm -f example-*.pdf example-*.png

################ Styles ################

STYLES   := chordpro chordii modern1 modern2 modern3 ukulele keyboard dark

styles   : $(addprefix style-,$(addsuffix .png,${STYLES}))

style-chordpro.pdf : basic2.cho
	${CHORDPRO} -X --cfg chordpro -o $@ $<

# Chordii default is US Letter format.
style-chordii.pdf : basic2.cho
	${CHORDPRO} -X --cfg chordii --def pdf.papersize=a4 -o $@ $<

style-modern1.pdf : basic2.cho
	${CHORDPRO} -X --cfg modern1 -o $@ $<

style-modern2.pdf : basic1.cho
	${CHORDPRO} -X --cfg modern2 -o $@ $<

style-modern3.pdf : basic1.cho
	${CHORDPRO} -X --cfg modern3 -o $@ $<

style-ukulele.pdf : basic2.cho
	${CHORDPRO} -X --cfg ukulele -o $@ $<

style-keyboard.pdf : basic2.cho
	${CHORDPRO} -X --cfg keyboard -o $@ $<

style-dark.pdf : basic2.cho
	${CHORDPRO} -X --cfg dark -o $@ $<

clean_styles ::
	rm -f style-*.pdf style-*.png

################ Generic  ################

%.png : %.pdf
	${CONVERT} $< $@
	cp -p $@ ${DEST}/$@

%.pdf : %.cho
	${CHORDPRO} -o $@ $<

clean :: clean_examples clean_styles
	rm -f *~

