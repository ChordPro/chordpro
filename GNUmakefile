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
TMP_DST := ${HOME}/tmp/${PROJECT}
RSYNC_ARGS := -rptgoDvHL
W10DIR := /Users/Johan/${PROJECT}
MACDST := macky:ChordPro

to_tmp : resources
	rsync ${RSYNC_ARGS} --files-from=MANIFEST    ./ ${TMP_DST}/
	rsync ${RSYNC_ARGS} --files-from=MANIFEST.WX ./ ${TMP_DST}/

to_tmp_cpan :
	rsync ${RSYNC_ARGS} --files-from=MANIFEST.CPAN ./ ${TMP_DST}/

to_c :
	test -d /mnt/c/Users || mount /mnt/c
	${MAKE} to_tmp to_tmp_cpan TMP_DST=/mnt/c${W10DIR}

to_mac : resources
	rsync ${RSYNC_ARGS} --files-from=MANIFEST      ./ ${MACDST}/
	rsync ${RSYNC_ARGS} --files-from=MANIFEST.WX   ./ ${MACDST}/
	rsync ${RSYNC_ARGS} --files-from=MANIFEST.CPAN ./ ${MACDST}/
	ssh macky rm -fr ${MACDST}/pp/windows

release :
	${PERL} Makefile.PL
	${MAKE} -f Makefile all test dist

# Actualize resources.

LIB := lib/ChordPro
RES := ${LIB}/res
PODSELECT := podselect

resources : ${RES}/config/chordpro.json ${RES}/pod/ChordPro.pod ${RES}/pod/Config.pod ${RES}/pod/A2Crd.pod docs/assets/pub/config60.schema

${RES}/config/chordpro.json : ${LIB}/Config.pm
	$(PERL) -Ilib $< > $@

${RES}/pod/ChordPro.pod : ${LIB}.pm
	${PODSELECT} $< > $@

${RES}/pod/Config.pod : ${LIB}/Config.pm
	${PODSELECT} $< > $@
	${PERL} -pe 's/^/    /' ${RES}/config/chordpro.json >> $@

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
	  perl script/rrjson.pl --json $$i > .json/`basename $$i`; \
	done
	cd .json; rm keyboard.json dark.json resetchords.json
	${JSONVALIDATOR} ${JSONOPTS} \
	  ${CFGLIB}/config.schema .json/*.json
	rm -fr .json

# Experimental

WIN := w10
WINVM := Win10Pro

wkit : _wkit1 _wkit _wkit2

_wkit :
	${MAKE} to_c
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

ABCDEST    = ${RES}/abc/abc2svg
ABCKIT     = abc2svg-be8faee2b4

abc :
	rm -f ${ABCDEST}/*
	perl ABC/build.pl --dest=${ABCDEST} ABC/${ABCKIT}.tar.gz 
	cp -p ABC/README.FIRST ABC/cmdline.js ${ABCDEST}/
	grep -v ${ABCDEST} MANIFEST > x
	find ${ABCDEST} -type f -printf "%p\n" \
	  | sort -u >> x
	mv x MANIFEST
