#! /bin/make -f

COVER  := --cover=cover.pdf
FRONT  := --front=front2.pdf
BACK   := --back=back.pdf

CHORDPRO := chordpro -X --config=pages.json --csv ${COVER} ${FRONT} ${BACK}
OPTS :=

ifeq (${ONE},)
default : test
else
default : one
endif

PDEPS := pages.cho pages.json ../../lib/ChordPro/Output/PDF.pm cover.pdf

base := $(addprefix p,\
$(foreach x,n e o,\
$(foreach y,0 1 2,\
$(foreach z,1 2,$x$y$z))))
base += po11p po11c
pdfs := $(addsuffix .pdf,${base})
csvs := $(addsuffix .csv,${base})

test :: clean ${pdfs}

cover.pdf :: makepages.pl
	perl makepages.pl

clean ::
	rm -fr *.pdf *.csv *~

# Define rule generating function.
define rule
p$(intcmp $(1),0,e,n,o)$(2)$(3).pdf : ${PDEPS}
	${CHORDPRO} $$< -o $$@ \
	  --def pdf.even-odd-pages=$(1) \
	  --def pdf.pagealign-songs=$(2) \
	  $$(if $(3),--start-page-number=$(3)) \
	  ${OPTS}
	setmeta.sh $$@
	diff $$(addprefix $$(basename $$@), .csv .ref)
endef

# Define the rules.
$(foreach even,-1 0 1,\
  $(foreach align,0 1 2,\
    $(foreach page,1 2,\
      $(eval $(call rule,${even},${align},${page})))))

po11c.pdf : ${PDEPS}
	${CHORDPRO} $< -o $@ \
	  --def pdf.even-odd-pages=1 \
	  --def pdf.pagealign-songs=1 \
	  --start-page-number=1 \
	  --def pdf.sort-pages=compact \
	  ${OPTS}
	setmeta.sh $@
	diff $(addprefix $(basename $@), .csv .ref)

po11p.pdf : ${PDEPS}
	${CHORDPRO} $< -o $@ \
	  --def pdf.even-odd-pages=1 \
	  --def pdf.pagealign-songs=1 \
	  --start-page-number=1 \
	  --def pdf.sort-pages=2page \
	  ${OPTS}
	setmeta.sh $@
	diff $(addprefix $(basename $@), .csv .ref)

one :
	rm -f ${ONE}
	${MAKE} ${ONE}; cp ${ONE} ${HOME}/tmp/x.pdf
