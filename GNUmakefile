#! /bin/make -f

################ Pass-through ################

.PHONY : all
all :	Makefile cleanup
	mv Makefile.old Makefile
	$(MAKE) -f Makefile all

.PHONY : test
test : Makefile
	env PERL5LIB=$(shell pwd)/CPAN:$(shell pwd)/aux $(MAKE) -f Makefile test

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
	for mnf in ${STDMNF} MANIFEST.CPAN MANIFEST.PP ; do \
	    rsync ${RSYNC_ARGS} --files-from=$$mnf ./ ${TMPDST}/; \
	done

# Windows 10, for Windows installer builds.
WINVM  := Win10Pro
WINDIR := /Users/Johan/Documents/${PROJECT}
WIN    := w10
WINMNT := /mnt/c
WINDST := ${WINMNT}/${WINDIR}

to_win : resources
	for mnf in ${STDMNF} ; do \
	    rsync ${RSYNC_ARGS} --files-from=$$mnf ./ ${WINDST}/; \
	done
	rsync ${RSYNC_ARGS} --files-from=MANIFEST.PP   \
	  --exclude=pp/macos/** \
	  --exclude=pp/linux/** --exclude=pp/debian/** \
	  ./ ${WINDST}/

# macOS Cataline 10.15, for classic builds.
MACHOST := macky
MACDST  := ${MACHOST}:Documents/${PROJECT}
to_mac : resources
	for mnf in ${STDMNF} ; do \
	    rsync ${RSYNC_ARGS} --files-from=$$mnf ./ ${MACDST}/; \
	done
	rsync ${RSYNC_ARGS} --files-from=MANIFEST.PP   \
	  --exclude=pp/windows/** \
	  --exclude=pp/debian/** \
	  ./ ${MACDST}/

# macOS Monterey 12/7/5, for Swift GUI builds.
MACCHODST  := maccho:Documents/${PROJECT}
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

wxg :
	make -C lib/ChordPro/Wx

sym :
	make -C lib/ChordPro/res/fonts

# Actualize resources.

LIB := lib/ChordPro
RES := ${LIB}/res
PODSELECT := podselect

RESOURCES := wxg ${LIB}/Config/Data.pm ${RES}/config/chordpro.json
RESOURCES += ${RES}/pod/ChordPro.pod ${RES}/pod/Config.pod ${RES}/pod/A2Crd.pod
RESOURCES += docs/assets/pub/config60.schema

resources : ${RESOURCES}

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
# JSONVALIDATOR = java -jar lib/jar/json-schema-validator-*-lib.jar
# JSONOPTS := --brief
# This requires npm install ajv-cli .
JSONVALIDATOR = ajv --validate-formats=false
JSONOPTS := --allowUnionTypes=true

checkjson :
	rm -fr .json
	mkdir .json
	cp -p ${CFGLIB}/config.schema .json/schema.json
	for i in $(shell git ls-files ${CFGLIB}) ; \
	do \
	  case "$$i" in \
	    */keyboard.json)    continue;; \
	    */dark.json)        continue;; \
	    */notes/*)          continue;; \
	    */*.tmpl)           continue;; \
	    */*.schema)         continue;; \
	  esac; \
	  perl -Ilib/ChordPro/lib script/rrjson.pl --json $$i > .json/`basename $$i`; \
	  ${JSONVALIDATOR} ${JSONOPTS} -s .json/schema.json -d .json/`basename $$i`; \
	done
	rm -fr .json

# Experimental

wkit : _wkit_startvm _wkit _wkiti _wkit_stopvm

_wkit :
	${MAKE} to_win
	ssh ${WIN} gmake -C ${WINDIR}/pp/windows
	cp ${WINDST}/pp/windows/ChordPro-Installer*.exe ${HOME}/tmp/

_wkiti :
	cp ${WINDST}/pp/windows/ChordPro-Installer*.exe \
	  ${HOME}/tmp/ChordPro-Installer-6-90-dev-msw-x64.exe
	scp ${HOME}/tmp/ChordPro-Installer-6-90-dev-msw-x64.exe \
	  chordpro-site:www/dl/

_wkit_startvm :
	-VBoxManage startvm ${WINVM} --type headless
	sleep 10

_wkit_stopvm :
	sleep 10
	sudo umount ${WINMNT}
	VBoxManage controlvm ${WINVM} poweroff
	VBoxManage snapshot ${WINVM} restorecurrent

# Host must use .zshenv to set the correct path.
MACVM := "MacOS"

mkit : _mkit_startvm _mkit _mkit_stopvm

_mkit :
	${MAKE} to_mac
	ssh ${MACHOST} make -C Documents/${PROJECT}/pp/macos
	scp ${MACDST}/pp/macos/ChordPro-*.dmg ${HOME}/tmp/

_mkit_startvm :
	-VBoxManage startvm ${MACVM} --type headless
	sleep 10

_mkit_stopvm :
	VBoxManage controlvm ${MACVM} poweroff
	VBoxManage snapshot ${MACVM} restorecurrent

LTS     := 22
LTSHOST := ubuntu${LTS}
LTSVM   := "Ubuntu ${LTS}.04 LTS"

appimage : _akit_startvm _akit _akit_stopvm

_akit :
	${MAKE} to_mac MACHOST=${LTSHOST}
	ssh ${LTSHOST} make -C Documents/ChordPro/pp/appimage
	scp ${LTSHOST}:Documents/ChordPro/pp/appimage/ChordPro-\*.AppImage ${HOME}/tmp/

_akit_startvm :
	-VBoxManage startvm ${LTSVM} --type headless
	ssh ${LTSHOST} sudo ntpdate -b ntp.squirrel.nl

_akit_stopvm :
	VBoxManage controlvm ${LTSVM} poweroff
	VBoxManage snapshot ${LTSVM} restorecurrent

.PHONY: TAGS

TAGS:
	etags.emacs `grep '\.p[lm]' MANIFEST`

.PHONY: svg

svg :
	cp -p ${HOME}/src/SVGPDF/lib/SVGPDF.pm lib/ChordPro/lib/
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

# 1.22.34
ABCKIT     = abc2svg-9e4ccff7c9

.PHONY: abc

abc :
	rm -f ${ABCDEST}/*
	perl ABC/build.pl --dest=${ABCDEST} ABC/${ABCKIT}.tar.gz 
	cp -p ABC/README.FIRST ABC/cmdline.js ${ABCDEST}/
	grep -v ${ABCDEST} MANIFEST > x
	find ${ABCDEST} -type f -printf "%p\n" >> x
	env LC_ALL=C sort -u x > MANIFEST
	rm x
