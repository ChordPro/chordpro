// tropt.js - module to optimize the notes after transposition
//
// Copyright (C) 2022-2024 Jean-Francois Moine
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
// This module is loaded when "%%tropt" appears in a ABC source.

if (typeof abc2svg == "undefined")
    var	abc2svg = {}

abc2svg.tropt = {

    // function called before start of the generation
    voice_adj: function(of, last_s) {
	if (last_s) {			// if not first time
		of(last_s)
		return
	}
    var	v, p_v, s, m, nt, p, a, np, na,
	C = abc2svg.C,
	vo_tb = this.get_voice_tb(),
	nv = vo_tb.length

	// check if some next note has the same pitch without any accidental
	function ok(s, p) {
	    var	nt, m

		while (s) {
			if (s.bar_type)
				return 1 //true
			if (s.type == C.NOTE) {
				for (m = 0; m <= s.nhd; m++) {
					nt = s.notes[m]
					if (nt.pit == p)
						return nt.acc
				}
			}
			s = s.next
		}
		return 1 //true
	} // ok()

	for (v = 0; v < nv; v++) {
		p_v = vo_tb[v]
		if (!p_v.tropt || !p_v.ckey.k_none || !p_v.tr_sco)
			continue
		for (s = p_v.sym; s; s = s.next) {
			if (s.type != C.NOTE)
				continue
			for (m = 0; m <= s.nhd; m++) {
				nt = s.notes[m]
				if (nt.tie_s) {		// if end of tie
					nt.pit = nt.tie_s.pit
					continue
				}
				p = nt.pit % 7		// A..G
				a = nt.acc
				na = 3
				switch (a) {
				case -1:
					switch (p) {
					case 2:		// C
					case 5:		// F
						break	
					default:
						continue
					}
					np = nt.pit - 1
					break
				case -2:
					switch (p) {
					case 2:		// C
					case 5:		// F
						na = -1
						break
					}
					np = nt.pit - 1
					break
				case 1:
					switch (p) {
					case 1:		// B
					case 4:		// E
						break	
					default:
						continue
					}
					np = nt.pit + 1
					break
				case 2:
					switch (p) {
					case 1:		// B
					case 4:		// E
						na = 1
						break	
					}
					np = nt.pit + 1
					break
				default:
					continue
				}
				if (ok(s, np)) {
					nt.pit = np
					nt.acc = na
					if (p_v.map)
						this.set_map(p_v, nt, na)
				}
			}
		}
	}
	of(last_s)
    }, // voice_adj()

    // set the tropt parameter
    do_pscom: function(of, text) {
	if (text.indexOf("tropt ") == 0)
		this.set_v_param("tropt", text.split(/[ \t]/)[1])
	else
		of(text)
    }, // do_pscom()

    // set the tropt parameter in the current voice
    set_vp: function(of, a) {
    var	i,
	curvoice = this.get_curvoice()

	for (i = 0; i < a.length; i++) {
		if (a[i] == "tropt=") {
			curvoice.tropt = this.get_bool(a[i + 1])
			break
		}
	}
	of(a)
    }, // set_vp()

    set_hooks: function(abc) {
	abc.do_pscom = abc2svg.tropt.do_pscom.bind(abc, abc.do_pscom)
	abc.voice_adj = abc2svg.tropt.voice_adj.bind(abc, abc.voice_adj)
	abc.set_vp = abc2svg.tropt.set_vp.bind(abc, abc.set_vp)
    }
} // tropt

if (!abc2svg.mhooks)
	abc2svg.mhooks = {}
abc2svg.mhooks.tropt = abc2svg.tropt.set_hooks
