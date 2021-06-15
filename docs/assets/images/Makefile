#! /bin/make -f

sources = $(wildcard style_*.pdf) simple.pdf labels.pdf
targets = $(sources:.pdf=.png) $(sources:.pdf=-small.png)

all :: ${targets}

test ::
	echo ${sources}
	echo ${targets}

%.png : %.pdf
	convert -define profile:skip=ICC -resize 1200x1698 -density 300 \
	  -background white -alpha remove $< $@

%-small.png : %.pdf
	convert -define profile:skip=ICC -resize 240x340 \
	  -background white -alpha remove \
	  -shave 1x1 -bordercolor black -border 1 $< $@

clean ::
	rm -f ${targets}

