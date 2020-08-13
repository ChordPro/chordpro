# GNUmakefile for MS Windows + Strawberry Perl + wxWidgets 3.0.

# Needed for the environment settings.
# .ONESHELL :

ROOT   := ../..
COMMON := ../common
SCRIPT := ${ROOT}/script
RES    := ..\..\lib\App\Music\ChordPro\res
PP := pp -u

all : clean chordpro wxchordpro

.PHONY :: chordpro wxchordpro

chordpro : chordpro.exe

wxchordpro : wxchordpro.exe

# PAR_VERBATIM=1 prevents POD filtering. ChordPro/Config.pm needs POD!
chordpro.exe : chordpro.pp
	${PP} --output=chordpro.exe @chordpro.pp ${SCRIPT}/chordpro.pl

# For wxWidgets, explicit libraries are specified in wxchordpro.pp and the
# PATH must be set accordingly.
# To set PATH from the makefile, we need .ONESHELL pseudo target above.

wxchordpro.exe : chordpro.pp wxchordpro.pp
	${PP} --output=wxchordpro.exe @wxchordpro.pp ${SCRIPT}/wxchordpro.pl

clean ::
	del *chordpro.exe
	del *.pp.deps

#### NOTE: THIS MAY NEED ADJUSTMENT FOR YOUR SYSTEM
ISC := 	"C:\Program Files (x86)\Inno Setup 6\Compil32.exe"

.PHONY :: iss_par
iss_par :: chordpro.exe wxchordpro.exe innosetup_par.iss chordproinst.bmp
	copy ${RES}\icons\chordpro.ico .
	perl vfix.pl innosetup_par.iss
	${ISC} /cc innosetup_par.iss

PLIBS := C:\Strawberry\perl\bin
CLIBS := C:\Strawberry\c\bin
DEST  := build

.PHONY :: ppl
ppl : clean chordpro.exe wxchordpro.exe unpack copy_coredll loaders

# Unpack the pp generated kits.
# We need to restore ChordPro/Config.pm since that has been mangled by par filters.
.PHONY :: unpack
unpack :
	perl ..\pp2ppl.pl --quiet --dest="${DEST}" chordpro.exe
	perl ..\pp2ppl.pl --quiet --dest="${DEST}" wxchordpro.exe
	copy "${ROOT}\lib\App\Music\ChordPro\Config.pm" "${DEST}\lib\App\Music\ChordPro\Config.pm" 
	copy "${DEST}\res\icons\chordpro.ico" "${DEST}"
	move "${DEST}\res" "${DEST}\lib\App\Music\ChordPro"

# The core DLLs needed for Strawberry perl. The Wx libs have been unpacked already.
copy_coredll :
	copy "${CLIBS}\libgcc_s_seh-1.dll"  "${DEST}"
	copy "${CLIBS}\libstdc++-6.dll"     "${DEST}"
	copy "${CLIBS}\libwinpthread-1.dll" "${DEST}"
	copy "${PLIBS}\perl530.dll"         "${DEST}"

# Portable Perl Loaders

PFX := "\"script\\\""
CC := gcc -Wall -Wstrict-prototypes -O2 -s -mms-bitfields -fwrapv -DSCRIPTPREFIX=${PFX}

.PHONY :: loaders
loaders : "${DEST}\wxchordpro.exe" "${DEST}\chordpro.exe"

"${DEST}\wxchordpro.exe" : ppl.c wxchordpro.rc
	perl vfix.pl wxchordpro.rc
	windres wxchordpro.rc ppl.o
	${CC} -mwindows -o "${DEST}\wxchordpro.exe" ppl.c ppl.o

"${DEST}\chordpro.exe" : ppl.c chordpro.rc
	perl vfix.pl chordpro.rc
	windres chordpro.rc ppl.o
	${CC} -mconsole -o "${DEST}\chordpro.exe" ppl.c ppl.o

# And finally, the installer.

.PHONY :: iss
iss : "${DEST}\wxchordpro.exe" innosetup.iss
	perl vfix.pl
	${ISC} /cc innosetup.iss

clean ::
	-rmdir /q/s "${DEST}"
