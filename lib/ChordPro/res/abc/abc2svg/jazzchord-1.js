// abc2svg - jazzchord.js - Adds jazz chord styling to chord symbols
//
// Copyright (C) 2020-2023 Jean-Francois Moine
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
// Code adapted from Chris Fargen.
//	https://gist.github.com/chrisfargen/4324c6cf6fed2c8f9a6eae1680e53169
//
// This module is loaded by %%jazzchord.
//
// Parameters
//	%%jazzchord [ string '=' replacement-string ]*

if (typeof abc2svg == "undefined")
    var	abc2svg = {}

abc2svg.jazzchord = {

    // default replacements
    defrep: {
	"-": "–",
	"°": "o",
	"º": "o",
	"ᵒ": "o",
	"0": "ø",
//	"6/9": "⁶⁄₉",
//	"maj": "Δ",
//	"M": "Δ",
//	"min": "–",
//	"m": "–",
	"^": "∆"
    },

    gch_build: function(of, s) {
    var	gch, ix, r, t,
	fmt = s.fmt

	if (!fmt.jazzchord) {
		of(s)
		return
	}

	// jazzify a chord
	function jzch(t) {
	    var r = '',
		a = t.match(/(\[?[A-G])([#♯b♭]?)([^/]*)\/?(.*)\)?/)
		// a[1]=note, a[2]=acc, a[3]=quality, a[4]=bass

		if (!a)
			return t
		if (a[2])
			r = "$7" + a[2]
		if (a[3][0] == 'm'		// if minor
		 && a[3].slice(0, 3) != "maj") {
			if (!r)
				r += "$7"
			if (a[3].slice(0, 3) == "min") {
				r += a[3].slice(0, 3)
				a[3] = a[3].slice(3)
			} else {		// assume 'm'
				r += 'm'
				a[3] = a[3].slice(1)
			}
		}
		if (a[3])
			r += (r ? "$0" : '') + "$8" + a[3]
		if (a[4])
			r += (r ? "$0" : '') + "$9/" + a[4]
		if (!r)
			return t
		return a[1] + r + "$0"
	} // jzch()

	for (ix = 0; ix < s.a_gch.length; ix++) {
		gch = s.a_gch[ix]
		t = gch.text
		if (gch.type != 'g'
		 || t.indexOf('$') >= 0)	// if some formatting already
			continue
		switch (t) {
		case "/": gch.text = "\ue101"; continue
		case "%": gch.text = "\ue500"; continue
		case "%%": gch.text = "\ue501"; continue
		}

		if (fmt.jzreg) {		// if replacement list
			t = t.replace(fmt.jzRE,
					function(x) {
						return fmt.jzrep[x]
			})
		}

		if (fmt.jazzchord == 1) {
			if (t[0] == '(')
				t = t.slice(1, -1)
			t = t.split('(')	// possible "ch1(ch2)"
			r = jzch(t[0])
			if (t.length > 1)
				r += '(' + jzch(t[1])
		} else {
			r = t
		}
		if (gch.text[0] == '(')
			gch.text = '(' + r + ')'
		else
			gch.text = r
	}
	of(s)				// build the chord symbols
    }, // gch_build()

    set_fmt: function(of, cmd, parm) {
    var	i, k, s,
	cfmt = this.cfmt()

	if (cmd == "jazzchord") {
		cfmt.jazzchord = this.get_bool(parm)
		if (!cfmt.jazzchord)
			return
		if (parm[0] == '2')
			cfmt.jazzchord = 2		// no style

		if(!cfmt.jzreg) {			// if new definition
//			cfmt.jzreg = "-|°|º|ᵒ|0|6/9|maj|M|min|m|\\^"
			cfmt.jzreg = "-|°|º|ᵒ|0|\\^"
			cfmt.jzrep = Object.create(abc2svg.jazzchord.defrep)
			cfmt.jzRE = new RegExp(cfmt.jzreg, 'g')
		}
		if (parm && parm.indexOf('=') > 0) {
			parm = parm.split(/[\s]+/)
			for (cmd = 0; cmd < parm.length; cmd++) {
				k = parm[cmd].split('=')
				if (k.length != 2)
//fixme: error
					continue
				s = k[1]		// replacement
				k = k[0]		// key
				i = cfmt.jzreg.indexOf(k)
				if (i >= 0) {		// if old key
					if (s) {	// new value
						cfmt.jzrep[k] = s
					} else {
						cfmt.jzreg = cfmt.jzreg.replace(k, '')
						cfmt.jzreg = cfmt.jzreg.replace('||', '|')
						delete cfmt.jzrep[k]
					}
				} else {
					cfmt.jzreg += '|' + k
					cfmt.jzrep[k] = s
				}
				cfmt.jzRE = new RegExp(cfmt.jzreg, 'g')
			}
		}
		return
	}
	of(cmd, parm)
    }, // set_fmt()

    set_hooks: function(abc) {
	abc.gch_build = abc2svg.jazzchord.gch_build.bind(abc, abc.gch_build)
	abc.set_format = abc2svg.jazzchord.set_fmt.bind(abc, abc.set_format)

	abc.add_style("\
\n.jc7{font-size:90%}\
\n.jc8{baseline-shift:25%;font-size:75%;letter-spacing:-0.05em}\
\n.jc9{font-size:75%;letter-spacing:-0.05em}\
")
	abc.param_set_font("setfont-7", "* * class=jc7")
	abc.param_set_font("setfont-8", "* * class=jc8")
	abc.param_set_font("setfont-9", "* * class=jc9")
    } // set_hooks()
} // jazzchord

if (!abc2svg.mhooks)
	abc2svg.mhooks = {}
abc2svg.mhooks.jazzchord = abc2svg.jazzchord.set_hooks
