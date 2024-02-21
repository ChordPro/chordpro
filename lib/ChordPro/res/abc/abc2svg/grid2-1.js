// grid2.js - module to replace a voice in the music by a chord grid
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
// This module is loaded when "%%grid2" appears in a ABC source.
//
// Parameters
//	%%grid2 y
// This command may appear globally or in a voice.

if (typeof abc2svg == "undefined")
    var	abc2svg = {}

abc2svg.grid2 = {

// function called before tune generation
    do_grid: function() {
    var s, v, p_v, ix, cs, c_a_cs, bt, gch,
	voice_tb = this.get_voice_tb()

	if (this.cfmt().grid2)
		for (v = 0; v < voice_tb.length; v++)
			if (voice_tb[v].grid2 == undefined)
				voice_tb[v].grid2 = 1

	for (v = 0; v < voice_tb.length; v++) {
		p_v = voice_tb[v]
		if (!p_v.grid2)
			continue
		curvoice = p_v
		this.set_v_param("stafflines", "...")	// no staff
		p_v.clef.invis = true;		// no clef
		p_v.key.k_sf = 0		// no key signature
		delete p_v.key.k_a_acc
		p_v.staffnonote = 2		// draw the staff
		for (s = p_v.sym; s; s = s.next) {
			delete s.a_dd		// no decoration
			if (!s.dur) {
				if (s.bar_type)
					bt = s.time
				continue
			}

			// set all notes
				s.invis = true;	//  as invisible
				delete s.sl1;	//  with no slur
				delete s.ti1	//  and no tie
				delete s.ti2
				for (ix = 0; ix <= s.nhd; ix++)
					delete s.notes[ix].tie_ty
				if (s.tf)	// don't show the tuplets
					s.tf[0] = 1
				if (!s.a_gch) {
					if (s.time == bt)
						s.a_gch = [ this.clone(c_a_cs) ]
					continue
				}
				for (ix = 0; ix < s.a_gch.length; ix++) {
					gch = s.a_gch[ix]
					if (gch.type == 'g') {
						c_a_cs = gch
						break
					}
				}
		}
	}
    }, // do_grid()

    // draw the chord symbol in the middle of the staff
    draw_gchord: function(of, i, s, x, y) {
    var	an
	if (s.p_v.grid2) {
		this.set_dscale(s.st)
		an = s.a_gch[i]
		if (an.type == 'g') {
			this.use_font(an.font)
			this.set_font(an.font)
			this.xy_str(s.x + an.x, 12 - an.font.size * .5,
					an.text)
		}
	} else {
		of(i, s, x, y)
	}
    },

    output_music: function(of) {
	abc2svg.grid2.do_grid.call(this);
	of()
    },

    set_fmt: function(of, cmd, param) {
	if (cmd == "grid2") {
	    var	curvoice = this.get_curvoice(),
		v = this.get_bool(param)

		if (curvoice)
			curvoice.grid2 = v
		else
			this.cfmt().grid2 = v
		return
	}
	of(cmd, param)
    },

    set_hooks: function(abc) {
	abc.draw_gchord = abc2svg.grid2.draw_gchord.bind(abc, abc.draw_gchord);
	abc.output_music = abc2svg.grid2.output_music.bind(abc, abc.output_music);
	abc.set_format = abc2svg.grid2.set_fmt.bind(abc, abc.set_format)
    }
} // grid2

if (!abc2svg.mhooks)
	abc2svg.mhooks = {}
abc2svg.mhooks.grid2 = abc2svg.grid2.set_hooks
