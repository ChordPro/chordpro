#! /bin/make -f

################ Pass-through ################

.PHONY : all
all :	Makefile cleanup
	mv Makefile.old Makefile
	$(MAKE) -f Makefile all

.PHONY : test
test : Makefile
	$(MAKE) -f Makefile test

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

Makefile : Makefile.PL lib/App/Music/ChordPro/Version.pm
	git-version lib/App/Music/ChordPro/Version.pm
	perl Makefile.PL

################ Extensions ################

PERL := perl
PROJECT := ChordPro
TMP_DST := ${HOME}/tmp/${PROJECT}

to_tmp : resources
	rsync -avH --files-from=MANIFEST    ./ ${TMP_DST}/
	rsync -avH --files-from=MANIFEST.WX ./ ${TMP_DST}/

to_tmp_cpan :
	rsync -avH --files-from=MANIFEST.CPAN ./ ${TMP_DST}/

release :
	${MAKE} -C ../WxChordPro to_src
	${PERL} Makefile.PL
	${MAKE} -f Makefile all test dist

# Actualize resources.

LIB := lib/App/Music/ChordPro
RES := ${LIB}/res
PODSELECT := podselect

resources : ${RES}/config/chordpro.json ${RES}/pod/ChordPro.pod ${RES}/pod/Config.pod

${RES}/config/chordpro.json : ${LIB}/Config.pm
	$(PERL) $< > $@

${RES}/pod/ChordPro.pod : ${LIB}.pm
	${PODSELECT} $< > $@

${RES}/pod/Config.pod : ${LIB}/Config.pm
	${PODSELECT} $< > $@

# Verify JSON data

CFGLIB := ${LIB}/res/config

checkjson :
	for i in ${CFGLIB}/*.json ; \
	do \
	  echo "Verifying $$i..."; \
	  json_pp -json_opt relaxed < $$i | \
	  jsonschema -i /dev/stdin ${CFGLIB}/config.schema; \
	done
