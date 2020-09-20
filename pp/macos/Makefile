#! /bin/make -f

# GNUmakefile for MacOS, Citrus Perl

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

PERLLIB := $(shell perl -MConfig -E 'say $$Config{archlib}')
PERLINC := ${PERLLIB}/perl5/CORE
PERLSO  := libperl.dylib

.PHONY :: ppl
ppl :: clean chordpro wxchordpro unpack copy_coredll loaders

.PHONY :: unpack
unpack :
	perl ../pp2ppl.pl --dest=${DEST} wxchordpro --quiet
	perl ../pp2ppl.pl --dest=${DEST} chordpro   --quiet
	cp -p "${ROOT}/lib/App/Music/ChordPro/Config.pm" "${DEST}/lib/App/Music/ChordPro/Config.pm" 
	cp "${DEST}/res/icons/chordpro.icns" ${DEST}
	mv "${DEST}/res" "${DEST}/lib/App/Music/ChordPro/"
	rm -f "${DEST}/script/main.pl"

# Copy core DLLs.
# We assume that the target system has the primary ddls like -ldl, -lc, ...
copy_coredll :
	cp -pL ${PERLLIB}/../citrus/dll/libperl.dylib ${DEST}/${PERLSO}
	install_name_tool -id  @executable_path/libperl.dylib ${DEST}/${PERLSO}

PREFIX := '"script/"'
CCOPTS := $(shell perl -MExtUtils::Embed -e ccopts) -DSCRIPTPREFIX=${PREFIX}
LDOPTS := ${DEST}/${PERLSO} -lpthread

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
	rm -fr ${DEST}

# Truly dynamic version of loader. Rename to {wx}chordpro if you dare.

"${DEST}/poc" : poc.c
	${CC} ${CCOPTS} -o "${DEST}/poc" poc.c -ldl

APPDIR := ChordPro.app

app : ppl app1

app1 :
	rm -fr ${APPDIR}
	cp -a "${DEST}/" "${APPDIR}/"
	cp "${DEST}/chordpro.icns" "${APPDIR}"
	mkdir -p "${APPDIR}/Contents/MacOS"
	mkdir -p "${APPDIR}/Contents/Resources"
	cp PkgInfo Info.plist "${APPDIR}/Contents"
	cp "${DEST}/chordpro.icns" "${APPDIR}/Contents/Resources"
	cd "${APPDIR}"; mv chordpro wxchordpro Contents/MacOS
	cd "${APPDIR}"; mv script lib Contents/MacOS
	cd "${APPDIR}"; mv lib*.dylib Contents/MacOS
	cd "${APPDIR}"; rm -f MANIFEST META.yml

dmg : app dmg1

dmg1 :
	rm -f Chordpro-Installer.dmg
	bash create-dmg \
		--volname "ChordPro Installer" \
		--volicon "${APPDIR}/chordpro.icns" \
		ChordPro-Installer.dmg "${APPDIR}"

clean ::
	rm -fr ${APPDIR}
