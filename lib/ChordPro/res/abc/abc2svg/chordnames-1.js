// abc2svg - chordnames.js - change the names of the chord symbols
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
// This module is loaded by %%chordnames.
//
// Parameters
// 1st syntax:
//		%%chordnames <comma separated list of chord names>
//	Each name replace one chord. The order is:
//		CDEFGAB<N.C.>
// 2nd syntax:
//		%%chordnames <comma separated list of key ':' value>
//	The key may be a chord letter ('A') with/or an accidental
//	Example:
//		%%chordnames Bb:B,B:H,b:s	% German chords

if (typeof abc2svg == "undefined")
    var	abc2svg = {}

abc2svg.chordnames = {

    gch_build: function(of, s) {
    var	gch, ix, t,
	cfmt = this.cfmt()

	if (s.a_gch && cfmt.chordnames) {
		for (ix = 0; ix < s.a_gch.length; ix++) {
			gch = s.a_gch[ix]
			t = gch.text
			if (gch.type != 'g' || !t)
				continue
			if (t[0] == 'n' || t[0] == 'N')
				t = 'N'
			gch.text = t.replace(cfmt.chordnames.re,
				function(c){return cfmt.chordnames.o[c]})
		}
	}
	of(s)
    }, // gch_build()

    gimpl: 'CDEFGABN',
    set_fmt: function(of, cmd, parm) {
    var	i, v,
	re = [],
	o = {},
	cfmt = this.cfmt()

	if (cmd == "chordnames") {
		parm = parm.split(',')
		if (parm[0].indexOf(':') > 0) {	// by object
			for (i = 0; i < parm.length; i++) {
				v = parm[i].split(':')
				if (!v[1])	// (no ':')
					continue
				o[v[0]] = v[1]
				re.push(v[0])
			}
		} else {			// implicit
			for (i = 0; i < parm.length; i++) {
				v = abc2svg.chordnames.gimpl[i]
				o[v] = parm[i]
				re.push(v)
			}
		}
		cfmt.chordnames = {re: new RegExp(re.join('|'), 'g'), o: o}
		return
	}
	of(cmd, parm)
    }, // set_fmt()

    set_hooks: function(abc) {
	abc.gch_build = abc2svg.chordnames.gch_build.bind(abc, abc.gch_build)
	abc.set_format = abc2svg.chordnames.set_fmt.bind(abc, abc.set_format)
    } // set_hooks()
} // chordnames

if (!abc2svg.mhooks)
	abc2svg.mhooks = {}
abc2svg.mhooks.chordnames = abc2svg.chordnames.set_hooks
