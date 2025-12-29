// fit2box.js - module for filling a tune in a box
//
// Copyright (C) 2025 Jean-François Moine
//
// This file is part of abc2svg.
//
// abc2svg is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// abc2svg is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with abc2svg.  If not, see <http://www.gnu.org/licenses/>.
//
// This module is loaded when "%%fit2box" appears in a ABC source.
//
// Parameters
//	%%fit2box width height
//		width is the width of the box.
//			The value '*' (star) is the value of %%pagewidth
//		height is the height of the box.
//			The value '*' (star) is the value od %%pageheight

if (typeof abc2svg == "undefined")
    var	abc2svg = {}

abc2svg.fit2box = {

    // generation function with %%fit2box
    do_fit: function(mus) {
    var	r, sv, v, w, h, hh, sc, marg, tit, cl,
	parse = mus.get_parse(),
	f = parse.file,
	fn = parse.fname,
	cfmt = mus.cfmt(),
	wb = cfmt.fit2box[0],
	hb = cfmt.fit2box[1],
	user = mus.get_user(),
	io = user.img_out,			// save the original img_out
	ob = ""					// output buffer

	user.img_out = function(p) {		// function to get the output file
			ob += p
		}

	// get a parameter
	function getparm(parm) {
	    var	j, v,
		i = f.indexOf("%%" + parm)

		if (i >= 0 && (!i || f[i - 1] == '\n')) {
			j = f.indexOf('\n', i)
			v = f.slice(i, j).split(/\s+/)
			v = mus.get_unit(v[1])
		} else {
			v = cfmt[parm]
		}
		return v
	} // getparm()

	// set an old or new parameter
	function setparm(parm, v) {
	    var	i, j,
		p = "%%" + parm

		i = f.indexOf(p)
		if (i >= 0 && (!i || f[i - 1] == '\n')) {
			j = f.indexOf('\n', i)
			f = f.replace(f.slice(i, j), p + ' ' + v)
		} else {
			f = p + ' ' + v + '\n' + f
		}
	} // setparm()

	// get/set the box dimensions
	if (wb == "*")
		wb = getparm("pagewidth")
	if (hb == "*")
		hb = getparm("pageheight")
	if (!hb)
		hb = 1123			// (1123 = 29.7cm)

	// set some parameters
	setparm("stretchlast", "0")
	setparm("stretchstaff", "0")

	// get the original margins and remove them for the first generation
	// (assume left margin == right margin)
	marg = getparm("leftmargin")
	setparm("leftmargin", "0")
	setparm("rightmargin", "0")

	// set the box width twice as before to avoid line breaks
	setparm("pagewidth", (wb * 2).toFixed(2))

	// force the scale
	if (f.indexOf("\n%%pagescale ") >= 0)
		f = f.replace(/(\n%%pagescale).*/, "$1 1")
	else
		f = f.replace(/(\nK:.*)/, "$1\n%%pagescale 1")
	cfmt.trimsvg = 1
	cfmt.fullsvg = "a"

	// do a first generation
	if (abc2svg.fit2box.otosvg)
		abc2svg.fit2box.otosvg(fn, f)
	else
		mus.tosvg(fn, f)

	// analyse the result of the generation
	cfmt = mus.cfmt()
	w = h = hh = 0
	r = ob.match(/<svg[^>]*/g)
	if (!r) {
		user.img_out = io		// restore the normal output
		return				// no SVG
	}
	while (1) {
		sv = r.shift()			// next music line
		if (!sv)
			break
		v = sv.match(/viewBox="0 0 ([\d.]+) ([\d.]+)"/)
		cl = sv.match(/class="([^"]+)"/) // "
//console.log("- sv  ====\n"+sv+"\n      ====\n  cl:"+cl)
		if (!tit			// the first SVG is the tune header
		 || cl[1] == "header"
		 || cl[1] == "footer") {
			hh += +v[2]
			if (cl[1] != "header"
			 && cl[1] != "footer")
				tit = 1
			continue
		}
		if (+v[1] > w)
			w = +v[1]		// max width (thanks to trimsvg)
		h += +v[2]			// whole height
	}
//console.log("-- box:"+wb+"x"+hb+" w:"+w.toFixed(2)+" marg:"+marg.toFixed(2)
//+" h:"+h.toFixed(2)+" hh:"+hh.toFixed(2))

	sc = (hb - hh) / h			// height scale

//fixme: magic value!
	w += 24
	v = (wb - marg * 2) / w			// width scale
//console.log("     scw:"+v.toFixed(3)+" sch:"+sc.toFixed(3))

	if (v <= sc) {
		sc = v					// width constraint
	} else {					// height constraint
		v = Math.round((wb - w * sc) / 2)	// margins
		if (v < marg)
			marg = v
	}

	setparm("pagewidth", wb)
	setparm("leftmargin", marg.toFixed(0))	// restore the margins
	setparm("rightmargin", marg.toFixed(0))
	setparm("pagescale", sc)
	setparm("stretchstaff", 1)
	setparm("stretchlast", 1)
	cfmt.fullsvg = ""
	cfmt.trimsvg = 0

	// do the last generation
//console.log("---\n"+f.slice(0, 500)+"\n---")
//console.log("-> "+wb+" "+hb+" sc:"+sc.toFixed(3)+" marg:"+marg)
	mus.tunes.shift()			// remove the tune class
	user.img_out = io			// restore the normal output
	if (abc2svg.fit2box.otosvg) {		// restore the tosvg function
		mus.tosvg = abc2svg.fit2box.otosvg
		abc2svg.fit2box.otosvg = null
	}
	mus.tosvg(fn, f)
	abc2svg.fit2box.on = 0
    }, // do_fit()

    tosvg: function(of, fn, file, bol, eof) {
    var	parse = this.get_parse()

	parse.fname = fn
	parse.file = bol ? file.slice(bol) : file
	parse.eol = 0

	abc2svg.fit2box.on = 1
	abc2svg.fit2box.do_fit(this)
    }, // tosvg()

    // get a formatting parameter
    set_fmt: function(of, cmd, parm) {
	if (cmd != "fit2box")
		return of(cmd, parm)
	if (abc2svg.fit2box.on)
		return
	abc2svg.fit2box.on = 1
	if (!parm) {					// stop fit2box
		if (abc2svg.fit2box.otosvg) {		// restore the tosvg function
			this.tosvg = abc2svg.fit2box.otosvg
			abc2svg.fit2box.otosvg = null
		}
		return
	}

    var	cfmt = this.cfmt(),
	parse = this.get_parse(),
	f = parse.file

	cfmt.fit2box = parm.split(/\s+/)

	// if no tune yet, change the generation function
	if (f.indexOf("X:") < 0) {
		if (!abc2svg.fit2box.otosvg) {
			abc2svg.fit2box.otosvg = this.tosvg
			this.tosvg = abc2svg.fit2box.tosvg.bind(this, this.tosvg)
		}
		return
	}

	// do the fit2box generation now
	parse.file = parse.file.slice(parse.eol)
	parse.eol = 0
	abc2svg.fit2box.do_fit(this)
	parse.file = f
	parse.eol = parse.file.length - 2	// stop the current parsing in tosvg()
    }, // set_fmt()

    set_hooks: function(abc) {
	abc.set_format = abc2svg.fit2box.set_fmt.bind(abc, abc.set_format)
    } // set_hooks()
} // fit2box

if (!abc2svg.mhooks)
	abc2svg.mhooks = {}
abc2svg.mhooks.fit2box = abc2svg.fit2box.set_hooks
