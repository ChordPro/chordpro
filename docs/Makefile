#! /bin/make -f

HUGO := hugo

default ::

server :
	make -C assets/images
	${HUGO} server -D --disableFastRender --navigateToChanged --bind ${HOSTNAME} --baseURL http://${HOSTNAME}:1313

beta ::
	make -C assets/images
	${HUGO}
	mv public/index.html public/allpages/index.html
	cp public/home/index.html public/

publish :: publish-beta

publish-beta ::
	rsync -acvHi --delete public/ chordpro-site:www/beta/

production :: prod

prod ::
	make -C assets/images
	${HUGO} --environment=stable
	mv public/index.html public/allpages/index.html
	cp public/home/index.html public/

publish-prod ::
	rsync -acvHi --delete public/ chordpro-site:www/chordpro/

clean ::
	rm -fr public resources
