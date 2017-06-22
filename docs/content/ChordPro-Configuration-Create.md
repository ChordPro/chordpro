# Creating a new custom configuration

![](images/maintenance.png)

From the command line, issue the command:

`chordpro` `--print-default-config` `>` `custom.json`

This will create a file `custom.json` in the current directory, containing all default configuration settings. As the name already suggests, this is a JSON document that can be maintained using any convenient text editor.

To verify the changes you have made, run `chordpro` as follows:

`chordpro` `--config=custom.json` _other arguments_

## Making it the standard configuration

When you are satisfied, you can make this your standard configuration as follows:

### Linux

Move the file to one of the following locations (in decreasing order of preference):

* `~/.config/chordpro/chordpro.json`
* `~/.config/chordpro.json`
* `~/.chordpro.json`
* `~/chordpro.json`

### Microsoft Windows

Move the file to one of the following locations (in decreasing order of preference):

![](images/todo.png)

* `.chordpro.json`
* `chordpro.json`

### Mac OS/X

![](images/todo.png)
