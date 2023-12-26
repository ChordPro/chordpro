# Docker

## Build

    docker build -t chordpro/chordpro:v6.030.0 .
    docker tag chordpro/chordpro:v6.030.0 chordpro/chordpro:latest

## Push to repo

    docker push chordpro/chordpro:latest

## Running chordpro

	docker run -ti --rm \
	  --env HOME=${HOME} \
	  --env USER=$USER \
	  --workdir `pwd` \
	  --volume ${HOME}:${HOME} \
	  chordpro/chordpro:latest chordpro

## Running wxchordpro

	docker run --rm \
	  --env DISPLAY=${DISPLAY} \
	  --volume /tmp/.X11-unix:/tmp/.X11-unix:rw \
	  --user `id -u`:`id -g` \
	  --env HOME=${HOME} \
	  --env USER=${USER} \
	  --workdir `pwd` \
	  --volume ${HOME}:${HOME}:rw \
	  chordpro/chordpro:latest wxchordpro

## Notes

When you pass your `$HOME` as shown above, and you have a
`.config/chordpro` in your home, the docker chordpro will use that for
its resources. In particular, it may be unable to locate the
`ChordProSymbols.ttf`. You can fix this by copying the font to your
`.config/chordpro/fonts/` folder. 

Volume spec `$HOME:$HOME` is needed to access files on your disk. To restrict
access to the current directory only, use `--volume $PWD:$PWD` instead.
