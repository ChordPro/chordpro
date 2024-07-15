// abc2svg - cmd.js - stripped down version of cmdline.js

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
var s				// (var for do_begin_end - grid3)
var cl				// (var for grid3)

abc2svg.path = []		// path to ABC files

// treat a file
function do_file(fn) {
    var	file = user.read_file(fn)

	if (!file) {
		user.errmsg("Cannot read file '" + fn + "'")
		return
	}

	// generate
	try {
		abc.tosvg(fn, file)
	}
	catch (e) {
		abc2svg.abort(e)
	}
} // do_file()

function abc_cmd(cmd, args, interp_name) {
	var fn = args[0]
	abc2svg.abort = function(e) {
		abc2svg.printErr('javascript error: ' + e.message +
			'\nStack:\n'  + e.stack)
		if (abc) {
			abc.parse.state = 0		// force block flush
			abc.blk_flush()
			abc2svg.abc_end()
		}
		abc2svg.quit()
	} // abort()

	// initialize the backend
	abc = new abc2svg.Abc(user)
	abc2svg.abc_init(args)
	do_file(fn)
//	abc.tosvg('cmd', '%%select\n')
	abc2svg.abc_end()
}

//Local Variables:
//tab-width: 4
//End:
