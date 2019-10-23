#! /bin/sh

if [ ! -s pango/prep.sh ]; then
    echo "Run prep.sh from the main directory." 1>&2
    exit 1
fi

cp pango/Makefile.PL-pango Makefile.PL
cp pango/Bundle.pm lib/App/Music/ChordPro/Bundle.pm
cp pango/common-chordpro.pp pp/common/chordpro.pp
