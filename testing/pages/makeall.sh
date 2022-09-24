#!/bin/sh

FM=${HOME}/Music/Tabbladen/Set_1.pdf
BM=${HOME}/Music/Tabbladen/Toegift.pdf

for pas in 0 1 2
do
    for eop in -1 0 1
    do
	chordpro -X -o eop${eop}_pas$pas.pdf --cfg chordpro.prp \
		 --def pdf.even-odd-pages=$eop \
		 --def pdf.pagealign-songs=$pas \
		 pages.cho
	chordpro -X -o eop${eop}_pas${pas}fb.pdf --cfg chordpro.prp \
		 --def pdf.even-odd-pages=$eop \
		 --def pdf.pagealign-songs=$pas \
		 pages.cho \
		 --front-matter=$FM \
		 --back-matter=$BM
    done
done
