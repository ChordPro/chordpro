# GNUmakefile for MS Windows + Strawberry Perl + wxWidgets 3.0.

.PHONY : chordpro wxchordpro

# Needed for the path setting.
.ONESHELL :

ROOT   := ../..
COMMON := ../common
SCRIPT := ${ROOT}/script

PP := pp -u

all : clean chordpro wxchordpro

chordpro : chordpro.exe

wxchordpro : wxchordpro.exe

chordpro.exe : chordpro.pp
	${PP} --output=chordpro.exe @chordpro.pp ${SCRIPT}/chordpro.pl

# For wxWidgets, explicit libraries are specified in wxchordpro.pp and the
# PATH must be set accordingly.
# To set PATH from the makefile, we need .ONESHELL pseudo target above.

wxchordpro.exe : chordpro.pp wxchordpro.pp
	set path=C:\\Strawberry\\perl\\site\\lib\\Alien\\wxWidgets\\msw_3_0_2_uni_gcc_3_4\\lib;%path%
	${PP} --output=wxchordpro.exe @wxchordpro.pp ${SCRIPT}/wxchordpro.pl

clean ::
	del *chordpro.exe
	del *.pp.deps

#### NOTE: THIS MAY NEED ADJUSTMENT FOR YOUR SYSTEM

ISC := 	"C:\\Program Files (x86)\\Inno Setup 5\\Compil32.exe"

install :: chordpro.exe wxchordpro.exe chordproinst.bmp
	copy ..\\..\\lib\\App\\Music\\ChordPro\\res\\icons\\chordpro.ico .

iss ::	install innosetup.iss
	perl vfix.pl
	${ISC} /cc innosetup.iss

