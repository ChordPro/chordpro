#! /bin/sh

if [ ! -s dev/prep.sh ]; then
    echo "Run prep.sh from the main directory." 1>&2
    exit 1
fi

cp dev/Makefile.PL-dev Makefile.PL
cp dev/Bundle.pm lib/App/Music/ChordPro/Bundle.pm
cp dev/common-chordpro.pp pp/common/chordpro.pp
