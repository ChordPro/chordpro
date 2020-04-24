#! /bin/make -f
# GNUmakefile for Linux + CitrusPerl

.PHONY : chordpro wxchordpro

ROOT   := ../..
COMMON := ../common
SCRIPT := ${ROOT}/script

PP := pp -u

chordpro : chordpro.pp ${COMMON}/chordpro.pp
	${PP} --output=chordpro @chordpro.pp ${SCRIPT}/chordpro.pl

wxchordpro : chordpro.pp ${COMMON}/chordpro.pp ${COMMON}/wxchordpro.pp
	${PP} --output=wxchordpro @wxchordpro.pp ${SCRIPT}/wxchordpro.pl

clean ::
	rm -f *.pp.deps *~ chordpro wxchordpro
