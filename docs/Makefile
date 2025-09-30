#! /bin/make -f

HUGO = hugo
ifeq ($(shell git branch --show-current),dev)
TARGET = beta
else
HUGO += --environment=stable
TARGET = chordpro
endif
HUGO += --baseURL=https://www.chordpro.org/${TARGET}/

CHORDPRO_VERSION = $(shell perl ../lib/ChordPro/Version.pm)

site :: build pagefind

build :: assets
	env CHORDPRO_VERSION=${CHORDPRO_VERSION} ${HUGO}
	mv public/index.html public/allpages/index.html
	cp public/home/index.html public/
	cp -p ../lib/ChordPro/res/fonts/ChordProSymbols.ttf public/pub/
	cp -p public/landing/index.html public/index.html

publish ::
	rsync -rlpgocHi --delete public/ chordpro-site:www/${TARGET}/

clean ::
	rm -fr public resources

# For development.
server: popup serve

serve :: assets
	env CHORDPRO_VERSION=${CHORDPRO_VERSION} \
	    ${HUGO} server --disableFastRender --navigateToChanged \
	        --bind ${HOSTNAME} --baseURL http://${HOSTNAME}:1313

assets ::
	cp ../lib/ChordPro/res/config/chordpro.json assets/pub/chordpro_json.txt

pagefind ::
	pagefind
	rsync -avH public/pagefind/ public/js/

popup ::
	( sleep 5; xdg-open  http://${HOSTNAME}:1313/ ) &

# A target to run the server on macOS as 'localhost' because it is more restrictive
macos: assets
		( sleep 3; open  http://localhost:1313 ) &
	env CHORDPRO_VERSION=${CHORDPRO_VERSION} \
	    ${HUGO} server --baseURL=http://localhost/ \
	        --disableFastRender --navigateToChanged

