#! /bin/make -f

HUGO := hugo

default ::

server :
	${HUGO} server -D --disableFastRender --navigateToChanged --bind ${HOSTNAME} --baseURL http://${HOSTNAME}:1313

production :: prod

prod ::
	rm -fr public && mkdir public
	${HUGO}
	mv public/index.html public/allpages/index.html
	cp public/home/index.html public/

publish ::
	rsync -acvHi --delete public/ chordpro-site:www/chordpro/

clean ::
	rm -fr public resources
