#! /bin/make -f

# GNUmakefile for MacOS, Citrus Perl

default : dmg

.PHONY :: chordpro wxchordpro

ROOT   := ../..
COMMON := ../common
SCRIPT := ${ROOT}/script
DEST   := build
VERSION := $(shell perl ../../lib/ChordPro/Version.pm)

PP := pp

# PAR Packer.

chordpro : chordpro.pp ${COMMON}/chordpro.pp
	${PP} --output=chordpro @chordpro.pp ${SCRIPT}/chordpro.pl

wxchordpro : chordpro.pp ${COMMON}/chordpro.pp ${COMMON}/wxchordpro.pp
	perl wxchordpro_pp.pl > wxchordpro.pp
	${PP} --output=wxchordpro @wxchordpro.pp ${SCRIPT}/wxchordpro.pl

clean ::
	rm -f *.pp.deps *~ chordpro wxchordpro

# Portable Perl Launcher

PERLLIB := $(shell perl -MConfig -E 'say $$Config{archlib}')
PERLINC := ${PERLLIB}/perl5/CORE
PERLSO  := $(shell perl -MConfig -E 'say $$Config{libperl}')

.PHONY :: ppl
ppl :: clean wxchordpro unpack copy_coredll loaders

.PHONY :: unpack
unpack :
	perl ../pp2ppl.pl --dest=${DEST} wxchordpro --quiet
	cp -p "${ROOT}/script/chordpro.pl" "${DEST}/script/chordpro.pl" 
	cp -p "${ROOT}/lib/ChordPro/Config.pm" "${DEST}/lib/ChordPro/Config.pm" 
	cp "${DEST}/res/icons/chordpro.icns" ${DEST}
	cp "${DEST}/res/icons/chordpro-doc.icns" ${DEST}
	mv "${DEST}/res" "${DEST}/lib/ChordPro/"
	rm -f "${DEST}/script/main.pl"

# Copy core DLLs.
# We assume that the target system has the primary ddls like -ldl, -lc, ...
copy_coredll :
	cp -pL ${PERLLIB}/CORE/libperl.dylib ${DEST}/${PERLSO}
	install_name_tool -id  @executable_path/${PERLSO} ${DEST}/${PERLSO}

PREFIX := '"script/"'
CCOPTS := $(shell perl -MExtUtils::Embed -e ccopts) -DSCRIPTPREFIX=${PREFIX}
LDOPTS := ${DEST}/${PERLSO} -lpthread
WXCLIB := $(shell perl -MAlien::wxWidgets -E 'say Alien::wxWidgets->prefix')
WXCNFG := ${WXCLIB}/bin/wx-config

.PHONY :: loaders
loaders : "${DEST}/wxchordpro" "${DEST}/chordpro"

# For testing...
.PHONY :: _loaders
_loaders : "${DEST}/chordpro"
	cp "${DEST}/chordpro" "${DEST}/perl"

"${DEST}/wxchordpro" : ppl.c dndhandler.cpp
	${CC} ${CCOPTS} -o "${DEST}/wxchordpro" -L${DEST} ${LDOPTS} ppl.c
	${CXX} -o "${DEST}/dndhandler" \
		dndhandler.cpp `${WXCNFG} --cxxflags --libs`
	perl ./reloc.pl "${DEST}/dndhandler"

"${DEST}/chordpro" : ppl.c
	${CC} ${CCOPTS} -o "${DEST}/chordpro" -L${DEST} ${LDOPTS} ppl.c

clean ::
	rm -fr ${DEST}

# Truly dynamic version of loader. Rename to {wx}chordpro if you dare.

"${DEST}/poc" : poc.c
	${CC} ${CCOPTS} -o "${DEST}/poc" poc.c -ldl

APPDIR := ChordPro.app

# http://www.mactipsandtricks.com/website/articles/Wiley_HT_appBundles2.lasso

app : ppl app1

app1 :
	rm -fr ${APPDIR} || rm -fr ${APPDIR}
	cp -a "${DEST}/" "${APPDIR}/"
	mkdir -p "${APPDIR}/Contents/MacOS"
	mkdir -p "${APPDIR}/Contents/Resources"
	cp PkgInfo Info.plist "${APPDIR}/Contents"
	cp "${DEST}/chordpro.icns" "${APPDIR}/Contents/Resources"
	cp "${DEST}/chordpro-doc.icns" "${APPDIR}/Contents/Resources"
	cd "${APPDIR}"; mv chordpro wxchordpro dndhandler Contents/MacOS
	cd "${APPDIR}"; mv script lib Contents/MacOS
	cd "${APPDIR}"; mv lib*.dylib Contents/MacOS
	cd "${APPDIR}"; rm -f MANIFEST META.yml
	perl ./reloc.pl ${APPDIR}/Contents/MacOS/libpng16.*.dylib
	perl ./reloc.pl ${APPDIR}/Contents/MacOS/libjpeg.*.dylib
	perl ./reloc.pl ${APPDIR}/Contents/MacOS/libtiff.*.dylib
	perl ./reloc.pl ${APPDIR}/Contents/MacOS/libz*.dylib
	perl ./reloc.pl ${APPDIR}/Contents/MacOS/libpcre2-32.*.dylib
	perl ./reloc.pl ${APPDIR}/Contents/MacOS/libwx*.dylib
	perl ./reloc.pl ${APPDIR}/Contents/MacOS/lib/auto/Wx/*.bundle
	perl ./reloc.pl ${APPDIR}/Contents/MacOS/lib/auto/Wx/*/*.bundle

dmg : app dmg1

DMG := ChordPro-Installer-${VERSION}.dmg

dmg1 :
	rm -f ${DMG}
	bash ./create-dmg \
		--volname "ChordPro Installer" \
		--volicon "${APPDIR}/chordpro.icns" \
		--window-pos 200 200 \
		--window-size 600 300 \
		--icon "${APPDIR}" 50 50 \
		--add-file "READ ME FIRST.html" README.html 300 50 \
		--hide-extension "READ ME FIRST.html" \
		${DMG} "${APPDIR}"

clean ::
	rm -fr ${APPDIR}
