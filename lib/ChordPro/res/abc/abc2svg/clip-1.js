// clip.js - module to handle the %%clip command
//
// Copyright (C) 2018-2024 Jean-Francois Moine
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
// This module is loaded when "%%clip" appears in a ABC source.
//
// Parameters
//	%%clip start_measure_nb [":" num "/" den] "-" end_measure_nb [":" num "/" den]

if (typeof abc2svg == "undefined")
    var	abc2svg = {}

abc2svg.clip = {

    get_clip: function(parm) {
    var	C = abc2svg.C

	// get the start/stop points
	function get_symsel(a) {
	    var	j, d, sq,
		b = a.match(/(\d+)([a-z]?)(:\d+\/\d+)?/)

		if (!b)
			return
		if (b[2])
			sq = b[2].charCodeAt(0) - 0x61
		if (!b[3])
			return {m: b[1], t: 0, sq: sq}	// on measure bar
		a = b[3].match(/:(\d+)\/(\d+)/)
		if (!a || a[2] < 1)
			return
		return {m: b[1], t: a[1] * C.BLEN / a[2], sq: sq}
	} // get_symsel()

	    var	b, c,
		a = parm.split(/[ -]/)

		if (a.length != 3) {
			this.syntax(1, this.errs.bad_val, "%%clip")
			return
		}
		if (!a[1])
			b = {m: 0, t: 0}
		else
			b = get_symsel(a[1]);
		c = get_symsel(a[2])
		if (!b || !c) {
			this.syntax(1, this.errs.bad_val, "%%clip")
			return
		}
		this.cfmt().clip = [b, c]
    }, // get_clip()

    // cut the tune
    do_clip: function() {
    var	C = abc2svg.C,
	abc = this,
	voice_tb = this.get_voice_tb(),
	cfmt = this.cfmt()

	// check the pointers (ties and slurs)
	function chkptr(last) {
	    var	i, sl, s2, m, nt,
		tim = last.time,
		s = abc.get_tsfirst()

		do {
			if (s.sls) {
				for (i = 0; i < s.sls.length; i++) {
					sl = s.sls[i]
					s2 = sl.se		// slur end
					if (s2.time >= tim)
						sl.loc = 'o'	// no end
				}
			}
			if (s.ti1			// if tie
			 && s.time + s.dur >= tim) {	// ending out of the clip seq.
				for (m = 0; m <= s.nhd; m++) {
					nt = s.notes[m]
					if (nt.tie_e && nt.tie_e.s.time >= tim)
						delete nt.tie_e	// no end
				}
			}
			s = s.ts_next
		} while (s)
	} // chkptr()

	// go to a global (measure + time)
	function go_global_time(s, sel) {
	    var	s2, bar_time, seq

		if (sel.m <= 1) {	// special case: there is no measure 0/1
			if (sel.m == 1) {
				for (s2 = s; s2; s2 = s2.ts_next) {
					if (s2.type == C.BAR
					 && s2.time != 0)
						break
				}
				if (s2.time < voice_tb[abc.get_cur_sy().top_voice].
								meter.wmeasure)
					s = s2
			}
		} else {
			for ( ; s; s = s.ts_next) {
				if (s.type == C.BAR
				 && s.bar_num >= sel.m)
					break
			}
			if (!s)
				return // null

			if (sel.sq) {
				seq = sel.sq
				for (s = s.ts_next; s; s = s.ts_next) {
					if (s.type == C.BAR
					 && s.bar_num == sel.m) {
						if (--seq == 0)
							break
					}
				}
				if (!s)
					return // null
			}
		}

		if (sel.t == 0)
			return s;
		bar_time = s.time + sel.t
		while (s.time < bar_time) {
			s = s.ts_next
			if (!s)
				return s
		}
		do {
			s = s.ts_prev	// go back to the previous sequence
		} while (!s.seqst)
		return s
	}

	    var	s, s2, sy, p_voice, v

		// remove the beginning of the tune
		s = this.get_tsfirst()
		if (cfmt.clip[0].m > 0
		 || cfmt.clip[0].t > 0) {
			s = go_global_time(s, cfmt.clip[0])
			if (!s) {
				this.set_tsfirst(null)
				return
			}

			// update the start of voices
			sy = this.get_cur_sy()
			for (s2 = this.get_tsfirst(); s2 != s; s2 = s2.ts_next) {
				switch (s2.type) {
				case C.CLEF:
					s2.p_v.clef = s2
					break
				case C.KEY:
					s2.p_v.key = this.clone(s2.as.u.key)
					s2.p_v.ckey = this.clone(s2.as.u.ckey)
					break
				case C.METER:
					s2.p_v.meter = this.clone(s2.as.u.meter)
					break
				case C.STAVES:
					sy = s2.sy;
					this.set_cur_sy(sy)
					break
				}
			}
			for (v = 0; v < voice_tb.length; v++) {
				p_voice = voice_tb[v]
				for (s2 = s; s2; s2 = s2.ts_next) {
					if (s2.v == v) {
						delete s2.prev
						break
					}
				}
				p_voice.sym = s2
			}
			s2 = this.get_tsfirst()
			if (s != s2) {
				if (s2.type == C.STAVES) {
					s2.ts_next = s
					s.ts_prev = s2
					s2.next = s2.p_v.sym
					s2.p_v.sym = s2
					s2.next.prev = s2
				} else {
					this.set_tsfirst(s)
					delete s.ts_prev
				}
			}
		}

		/* remove the end of the tune */
		s = go_global_time(s, cfmt.clip[1])
		if (!s)
			return

		/* keep the current sequence */
		do {
			s = s.ts_next
			if (!s)
				return
		} while (!s.seqst)

		/* cut the voices */
		for (v = 0; v < voice_tb.length; v++) {
			p_voice = voice_tb[v]
			for (s2 = s.ts_prev; s2; s2 = s2.ts_prev) {
				if (s2.v == v) {
					delete s2.next
					break
				}
			}
			if (!s2)
				p_voice.sym = null
		}
		delete s.ts_prev.ts_next

		chkptr(s.ts_prev)	// check the pointers (ties and slurs)
	}, // do_clip()

    do_pscom: function (of, text) {
	if (text.slice(0, 5) == "clip ")
		abc2svg.clip.get_clip.call(this, text)
	else
		of(text)
    },

    set_bar_num: function(of) {
	of()
	if (this.cfmt().clip)
		abc2svg.clip.do_clip.call(this)
    },

    set_hooks: function(abc) {
	abc.do_pscom = abc2svg.clip.do_pscom.bind(abc, abc.do_pscom);
	abc.set_bar_num = abc2svg.clip.set_bar_num.bind(abc, abc.set_bar_num)
    }
} // clip

if (!abc2svg.mhooks)
	abc2svg.mhooks = {}
abc2svg.mhooks.clip = abc2svg.clip.set_hooks
