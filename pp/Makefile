#! /bin/make -f

.PHONY : chordpro wxchordpro

# Use pp from path, not necessaroly /usr/bin.
PP := perl -S pp

chordpro :
	${PP} --output=chordpro @chordpro.pp ../script/chordpro.pl

wxchordpro :
	${PP} --output=wxchordpro @chordpro.pp @wxchordpro.pp ../script/wxchordpro.pl ../script/chordpro.pl

clean ::
	rm -f *.pp.deps *~ chordpro wxchordpro
