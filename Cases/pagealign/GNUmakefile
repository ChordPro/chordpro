#! /bin/make -f

COVER  := --cover=cover.pdf
FRONT  := --front=front2.pdf
BACK   := --back=back.pdf

CHORDPRO := chordpro -X --config=pages.json --csv ${COVER} ${FRONT} ${BACK}
OPTS :=

default : test

PDEPS := pages.cho pages.json ../../lib/ChordPro/Output/PDF.pm cover.pdf

base := $(addprefix p,$(foreach x,e o,$(foreach y,0 1 2,$x$y)))
pdfs := $(addsuffix .pdf,${base})
csvs := $(addsuffix .csv,${base})

test :: clean ${pdfs}

cover.pdf :: makepages.pl
	perl makepages.pl

clean ::
	rm -fr *.pdf *.csv *~

# Define rule generating function.
define rule
p$(intcmp $(1),0,e,x,o)$(2).pdf : ${PDEPS}
	${CHORDPRO} $$< -o $$@ \
	  --def pdf.even-odd-pages=$(1) \
	  --def pdf.pagealign-songs=$(2) \
	  ${OPTS}
	setmeta.sh $$@
	diff $$(addprefix $$(basename $$@), .csv .ref)
endef

# Define the rules.
$(foreach even,-1 1,\
  $(foreach align,0 1 2,\
    $(eval $(call rule,${even},${align}))))
