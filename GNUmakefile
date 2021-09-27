#! /bin/make -f

################ Pass-through ################

.PHONY : all
all :	Makefile cleanup
	mv Makefile.old Makefile
	$(MAKE) -f Makefile all

.PHONY : test
test : Makefile
	env PERL5LIB=$(shell pwd)/CPAN $(MAKE) -f Makefile test

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

Makefile : Makefile.PL lib/App/Music/ChordPro/Version.pm resources
	perl Makefile.PL

################ Extensions ################

PERL := perl
PROJECT := ChordPro
TMP_DST := ${HOME}/tmp/${PROJECT}
RSYNC_ARGS := -rptgoDvHL

to_tmp : resources
	rsync ${RSYNC_ARGS} --files-from=MANIFEST    ./ ${TMP_DST}/
	rsync ${RSYNC_ARGS} --files-from=MANIFEST.WX ./ ${TMP_DST}/

to_tmp_cpan :
	rsync ${RSYNC_ARGS} --files-from=MANIFEST.CPAN ./ ${TMP_DST}/

release :
	${PERL} Makefile.PL
	${MAKE} -f Makefile all test dist

# Actualize resources.

LIB := lib/App/Music/ChordPro
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

docs/assets/pub/config60.schema : ${RES}/config/config.schema
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
	  json_pp -json_opt relaxed < $$i > .json/`basename $$i`; \
	done
	rm -f .json/pd_colour.json
	${JSONVALIDATOR} ${JSONOPTS} \
	  ${CFGLIB}/config.schema .json/*.json
	rm -fr .json
