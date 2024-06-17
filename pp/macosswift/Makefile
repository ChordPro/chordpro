#!/bin/make -f

CURRDATE := $(shell date "+%Y-%m-%d")
VV := $(shell perl ../../lib/ChordPro/Version.pm)
WRAPPERBIN := ChordProMac/ChordProMac/Bin
DMGNAME := ChordPro_MacOS-${VV}.dmg
MKDIR := mkdir
DEST := build

all: archive

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
	cd "../macos" && make clean

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

archive: xcodebuild
	@echo "Archive ChordPro"
	$(MKDIR) -p "${DEST}/ChordPro"
	cp -r "${DEST}/Release/ChordPro.app" "build/ChordPro"
	cp "ChordProMac/Read Me First.html" "${DEST}/ChordPro"
	rm -f "${DEST}/${DMGNAME}"
	hdiutil create -format UDZO -srcfolder build/ChordPro/ "${DEST}/${DMGNAME}"

clean:
	rm -fr ${DEST}
