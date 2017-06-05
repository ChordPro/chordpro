Linux systems always have the Perl environment installed. At least, they should have...

If the Perl environment is correctly installed, there will be an administrator command `cpan`. Open a command prompt window and type at the prompt:

`sudo cpan install wxchordpro`

This will ask the administrator (super user) password and then install everything neccessary to run the ChordPro GUI program. Upon completion, you should be able to type at the command prompt:

`wxchordpro`

You will get a file open dialog. Just press `Cancel` and terminate the program with `File` > `Exit`.

You may proceed to [[Getting Started|ChordPro Getting Started]].

If you are familiar with the Linux command line tools, you can install the (much smaller) ChordPro command line program instead:

`sudo cpan install chordpro`

Upon completion, you should be able to type at the command prompt:

`chordpro --version`

and get a response similar to:

`This is ChordPro version 5.00.00`

You're all set to go now. You may proceed to [[Getting Started|ChordPro Getting Started]].