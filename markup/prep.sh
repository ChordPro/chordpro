#! /bin/sh

if [ ! -s markup/prep.sh ]; then
    echo "Run prep.sh from the main directory." 1>&2
    exit 1
fi

cp markup/Makefile.PL-markup Makefile.PL
cp markup/Bundle.pm lib/App/Music/ChordPro/Bundle.pm
cp markup/common-chordpro.pp pp/common/chordpro.pp
