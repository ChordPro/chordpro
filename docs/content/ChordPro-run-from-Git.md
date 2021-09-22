---
title: "Running from Git"
description: "Running from Git"
---

# Running from Git

If you want to keep track of the latest developments you can run
Chordpro directly from the Git repository.

It is easiest to first install the release version of ChordPro using
one of the techniques mentioned on the
[Installing ChordPro]({{< relref "chordpro-installation" >}}) page. This will make sure most of the
required dependencies are installed.

Unless git is already installed, install it from the package repository.

Then, on the command line:

    git clone https://github.com/ChordPro/chordpro

This will create a new directory `chordpro`.

    cd chordpro
    git checkout dev
	perl Makefile.PL
	
This will inform you about missing dependencies. If so, install the
missing dependencies the usual way (package repository, `cpan` tool...).
	
To verify the installation, run

	make all test
    perl script/chordpro --version

This should say something similar to

    This is ChordPro version 0.977_036

The development version is not always equipped for global
installation, so to run it **always** include the path to the
`chordpro` program, e.g.:

	perl script/chordpro 

This is in particular important if you also have a stable version
installed to avoid accidentally running the wrong version of the program.
