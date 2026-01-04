#! /bin/make -f

DOCKER := docker
WXV := 3.009
AWV := 0.71
BUILDARGS := --build-arg WXV=${WXV} --build-arg AWV=${AWV}

default :: dev

# "RUN cpanm chordpro" will never get rebuilt since the command is cached.
# To make sure we are building a new version, provide an explicit
# versioned kit name.
VERSION := ${shell perl ../../lib/ChordPro/Version.pm}
KIT     := J/JV/JV/App-Music-ChordPro-${VERSION}.tar.gz

prod :: prep
	perl -pe 's;RUN cpanm chordpro;RUN cpanm ${KIT};' \
	    Dockerfile > Dockerfile.tmp
	${DOCKER} build ${BUILDARGS} --file Dockerfile.tmp \
	    --target chordpro-prod \
	    --tag chordpro/chordpro:v${VERSION} \
	    --tag chordpro/chordpro:latest .

dev :: prep
	tar -zcf chordpro-dev.tar.gz -C ../.. \
	    -T ../../MANIFEST -T ../../MANIFEST.WX
	${DOCKER} build ${BUILDARGS} \
	    --target=chordpro-dev \
	    --tag chordpro/chordpro-dev:latest .

clean ::
	rm -f Dockerfile.tmp chordpro-dev.tar.gz *~

prep ::
	cp ${HOME}/src/Alien-wxWidgets/Released/Alien-wxWidgets-${AWV}.tar.gz .
	cp ${HOME}/src/wxPerl/Released/Wx-${WXV}.tar.gz .

clean ::
	rm -f Wx-*.tar.gz
	rm -f Alien-wxWidgets-*.tar.gz
	rm -f chordpro-dev.tar.gz

# publish:
#
# Always tag latest as vX.YYY and vX.YYY.x
# docker tag chordpro/chordpro:latest chordpro/chordpro:v6.060.0
# docker tag chordpro/chordpro:latest chordpro/chordpro:v6.060
# docker push chordpro/chordpro:v6.060.0
# docker push chordpro/chordpro:v6.060
# docker push chordpro/chordpro:latest

