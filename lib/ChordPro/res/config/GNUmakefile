#! /bin/make -f

SRC = ../../../..
SCRIPT = ${SRC}/script
RRJSON = perl -Mlib=${SRC}/lib/ChordPro/lib ${SCRIPT}/rrjson.pl --order --json_xs
CFGLIB := ${SRC}/lib/ChordPro/res/config
# JSONVALIDATOR = java -jar lib/jar/json-schema-validator-*-lib.jar
# JSONOPTS := --brief
# This requires npm install ajv-cli .
JSONVALIDATOR = ajv --validate-formats=false
JSONOPTS := --allowUnionTypes=true

checkjson :
	rm -fr .json
	mkdir .json
	cp -p ${CFGLIB}/config.schema .json/schema.json
	for i in $(shell git ls-files ${CFGLIB}) ; \
	do \
	  case "$$i" in \
	    keyboard.json)    continue;; \
	    dark.json)        continue;; \
	    notes/*)          continue;; \
	    *.rjson)          continue;; \
	    *.tmpl)           continue;; \
	    *.schema)         continue;; \
	  esac; \
	  ${RRJSON} $$i | \
	  perl -pe 's/"(-?\d+)"/$$1/' > .json/`basename $$i`; \
	  ${JSONVALIDATOR} ${JSONOPTS} -s .json/schema.json -d .json/`basename $$i` || touch .fail ; \
	done
	test -f .fail || rm -fr .json


%.json : %.rjson
	${RRJSON} --no-pretty $< |\
	perl -pe 's/"(-?\d+)"/$$1/g' > $@~
	cmp $@ $@~ || mv $@~ $@


newconf.jsx : config.schema chordpro.rjson
	${RRJSON} --schema config.schema --indent=4 --rrjson chordpro.rjson > newconf.jsx
