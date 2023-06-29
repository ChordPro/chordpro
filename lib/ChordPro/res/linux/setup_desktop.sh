#!/bin/sh

# Performs a local (user) install of desktop items.
# This will also associate files with extension `.cho`, `.chordpro`,
# `.chopro`, and `.crd` with the ChordPro program.

action="install"
actype="user"

if [ "$1" = "uninstall" ]; then
    action="uninstall"
fi

RES=`chordpro --about|perl -ne 's/^Resource path +(.+)/$1/i && print'`
if [ "${RES}" = "" ]; then
    echo "Error finding ChordPro resources. Is it installed?" 1>2
    exit 1
fi

XDG=${HOME}/.local/share
XDG_APP=${XDG}/applications
XDG_MIME=${XDG}/mime
XDG_ICONS=${XDG}/icons

# Icons.
ILIB=${RES}/icons
# Templates.
TLIB=${RES}/linux
TPL=chordpro.desktop
XML=chordpro.xml
ISIZE=256

if [ $action = "install" ]
then

    # Prepare the desktop template.
    desktop-file-edit --set-icon="${ILIB}/chordpro.png" ${TLIB}/${TPL}

    # Install for user desktop
    desktop-file-install --mode=0755 --dir=$HOME/Desktop ${TLIB}/${TPL}
    desktop-file-validate ${HOME}/Desktop/${TPL}

    # Install in applications menu.
    desktop-file-install --dir=${XDG_APP} \
	--rebuild-mime-info-cache ${TLIB}/${TPL}

    # Install mime info.
    cp -p ${TLIB}/${XML} ${XDG_MIME}/packages/
    xdg-icon-resource install --context mimetypes --size ${ISIZE} \
	${ILIB}/chordpro-doc.png x-chordpro-doc

else

    rm -f ${HOME}/Desktop/${TPL}
    rm -f ${XDG_APP}/${TPL}
    xdg-icon-resource uninstall --context mimetypes --size ${ISIZE} x-chordpro-doc
    rm -f ${XDG_MIME}/packages/${XML}

fi

# Update current info.
update-desktop-database ${XDG_APP} 
update-mime-database ${XDG_MIME}
test -x /usr/bin/update-icon-caches && update-icon-caches ${XDG_ICONS} || true
test -x /usr/bin/gtk-update-icon-cache && gtk-update-icon-cache ${XDG_ICONS} || true


