#! /bin/make -f

################ Pass-through ################

.PHONY : all
all :	Makefile cleanup
	mv Makefile.old Makefile
	$(MAKE) -f Makefile all

.PHONY : test
test : Makefile
	env PERL5LIB=$(shell pwd)/CPAN $(MAKE) -f Makefile test

.PHONY : tests
tests : test
	prove -b xt

.PHONY : clean
clean : cleanup
	rm -f *~

.PHONY : cleanup
cleanup : Makefile
	$(MAKE) -f Makefile clean

.PHONY : dist
dist : Makefile resources
	$(MAKE) -f Makefile dist

.PHONY : install
install : Makefile
	$(MAKE) -f Makefile install

Makefile : Makefile.PL lib/ChordPro/Version.pm resources
	perl Makefile.PL

################ Extensions ################

PERL := perl
PROJECT := ChordPro
RSYNC_ARGS := -rptgoDvHL

STDMNF := MANIFEST MANIFEST.CPAN

TMPDST := ${HOME}/tmp/${PROJECT}
to_tmp : resources
	for mnf in ${STDMNF} MANIFEST.WX MANIFEST.CPAN MANIFEST.PP ; do \
	    rsync ${RSYNC_ARGS} --files-from=$$mnf ./ ${TMPDST}/; \
	done

