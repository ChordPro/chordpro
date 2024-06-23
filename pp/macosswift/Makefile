#!/bin/make -f

CURRDATE := $(shell date "+%Y-%m-%d")
VERSION := $(shell perl ../../lib/ChordPro/Version.pm)
WRAPPERBIN := ChordProMac/ChordProMac/Bin
DMGNAME := ChordPro-${VERSION}.dmg
MKDIR := mkdir
DEST := build

all : dmg

chordpro:
	@echo "Building ChordPro core"
	cd "../macos" && make ppl TARGET=chordpro
	@echo "Code signing..."
	codesign --force -s - "../macos/build/libperl.dylib"
	find  "../macos/build/" -name '*.bundle' -type f | while read bundle; do codesign --force -s - "$$bundle"; done
	@echo "Copy core to the wrapper..."
	rm -fr "${WRAPPERBIN}"
	$(MKDIR) -p "${WRAPPERBIN}"
	cp -r "../macos/build/chordpro" "${WRAPPERBIN}"
	cp -r "../macos/build/libperl.dylib" "${WRAPPERBIN}"
	cp -r "../macos/build/lib" "${WRAPPERBIN}"
	cp -r "../macos/build/script" "${WRAPPERBIN}"
	@echo "Cleanup core..."
	cd "../macos" && make clean TARGET=chordpro
	@echo "Add core info to the wrapper..."
	${WRAPPERBIN}/chordpro -A -A -A -> ${WRAPPERBIN}/ChordProInfo.json

xcodebuild: chordpro
	@echo "Building ChordProMac"
	rm -fr "${DEST}/XcodeSource"
	$(MKDIR) -p "${DEST}/XcodeSource"
	cp -r "ChordProMac" "${DEST}/XcodeSource"
	xcodebuild -project ${DEST}/XcodeSource/ChordProMac/ChordProMac.xcodeproj \
		-arch x86_64 \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO \
		BUILD_DIR=../../../build
	rm -fr "${WRAPPERBIN}"

APPDIR := ${DEST}/ChordPro/ChordPro.app

archive: xcodebuild
	@echo "Archive ChordPro"
	$(MKDIR) -p "${DEST}/ChordPro"
	cp -r "${DEST}/Release/ChordPro.app" "${DEST}/ChordPro"

dmg : archive dmg1

dmg1 :
	rm -f "${DMGNAME}"
	bash ../macos/create-dmg \
	    --volname ChordPro \
	    --volicon "${APPDIR}/Contents/Resources/lib/ChordPro/res/icons/chordpro.icns" \
	    --window-pos 200 200 \
	    --window-size 600 300 \
	    --icon "ChordPro.app" 50 50 \
	    --add-file "READ ME FIRST.html" "ChordProMac/Read Me First.html" 300 50 \
	    --hide-extension "READ ME FIRST.html" \
	    "${DMGNAME}" "${APPDIR}"

clean ::
	rm -fr "${DEST}"

realclean :: clean
	rm -f "${DMGNAME}"
