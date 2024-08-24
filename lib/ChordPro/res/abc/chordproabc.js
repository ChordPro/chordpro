// QuickJS script for ChordPro ABC to SVG.
//
// Based on the script 'abcqjs', part of the abc2svg package.

// Copy of the command line arguments.
var args = scriptArgs

// 1st argument is this script.
var script = args.shift()

// 2nd argument is the path where the scripts reside.
var path = args.shift() + "/"

// 3rd is the output file, so we do not need redirection and a shell.
var output = args.shift()

// Interpreter specific functions.
function load(fn) {
    return std.loadScript(fn)
}

// The abc2svg glue.
var abc2svg = {
    print: print,
    printErr: function(str) {
	std.err.printf("%s\n", str)
    },
    quit: function() {
	std.exit(1)
    },
    readFile: std.loadFile,
    get_mtime: function(fn) {
	return new Date(os.stat(fn)[0].mtime)
    },
    loadjs: function(fn, relay, onerror) {
	try {
	    load(fn[0] == "/" ? fn : (path + fn))
	    if (relay)
		relay()
	}
	catch(e) {
	    if (onerror)
		onerror()
	    else
		abc2svg.printErr("Cannot read file " + fn +
				 "\n  " + e.name + ": " + e.message)
	    return
	}
    } // loadjs()
} // abc2svg

// --- main ---

if ( std.getenv("CHORDPRO_ABC_DEBUG") ) {
    std.out.printf( "script = %s\n", script )
    std.out.printf( "output = %s\n", output )
    std.out.printf( "path   = %s\n", path )
}

console.log = abc2svg.printErr

// Create output file and redirect output.
var out = std.open( output, "w" )
abc2svg.print = function(line) {
    out.puts( line + '\n' )
}

// Load the abc2svg core.
load( path + "abc2svg-1.js" )
load( path + "../hooks.js" )
load( path + "cmdline.js" )

// Run the generator with the remaining arguments.
if ( os.open( path + "tohtml.js", 0, 0 ) >= 0 ) {
    args.unshift("tohtml.js")
}
else {
    args.unshift("toxhtml.js")
}
abc_cmd( "chordproabc", args, "QuickJS" )

