CURRDATE := $(shell date "+%Y-%m-%d")
TESTBUILDDIR := TestBuild
DMGNAME := ChordPro macOS ${CURRDATE}.dmg
MKDIR := mkdir

DEST   := build

WRAPPERBIN := ChordProMac/ChordProMac/Bin

all: archive
	
chordpro:
	@echo "Building ChordPro core"
	cd "../macos" && make ppl TARGET=chordpro
	@echo "Code signing..."
	codesign --force -s - "../macos/build/libperl.dylib"
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
	rm -f "${TESTBUILDDIR}/${DMGNAME}"
	hdiutil create -format UDZO -srcfolder build/ChordPro/ "${DEST}/${DMGNAME}"
	
clean:
	rm -fr ${DEST}