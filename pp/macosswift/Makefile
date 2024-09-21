#!/bin/make -f

CURRDATE := $(shell date "+%Y-%m-%d")
VERSION := $(shell perl ../../lib/ChordPro/Version.pm)
ROOT   := ../..
COREDIR := ChordProMac/ChordProMac/Core
MKDIR := mkdir
DEST := build

# ARCH can be 'x86_64' for Intel or 'arm64' for Apple Silicon
ARCH := x86_64

all : dmg

chordpro:
	@echo "Building ChordPro core"
	cd "../macos" && make ppl TARGET=chordpro
	@echo "Code signing..."
	codesign --force -s - "../macos/build/libperl.dylib"
	find  "../macos/build/" -name '*.bundle' -type f | while read bundle; do codesign --force -s - "$$bundle"; done
	@echo "Copy core to the wrapper..."
	rm -fr "${COREDIR}"
	$(MKDIR) -p "${COREDIR}"
	cp -r "../macos/build/chordpro" "${COREDIR}"
	cp -r "../macos/build/libperl.dylib" "${COREDIR}"
	cp -r "../macos/build/lib" "${COREDIR}"
	cp -r "../macos/build/script" "${COREDIR}"
	@echo "Cleanup core..."
	cd "../macos" && make clean TARGET=chordpro

xcodebuild: chordpro
	@echo "Building ChordProMac"
	rm -fr "${DEST}/XcodeSource"
	$(MKDIR) -p "${DEST}/XcodeSource"
	cp -r "ChordProMac" "${DEST}/XcodeSource"
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
	cp -r "${DEST}/Release/ChordPro.app" "${DEST}/ChordPro"

dmg : archive dmg1

ifeq (${ARCH},x86_64)
VOLTYPE := Intel
DMGNAME := ChordPro-${VERSION}-macOS-INTEL.dmg
else
VOLTYPE := Apple Silicon
DMGNAME := ChordPro-${VERSION}-macOS-ARM.dmg
endif

dmg1 :
	rm -f ${DMGNAME}
	bash ../macos/create-dmg \
	    --volname "ChordPro (${VOLTYPE})" \
	    --volicon "${APPDIR}/Contents/Resources/AppIcon.icns" \
	    --window-pos 200 200 \
	    --window-size 640 500 \
	    --icon-size 64 \
	    --add-file "READ ME FIRST.html" README.html 530 50 \
	    --icon "ChordPro.app" 530 150 \
	    --hide-extension "READ ME FIRST.html" \
	    --app-drop-link 530 250 \
	    --background "${ROOT}/lib/ChordPro/res/icons/chordpro-bg.png" \
	    "${DMGNAME}" "${APPDIR}"

clean ::
	rm -fr "${DEST}"

realclean :: clean
	rm -f "${DMGNAME}"
