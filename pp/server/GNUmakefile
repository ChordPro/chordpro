#! /usr/bin/make -f

build :
	docker build -t chordpro-server .

plackup :
	env PERL5LIB=../../CPAN:../../lib plackup -r dancer/chordpro-server.pl

# With -ti you can kill the bastard with ^C.
run :
	docker run --rm -p 5000:5000 -ti chordpro-server

compose :
	docker-compose up --no-start

start:
	docker start chordpro-server

stop:
	docker stop chordpro-server

kill:
	docker stop `docker ps|grep chordpro-server|cut -f1 -d\ `

bash:
	docker exec -ti chordpro-server bash

demo:
	curl \
	  -F 'song=@examples/swinglow.cho' \
	  http://127.0.0.1:5000/chordpro/pdf -o demo.pdf
