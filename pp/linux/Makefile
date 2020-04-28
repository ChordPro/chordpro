#! /bin/make -f

# GNUmakefile for Linux + wxGTK3

.PHONY : chordpro wxchordpro ppl

ROOT   := ../..
COMMON := ../common
SCRIPT := ${ROOT}/script
DIST := dist

PP := pp -u

# PAR Packer.

chordpro : chordpro.pp ${COMMON}/chordpro.pp
	${PP} --output=chordpro @chordpro.pp ${SCRIPT}/chordpro.pl

wxchordpro : chordpro.pp ${COMMON}/chordpro.pp ${COMMON}/wxchordpro.pp
	${PP} --output=wxchordpro @wxchordpro.pp ${SCRIPT}/wxchordpro.pl

# Portable Perl Launcher

PERLLIB := /usr/lib64
PERLINC := ${PERLLIB}/perl5/CORE

ppl :: chordpro wxchordpro _ppl

_ppl :
	rm -fr ${DIST}
	perl ../pp2ppl.pl --dest=${DIST} wxchordpro --quiet
	perl ../pp2ppl.pl --dest=${DIST} chordpro --quiet
	cp -p ${PERLLIB}/libperl.so.5.30 ${DIST}
	${CC} -o perl       -I${PERLINC} ${COMMON}/ppl.c
	${CC} -o chordpro   -I${PERLINC} ${COMMON}/ppl.c
	${CC} -o wxchordpro -I${PERLINC} ${COMMON}/ppl.c

clean ::
	rm -f *.pp.deps *~ chordpro wxchordpro
