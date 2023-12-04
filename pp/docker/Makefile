#! /bin/make -f

DOCKER := docker

default :: dev

prod ::
	${DOCKER} build -t chordpro/chordpro:latest . --target chordpro-prod

dev ::
	tar -zcf chordpro-dev.tar.gz -C ../.. -T ../../MANIFEST
	${DOCKER} build -t chordpro/chordpro-dev:latest . --target=chordpro-dev

clean ::
	rm -f qjs abc2svg_qjs.tar.gz chordpro-dev.tar.gz
