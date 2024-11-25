# Build ChordPro from source on a Mac

While it is not too easy to build **ChordPro** from source on a Mac, it is doable.

***Note**: These instructions are tested on macOS Sonoma, Ventura and Monterey.*

## Build ChordPro CLI

This is needed to build any of the options:

- Command Line version
- GUI version

### Homebrew

Install [homebrew](https://brew.sh) and follow its instructions carefully.

### Perl

Once homebrew is installed, install the following formulas:

	brew install perl
	brew install cpanminus

Again, follow the instructions. It is important to add stuff to your `~/.zprofile`. In the end, the content should look like this:

	eval "$(/opt/homebrew/bin/brew shellenv)"
	eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib=$HOME/perl5)"

***Note**: The pre-installed version of Perl cannot be used to build ChordPro. It contains a ‘universal’ dynamic library, both for Intel and ARM and ChordPro needs it for a specific architecture.*

Then, instal the following Perl package:

	cpanm PAR::Packer

***Note**: This package comes pre-installed on the Mac but it is insisting on using the ‘system-perl’. So we have to add a local version and that is why it is so important to have a correct `~/.zprofile`.*

### Build ChordPro CLI
	
- Download or clone the [dev](https://github.com/ChordPro/chordpro/tree/dev) branch of *ChordPro*.
- Open the downloaded folder in the Terminal (right-click folder in the Finder and choose ‘New Terminal at Folder’)

In the Terminal:

	cpanm --installdeps .

***Note**: Don’t forget the ‘.’ at the end!*

This will install all the needed dependencies to build *ChordPro*.

***Note**: Sometimes, ChordPro will add new dependencies. If compiling does not work anymore after a checkout, run above comment again.*

Now you can build the CLI version of *ChordPro*:

	cd pp/macos
	make ppl TARGET=chordpro
	
You will get some warnings but the building should complete and there is a *ChordPro* binary in the `pp/macos/build` directory.

***Note**: If you build on an Apple Silicon Mac, this binary will -not- run because it is unsigned. No worries, we deal with that later when building a GUI.*

## ChordPro GUI

This is *absolutely* not easy.

### Homebrew

Install [wxWidgets](https://www.wxwidgets.org) with Homebrew; the cross-platform GUI toolkit used for the GUI.

	brew install wxwidgets

Install an additional formula:

	brew install zlib
	
### Perl

Extra dependencies you have to install:

	cpanm Alien::wxWidgets
	cpanm ExtUtils::XSpp

Now comes the biggest challenge; install xwPerl from source. Unfortunately, wxPerl is currently not well maintained and Johan Vromans, the maintainer of *ChordPro*, created an independent fork. [Download](https://github.com/sciurius/wxPerl) the latest release from his repo.

Open the `Wx-x.xxx` folder in the terminal and do the following:

	perl ./Makefile.PL
	make
	make install
	
### Build the GUI
	
Go to the `pp/macos` directory again and build ChordPro GUI:

	make
	
This will build a DMG for the architecture of the Mac you are using now.

***Note**: An Apple Silicon version will be ad-hoc signed or else it will simply not run.*

You should now have a DMG in the `pp/macos` directory that is ready to use.


