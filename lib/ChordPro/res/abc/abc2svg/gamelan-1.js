// gamelan.js - module to output Gamelan (indonesian) music sheets
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
// This module is loaded when "%%gamelan" appears in a ABC source.
//
// Parameters (none)
//	%%gamelan 1
// scale:
// - sléndro - 5 equal tones
//	5-TET	C   D   E     G   A
//	detune	0 +40 +80 . +20 +60 .
// - pélog - 7 unequal tones
//		D _E+ F- ^G+ A _B c+ d
//		1  2  3   4  5  6 7  1
// (first note = ding)
//   Bali
//	selisir ^C D E ^G A	12356
//	tembung	E F A B c	45612
//	sunaren	F G B c d (?)	56723
//   Java
//	bem	D_E ^G A _B	12456
//	barang	_E F A _B c	23567
// numbers
//	??	E F G B c
//	??	C ^C _E G _A (or ^C D E ^G A)
// dot = continuation (not rest)

if (typeof abc2svg == "undefined")
    var	abc2svg = {}

abc2svg.gamelan = {

  cde2fcg: new Int8Array([0, 2, 4, -1, 1, 3, 5]),
  cgd2cde: new Int8Array([0, -4, -1, -5, -2, -6, -3,
			  0, -4, -1, -5, -2, -6, -3, 0]),
  acc2: new Int8Array([-2, -1, 3, 1, 2]),

// change %%staves and %%score
  do_pscom: function(of, p) {
	switch (p.match(/\w+/)[0]) {
	case 'staves':
	case 'score':
		p = p.replace(/\(|\)/g, '')
		break
	}
	of(p)
  },

// adjust some symbols before the generation
  output_music: function(of) {
    var	C = abc2svg.C,
	abc = this,
	cur_sy = abc.get_cur_sy(),
	voice_tb = abc.get_voice_tb()

	if (!abc.cfmt().gamelan) {
		of()
		return
	}

	// expand dots and long notes/rests
	function slice(s) {
	    var	m, n, s2, s3, d, d_orig

		if (s.dur <= C.BLEN * 3 / 8) {
			if ((s.dur_orig / 9 | 0) * 9 != s.dur_orig)
				return
			d = s.dur / 3
			d_orig = s.dur_orig / 3
			s.dur -= d
			s.dur_orig -= d_orig
			n = 1
		} else {
			if (s.dur >= C.BLEN)
				n = 3
			else if (s.dur == C.BLEN / 2)
				n = 1
			else
				n = 2
			d = d_orig = C.BLEN / 4
			s.dur = s.dur_orig = C.BLEN / 4
		}
		for (m = 0; m <= s.nhd; m++)
			s.notes[m].dur = s.dur
		s.beam_on = true
		while (--n >= 0) {
			s2 = {
				type: C.REST,
				v: s.v,
				p_v: s.p_v,
				st: s.st,
				fmt: s.fmt,
				dur: d,
				dur_orig: d_orig,
				stem: 1,
				multi: 0,
				nhd: 0,
				notes: [{
					pit: s.notes[0].pit,
					jn: 8
				}],
				xmx: 0,
				beam_on: true,
				noplay: true,
				time: s.time + s.dur,
				prev: s,
				next: s.next
			}
			s.next = s2
			if (s2.next)
				s2.next.prev = s2

			if (!s.ts_next) {
				s.ts_next = s2
				if (s.soln)
					s.soln = false
				s2.ts_prev = s
				s2.seqst = true
			} else {
			    for (s3 = s.ts_next; s3; s3 = s3.ts_next) {
				if (s3.time < s2.time)
					continue
				if (s3.time > s2.time) {
					s2.seqst = true
					s3 = s3.ts_prev
				}
				s2.ts_next = s3.ts_next
				s2.ts_prev = s3
				if (s2.ts_next)
					s2.ts_next.ts_prev = s2
				s3.ts_next = s2
				break
			    }
			}
			s = s2
		}
	} // slice()

	// replace the tied notes by a '.'
	function do_tie(s) {
	    var	end_time = s.time + s.dur
		while (1) {
			s = s.ts_next
			if (!s || s.time > end_time)
				return	// ?!
			if (s.type == C.NOTE
			 && s.time == end_time)
				break
		}
		s.notes[0].jn = 8
		s.notes[0].jo = 2
	} // do_tie()

	function set_sym(p_v) {
	    var s, s2, note, pit, nn, p, a, m, i,
		sf = p_v.key.k_sf,
		delta = abc2svg.gamelan.cgd2cde[sf + 7] - 2

		delete p_v.key.k_a_acc		// no accidental

		// no (visible) clef
		p_v.clef.invis = true

		// scan the voice
		for (s = p_v.sym; s; s = s.next) {
			s.st = p_v.st
			switch (s.type) {
			case C.CLEF:
				s.invis = true
//				continue
			default:
				continue
			case C.KEY:
				delta = abc2svg.gamelan.cgd2cde[s.k_sf + 7] - 2
				continue
			case C.REST:
				if (s.notes[0].jn)
					continue
				s.notes[0].jn = 0
				s.notes[0].pit = 21
				slice(s)
				continue
			case C.NOTE:			// change the notes
				break
			}

			s.stem = 1
			s.stemless = true

			// set the slurs offset and direction
			if (s.sls) {
				for (i = 0; i < s.sls.length; i++)
					s.sls[i].ty = C.SL_BELOW
			}

			for (m = 0; m <= s.nhd; m++) {
				note = s.notes[m]

				// note head
				p = note.pit
				pit = p + delta
				if (note.jn == undefined) {	// if not tied
					note.jn = ((pit + 77) % 7) + 1	// note number
					note.jo = (pit / 7) | 0	// octave number
				}

				// set a fixed offset to the note
				// for the slurs and decorations
				note.pit = 21			// "A"

				// accidentals
				a = note.acc
				if (a) {
					nn = abc2svg.gamelan.cde2fcg[(p + 5 + 16 * 7) % 7] - sf
					if (a != 3)
						nn += a * 7
					nn = ((((nn + 1 + 21) / 7) | 0) + 2 - 3 + 32 * 5) % 5
					note.acc = abc2svg.gamelan.acc2[nn]
				}

				if (note.tie_ty) {
					do_tie(s)
					delete note.tie_ty
				}
			}

			// change the dots and the long notes
			slice(s)

			// replace the staccato dot
			if (s.a_dd) {
				for (i = 0; i < s.a_dd.length; i++) {
					if (s.a_dd[i].glyph == "stc") {
						abc.deco_put("gstc", s)
						s.a_dd[i] = s.a_dd.pop()
					}
				}
			}
		}
	} // set_sym()

	// -- output_music --

	for (v = 0; v < voice_tb.length; v++)
		set_sym(voice_tb[v])

	of()
  }, // output_music()

  draw_symbols: function(of, p_voice) {
    var	i, m, nl, note, s, s2, x, y,
	C = abc2svg.C,
	abc = this,
	dot = "\ue1e7",
	staff_tb = abc.get_staff_tb(),
	out_svg = abc.out_svg,
	out_sxsy = abc.out_sxsy,
	xypath = abc.xypath

	if (!abc.cfmt().gamelan) {
		of(p_voice)
		return
	}

	// draw the duration lines above the notes
	function draw_dur(s1, y, s2, n, nl) {
	    var s, s3

		xypath(s1.x - 3, y + 24)
		out_svg('h' + (s2.x - s1.x + 8).toFixed(1) + '"/>\n')	// "
		y -= 2.5
		while (++n <= nl) {
			s = s1
			while (1) {
				if (s.nflags && s.nflags >= n) {
					s3 = s
					while (s != s2) {
						if (s.next.beam_br1
						 || (s.next.beam_br2 && n > 2)
						 || (s.next.nflags
						  && s.next.nflags < n))
							break
						s = s.next
					}
					draw_dur(s3, y, s, n, nl)
				}
				if (s == s2)
					break
				s = s.next
			}
		}
	} // draw_dur()

	function out_mus(x, y, p) {
		out_svg('<text x="')
		out_sxsy(x, '" y="', y)
		out_svg('">' + p + '</text>\n')
	} // out_txt()

	function out_txt(x, y, p) {
		out_svg('<text class="bn" x="')
		out_sxsy(x, '" y="', y)
		out_svg('">' + p + '</text>\n')
	} // out_txt()

	function draw_hd(s, x, y) {
	    var	m, note, ym

		for (m = 0; m <= s.nhd; m++) {
			note = s.notes[m]
			out_txt(x - 3.5, y + 8, "01234567."[note.jn])
			if (note.acc) {
				out_svg('<path class="stroke" stroke-width="1.1" d="M')
				if (note.acc > 0) {
					out_sxsy(x - 6, ' ', y + 10)
					out_svg("l12 -6")
				} else {
					out_sxsy(x - 6, ' ', y + 16)
					out_svg("l12 6")
				}
				out_svg('"/>\n')
			}
			if (note.jo > 2) {
				out_mus(x - 1, y + 23, dot)
				if (note.jo > 3) {
					y += 3
					out_mus(x - 1, y + 23.4, dot)
				}
			} else if (note.jo < 2) {
				ym = y + 4
				out_mus(x - 1, ym, dot)
			}
			y += 20
		}
	} // draw_hd()

	// -- draw_symbols --

	for (s = p_voice.sym; s; s = s.next) {
		if (s.invis)
			continue
		switch (s.type) {
		case C.NOTE:
		case C.REST:
			x = s.x
			y = staff_tb[s.st].y
			draw_hd(s, x, y)
			break
		}
	}

	// draw the (pseudo) beams
	for (s = p_voice.sym; s; s = s.next) {
		if (s.invis)
			continue
		switch (s.type) {
		case C.NOTE:
		case C.REST:
			nl = s.nflags
			if (nl <= 0)
				continue
			y = staff_tb[s.st].y
			s2 = s
			while (s.next && s.next.nflags > 0) {
				s = s.next
				if (s.nflags > nl)
					nl = s.nflags
				if (s.beam_end)
					break
			}
			draw_dur(s2, y + 7, s, 1, nl)
			break
		}
	}
  }, // draw_symbols()

// set some parameters
    set_fmt: function(of, cmd, param) {
	if (cmd == "gamelan") {
	    var	cfmt = this.cfmt()

		if (!this.get_bool(param))
			return
		cfmt.gamelan = true
		cfmt.staffsep = 20
		cfmt.sysstaffsep = 14
		this.set_v_param("stafflines", "...")
		cfmt.tuplets = [0, 1, 0, 1]	// [auto, slur, number, above]
		return
	}
	of(cmd, param)
    }, // set_fmt()

// adjust some values
    set_pitch: function(of, last_s) {
	of(last_s)
	if (!last_s
	 || !this.cfmt().gamelan)
		return			// first time

    var	C = abc2svg.C
	
	for (var s = this.get_tsfirst(); s; s = s.ts_next) {
		switch (s.type) {

		// adjust the vertical spacing above the note heads
		case C.NOTE:
			s.ymx = 20 * s.nhd + (s.nflags > 0 ? 30 : 24)
			if (s.notes[s.nhd].jo > 2) {
				s.ymx += 3
				if (s.notes[s.nhd].jo > 3)
					s.ymx += 2
			}
			s.ys = s.ymx		// (for tuplets)
			break
		}
	}
    }, // set_pitch()

// set the width of some symbols
    set_width: function(of, s) {
	of(s)
	if (!this.cfmt().gamelan)
		return

    var	w, m, note,
	C = abc2svg.C

	switch (s.type) {
	case C.CLEF:
	case C.KEY:
	case C.METER:
		s.wl = s.wr = .1		// (must not be null)
		break
	}
    }, // set_width()

    set_hooks: function(abc) {
	abc.do_pscom = abc2svg.gamelan.do_pscom.bind(abc, abc.do_pscom)
	abc.draw_symbols = abc2svg.gamelan.draw_symbols.bind(abc, abc.draw_symbols)
	abc.output_music = abc2svg.gamelan.output_music.bind(abc, abc.output_music)
	abc.set_format = abc2svg.gamelan.set_fmt.bind(abc, abc.set_format)
	abc.set_pitch = abc2svg.gamelan.set_pitch.bind(abc, abc.set_pitch)
	abc.set_width = abc2svg.gamelan.set_width.bind(abc, abc.set_width)

	// big staccato dot
	abc.get_glyphs().gstc = '<circle id="gstc" cx="0" cy="-3" r="2"/>'
	abc.get_decos().gstc = "0 gstc 5 1 1"

	abc.add_style("\n.bn {font-family:sans-serif; font-size:16px}")
    } // set_hooks()
} // gamelan

if (!abc2svg.mhooks)
	abc2svg.mhooks = {}
abc2svg.mhooks.gamelan = abc2svg.gamelan.set_hooks
