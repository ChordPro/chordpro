#! /bin/make -f

# GNUmakefile for Linux + wxGTK3

.PHONY :: chordpro wxchordpro

ROOT   := ../..
COMMON := ../common
SCRIPT := ${ROOT}/script
DEST   := build
VERSION := $(shell perl ../../lib/ChordPro/Version.pm)

PP := pp -u

default : appimage

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
PERLSO  := $(shell perl -wle 'printf("libperl.so.%d.%d\n",$$1,$$2) if $$] =~ /^(\d+)\.(\d\d\d)/')

.PHONY :: ppl
ppl :: clean wxchordpro unpack copy_coredll loaders

.PHONY :: unpack
unpack :
	perl ../pp2ppl.pl --dest=${DEST} wxchordpro --quiet
	cp -p "${ROOT}/script/chordpro.pl" "${DEST}/script/chordpro.pl" 
	cp -p "${ROOT}/lib/ChordPro/Config.pm" "${DEST}/lib/ChordPro/Config.pm" 
	cp "${DEST}/res/icons/chordpro.ico" ${DEST}
	mv "${DEST}/res" "${DEST}/lib/ChordPro/"

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
	find . -type f -name '*.so' -exec patchelf --set-rpath '$$ORIGIN' {} \;
	find . -type f -name '*.so.*' -exec patchelf --set-rpath '$$ORIGIN' {} \;

PREFIX := '"script/"'
CCOPTS := $(shell perl -MExtUtils::Embed -e ccopts) -DSCRIPTPREFIX=${PREFIX}
LDOPTS := -Wl,--rpath='$${ORIGIN}' ${DEST}/${PERLSO} -lpthread
LDOPTS := -Wl,--rpath='$$ORIGIN' ${DEST}/${PERLSO} -lpthread

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

# Build AppImage.
APPIMAGETOOL := appimagetool

appimage : ppl
	cp AppRun ${DEST}
	cd ${DEST}; ln lib/ChordPro/res/linux/chordpro.desktop .
	cd ${DEST}; ln lib/ChordPro/res/icons/chordpro.png .
	${APPIMAGETOOL} -n ${DEST} ChordPro-${VERSION}.AppImage

# Truly dynamic version of loader. Rename to {wx}chordpro if you dare.

"${DEST}/poc" : poc.c
	${CC} ${CCOPTS} -o "${DEST}/poc" poc.c -ldl
