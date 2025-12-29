// soloffs.js - module to set the X offset of some elements at start of music line
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
// Parameters
//	%%soloffs <type>=<offset> [<type>=<offset>]*
//		<type> is one of 'part', 'tempo' or 'space'
//		<offset> is the X offset from the start of staff

if (typeof abc2svg == "undefined")
    var	abc2svg = {}

abc2svg.soloffs = {

    set_fmt: function(of, cmd, parm) {
	if (cmd == "soloffs") {
	    var	i, v,
		C = abc2svg.C,
		soloffs = this.cfmt().soloffs = {}

		parm = parm.split(/\s+/)
		while (parm.length) {
			i = parm.shift().split('=')
			v = Number(i[1])
			if (isNaN(v))
				continue		// error
			switch (i[0]) {
//			case 'bar':
//				soloffs[C.BAR] = v
//				break
			case 'part':
				soloffs[C.PART] = v		// see deco.js
				break
			case 'tempo':
				soloffs[C.TEMPO] = v + 16	// see deco.js
				break
			case 'space':
				soloffs[C.SPACE] = v
				break
//			default:
//				// error
//				break
			}
		}
		return
	}
	of(cmd, parm)
    },

    set_sym_glue: function(of, width) {
    var	s,
	tsfirst = this.get_tsfirst(),
	soloffs = this.cfmt().soloffs;

	of(width)		// compute the x offset of the symbols
	if (!soloffs)
		return
	for (s = tsfirst; s; s = s.ts_next) {
		if (s.time != tsfirst.time)
			break
		if (soloffs[s.type] != undefined)
			s.x = soloffs[s.type]
		if (s.part && soloffs[abc2svg.C.PART] != undefined)
			s.part.x = soloffs[abc2svg.C.PART]
	}
    }, // set_sym_glue()

    set_hooks: function(abc) {
	abc.set_sym_glue = abc2svg.soloffs.set_sym_glue.bind(abc, abc.set_sym_glue);
	abc.set_format = abc2svg.soloffs.set_fmt.bind(abc, abc.set_format)
    }
} // soloffs

if (!abc2svg.mhooks)
	abc2svg.mhooks = {}
abc2svg.mhooks.soloffs = abc2svg.soloffs.set_hooks
