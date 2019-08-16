#! /bin/make -f
# GNUmakefile for Linux + CitrusPerl
# Based on CitrusPerl 5.24 with wxWidgets 3.0.

.PHONY : chordpro wxchordpro

ROOT   := ../..
COMMON := ../common
SCRIPT := ${ROOT}/script

# Perlbrew for CitrusPerl.
PP := perl -Ilib/perl5 -Mlocal::lib=lib/perl5 bin/pp
WXLIBS := /bulk/perlbrew/perls/citrus-5.24.1-wx-3.0/vendor/lib/Alien/wxWidgets/gtk_3_0_2_uni/lib

chordpro : res chordpro.pp ${COMMON}/chordpro.pp
	${PP} --output=chordpro @chordpro.pp ${SCRIPT}/chordpro.pl

wxchordpro : res chordpro.pp ${COMMON}/chordpro.pp ${COMMON}/wxchordpro.pp
	env LD_LIBRARY_PATH=${WXLIBS} \
	${PP} --output=wxchordpro @wxchordpro.pp ${SCRIPT}/wxchordpro.pl

res :
	test -f ${ROOT}/GNUmakefile && make -C ${ROOT} -f GNUmakefile resources || true

clean ::
	rm -f *.pp.deps *~ chordpro wxchordpro
