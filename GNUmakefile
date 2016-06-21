#! /bin/make -f

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

cpw_prep_cpan :
	rsync -avH --files-from=MANIFEST.CPAN ./ ${CPW_DST}/
