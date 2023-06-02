# Docker

docker build -t chordpro .

## Normal chordpro

docker run -ti --rm \
  --env HOME=$HOME \
  --env USER=$USER \
  --workdir `pwd` \
  --volume $HOME:$HOME \
  chordpro chordpro

## WxChordPro

docker run --rm \
  --env DISPLAY=$DISPLAY \
  --volume /tmp/.X11-unix:/tmp/.X11-unix:rw \
  --user `id -u`:`id -g` \
  --env HOME=$HOME \
  --env USER=$USER \
  --workdir `pwd` \
  --volume $HOME:$HOME:rw \
  chordpro wxchordpro

## Notes

When you pass your $HOME as shown above, and you have a
.config/chordpro in your home, the docker chordpro will use that for
its resources. In particular, it may be unable to locate the
ChordProSymbols.ttf. 

Volume spec `$HOME:$HOME` is needed to access files on your disk. To restrict
access to the current directory only, use `--volume $PWD:$PWD`.
