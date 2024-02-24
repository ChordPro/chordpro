<style>
p{margin-left:.5cm;max-width:21cm}
li{margin-left:.5cm;max-width:20cm}
li p{margin-left:0}
</style>
## abc2svg

**abc2svg** is a set of ECMAscript files that handle the
[ABC music notation](http://abcnotation.com/). This includes
editing, displaying, printing, playing the music files and
converting them to other formats such as ABC and MEI notations.

The **abc2svg** core is based on the
[abcm2ps](https://github.com/lewdlime/abcm2ps) C code
which requires compilation on every operating system. 
The **abc2svg** scripts can run in any system with no compilation on
any platform that contains an internet browser. This includes MS-Windows,
Apple, and Unix-like systems (Linux, BSD...) as well as portable devices
such as cell phones and tablets.

A description of the ABC parameters that relate to both abcm2ps
and abc2svg can be found [here][1].

[1]: http://moinejf.free.fr/abcm2ps-doc/index.html "abc2svg documentation"

### 1. Web browser usage

#### 1.1 Rendering ABC files from a local or remote source

After accessing ABC files with a web browser either from a local or web
source, you can render or play the music without much preparation.
One approach uses [bookmarklets](https://en.wikipedia.org/wiki/Bookmarklet).

A bookmarklet is the same as a normal bookmark in a web browser.
Its title (or name) is anything you want to use to identify it and its URL
(or location or address) is javascript code starting by `javascript:`.
First, create a bookmark from this page adding it to your library of
bookmarks. Next, edit this mark changing the title and the URL. (Details
for editing a bookmark are specific for each browser. To get instructions,
search on the internet the name of the browser and keywords such as
'bookmarklet' and 'javascript in url'). To edit the URL, extract
the javascript code
by right clicking on one of the bookmarklets below and selecting
copy url. Then, paste this code into the URL of your new bookmark
in your library.

To use a abc2svg bookmarklet, first, load an ABC file into your
browser either from a web site of from a file on your system.
Once you see the textual abc code, click on the bookmarklet
that you created. After a slight delay depending upon the
complexity of the abc code, it should be replaced by a music
representation or a list of the contents of the ABC file. Here
are two bookmarklets that you can try.

This
<a href="javascript:(function(){var%20s,n=2,d=document,b=d.body;d.head.innerHTML='%3cstyle%3esvg{display:block};@media print{body{margin:0;padding:0;border:0};.nop{display:none}}%3c/style%3e\n';b.innerHTML='%3cscript type=%22text/vnd.abc%22%3e\n'+b.textContent+'%3c/script%3e\n';function%20f(u){s=d.createElement('script');s.src='http://moinejf.free.fr/js/'+u;s.onload=function(){if(--n==0)dom_loaded()};d.head.appendChild(s)};f('abcweb-1.js');f('snd-1.js')})()"
title="Copy me">first abc2svg bookmarklet</a>
renders all the music it finds in the page currently displayed.  
Once the music is displayed, clicking inside a tune starts playing it
from the beginning.
Clicking on a particular note or rest starts playing from that point.  
To print or convert the music to a PDF file,
simply click on the 'Print' button of the web browser.
(If the 'Print' button does not appear on your browser menu,
try right clicking on the web page.)

Alternatively, if your source contains many tunes, you can
use this
<a href="javascript:(function(){var%20s,n=2,d=document,b=d.body;d.head.innerHTML='%3cstyle%3esvg{display:block};@media print{body{margin:0;padding:0;border:0};.nop{display:none}}%3c/style%3e\n';b.innerHTML='%3cscript type=%22text/vnd.abc%22%3e\n'+b.textContent+'%3c/script%3e\n';function%20f(u){s=d.createElement('script');s.src='http://moinejf.free.fr/js/'+u;s.onload=function(){if(--n==0)dom_loaded()};d.head.appendChild(s)};f('abcweb1-1.js');f('snd-1.js')})()"
title="Copy me">second bookmarklet</a>.
The browser will list the titles of the tunes.
Clicking on a title displays the tune.
Playing and printing work in the same manner as above.  
The generated pages contain a yellow menu in the top right corner which permits
you to return to the tune list or to modify the music. With this last option,
you can adjust the page size before printing, correct the ABC syntax or
do some transposition.
Note that these changes stay only with the browser and are not saved
to your system.

If you want to experiment with these bookmarklets, here are some raw ABC files:

- [from my site](http://moinejf.free.fr/abc/agora.abc "agora.abc")
- [from Cranford Publications][2]

[2]: http://www.cranfordpub.com/tunes/abcs/NatalieBlueprint.txt "Blueprint"

#### 1.2 Writing, playing and printing music with the abc2svg editor

The [abc2svg editor][3]
is another example of what can be done with **abc2svg**.

[3]: http://moinejf.free.fr/js/edit-1.xhtml "ABC editor based on abc2svg"

If you are unfamiliar with ABC music notation, just copy this ABC sequence below
and paste it into the text area of the editor.

	X:1
	T:C scale
	M:C
	L:1/4
	K:C
	CDEF|GABc|

If your ABC files contain `%%abc-include`, then you must:

  - load the ABC file using the browse button,
  - click the include file name button,
  - and load the include file using the same previous browse button.  

Only one included file is allowed.

If you have installed abc2svg in a site of yours, you may put a file
**pref.js** with the abc2svg scripts. This file may contain various
javascript functions and also ABC parameters.
These parameters must be defined inside the following sequence:

	if (typeof abc2svg == "undefined")    
	    var abc2svg = {}
	if (!abc2svg.a_inc)
		abc2svg.a_inc = {}
	abc2svg.a_inc["default.abc"] = `
	.. put here the ABC parameters ..
	`

If you have a US keyboard, its behaviour can be changed for easier music
entering by one of these bookmarklets:
<a href="javascript:(function(){if(typeof%20abc2svg.loadjs=='function'){abc2svg.loadjs('abckbd-1.js')}else{alert('use%20with%20abc2svg%20editor')}})()"
title="Copy me">keyboard 1</a>
and
<a href="javascript:(function(){if(typeof%20abc2svg.loadjs=='function'){abc2svg.loadjs('abckbd2-1.js')}else{alert('use%20with%20abc2svg%20editor')}})()"
title="Copy me">keyboard 2</a>.

#### 1.3 Publishing music on your web pages

To insert music in your web pages, you just have to insert the lines

	<script src="http://moinejf.free.fr/js/abcweb-1.js"></script>
	<script src="http://moinejf.free.fr/js/snd-1.js"></script>

in the HTML &lt;head&gt; and put the music as
ABC sequences in the &lt;body&gt;.

[This example][4] demonstrates how to do it.
(Note that, in the example, the paths are relative - see why below.)

[4]: http://moinejf.free.fr/abcm2ps-doc/tabac.html "J'ai du bon tabac"

As it is apparent, HTML and ABC can be mixed in the same html file.
Both are rendered in the order you defined them.

You may also have noticed this style about SVG elements:  
`        svg { display: block }`

It puts the lines of music on vertical areas.  
Without this style, the music is in-lined as in [this other example][5].

[5]: http://moinejf.free.fr/abcm2ps-doc/dansou-i.html "Tune index example"

Global ABC parameters may be added as `parameter=value` in the query string
of the URL of the page. The [following example][16] calls the same
"J'ai du bon tabac" with `pagescale=1.2` (giving `%%pagescale 1.2`).

[16]: http://moinejf.free.fr/abcm2ps-doc/tabac.html?pagescale=1.2 "J'ai du bon tabac"

In the above examples, all the ABC music is generated (displayed
and ready to be played) by means of the script **abcweb-1.js**.  
If there is a large collection of tunes, it may be preferable to
link to the other script, **abcweb1-1.js**, which offers a tune selection.
Without an explicit
selection (see below), a list of the tunes is displayed, and,
after a tune has been selected, the whole page is replaced by the music.
(The HTML code, if any, is not displayed.)
You can go back to the list of the tunes thanks to the menu
on the top right corner of the screen. Here is [a real example][6].

[6]: http://moinejf.free.fr/abc/boyvin-2-2.html "J. Boyvin organ tunes"

As you may notice in the menu, the edition of the ABC content is proposed.
This permits you, for example, to transpose the tunes.
This edition is done inside the browser, so, your changes will be lost
after leaving the page.

When accessing such pages, an external selection of the tunes
can be accomplished by ending the URL with the character '`#`'
followed by a [regular expression][7]
to be applied to the tune headers.
For instance, here is the ['Duo' de J. Boyvin][8].

[7]: https://en.wikibooks.org/wiki/Regular_Expressions "Regular expressions"
[8]: http://moinejf.free.fr/abc/boyvin-2-2.html#T:Duo "Duo"

With any of the above scripts the music may be printed using
the 'Print' button of the browser. You should add a style as:  
`       @media print{body{margin:0;padding:0;border:0}.nop{display:none}}`  

to remove the margins, the error messages and the menus from the
printed pages.

#### 1.4 Installing abc2svg on your system or on your server

The **abc2svg** package on my server is still being tuned
which could change its behaviour at any unknown time; so you may
prefer to install and run it from your own system. 

There are many ways to install abc2svg:

- [tarball][16] or [.zip archive][17] from my site  
  Both files contain the scripts that are generated from the source
  when abc2svg is stable enough. The scripts are ready
  to be used from the root directory.

[16]: http://moinejf.free.fr/abc2svg.tar.bz2 "tarball"
[17]: http://moinejf.free.fr/abc2svg.zip "ZIP file"

- [Guido Gonzato's page](http://abcplus.sourceforge.net/#abc2svg)  
  Guido maintains a ZIP archive of the abc2vg scripts after
  each release of a new version (many thanks, Guido!).  
  You can just download and unzip this archive. **abc2svg** should
  run immediately in your machine without connecting to my site.  
  In the same page, you can also find some binaries of QuickJS,
  a fast javascript interpreter (see below).

- tarball  
  From the timeline in the [chisel repository][13], you can get a tarball
  of any version of the abc2svg source and install it in your system.  
  The abc2svg scripts must then be built from the raw source files
  described in the section 'Build' below.  
  The disadvantage of this approach is that if you want
  to use an other or newer version you need to download a new tarball.

[13]: https://chiselapp.com/user/moinejf/repository/abc2svg/timeline

- fossil clone  
  If you can get the fossil program (one binary) for your system,
  you may clone the chisel repository by  
  `        fossil clone https://chiselapp.com/user/moinejf/repository/abc2svg abc2svg.fossil`  
  `        fossil open abc2svg.fossil`  
  and get the abc2svg source files containing the last changes
  between the official versions. Updating your files is done by  
  `        fossil pull`  
  `        fossil update`  
  Building the scripts is done in the same way as with a tarball.  
  The repository is presently over 50Mb.

  For those unfamiliar with [fossil][14], it is an integrated
  software management system similar to [git](https://git-scm.com/).  
  Chisel acts like a repository similar to [github](https://github.com/).

[14]: https://fossil-scm.org/home/doc/trunk/www/index.wiki

Using bookmarklets with a local installation does not work directly
because of a cross-domain security hole, but this is possible by running
a local HTTP server (you will also have to change the location
of the scripts in the bookmarklet code).

If you have write access on a remote server, you may put there
the abc2svg scripts. There is no automatic process to do that.
You will have to
[look at my site](http://moinejf.free.fr/js/ "all abc2svg scripts")
to determine the files that need to be copied.

In addition, you have to set the correct location of the abc2svg scripts
in your pages. As a trick, I put the abc2svg scripts in a folder
at the same level as the HTML files:

`        <script src="../js/abcweb-1.js"></script>`

This allows the generation of the music to run either locally
or remotely.

### 2. Automatic creation of music sheets

#### 2.1 abc2svg shell scripts

As you have seen, printing the music can be done easily with any web browser.
You can automate the process of creating music sheets
with **abc2svg** using shell scripts running a Javascript interpreter.

The interfaces to the various interpreters are different. Below you will
find the scripts I had to built.

- `abcqjs` with `qjs` [QuickJS by Fabrice Bellard and Charlie Gordon][10]
- `abcmjs` with `js78`, `js60`, `js52` or `js24` (Mozilla JavaScript shell)
- `abcjsc` with `jsc` (webkit2gtk)
- `abcnode` with `node` (nodeJS without module)

[10]: https://bellard.org/quickjs/

Each script gets the abc2svg options and ABC files from the command line
and sends the generated file to `stdout` and possible errors to `stderr`.  
The general syntax of the command line is:  
`        script [script.js] [options] ABC_file [[options] ABC_file]* [options]`
with:

- `script.js` is an optional backend script.  
  It defaults to `tohtml.js` (HTML+SVG)
- `options` are the ABC options.  
  For compatibility, the last options are moved before the last ABC file.

These scripts try to read a file `default.abc` at startup time.
This file and also the files included by `%%abc-include` are searched
in the current directory or in the colon separated list of directories
contained in the environment variable `ABCPATH`.

#### 2.2 Backend scripts

By default, the shell scripts generate (HTML+SVG) files.  
This output may be modified by backend scripts. These ones must appear
immediately following the name of the shell script.  
They are:

- `toabc.js`  
  This script returns the (selected) ABC tunes from the ABC source file  
  applying transposition.  
  The resulting file does not contain the formatting parameters.  
  Example:  
  `        abcqjs toabc.js my_file.abc --select X:2 > tune_2.abc`

- `toabw.js`  
  This script outputs an Abiword file (ABW+SVG) that can be read by some
  word processors (abiword, libreoffice...). The word processor allows
  you to convert the file to many other formats from a command line.  
  The abc2svg music font (`abc2svf.woff` or `abc2svg.ttf`) must be installed
  in the local system for displaying and/or converting the .abw file.  
  Example:  
  `        abcmjs toabw.js my_file.abc > my_file.abw`

- `tomei.js`  
  This script outputs the music as a [MEI](https://music-encoding.org/) file.  
  Note, only one tune may be translated from ABC to MEI (multi-tunes ABC files
  generate bad MEI files).

- `tonotes.js`  
  This script outputs a list of the MIDI events.

- `toodt.js`  
  This script creates an Open Document (ODT+SVG) which can be read by most
  word processors (abiword, libreoffice...).  
  When runs with the shell script `abc2svg`, it asks for the npm module
  `jszip` to be installed.
  When run with `abcqjs` on unix-like systems, it creates a temporary
  directory tree in `/tmp`.  
  The output ODT document may be specified in the command line argument
  after `-o` (default `abc.odt`).  
  Example:  
  `        abcqjs toodt.js my_file.abc -o my_file.odt`

- `toparam.js`  
  This script just outputs the abc2svg parameters.

#### 2.3 PDF generation

`abctopdf` is a shell script which converts ABC to PDF using one of the
previous shell scripts and, either a chrome/chromium compatible web browser
(settable by the environment variable 'BROWSER'),
or the program [weasyprint](https://weasyprint.org/).

Note also that, with `weasyprint`, the paper size is forced to A4.
Instructions for changing this size may be found in the script source.

The output PDF document may be specified by the command line argument `-o`
(default `abc.pdf`).

Example:  
`        abctopdf my_file.abc -o my_file.pdf`

### 3. Build

The abc2svg scripts which are used to render the music
either by a web browser or by a shell script must be built from
the source files you got by tarball or fossil clone.

Quoting [Douglas Crockford](https://www.crockford.com/jsmin.html),
minification is a process that removes comments and unnecessary whitespace from
JavaScript files. It typically reduces file size by half, resulting in
faster downloads.

If you can run one of the tools [ninja](https://ninja-build.org/)
or [samurai](https://github.com/michaelforney/samurai), you can build
the scripts

- without minification  
  This is useful for debugging purposes and the scripts are more human friendly.

  `        NOMIN=1 samu -v`

   or

  `        NOMIN=1`  
  `        export NOMIN`  
  `        ninja -v`

- in a standard way with minification  
  In this case, you need one of the tools
  [JSMin](https://www.crockford.com/jsmin.html) or
 `uglifyjs` which comes with nodeJS.

  `        samu -v`

If you also want to change or add music glyphs, you may edit the source
file `font/abc2svg.sfd`.
In this case, you will need both `base64` and `fontforge`, and run

`        samu -v font.js`

If you cannot or don't want to install `ninja` or `samurai`, you may build
the abc2svg files by the shell script `./build`.
(This script must be run by a Posix compatible shell.)

### 4. Inside the code of abc2svg

#### 4.1 Core and modules

`abc2svg-1.js` is the **abc2svg** core.  
It contains the ABC parser and the SVG generation engine.
It is needed for all music rendering. It is automatically loaded
by the web scripts and the shell scripts.  
If you want to use the core with your own scripts,
its API is described in the [wiki][11].

[11]: https://chiselapp.com/user/moinejf/repository/abc2svg/wiki?name=interface-1

The core does not handle all the abc2svg commands/parameters.
Some of them are treated by modules.
A module is a script which is loaded in the browser or in the JS interpreter
when the command it treats is seen in the ABC flow.  
Detailed information about the modules may be found in the [wiki][12].

[12]: https://chiselapp.com/user/moinejf/repository/abc2svg/wiki?name=modules

#### 4.2 Internal information

- The music is displayed as SVG images. There is one image per
  music line / text block.  
  If you want to move these images to some other files,
  each one must contain the full CSS and defs. For that, insert  
  `        %%fullsvg x`  
  in the ABC file before rendering (see the
  [fullsvg documentation](http://moinejf.free.fr/abcm2ps-doc/fullsvg.html)
  for more information).

- Playing uses the HTML5 audio and/or the midi APIs.  
  For audio, by default, abc2svg uses a sound font (format SF2)
  which is split into one file
  per instrument. This sound font is stored in the subdirectory `Scc1t2/`.
  Each instrument file is a base64 encoded javascript array.  

	Other sound fonts may be used. Some of them are stored in the subdirectory
  `sf2/` (`AWE_ROM_gm` and `2MBGMGS`). Two formats are supported: raw SF2 and
  SF2 wrapped into javascript (the raw SF2 files can be loaded
  only when they are in the same HTTP domain).
  The shell script `sf.sh` (in `sf2/`) may be used to create the javacript files
  from raw SF2 files.

	The sound font to be used for playing may be defined in the ABC code
  by the command `%%soundfont`. E.g.:  
  `        %%soundfont http://moinejf.free.fr/js/sf2/AWE_ROM_gm.js`

- The names of the abc2svg scripts have a suffix which is the version of
  the core interface (actually '`-1`').

#### 4.3 More about the web scripts

Here are the scripts which are used in a web context:

- `abcweb-1.js`  
  This script replaces the ABC sequences found in the (X)HTML file
  by SVG images of the music.  
  The ABC sequences are searched:
  - first inside &lt;script&gt; elements with a type
    ["text/vnd.abc"](https://www.iana.org/assignments/media-types/text/vnd.abc)
    (the script tag is replaced by a &lt;div&gt;),
  - or inside (X)HTML elements with a class `abc` (lower case letters),
  - otherwise on `X:` or `%abc-` at start of line up to a XML tag at start of line.

	When a ABC sequence is not included in a &lt;script&gt; and when it contains
  the characters '<', '>' or '&',
  it must be enclosed in a XML comment or in a CDATA
  (%&lt;![CDATA[ .. %]]&gt; - the comment or CDATA must be in a ABC comment).

	When using &lt;script&gt;, it is possible to set abc2svg parameters via CSS.
  For that, the &lt;style&gt; in the HTML &lt;head&gt; may contain custom
  properties (properties starting with '--') and these properties are converted
  to abc2svg parameters (starting with '%%') before the ABC sequence.  
  For instance, in the (&lt;head&gt;) &lt;style&gt; element, you can put:  
  `        .parm {--pagewidth:30cm;  --bgcolor : yellow}`

	and in some &lt;script ..vnd.abc..&gt;, you set the class:  
  `        <script class="parm" type="text/vnd.abc">`

	This defines the page width and the background color of the generated music.

	See the
  [%%beginml documentation](http://moinejf.free.fr/abcm2ps-doc/beginml.html)
  for an example, and here is [how to put inline music in HTML][15].   
  Playing and highlighting the played notes may be offered loading
  the script `snd-1.js` (see below).

[15]: http://moinejf.free.fr/abcm2ps-doc/inline.html "abc2svg - inline music"

    This script also accepts a parameter `with_source`.
    When this parameter is set, the music source is included before the
    SVG images of the music. An argument `nohead` prevents displaying
    the source of the first music sequence. The music source is displayed
    in a &lt;pre&gt; element of class `source`. The SVG's are included
    in a &lt;div&gt; of the same class `source`.
    The source may be displayed either above (default) or
    at the left side of the music (using a style as
    `.source{display: inline-block; vertical-align: top}`).
    See the source of
    [abcm2ps/abc2svg features](http://moinejf.free.fr/abcm2ps-doc/features.html)
    for an example.

    The music source may be editable.
    To change it, the script contains two functions:  
    - `abc2svg.get_music` returns the source of the music sequence
       (in &lt;script&gt; type "text/vnd.abc", class="abc" or inlined ABC)
       Its argument is the HTML &lt;div&gt; element that contains the music.  
    - `abc2svg.set_music` has two arguments, the HTML &lt;div&gt; element
       and the new source of the music.
       It generates and replaces the music in the &lt;div&gt;.

- `abcweb1-1.js`  
  The page body is analyzed as a ABC file and its content is
  replaced by music as SVG images.  
  If the page contains reserved XML characters ('&lt;', '&gt;' and '&amp;'),
  the ABC code must be enclosed in a
  `         <script type="text/vnd.abc"> .. </script>`
  sequence.

	When there are many tunes in the file, the script displays a list
  of the tunes. The list step may be bypassed when the URL of the file
  contains a regular expression in the 'hash' value ('#' followed by
  a string at the end of the URL).
  This string does a
  [%%select](http://moinejf.free.fr/abcm2ps-doc/select.xhtml).

	When one or many tunes are displayed, a menu in the top/right corner
  offers to go back to the tune list or to modify the ABC source.

- `snd-1.js`  
  This script may be used with `abcweb-1.js` or `abcweb1-1.js`
  to play the rendered ABC music.  

### 6. Credit

**abc2svg** includes the following packages:

- wps by Tomas Hlavaty  
  <http://logand.com/sw/wps/log.html>

- JavaScript SoundFont 2 Parser by imaya/GREE Inc and Colin Clark  
  <https://github.com/colinbdclark/sf2-parser>

- Scc1t2  
  <http://www.ibiblio.org/thammer/HammerSound/localfiles/soundfonts/>

- strftime by T. H. Doan  
  <https://thdoan.github.io/strftime/>

[Jean-François Moine](http://moinejf.free.fr)
