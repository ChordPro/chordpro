# GNUmakefile for MS Windows + Strawberry Perl + wxWidgets 3.0.

# Needed for the environment settings.
# .ONESHELL :

ROOT   := ../..
COMMON := ../common
SCRIPT := ${ROOT}/script
RES    := ..\..\lib\ChordPro\res
PP     := pp
PLDIR  := C:\Strawberry
WXDIR  := C:\wxWidgets-3.3.1
PERL   := perl540

all : ppl iss

.PHONY :: chordpro wxchordpro

chordpro : chordpro.exe

wxchordpro : wxchordpro.exe

# PAR_VERBATIM=1 prevents POD filtering. ChordPro/Config.pm needs POD!
chordpro.exe : chordpro.pp
	${PP} --output=chordpro.exe @chordpro.pp ${SCRIPT}/chordpro.pl

# For wxWidgets, explicit libraries are specified in wxchordpro.pp and the
# PATH must be set accordingly.
# To set PATH from the makefile, we need .ONESHELL pseudo target above.

wxchordpro.exe : chordpro.pp wxchordpro.pp ${COMMON}/chordpro.pp ${COMMON}/wxchordpro.pp
	${PP} --output=wxchordpro.exe @wxchordpro.pp ${SCRIPT}/wxchordpro.pl

wxchordpro.pp : ../common/libtool.pl
	perl $< --output=$@

clean ::
	del *chordpro.exe
	del *.pp.deps

#### NOTE: THIS MAY NEED ADJUSTMENT FOR YOUR SYSTEM
ISCC := "C:\Program Files (x86)\Inno Setup 6\iscc.exe"

.PHONY :: iss_par
iss_par :: chordpro.exe wxchordpro.exe innosetup_par.iss chordproinst.bmp
	copy ${RES}\icons\chordpro.ico .
	copy ${RES}\icons\chordpro-doc.ico .
	perl vfix.pl innosetup_par.iss
	${ISCC} innosetup_par.iss

PLIBS := ${PLDIR}\perl\bin
CLIBS := ${PLDIR}\c\bin
# DEST MAY NOT CONTAIN SPACES!
DEST  := build

.PHONY :: ppl
ppl : clean wxchordpro.exe unpack copy_coredll loaders

# Unpack the pp generated kits.
# We need to restore ChordPro/Config.pm since that has been mangled by par filters.
.PHONY :: unpack
unpack :
	perl ..\pp2ppl.pl --quiet --dest=${DEST} wxchordpro.exe
	copy "${ROOT}\script\chordpro.pl" ${DEST}\script\chordpro.pl
	copy "${ROOT}\lib\ChordPro\Config.pm" ${DEST}\lib\ChordPro\Config.pm 
	copy ${DEST}\res\icons\*.ico ${DEST}
	copy ${DEST}\res\icons\*.png ${DEST}
	move ${DEST}\res ${DEST}\lib\ChordPro
	copy WebView2Loader.dll ${DEST}

# The core DLLs needed for Strawberry perl. The Wx libs have been unpacked already.
copy_coredll :
	copy "${CLIBS}\libgcc_s_seh-1.dll"  ${DEST}
	copy "${CLIBS}\libstdc++-6.dll"     ${DEST}
	copy "${CLIBS}\libwinpthread-1.dll" ${DEST}
	copy "${PLIBS}\${PERL}.dll"         ${DEST}

# Portable Perl Loaders

PFX := "\"script\\\""
CC := gcc -Wall -Wstrict-prototypes -O2 -s -mms-bitfields -fwrapv -DSCRIPTPREFIX=${PFX}

.PHONY :: loaders
loaders : ${DEST}\wxchordpro.exe ${DEST}\chordpro.exe

${DEST}\wxchordpro.exe : ppl.c wxchordpro.rc
	perl vfix.pl wxchordpro.rc
	windres -I ${WXDIR}/include wxchordpro.rc ppl.o
	${CC} -DUTF8 -mwindows -o ${DEST}\wxchordpro.exe ppl.c ppl.o

${DEST}\chordpro.exe : ppl.c chordpro.rc
	perl vfix.pl chordpro.rc
	windres chordpro.rc ppl.o
	${CC} -DUTF8 -mconsole -o ${DEST}\chordpro.exe ppl.c ppl.o

# And finally, the installer.

.PHONY :: iss
iss : ${DEST}\wxchordpro.exe innosetup.iss
	perl vfix.pl
	${ISCC} /q innosetup.iss

clean ::
	-rmdir /q/s ${DEST}
