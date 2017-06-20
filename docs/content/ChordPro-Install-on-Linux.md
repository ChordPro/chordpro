# Installing with cpan

Assuming your Linux systems has the Perl environment correctly installed (standard on nearly all distros), there will be an administrator command `cpan`. In a terminal, simply run the appropriate command from the options below for the version you want to install. It will ask the administrator (super user) password and then install everything neccessary to run ChordPro.

## GUI (graphical) interface version

`sudo cpan install wxchordpro`

Then, to open the program, run `wxchordpro` at a terminal prompt. 
You will get a file open dialog. To close the program, you can press `Cancel` and terminate the program with `File` > `Exit`.

## CLI (command-line) interface version

`sudo cpan install chordpro`

To check for successful install, run `chordpro --version`. That should return a result like `This is ChordPro version 5.00.00`.

# Running Chordpro on Linux

Whether using GUI or CLI version, you may proceed to [[Getting Started|ChordPro Getting Started]].