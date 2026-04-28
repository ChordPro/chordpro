// swing.js - module to set a swing feel
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
// This module is loaded when "%%playswing" appears in a ABC source.
//
// Parameters
//	%%playswing duration_1 restart_time duration_2
// with the durations and time in percent of the duration of the two notes.
//
// This command may appear globally or in a voice.

"use strict"
if (typeof abc2svg == "undefined")
    var	abc2svg = {}

abc2svg.swing = {
// this function is called from sndgen
    swing: function(first, voice_tb, cfmt) {
    var	v, p_v, sw, s, s2, d, m, beat, anac,
	C = abc2svg.C,
	a_dur = [],
	nv = voice_tb.length

	// set the times of the notes subject to swing adjustment
	function set_dur(s) {
		if (!s.a_meter[0] || s.a_meter[0].top[0] == 'C'
		 || !s.a_meter[0].bot)
			beat = C.BLEN / 4		// quarter note
		else if (s.a_meter[0].bot[0] == 8
		      && s.a_meter[0].top[0] % 3 == 0)
			return 1			// no swing
		else
			beat = C.BLEN / s.a_meter[0].bot[0] |0
		a_dur[0] = beat / 2			// x/n/
		a_dur[1] = beat / 4			// x3//n//

		// check if there is an anacrusis
		if (!s.time) {
			anac = 0
		    var	wm = s.wmeasure
			while (s && s.time < wm) {
				if (s.bar_type) {
					anac = wm - s.time
					break
				}
				s = s.next
			} 
		}
	} // set_dur()

	for (v = 0; v < nv; v++) {
		p_v = voice_tb[v]
		sw = cfmt.swing || p_v.swing
		if (!sw || !p_v.sym)
			continue
		if (set_dur(p_v.meter))
			continue			// no swing
		for (s = p_v.sym; s.next; s = s.next) {
			if (s.subtype == "swing")
				sw = s.sw
			if (!sw
			 || !s.dur) {
				if (s.a_meter)
					set_dur(s)
				continue
			}
			if ((s.time + anac - a_dur[0]) % beat
			 && (s.time + anac - a_dur[1]) % beat) {
				s2 = s
				continue
			}
			if (s2 && s2.time + s2.dur == s.time) {
				d = s2.dur - (s2.time + s2.dur) % beat + sw[0] * beat
				s2.dur = d
				for (m = 0; m < s.nhd; m++)
					s2.notes[m].dur = d
			}
			d = s.time + s.dur
			s.time = ((s.time / beat | 0) + sw[0] + sw[1]) * beat
			if (s.dur > beat / 2 || s.ti1)
				d -= s.time
			else
				d = sw[2] * beat
			s.dur = d
			for (m = 0; m < s.nhd; m++)
				s.notes[m].dur = d
			s2 = s
		}
	}
    }, // swing()

    set_fmt: function(of, cmd, parm) {
    var	parse, sw, curvoice, i, s

	if (cmd == "playswing") {
		parse = this.get_parse(),
		curvoice = this.get_curvoice()
		sw = /(\d+)\s+(\d+)\s+(\d+)/.exec(parm)

		if (sw) {
			sw = sw.splice(1)
			if (+sw[0] + +sw[1] + +sw[2] > 100)
				return abc.syntax(1, "playswing greater than 100%")
			for (i = 0; i < 3; i++)
				sw[i] = +sw[i] / 100
		}
		if (parse.state >= 2) {
			s = this.new_block("swing")
			s.play = s.invis = 1 //true
			s.sw = sw
			if (sw)
				curvoice.swing = 1 //true
		} else {
			this.cfmt().swing = sw
		}
		return
	}
	of(cmd, parm)
    }, // set_fmt()

    set_hooks: function(abc) {
	abc.set_format = abc2svg.swing.set_fmt.bind(abc, abc.set_format)
    }
} // swing

if (!abc2svg.mhooks)
	abc2svg.mhooks = {}
abc2svg.mhooks.swing = abc2svg.swing.set_hooks
