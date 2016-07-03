#! /bin/make -f

################ Pass-through ################

.PHONY : all
all :	cleanup config pod
	perl Makefile.PL
	$(MAKE) -f Makefile all

.PHONY : test
test :
	$(MAKE) -f Makefile test

.PHONY : clean
clean : cleanup
	rm -f *~

.PHONY : cleanup
cleanup :
	if test -f Makefile; then \
	    $(MAKE) -f Makefile clean; \
	fi

.PHONY : dist
dist :	config pod
	$(MAKE) -f Makefile dist

.PHONY : install
install :
	$(MAKE) -f Makefile install

config : res/config/chordpro.json

res/config/chordpro.json : lib/App/Music/ChordPro/Config.pm
	perl $< > $@

pod : res/pod/ChordPro.pod res/pod/Config.pod

res/pod/ChordPro.pod : lib/App/Music/ChordPro.pm
	podselect $< > $@

res/pod/Config.pod : lib/App/Music/ChordPro/Config.pm
	podselect $< > $@

################ Extensions ################

PROJECT := ChordPro
CAVADIR := cava

cp_build :
	cavaconsole --scan --build --makeins --project=${CAVADIR}

cp_build_noscan :
	cavaconsole --build --makeins --project=${CAVADIR}

cp_clean :
	rm -r ${CAVADIR}/release/${PROJECT}
	rm ${CAVADIR}/installer/*

CPW_DST = ${HOME}/tmp/${PROJECT}

cpw_prep :
	rsync -avH --files-from=MANIFEST ./ ${CPW_DST}/
	rsync -avH --files-from=MANIFEST.WX ./ ${CPW_DST}/
	rsync -avH --files-from=MANIFEST.PP ./ ${CPW_DST}/
	perl lib/App/Music/ChordPro/Config.pm > ${CPW_DST}/res/config/chordpro.json

cpw_prep_cpan :
	rsync -avH --files-from=MANIFEST.CPAN ./ ${CPW_DST}/

