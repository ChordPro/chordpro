// sth.js - module to set the stem heights
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
// This module is loaded when "%%sth" appears in a ABC source.
//
// Parameters
//	%%sth h1 h2 h3 ...
// The values h1, h2, .. are applied to the following notes which
// have a stem and which are not inside a beam.
// The value may be '*' for keeping the original stem length.

if (typeof abc2svg == "undefined")
    var	abc2svg = {}

abc2svg.sth = {

// function called after beam calculation
    recal_beam: function(bm, s) {
    var staff_tb = this.get_staff_tb(),
	y = staff_tb[s.st].y,
	s2 = bm.s2,
	y2 = staff_tb[s2.st].y

	if (s.sth != undefined)
		s.ys = s.sth
	if (s2.sth != undefined)
		s2.ys = s2.sth;
	bm.a = (s.ys + y - s2.ys - y2) / (s.xs - s2.xs);
	bm.b = s.ys - s.xs * bm.a + y
	while (1) {
		s.ys = bm.a * s.xs + bm.b - y
		if (s.stem > 0)
			s.ymx = s.ys + 2.5
		else
			s.ymn = s.ys - 2.5;
		s = s.next
		if (s == s2)
			break
	}
    },

// function called after the stem heights have been computed
    set_sth: function() {
    var s, h, v, sth_a, p_voice,
	voice_tb = this.get_voice_tb()

	for (v = 0; v < voice_tb.length; v++) {
		p_voice = voice_tb[v]
		if (p_voice.sth != null)	// if no stem length in this voice
			continue
		sth_a = []
		for (s = p_voice.sym; s; s = s.next) {
			if (s.sth) {
				sth_a = s.sth;
				s.sth = null
			}
			if (sth_a.length == 0
			 || s.nflags <= -2 || s.stemless
			 || !(s.beam_st || s.beam_end))
				continue
			h = sth_a.shift()
			if (h == '*')
				continue	// no change
			if (h == '|') {		// skip to the next measure bar
				for (s = s.next; s; s = s.next) {
					if (s.bar_type)
						break
				}
				continue
			}
			h = Number(h)
			if (isNaN(h) || !h)
				continue	// fixme: error
			if (s.stem >= 0) {
				s.ys = s.y + h;
				s.ymx = (s.ys + 2.5) | 0
			} else {
				s.ys = s.y - h;
				s.ymn = (s.ys - 2.5) | 0
			}
			s.sth = s.ys
		}
	}
    }, // set_sth()

    calculate_beam: function(of, bm, s1) {
    var	done = of(bm, s1)
	if (done && bm.s2 && (s1.sth || bm.s2.sth))
		abc2svg.sth.recal_beam.call(this, bm, s1)
	return done
    },

    new_note: function(of, grace, tp_fact) {
    var	C = abc2svg.C,
	s = of(grace, tp_fact),
	curvoice = this.get_curvoice()

	if (curvoice.sth && s && s.type == C.NOTE) {
		s.sth = curvoice.sth;
		curvoice.sth = null	// some stem widths in this voice
	}
	return s
    },

    set_fmt: function(of, cmd, param) {
	if (cmd == "sth") {
	    var	curvoice = this.get_curvoice()
		if (curvoice)
			curvoice.sth = param.split(/[ \t;-]+/)
		return
	}
	of(cmd, param)
    },

    set_stems: function(of) {
	of();
	abc2svg.sth.set_sth.call(this)
    },

    set_hooks: function(abc) {
	abc.calculate_beam = abc2svg.sth.calculate_beam.bind(abc, abc.calculate_beam);
	abc.new_note = abc2svg.sth.new_note.bind(abc, abc.new_note);
	abc.set_format = abc2svg.sth.set_fmt.bind(abc, abc.set_format);
	abc.set_stems = abc2svg.sth.set_stems.bind(abc, abc.set_stems)
    }
} // sth

if (!abc2svg.mhooks)
	abc2svg.mhooks = {}
abc2svg.mhooks.sth = abc2svg.sth.set_hooks
