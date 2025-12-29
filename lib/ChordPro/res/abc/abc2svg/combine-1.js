// combine.js - module to add a combine chord line
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
// This module is loaded when "%%voicecombine" appears in a ABC source.
//
// Parameters
//	%%voicecombine n	'n' is the combine level

if (typeof abc2svg == "undefined")
    var	abc2svg = {}

abc2svg.combine = {

    // function called at start of the generation when multi-voices
    comb_v: function() {
    var	C = abc2svg.C,
	abc = this

    // get the symbol of the note to combine
    function get_cmb(s) {
    var	p,
	s2 = s.ts_next,
	i = s.p_v.id.indexOf('.')		// '.' is the group separator

	if (i >= 0) {
		p = s.p_v.id.slice(0, i)	// group
		while (s2 && s2.time == s.time) {
			if (s2.p_v.id.indexOf(p) == 0)
				break
			s2 = s2.ts_next
		}
	}
	return s2
    } // get_cmb()

    // check if voice combine may occur
    function may_combine(s) {
    var	nhd2,
	s2 = get_cmb(s)

	if (!s2 || (s2.type != C.NOTE && s2.type != C.REST))
		return false
	if (s2.st != s.st
	 || s2.time != s.time
	 || s2.dur != s.dur)
		return false
	if (s.combine <= 0
	 && s2.type != s.type)
		return false
//	if (s2.a_dd) { //fixme: should check the double decorations
//		return false
//	}
	if (s.a_gch && s2.a_gch)
		return false
	if (s.type == C.REST) {
		if (s.type == s2.type) {
			if (s.invis && !s2.invis)
				return //false
		} else if (s.combine <= 2) {
			return //false
		}
		return true
	}
	if (s2.beam_st != s.beam_st
	 || s2.beam_end != s.beam_end)
		return false;
	nhd2 = s2.nhd
	if (s.combine <= 1
	 && s.notes[0].pit <= s2.notes[nhd2].pit + 1)
		return false
	return true
    } // may_combine()

    // combine two notes
    function combine_notes(s, s2) {
    var	nhd, type, m, not

	// put the notes of the 2nd voice into the 1st one
	for (m = 0; m <= s2.nhd; m++) {
		not = abc.clone(s2.notes[m])
		not.noplay = true	// and don't play it
		s.notes.push(not)
	}
	s.nhd = nhd = s.notes.length - 1;
	s.notes.sort(abc2svg.pitcmp)	// sort the notes by pitch

	if (s.combine >= 3) {		// remove unison heads
//fixme: KO for playback
		for (m = nhd; m > 0; m--) {
			if (s.notes[m].pit == s.notes[m - 1].pit
			 && s.notes[m].acc == s.notes[m - 1].acc)
				s.notes.splice(m, 1)
		}
		s.nhd = nhd = s.notes.length - 1
	}

	s.ymx = 3 * (s.notes[nhd].pit - 18) + 4;
	s.ymn = 3 * (s.notes[0].pit - 18) - 4;

	// force the tie directions
	type = s.notes[0].tie_ty
	if ((type & 0x07) == C.SL_AUTO)
		s.notes[0].tie_ty = C.SL_BELOW | (type & C.SL_DOTTED);
	type = s.notes[nhd].tie_ty
	if ((type & 0x07) == C.SL_AUTO)
		s.notes[nhd].tie_ty = C.SL_ABOVE | (type & C.SL_DOTTED)
} // combine_notes()

// combine 2 voices
// return the remaining one
function do_combine(s) {
	var s2, s3, type, i, n, sl

		s2 = get_cmb(s)

		// there may be more voices
		if (!s.in_tuplet
		 && s2.combine != undefined && s2.combine >= 0
		 && may_combine(s2))
			s2 = do_combine(s2)

		if (s.type != s2.type) {	// if note and rest
			if (s2.type != C.REST) {
				s2 = s;
				s = s2.ts_next
			}
		} else if (s.type == C.REST) {
			if (s.invis
			 && !s2.invis)
				delete s.invis
			s.multi = 0
		} else {
			combine_notes(s, s2)
			if (s2.ti1)
				s.ti1 = true
			if (s2.ti2)
				s.ti2 = true
		}

		// if some slurs start on the second symbol
		// move them to the combined symbol
		// also, set a flag in the symbols of the ending slurs
		if (s2.sls) {
			if (s.sls)
				Array.prototype.push.apply(s.sls, s2.sls)
			else
				s.sls = s2.sls
			for (i = 0; i < s2.sls.length; i++) {
				sl = s2.sls[i]
				if (sl.se)
					sl.se.slsr = s	// reverse pointer
				sl.ty = C.SL_BELOW
			}
			delete s2.sls
		}

		// if a combined slur is ending on the second symbol,
		// update its starting symbol
		s3 = s2.slsr			// pointer to the starting symbol
		if (s3) {
			for (i = 0; i < s3.sls.length; i++) {
				sl = s3.sls[i]
				if (sl.se == s2)
					sl.se = s
			}
		}

		if (s2.a_gch)
			s.a_gch = s2.a_gch
		if (s2.a_dd) {
			if (!s.a_dd)
				s.a_dd = s2.a_dd
			else
				Array.prototype.push.apply(s.a_dd, s2.a_dd)
		}

		s2.play = s2.invis = true	// don't display, but play
		return s
} // do_combine()

	// code of comb_v()
	var s, s2, g, i, r

	for (s = abc.get_tsfirst(); s; s = s.ts_next) {
		switch (s.type) {
		case C.REST:
			if (s.combine == undefined || s.combine < 0)
				continue
			if (may_combine(s))
				s = do_combine(s)
//			continue		// fall thru
		default:
			continue
		case C.NOTE:
			if (s.combine == undefined || s.combine <= 0)
				continue
			break
		}

		if (!s.beam_st)
			continue

		s2 = s
		while (1) {
			if (!may_combine(s2)) {
				s2 = null
				break
			}
//fixme: may have rests in beam
			if (s2.beam_end)
				break
			do {
				s2 = s2.next
			} while (s2.type != C.NOTE && s2.type != C.REST)
		}
		if (!s2)
			continue
		s2 = s
		while (1) {
			s2 = do_combine(s2)
//fixme: may have rests in beam
			if (s2.beam_end)
				break
			do {
				s2 = s2.next
			} while (s2.type != C.NOTE && s2.type != C.REST)
		}
	}
    }, // comb_v()

    do_pscom: function(of, text) {
	if (text.slice(0, 13) == "voicecombine ")
		this.set_v_param("combine", text.split(/[ \t]/)[1])
	else
		of(text)
    },

    new_note: function(of, gr, tp) {
    var curvoice = this.get_curvoice()
    var s = of(gr, tp)
	if (s && s.notes && curvoice.combine != undefined)
		s.combine = curvoice.combine
	return s
    },

    set_stem_dir: function(of) {
	of();
	abc2svg.combine.comb_v.call(this)
    },

    // set the combine parameter in the current voice
    set_vp: function(of, a) {
    var	i,
	curvoice = this.get_curvoice()

	for (i = 0; i < a.length; i++) {
		if (a[i] == "combine=") {	// %%voicecombine
			curvoice.combine = a[i + 1]
			break
		}
	}
	of(a)
    },

    set_hooks: function(abc) {
	abc.do_pscom = abc2svg.combine.do_pscom.bind(abc, abc.do_pscom);
	abc.new_note = abc2svg.combine.new_note.bind(abc, abc.new_note);
	abc.set_stem_dir = abc2svg.combine.set_stem_dir.bind(abc, abc.set_stem_dir);
	abc.set_vp = abc2svg.combine.set_vp.bind(abc, abc.set_vp)
    }
} // combine

if (!abc2svg.mhooks)
	abc2svg.mhooks = {}
abc2svg.mhooks.combine = abc2svg.combine.set_hooks
