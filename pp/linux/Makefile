#! /bin/make -f

# GNUmakefile for Linux + wxGTK3

.PHONY :: chordpro wxchordpro

ROOT   := ../..
COMMON := ../common
SCRIPT := ${ROOT}/script
DEST   := build

PP := pp -u

# PAR Packer.

chordpro : chordpro.pp ${COMMON}/chordpro.pp
	${PP} --output=chordpro @chordpro.pp ${SCRIPT}/chordpro.pl

wxchordpro : chordpro.pp ${COMMON}/chordpro.pp ${COMMON}/wxchordpro.pp
	${PP} --output=wxchordpro @wxchordpro.pp ${SCRIPT}/wxchordpro.pl

clean ::
	rm -f *.pp.deps *~ chordpro wxchordpro

# Portable Perl Launcher

PERLLIB := /usr/lib64
PERLINC := ${PERLLIB}/perl5/CORE
PERLSO  := $(shell perl -wle 'printf("perl%d%06d.so\n",$$1,$$2) if $$] =~ /^(\d+)\.(\d\d\d\d\d\d)/')

.PHONY :: ppl
ppl :: clean chordpro wxchordpro unpack copy_coredll loaders

.PHONY :: unpack
unpack :
	perl ../pp2ppl.pl --dest=${DEST} wxchordpro --quiet
	perl ../pp2ppl.pl --dest=${DEST} chordpro   --quiet
	cp -p "${ROOT}/lib/App/Music/ChordPro/Config.pm" "${DEST}/lib/App/Music/ChordPro/Config.pm" 
	cp "${DEST}/res/icons/chordpro.ico" ${DEST}
	mv "${DEST}/res" "${DEST}/lib/App/Music/ChordPro/"

# Copy code DLLs.
# We assume that the target system has:
#        linux-vdso.so.1
#        libdl.so.2
#        libc.so.6
#        libm.so.6
#        libcrypt.so.2
#        /lib64/ld-linux-x86-64.so.2

copy_coredll :
	cp -pL ${PERLLIB}/libperl.so ${DEST}/${PERLSO}
	patchelf --set-soname ${PERLSO} ${DEST}/${PERLSO}
	cp -pL ${PERLLIB}/libpthread.so.0 ${DEST}/

PREFIX := '"script/"'
CCOPTS := $(shell perl -MExtUtils::Embed -e ccopts) -DSCRIPTPREFIX=${PREFIX}
LDOPTS := -Wl,--rpath='$${ORIGIN}' ${DEST}/${PERLSO} -lpthread

.PHONY :: loaders
loaders : "${DEST}/wxchordpro" "${DEST}/chordpro"

# For testing...
.PHONY :: _loaders
_loaders : "${DEST}/chordpro"
	cp "${DEST}/chordpro" "${DEST}/perl"

"${DEST}/wxchordpro" : ppl.c
	${CC} ${CCOPTS} -o "${DEST}/wxchordpro" -L${DEST} ${LDOPTS} ppl.c

"${DEST}/chordpro" : ppl.c
	${CC} ${CCOPTS} -o "${DEST}/chordpro" -L${DEST} ${LDOPTS} ppl.c

clean ::
	rm -fr build

# Truly dynamic version of loader. Rename to {wx}chordpro if you dare.

"${DEST}/poc" : poc.c
	${CC} ${CCOPTS} -o "${DEST}/poc" poc.c -ldl
