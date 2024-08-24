#! /bin/make -f

DOCKER := docker

default :: dev

# "RUN cpanm chordpro" will never get rebuilt since the command is cached.
# To make sure we are building a new version, provide an explicit
# versioned kit name.
KITPFX := J/JV/JV/App-Music-ChordPro

prod ::
	perl -Mlib=../../lib -MChordPro::Version \
	    -pe 's;RUN cpanm chordpro;' \
	    -e 'RUN cpanm ${KITPFX}-$$ChordPro::Version::VERSION.tar.gz;' \
	    Dockerfile > Dockerfile.tmp
	${DOCKER} build -f Dockerfile.tmp -t chordpro/chordpro:latest . --target chordpro-prod

dev ::
	tar -zcf chordpro-dev.tar.gz -C ../.. \
	    -T ../../MANIFEST -T ../../MANIFEST.FONTS
	${DOCKER} build -t chordpro/chordpro-dev:latest . --target=chordpro-dev

clean ::
	rm -f Dockerfile.tmp chordpro-dev.tar.gz *~

# publish:
#
# docker tag chordpro/chordpro:latest chordpro/chordpro:v6.060.0
# docker push chordpro/chordpro:v6.060.0
# docker push chordpro/chordpro:latest

