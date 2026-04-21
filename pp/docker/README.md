# Podman and Docker

## Build

_Use the Makefile_

    docker build -t chordpro/chordpro:v6.030.0 .
    docker tag chordpro/chordpro:v6.030.0 chordpro/chordpro:v6.030
    docker tag chordpro/chordpro:v6.030.0 chordpro/chordpro:latest

## Push to repo

    docker push chordpro/chordpro:latest
    docker push chordpro/chordpro:v6.030.0
    docker push chordpro/chordpro:v6.030

## Running chordpro

Podman:

	podman run --rm \
	  --env HOME="${HOME}" \
	  --env USER=${USER} \
	  --user 0 \
	  --volume /run/user/`id -u`:/run/user/`id -u` \
	  --volume "${HOME}/.config":"${HOME}/.config" \
	  --volume "${HOME}/.local":"${HOME}/.local" \
	  --volume "${HOME}/.cache":"${HOME}/.cache" \
	  --volume "${HOME}/tmp":"${HOME}/tmp" \
	  --volume "${HOME}":"${HOME}" \
	  --workdir "`pwd`" \
	  docker.io chordpro/chordpro:latest \
	  chordpro

Docker:

	docker run --rm \
	  --env HOME="${HOME}" \
	  --env USER=${USER} \
	  --user `id -u`:`id -g` \
	  --volume /run/user/`id -u`:/run/user/`id -u` \
	  --volume "${HOME}/.config":"${HOME}/.config" \
	  --volume "${HOME}/.local":"${HOME}/.local" \
	  --volume "${HOME}/.cache":"${HOME}/.cache" \
	  --volume "${HOME}":"${HOME}" \
	  --workdir "`pwd`" \
	  chordpro/chordpro:latest \
	  chordpro

## Running wxchordpro

Podman:

	podman run --rm \
	  --env DISPLAY=${DISPLAY} \
	  --env HOME="${HOME}" \
	  --env USER=${USER} \
	  --user 0 \
	  --volume /dev/dri:/dev/dri \
	  --volume /tmp/.X11-unix:/tmp/.X11-unix \
	  --volume /run/user/`id -u`:/run/user/`id -u` \
	  --volume "${HOME}/.Xauthority":"${HOME}/.Xauthority" \
	  --volume "${HOME}/.config":"${HOME}/.config" \
	  --volume "${HOME}/.local":"${HOME}/.local" \
	  --volume "${HOME}/.cache":"${HOME}/.cache" \
	  --volume "${HOME}/tmp":"${HOME}/tmp" \
	  --volume "${HOME}":"${HOME}" \
	  --workdir "`pwd`" \
	  docker.io/chordpro/chordpro:latest \
	  wxchordpro

Docker:

	docker run --rm \
	  --env DISPLAY=${DISPLAY} \
	  --env HOME="${HOME}" \
	  --env USER=${USER} \
	  --user `id -u`:`id -g` \
	  --volume /dev/dri:/dev/dri \
	  --volume /tmp/.X11-unix:/tmp/.X11-unix \
	  --volume /run/user/`id -u`:/run/user/`id -u` \
	  --volume "${HOME}/.Xauthority":"${HOME}/.Xauthority" \
	  --volume "${HOME}/.config":"${HOME}/.config" \
	  --volume "${HOME}/.local":"${HOME}/.local" \
	  --volume "${HOME}/.cache":"${HOME}/.cache" \
	  --volume "${HOME}":"${HOME}" \
	  --workdir "`pwd`" \
	  chordpro/chordpro:latest \
	  wxchordpro

## Notes

When you pass your `$HOME` as shown above, and you have a
`.config/chordpro` in your home, the docker chordpro will use that for
its resources.

Volume spec `$HOME:$HOME` is needed to access files on your disk. To restrict
access to the current directory only, use `--volume $PWD:$PWD` instead.
