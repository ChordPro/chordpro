#! /bin/make -f

# GNUmakefile for MacOS, Wx 3.2

.PHONY :: chordpro wxchordpro

ROOT   := ../..
COMMON := ../common
BASE   := ../linux
SCRIPT := ${ROOT}/script
DEST   := build
VERSION := $(shell perl ../../lib/ChordPro/Version.pm)
TARGET := wxchordpro
PP := pp
# Check if we build on Intel or ARM
ARCH   := $(shell uname -m)

default : dmg

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
PERLSO  := $(shell perl -MConfig -E 'say $$Config{libperl}')

.PHONY :: ppl
ppl :: clean ${TARGET} unpack copy_coredll loaders

.PHONY :: unpack
unpack :
	perl ../pp2ppl.pl --dest=${DEST} ${TARGET} --quiet
	cp -p "${ROOT}/script/chordpro.pl" "${DEST}/script/chordpro.pl" 
	cp -p "${ROOT}/lib/ChordPro/Config.pm" "${DEST}/lib/ChordPro/Config.pm" 
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
ifeq (${TARGET},wxchordpro)
WXCLIB := $(shell perl -MAlien::wxWidgets -E 'say Alien::wxWidgets->prefix')
WXCNFG := ${WXCLIB}/bin/wx-config
endif

.PHONY :: loaders
loaders : "${DEST}/${TARGET}" "${DEST}/chordpro"

# For testing...
.PHONY :: _loaders
_loaders : "${DEST}/chordpro"
	cp "${DEST}/chordpro" "${DEST}/perl"

"${DEST}/wxchordpro" : ${BASE}/ppl.c dndhandler.swift
	${CC} -DMACOS ${CCOPTS} -o "${DEST}/wxchordpro" -L${DEST} ${LDOPTS} ${BASE}/ppl.c
	swiftc dndhandler.swift -target ${ARCH}-apple-macos10.15 -o "${DEST}/dndhandler"

"${DEST}/chordpro" : ${BASE}/ppl.c
	${CC} -DMACOS ${CCOPTS} -o "${DEST}/chordpro" -L${DEST} ${LDOPTS} ${BASE}/ppl.c

clean ::
	rm -fr ${DEST}

APPDIR := ChordPro.app

# http://www.mactipsandtricks.com/website/articles/Wiley_HT_appBundles2.lasso

app : ppl app1

app1 :
	rm -fr ${APPDIR} || rm -fr ${APPDIR}
	cp -a "${DEST}/" "${APPDIR}/"
	mkdir -p "${APPDIR}/Contents/MacOS"
	mkdir -p "${APPDIR}/Contents/Resources/cli"
	cp PkgInfo Info.plist "${APPDIR}/Contents"
	cp *.icns "${APPDIR}/Contents/Resources"
	cd "${APPDIR}"; mv script lib Contents/MacOS
	cd "${APPDIR}"; mv lib*.dylib Contents/MacOS
	cd "${APPDIR}"; rm -f MANIFEST META.yml
ifeq (${TARGET},wxchordpro)
	cd "${APPDIR}"; mv chordpro wxchordpro dndhandler Contents/MacOS
	perl ./reloc.pl ${APPDIR}/Contents/MacOS/libpng16.*.dylib
	perl ./reloc.pl ${APPDIR}/Contents/MacOS/libjpeg.*.dylib
	perl ./reloc.pl ${APPDIR}/Contents/MacOS/libtiff.*.dylib
	perl ./reloc.pl ${APPDIR}/Contents/MacOS/libz*.dylib
	perl ./reloc.pl ${APPDIR}/Contents/MacOS/libpcre2-32.*.dylib
	perl ./reloc.pl ${APPDIR}/Contents/MacOS/libwx*.dylib
	perl ./reloc.pl ${APPDIR}/Contents/MacOS/lib/auto/Wx/*.bundle
	perl ./reloc.pl ${APPDIR}/Contents/MacOS/lib/auto/Wx/*/*.bundle
	cd "${APPDIR}"; ln -s ../../MacOS/chordpro Contents/Resources/cli/chordpro
ifeq (${ARCH},arm64)
	find  "${APPDIR}/Contents/" -name '*.dylib' -type f | while read bundle; do codesign --force -s - "$$bundle"; done
	find  "${APPDIR}/Contents/" -name '*.bundle' -type f | while read bundle; do codesign --force -s - "$$bundle"; done
	codesign --force --deep -s - ${APPDIR}
endif
else
	cd "${APPDIR}"; cp chordpro dndhandler
	cd "${APPDIR}"; mv chordpro dndhandler Contents/MacOS
endif

dmg : app dmg1

ifeq (${TARGET},wxchordpro)
VOLTYPE := Classic
else
VOLTYPE := CLI
endif

ifeq (${ARCH},x86_64)
ARCHTYPE := Intel
DMGNAME := ChordPro-${VOLTYPE}-${VERSION}-macOS-INTEL.dmg
else
ARCHTYPE := Apple Silicon
DMGNAME := ChordPro-${VOLTYPE}-${VERSION}-macOS-ARM.dmg
endif

dmg1 :
	rm -f ${DMGNAME}
	bash ./create-dmg \
		--volname "ChordPro ${VOLTYPE} (${ARCHTYPE})" \
		--volicon chordpro-dmg.icns \
		--window-pos 200 120 \
		--window-size 680 440 \
		--icon-size 64 \
		--icon "${APPDIR}" 540 75 \
		--hide-extension "${APPDIR}" \
		--add-file "READ ME FIRST.html" README.html  540 175 \
		--hide-extension "READ ME FIRST.html" \
		--add-file "Install.zsh" Install.zsh 540 275 \
		--hide-extension "Install.zsh" \
		--background "${DEST}/lib/ChordPro/res/icons/chordpro-bg.png" \
		"${DMGNAME}" "${APPDIR}"

clean ::
	rm -fr ${APPDIR}

realclean :: clean
	rm -f "${DMGNAME}"
