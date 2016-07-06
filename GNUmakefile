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
dist : Makefile
	$(MAKE) -f Makefile resources dist

.PHONY : install
install : Makefile
	$(MAKE) -f Makefile install

Makefile : Makefile.PL
	perl Makefile.PL

################ Extensions ################

PROJECT := ChordPro
TMP_DST = ${HOME}/tmp/${PROJECT}

to_tmp :
	make -f Makefile resources
	rsync -avH --files-from=MANIFEST    ./ ${TMP_DST}/
	rsync -avH --files-from=MANIFEST.WX ./ ${TMP_DST}/
	rsync -avH --files-from=MANIFEST.PP ./ ${TMP_DST}/

to_tmp_cpan :
	rsync -avH --files-from=MANIFEST.CPAN ./ ${TMP_DST}/

