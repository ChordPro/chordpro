#! /bin/make -f

# GNUmakefile for Linux + wxGTK3

.PHONY :: chordpro wxchordpro

ROOT   := ../..
COMMON := ../common
BASE   := ../linux
SCRIPT := ${ROOT}/script
DEST   := build
VERSION := $(shell perl ../../lib/ChordPro/Version.pm)
TARGET := wxchordpro

PP := pp

default : appimage

# PAR Packer.

chordpro : chordpro.pp ${COMMON}/chordpro.pp
	${PP} --output=chordpro @chordpro.pp ${SCRIPT}/chordpro.pl

wxchordpro : wxchordpro.pp ${COMMON}/chordpro.pp ${COMMON}/wxchordpro.pp
	${PP} --output=wxchordpro @wxchordpro.pp ${SCRIPT}/wxchordpro.pl

clean ::
	rm -f *.pp.deps *~ chordpro wxchordpro

# Portable Perl Launcher

SYSLIB := /usr/lib/x86_64-linux-gnu
PERL_SO  := $(shell ldd `which perl`|perl -ne 's/^.* => (.*libperl.so.*) \(.*\)/$$1/ && print')
PERLSO  := $(shell perl -wle 'printf("libperl.so.%d.%d\n",$$1,$$2) if $$] =~ /^(\d+)\.(\d\d\d)/')

.PHONY :: ppl
ppl :: clean ${TARGET} unpack copy_coredll loaders

.PHONY :: unpack
unpack :
	perl ../pp2ppl.pl --dest=${DEST} ${TARGET} --quiet
	cp -p "${ROOT}/script/chordpro.pl" "${DEST}/script/chordpro.pl"
	cp -p "${ROOT}/lib/ChordPro/Config.pm" "${DEST}/lib/ChordPro/Config.pm"
	cp "${DEST}/res/icons/chordpro.ico" ${DEST}
	mv "${DEST}/res" "${DEST}/lib/ChordPro/"

# Copy core DLLs.
# We assume that the target system has:
#        linux-vdso.so.1
#        libdl.so.2
#        libc.so.6
#        libm.so.6
#        libpthread.so.1
#        libcrypt.so.2
#        /lib64/ld-linux-x86-64.so.2

copy_coredll :
	cp -pL ${SYSLIB}/libperl.so ${DEST}/${PERLSO}
	patchelf --set-soname ${PERLSO} ${DEST}/${PERLSO}
	find . -type f -name '*.so' -exec patchelf --set-rpath '$$ORIGIN' {} \;
	find . -type f -name '*.so.*' -exec patchelf --set-rpath '$$ORIGIN' {} \;

PREFIX := '"script/"'
CCOPTS := $(shell perl -MExtUtils::Embed -e ccopts) -DSCRIPTPREFIX=${PREFIX}
LDOPTS := $(shell perl -MExtUtils::Embed -e ldopts)

.PHONY :: loaders
loaders : "${DEST}/${TARGET}" "${DEST}/chordpro"

# For testing...
.PHONY :: _loaders
_loaders : "${DEST}/chordpro"
	cp "${DEST}/chordpro" "${DEST}/perl"

"${DEST}/wxchordpro" : ${BASE}/ppl.c
	${CC} ${CCOPTS} -o "${DEST}/wxchordpro" -L${DEST} \
	    ${BASE}/ppl.c ${SYSLIB}/libperl.a ${SYSLIB}/libcrypt.a -lm ${LDOPTS}

"${DEST}/chordpro" : ${BASE}/ppl.c
	${CC} ${CCOPTS} -o "${DEST}/chordpro" -L${DEST} \
	    ${BASE}/ppl.c ${SYSLIB}/libperl.a ${SYSLIB}/libcrypt.a -lm ${LDOPTS}

clean ::
	rm -fr build

# Build AppImage.
APPIMAGETOOL := appimagetool

appimage : ppl _appimage

_appimage :
	cp ${BASE}/AppRun ${DEST}/AppRun
	chmod 0755 ${DEST}/AppRun
	cd ${DEST}; ln -f lib/ChordPro/res/linux/chordpro.desktop .
	cd ${DEST}; ln -f lib/ChordPro/res/icons/chordpro.png .
	${APPIMAGETOOL} -n ${DEST} ChordPro-${VERSION}.AppImage
