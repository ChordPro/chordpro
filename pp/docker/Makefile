#! /bin/make -f

DOCKER := docker

prod ::
	${DOCKER} build -t chordpro/chordpro:latest . --target chordpro-prod

dev ::
	test -f qjs || cp -pL ../linux/qjs .
	test -f abc2svg_qjs.tar.gz || cp -pL ../common/abc2svg_qjs.tar.gz .
	tar -zcf chordpro-dev.tar.gz -C ../.. -T ../../MANIFEST
	${DOCKER} build -t chordpro/chordpro-dev:latest . --target=chordpro-dev

clean ::
	rm -f qjs abc2svg_qjs.tar.gz chordpro-dev.tar.gz
