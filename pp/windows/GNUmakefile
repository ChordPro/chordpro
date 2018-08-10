# gmake file for MS Windows + CitrusPerl
# Based on 64-bit gmake and CitrusPerl 5.24 with wxWidgets 3.0.

SCRIPT := ../../script

.ONESHELL :

all :	clean chordpro.exe wxchordpro.exe iss

PP := pp

chordpro.exe :: chordpro.pp
	${PP} --output=chordpro.exe @chordpro.pp ${SCRIPT}/chordpro.pl

# For wxWidgets, explicit libraries are specified in wxchordpro.pp and the
# PATH must be set accordingly.
# To set PATH from the makefile, we need .ONESHELL pseudo target above.

wxchordpro.exe :: chordpro.pp wxchordpro.pp ../common/wxchordpro.pp
	set path=C:\\perl\\vendor\\lib\\Alien\\wxWidgets\\msw_3_0_2_uni_gcc_1_2\\lib;%path%
	${PP} --output=wxchordpro.exe @wxchordpro.pp ${SCRIPT}/wxchordpro.pl

ISC := 	"C:\\Program Files (x86)\\Inno Setup 5\\Compil32.exe"
DST :=  "C:\\Users\\Johan\\Documents\\ChordPro"

install :: chordpro.exe wxchordpro.exe chordproinst.bmp
	copy chordpro.exe ${DST}
	copy wxchordpro.exe ${DST}
	copy chordproinst.bmp ${DST}

iss ::	install innosetup.iss
	perl vfix.pl
	${ISC} /cc innosetup.iss
	copy ${DST}\\ChordPro-GUI-*.exe .

# NOTE: THIS IS FOR TESTING/DEVELOPMENT ONLY.

clean ::
	del chordpro.exe wxchordpro.exe *.pp.deps
	del ${DST}\\*.exe