# Windows 10, for Windows installer builds.
WINDIR := /Users/Johan/${PROJECT}
WINDST := /mnt/c${WINDIR}
#WINDST := w10:${PROJECT}
to_win : resources
	for mnf in ${STDMNF} MANIFEST.WX ; do \
	    rsync ${RSYNC_ARGS} --files-from=$$mnf ./ ${WINDST}/; \
	done
	rsync ${RSYNC_ARGS} --files-from=MANIFEST.PP   \
	  --exclude=pp/macos/** --exclude=pp/macosswift/** \
	  --exclude=pp/linux/** --exclude=pp/debian/** \
	  ./ ${WINDST}/

# macOS Cataline 10.15, for classic builds.
MACHOST := macky
MACDST  := ${MACHOST}:${PROJECT}
to_mac : resources
	for mnf in ${STDMNF} MANIFEST.WX ; do \
	    rsync ${RSYNC_ARGS} --files-from=$$mnf ./ ${MACDST}/; \
	done
	rsync ${RSYNC_ARGS} --files-from=MANIFEST.PP   \
	  --exclude=pp/windows/** --exclude=pp/macosswift/** \
	  --exclude=pp/debian/** \
	  ./ ${MACDST}/

# macOS Monterey 12/7/5, for Swift GUI builds.
MACCHODST  := maccho:${PROJECT}
to_maccho : resources
	for mnf in ${STDMNF} ; do \
	    rsync ${RSYNC_ARGS} --files-from=$$mnf ./ ${MACCHODST}/; \
	done
	rsync ${RSYNC_ARGS} --files-from=MANIFEST.PP   \
	  --exclude=pp/windows/** --exclude=pp/debian/** \
	  ./ ${MACCHODST}/

release :
	${PERL} Makefile.PL
	${MAKE} -f Makefile all test dist

# Actualize resources.

LIB := lib/ChordPro
RES := ${LIB}/res
PODSELECT := podselect

resources : ${LIB}/Config/Data.pm ${RES}/config/chordpro.json ${RES}/pod/ChordPro.pod ${RES}/pod/Config.pod ${RES}/pod/A2Crd.pod docs/assets/pub/config60.schema

${LIB}/Config/Data.pm : ${RES}/config/chordpro.json
	perl script/cfgboot.pl $< > $@~
	cmp $@ $@~ || mv $@~ $@

${RES}/pod/ChordPro.pod : ${LIB}.pm
	${PODSELECT} $< > $@

${RES}/pod/Config.pod : ${RES}/config/chordpro.json
	( echo "=head1 ChordPro Default Configuration"; \
	  echo ""; \
	  echo "=encoding UTF8"; \
	  echo ""; \
	  perl -pe 's/^/    /' $< ) > $@

${RES}/pod/A2Crd.pod : ${LIB}/A2Crd.pm
	${PODSELECT} $< > $@

docs/assets/pub/config61.schema : ${RES}/config/config.schema
	cp -p $< $@

# Verify JSON data

CFGLIB := ${LIB}/res/config
JSONVALIDATOR = java -jar lib/jar/json-schema-validator-*-lib.jar
JSONOPTS := --brief

checkjson :
	rm -fr .json
	mkdir .json
	for i in ${CFGLIB}/*.json ; \
	do \
	  perl -Ilib/ChordPro/lib script/rrjson.pl --json $$i > .json/`basename $$i`; \
	done
	cd .json; rm keyboard.json dark.json resetchords.json
	${JSONVALIDATOR} ${JSONOPTS} \
	  ${CFGLIB}/config.schema .json/*.json
	rm -fr .json

# Experimental

WINVM := Win10Pro

wkit : _wkit1 _wkit _wkit2

_wkit :
	${MAKE} to_win
	ssh ${WIN} gmake -C ChordPro/pp/windows
	scp ${WIN}:ChordPro/pp/windows/ChordPro-Installer\*.exe ${HOME}/tmp/

_wkit1 :
	-VBoxManage startvm ${WINVM} --type headless

_wkit2 :
	sudo umount /misc/c
	VBoxManage controlvm ${WINVM} poweroff
	VBoxManage snapshot ${WINVM} restorecurrent

DEB := debby
DEBVM := Debian

appimage : _akit1 _akit _akit2

_akit :
	rsync -avHi ./ ${DEB}:ChordPro/ --exclude .git --exclude build --exclude docs
	ssh ${DEB} make -C ChordPro/pp/debian
	scp ${DEB}:ChordPro/pp/debian/ChordPro-\*.AppImage ${HOME}/tmp/

_akit1 :
	-VBoxManage startvm ${DEBVM} --type headless

_akit2 :
	VBoxManage controlvm ${DEBVM} poweroff
	VBoxManage snapshot ${DEBVM} restorecurrent

.PHONY: TAGS

TAGS:
	etags.emacs `grep '\.p[lm]' MANIFEST`

.PHONY: svg

svg :
	cp -p ${HOME}/src/SVGPDF/lib/SVGPDF.pm lib/ChordPro/lib
	cp -p ${HOME}/src/SVGPDF/lib/SVGPDF/*.pm lib/ChordPro/lib/SVGPDF/
	cp -p ${HOME}/src/SVGPDF/lib/SVGPDF/Contrib/*.pm lib/ChordPro/lib/SVGPDF/Contrib/

.PHONY: svg

rrjson :
	mkdir -p lib/ChordPro/lib/JSON/Relaxed
	cp -p ${HOME}/src/JSON-Relaxed/lib/JSON/Relaxed.pm \
	  lib/ChordPro/lib/JSON/
	cp -p ${HOME}/src/JSON-Relaxed/lib/JSON/Relaxed/Parser.pm \
	  ${HOME}/src/JSON-Relaxed/lib/JSON/Relaxed/ErrorCodes.pm \
	  lib/ChordPro/lib/JSON/Relaxed/
	cp -p ${HOME}/src/JSON-Relaxed/scripts/rrjson.pl \
	  script/

ABCDEST    = ${RES}/abc/abc2svg

# 1.22.14
ABCKIT     = abc2svg-be8faee2b4

# 1.22.18 + Fix for grid widths.
ABCKIT     = abc2svg-fca05cd348

# 1.22.18 + 'lm' and 'width' for grids
ABCKIT     = abc2svg-9b12853f66

.PHONY: abc

abc :
	rm -f ${ABCDEST}/*
	perl ABC/build.pl --dest=${ABCDEST} ABC/${ABCKIT}.tar.gz 
	cp -p ABC/README.FIRST ABC/cmdline.js ${ABCDEST}/
	grep -v ${ABCDEST} MANIFEST > x
	find ${ABCDEST} -type f -printf "%p\n" \
	  | sort -u >> x
	mv x MANIFEST
