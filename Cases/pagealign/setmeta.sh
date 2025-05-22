#!/bin/sh

# Preset atril metadata for convenient viewing.

file=$1; shift
even=1
if [ "$1" == "" ]; then even=0; fi

case `basename "${file}"` in
    pe[0-2]?.pdf) even=1;;
    po[0-2]?.pdf) even=0;;
esac
		  
meta="metadata::atril"

gio set "${file}" ${meta}::page 0
gio set "${file}" ${meta}::zoom 0.12
gio set "${file}" ${meta}::continuous 1
gio set "${file}" ${meta}::dual-page 1
gio set "${file}" ${meta}::zoom 0.12
gio set "${file}" ${meta}::dual-page-odd-left $even
gio set "${file}" ${meta}::window_width 288
gio set "${file}" ${meta}::sizing_mode free
