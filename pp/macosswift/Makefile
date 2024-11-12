#!/bin/make -f

CURRDATE := $(shell date "+%Y-%m-%d")
VERSION  := $(shell perl ../../lib/ChordPro/Version.pm)
ROOT     := ../..
COREDIR  := ChordProMac/ChordProMac/Core
MKDIR    := mkdir
DEST     := build
# Check if we build on Intel or ARM
ARCH     := $(shell uname -m)

all : dmg

chordpro:
	@echo "Building ChordPro core"
	cd "../macos" && make ppl TARGET=chordpro
	@echo "Code signing..."
	codesign --force -s - "../macos/build/libperl.dylib"
	find  "../macos/build/" -name '*.bundle' -type f | while read bundle; do codesign --force -s - "$$bundle"; done
	@echo "Copy core to the wrapper..."
	rm -fr "${COREDIR}"
	$(MKDIR) -p "${COREDIR}/cli"
	cp -r "../macos/build/chordpro" "${COREDIR}"
	cp -r "../macos/build/libperl.dylib" "${COREDIR}"
	cp -r "../macos/build/lib" "${COREDIR}"
	cp -r "../macos/build/script" "${COREDIR}"
	cd "${COREDIR}"; ln -s -v ../chordpro cli/chordpro
	@echo "Cleanup core..."
	cd "../macos" && make clean TARGET=chordpro

xcodebuild: chordpro
	@echo "Building ChordProMac"
	rm -fr "${DEST}/XcodeSource"
	$(MKDIR) -p "${DEST}/XcodeSource"
	cp -R "ChordProMac" "${DEST}/XcodeSource"
	xcodebuild -project ${DEST}/XcodeSource/ChordProMac/ChordProMac.xcodeproj \
		-arch ${ARCH} \
		CODE_SIGN_IDENTITY="-" \
		CODE_SIGNING_REQUIRED=YES \
		BUILD_DIR=../../../build
	rm -fr "${COREDIR}"

APPDIR := ${DEST}/ChordPro/ChordPro.app

archive: xcodebuild
	@echo "Archive ChordPro"
	$(MKDIR) -p "${DEST}/ChordPro"
	cp -R "${DEST}/Release/ChordPro.app" "${DEST}/ChordPro"

dmg : archive dmg1

ifeq (${ARCH},x86_64)
ARCHTYPE := Intel
DMGNAME := ChordPro-${VERSION}-macOS-INTEL.dmg
else
ARCHTYPE := Apple Silicon
DMGNAME := ChordPro-${VERSION}-macOS-ARM.dmg
endif

dmg1 :
	rm -f ${DMGNAME}
	bash ../macos/create-dmg \
		--volname "ChordPro (${ARCHTYPE})" \
		--volicon ../macos/chordpro-dmg.icns \
		--window-pos 200 120 \
		--window-size 680 440 \
		--icon-size 64 \
		--icon "ChordPro.app" 540 75 \
		--hide-extension "ChordPro.app" \
		--add-file "READ ME FIRST.html" ../macos/README.html  540 175 \
		--hide-extension "READ ME FIRST.html" \
		--add-file "Install.zsh" ../macos/Install.zsh 540 275 \
		--hide-extension "Install.zsh" \
		--background "${ROOT}/lib/ChordPro/res/icons/chordpro-bg.png" \
		"${DMGNAME}" "${APPDIR}"

clean ::
	rm -fr "${DEST}"

realclean :: clean
	rm -f "${DMGNAME}"
