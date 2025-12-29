// capo.js - module to add a capo chord line
//
// Copyright (C) 2018-2023 Jean-Francois Moine
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
// This module is loaded when "%%capo" appears in a ABC source.
//
// Parameters
//	%%capo n	'n' is the capo fret number

if (typeof abc2svg == "undefined")
    var	abc2svg = {}

abc2svg.capo = {
    // b40 intervals of capo
    icb40: [0, 5, 6,11,16,17,22,23,28,33,34,39],
//	    e  f ^f  g _a  a _b  b  c _d  d _e

    gch_build: function(of, s) {
    var	t, i, gch, gch2, i2,
	abc = this,
	p_v = abc.get_curvoice(),
	a_gch = s.a_gch

	if (p_v.capo && a_gch) {
		t = p_v.capo
		i = 0

		while (1) {
			gch = a_gch[i++]
			if (!gch) {
				of(s)
				return
			}
			if (gch.type == 'g')
				break
		}
		gch2 = Object.create(gch)
		gch2.capo = false	// (would be erased when setting gch)
		gch2.text = abc.gch_tr1(gch2.text, -abc2svg.capo.icb40[t % 12])
		if (!p_v.capo_first) {		// if new voice
			p_v.capo_first = true
			gch2.text += "  (capo: " + t.toString() + ")"
		}

		gch2.font = abc.get_font(abc.cfmt().capofont ?
						"capo" : "annotation")
		a_gch.splice(i, 0, gch2)

		// set a mark in the first chord symbol for %%diagram
		gch.capo = true
	}
	of(s)
    },

    set_fmt: function(of, cmd, param) {
	if (cmd == "capo") {
		this.set_v_param("capo_", param)
		return
	}
	of(cmd, param)
    },

    // get the parameters of the current voice
    set_vp: function(of, a) {
    var	i, v,
	p_v = this.get_curvoice()

	for (i = 0; i < a.length; i++) {
		if (a[i] == "capo_=") {
			v = Number(a[++i])
			if (isNaN(v) || v <= 0)
				this.syntax(1, "Bad fret number in %%capo")
			else
				p_v.capo = v
			break
		}
	}
	of(a)
    }, // set_vp()

    set_hooks: function(abc) {
	abc.gch_build = abc2svg.capo.gch_build.bind(abc, abc.gch_build);
	abc.set_format = abc2svg.capo.set_fmt.bind(abc, abc.set_format)
	abc.set_vp = abc2svg.capo.set_vp.bind(abc, abc.set_vp)
    }
} // capo

if (!abc2svg.mhooks)
	abc2svg.mhooks = {}
abc2svg.mhooks.capo = abc2svg.capo.set_hooks
