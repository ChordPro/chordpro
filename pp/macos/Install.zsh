#!/bin/zsh

#######################################################
#                                                     #
# Install ChordPro on macOS                           #
#                                                     #
# For security reasons; this script is not executable #
# by double-clicking on it.                           #
#                                                     #
# To run it, you have to drop it into a Terminal      #
# window or drop it onto its icon.                    #
#                                                     #
#######################################################

## Nice colours

ORANGE="\e[38;5;130m"

BLUE="\e[1m\e[38;5;27m"

RESET="\e[0m"

APPLICATION="\e[1m$ORANGE""ChordPro""$RESET"

APPLICATION_CLI="\e[1m$ORANGE""chordpro""$RESET\e[3m CLI$RESET"

# We need administration access to run this script
if [ $(id -u) != 0 ]; then
   echo "\n$BLUE""This install script requires administration permission to install $APPLICATION$RESET"
   echo "
It will do the following:

- Copy $APPLICATION to your applications folder
- Move $APPLICATION out of quarantine
- Add the $APPLICATION_CLI to your Terminal \$PATH
"
   echo "\e[1m""Use it at your own risk...$RESET\n"
   sudo "$0" "$@"
   exit
fi

echo "\nCopy $APPLICATION to your Applications folder..."

rm -fr "/Applications/ChordPro.app"

cp -R "${0:a:h}/ChordPro.app" /Applications/

echo "Remove the quarantine flag..."

xattr -rd com.apple.quarantine /Applications/ChordPro.app

echo "Adding the $APPLICATION_CLI to your \$PATH for real power in the Terminal..."

echo "/Applications/ChordPro.app/Contents/Resources/cli" > /private/etc/paths.d/chordpro

echo "\n\e[3m""You have to start a new Terminal window to use the $APPLICATION_CLI from your \$PATH.$RESET"

echo "\n$BLUE""Done!$RESET\n\nEnjoy $APPLICATION on your Mac!\n"

