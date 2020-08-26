#! /bin/make -f

HUGO = hugo
ifeq ($(shell git branch --show-current),dev)
TARGET = beta
else
HUGO += --environment=stable
TARGET = chordpro
endif
HUGO += --baseURL=https://www.chordpro.org/${TARGET}/

site ::
	make -C assets/images
	${HUGO}
	mv public/index.html public/allpages/index.html
	cp public/home/index.html public/

publish ::
	rsync -acvHi --delete public/ chordpro-site:www/${TARGET}/

clean ::
	rm -fr public resources

# For development.
server ::
	make -C assets/images
	${HUGO} server --disableFastRender --navigateToChanged --bind ${HOSTNAME} --baseURL http://${HOSTNAME}:1313

