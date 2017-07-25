The way the output is formatted and some behavioural aspects of the reference implementation are configurable via configuration files. These are [JSON](http://www.json.org/) files that can be created and modified using any convenient text editor. There are also several JSON editors available, often in the form of web services. For schema-based editors, the schema can be downloaded from the [ChordPro site](http://www.chordpro.org/chordpro/config50.schema).

ChordPro tries to read several configuration files and combines their contents to form the actual configuration. In the examples below the symbol `~` denotes the user's home directory. Windows users may need to change the forward slashes to backward slashes.

1. On systems that support it, a system-wide configuration file is read. On Linux systems, this is `/etc/chordpro.json`.

2. A legacy config file from the older _Chord_<sub>ii</sub> program is processed. By default this is `~/.chordrc` but this can be changed using environment variables `CHORDIIRC` or `CHORDRC`.

3. A user specific configuration file is read from either:
* `~/.config/chordpro/chordpro.json`
* `~/.config/chordpro.json`
* `~/.chordpro/chordpro.json`
4. A project specific configuration file is read from either:
* `chordpro.json`
* `.chordpro.json`