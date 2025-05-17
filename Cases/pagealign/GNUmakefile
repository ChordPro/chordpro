#! /bin/make -f

CHORDPRO := chordpro

OPTS =
_OPTS = -o pages.pdf pages.cho -X --csv
_OPTS += --cover cover.pdf
_OPTS += --front front.pdf
_OPTS += --back-matter back.pdf
# _OPTS += --def pdf.outlines.bookmarks.omit=false

CFG := cfg.json

default : test

pages.pdf : pages.cho cover.pdf ${CFG}
	${CHORDPRO} --cfg ${CFG} ${_OPTS} ${OPTS}  
	cp -p pages.pdf ${HOME}/tmp/x.pdf

cover.pdf :: makepages.pl
	perl makepages.pl

clean ::
	rm -fr *.pdf *~

PDEPS := pages.cho pages.json ../../lib/ChordPro/Output/PDF.pm

pn0.pdf : ${PDEPS}
	${CHORDPRO} $< -X --cfg pages.json --csv -o $@ \
	  --cover cover.pdf --front front2.pdf --back back.pdf \
	  --def pdf.even-odd-pages=0 \
	  --def pdf.pagealign-songs=0
	diff $(basename $@).{csv,ref}

pn1.pdf : ${PDEPS}
	${CHORDPRO} $< -X --cfg pages.json --csv -o $@ \
	  --cover cover.pdf --front front2.pdf --back back.pdf \
	  --def pdf.even-odd-pages=0 \
	  --def pdf.pagealign-songs=1
	diff $(basename $@).{csv,ref}

pn2.pdf : ${PDEPS}
	${CHORDPRO} $< -X --cfg pages.json --csv -o $@ \
	  --cover cover.pdf --front front2.pdf --back back.pdf \
	  --def pdf.even-odd-pages=0 \
	  --def pdf.pagealign-songs=2
	diff $(basename $@).{csv,ref}

po0.pdf : ${PDEPS}
	${CHORDPRO} $< -X --cfg pages.json --csv -o $@ \
	  --cover cover.pdf --front front2.pdf --back back.pdf \
	  --def pdf.even-odd-pages=1 \
	  --def pdf.pagealign-songs=0
	diff $(basename $@).{csv,ref}

po1.pdf : ${PDEPS}
	${CHORDPRO} $< -X --cfg pages.json --csv -o $@ \
	  --cover cover.pdf --front front2.pdf --back back.pdf \
	  --def pdf.even-odd-pages=1 \
	  --def pdf.pagealign-songs=1
	diff $(basename $@).{csv,ref}

po2.pdf : ${PDEPS}
	${CHORDPRO} $< -X --cfg pages.json --csv -o $@ \
	  --cover cover.pdf --front front2.pdf --back back.pdf \
	  --def pdf.even-odd-pages=1 \
	  --def pdf.pagealign-songs=2
	diff $(basename $@).{csv,ref}

pe0.pdf : ${PDEPS}
	${CHORDPRO} $< -X --cfg pages.json --csv -o $@ \
	  --cover cover.pdf --front front2.pdf --back back.pdf \
	  --def pdf.even-odd-pages=-1 \
	  --def pdf.pagealign-songs=0
	diff $(basename $@).{csv,ref}

pe1.pdf : ${PDEPS}
	${CHORDPRO} $< -X --cfg pages.json --csv -o $@ \
	  --cover cover.pdf --front front2.pdf --back back.pdf \
	  --def pdf.even-odd-pages=-1 \
	  --def pdf.pagealign-songs=1
	diff $(basename $@).{csv,ref}

pe2.pdf : ${PDEPS}
	${CHORDPRO} $< -X --cfg pages.json --csv -o $@ \
	  --cover cover.pdf --front front2.pdf --back back.pdf \
	  --def pdf.even-odd-pages=-1 \
	  --def pdf.pagealign-songs=2
	diff $(basename $@).{csv,ref}

test :
	rm -f p{e,o,n}{0,1,2}.{pdf,csv}
	perl makepages.pl
	${MAKE} $(shell echo p{e,o,n}{0,1,2}.pdf)
