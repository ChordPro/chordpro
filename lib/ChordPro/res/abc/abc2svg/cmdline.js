// abc2svg - cmdline.js - command line
//
// Copyright (C) 2014-2023 Jean-Francois Moine
//
// This file is part of abc2svg.
//
// abc2svg is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// abc2svg is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with abc2svg.  If not, see <http://www.gnu.org/licenses/>.

// user definitions
var user = {
	read_file: function(fn) {	// read a file (main or included)
	    var	i,
		p = fn,
		file = abc2svg.readFile(p)

		if (!file && fn[0] != '/') {
			for (i = 0; i < abc2svg.path.length; i++) {
				p = abc2svg.path[i] + '/' + fn
				file = abc2svg.readFile(p)
				if (file)
					break
			}
		}

		if (!file)
			return file

		// memorize the file path
		i = p.lastIndexOf('/')
		if (i > 0) {
			p = p.slice(0, i)
			if (abc2svg.path.indexOf(p) < 0)
				abc2svg.path.unshift(p)
		}

		// convert the file content into a Unix string
		i = file.indexOf('\r')
		if (i >= 0) {
			if (file[i + 1] == '\n')
				file =  file.replace(/\r\n/g, '\n')	// M$
			else
				file =  file.replace(/\r/g, '\n')	// Mac
		}

		// load the required modules (synchronous)
		abc2svg.modules.load(file)

		return file
	},
	errtxt: '',
	errmsg:			// print or store the error messages
		typeof abc2svg.printErr == 'function'
			? function(msg, l, c) { abc2svg.printErr(msg) }
			: function(msg, l, c) { user.errtxt += msg + '\n' }
} // user

var	abc				// (global for 'toxxx.js')

if (!abc2svg.path)
	abc2svg.path = []		// path to ABC files - from env ABCPATH

// treat a file
function do_file(fn) {
    var	file = user.read_file(fn)

	if (!file) {
		if (fn != "default.abc")
			user.errmsg("Cannot read file '" + fn + "'")
		return
	}
//	if (typeof(utf_convert) == "function")
//		file = utf_convert(file)

	// generate
	try {
		abc.tosvg(fn, file)
	} catch (e) {
		abc2svg.abort(e)
	}
} // do_file()

function abc_cmd(cmd, args, interp_name) {
	var	arg, parm, fn;

	abc2svg.abort = function(e) {
		abc2svg.printErr('javascript error: ' + e.message +
			'\nStack:\n'  + e.stack)
		abc2svg.quit()
	} // abort()

	// put the last options before the last file
	function arg_reorder(a) {
	    var	f,
		i = a.length - 2

		while (i > 2 && a[i].slice(0, 2) == '--')
			i -= 2
		f = a[--i]
		a.splice(i, 1)
		a.push(f)
	} // arg_reorder()

	// if the first argument is a javascript file, load it
	if (args[0] && args[0].slice(-3) == '.js') {
		abc2svg.loadjs(args[0])
		args.shift()
	}

	if (!args[0]) {
		abc2svg.printErr('ABC translator with ' + interp_name +
			' and abc2svg-' + abc2svg.version + ' ' +
					abc2svg.vdate +
			'\nUsage:\n  ' + cmd +
		    ' [script.js] [options] ABC_file [[options] ABC_file]* [options]\n\
Arguments:\n\
  script.js  generation script to load - default: tohtml.js (HTML+SVG)\n\
  options    ABC options (the last options are moved before the last file)\n\
  ABC_file   ABC file')
		abc2svg.quit()
	}

	// the default output is HTML+SVG
	if (typeof abc2svg.abc_init != 'function')
		abc2svg.loadjs("tohtml.js")

	// initialize the backend
	abc = new abc2svg.Abc(user)
	if (typeof global == "object" && !global.abc)
		global.abc = abc
	abc2svg.abc_init(args)

	// load 'default.abc'
	try {
		do_file("default.abc")
	} catch (e) {
	}

	// put the last options before the last ABC file
	if (args.length > 2 && args[args.length - 2].slice(0, 2) == '--')
		arg_reorder(args)

	while (1) {
		arg = args.shift()
		if (!arg)
			break
		if (arg[0] == "-" && arg[1] == "-") {
			parm = arg.replace('--', 'I:') + " " +
				args.shift() + "\n"
			abc2svg.modules.load(parm)
			abc.tosvg(cmd, parm)
		} else {
			do_file(arg)
			abc.tosvg('cmd', '%%select\n')
		}
	}
	abc2svg.abc_end()
}

// nodejs
if (typeof module == 'object' && typeof exports == 'object') {
	exports.user = user;
	exports.abc_cmd = abc_cmd
}
