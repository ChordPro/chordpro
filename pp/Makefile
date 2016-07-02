#! /bin/make -f

.PHONY : chordpro wxchordpro

# Use pp from path, not necessaroly /usr/bin.
PP := perl -S pp

chordpro : res
	${PP} --output=chordpro @chordpro.pp ../script/chordpro.pl

wxchordpro : res
	${PP} --output=wxchordpro @wxchordpro.pp ../script/wxchordpro.pl ../script/chordpro.pl

res :
	: test -f ../GNUmakefile && make -C .. pod config
	perl -MPAR::Packer -E 'say qq{"$$PAR::Packer::VERSION";};' > ../res/PAR-Packer-Version.pl

clean ::
	rm -f *.pp.deps *~ chordpro wxchordpro
