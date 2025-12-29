// abc2svg - nns.js - module to output chords in the NNS
//			(Nashville Notation System)
//
// Copyright (C) 2021-2023 Jean-Francois Moine
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
// This module is loaded when "%%nns" appears in a ABC source.
//
// Parameters
//	%%nns [n] [include=<list>] [nomusic] [repbrk] [roman= 1 | 2]
//		<n> = number of chords per line (1: auto)
//			> 0: above the tune, < 0: under the tune
//		<list> = comma separated list of (continuous) measure numbers
//		'nomusic' displays only the chord
//		'repbrk' starts a new grid line on start/stop repeat
//		'roman' display the chord in the Roman Numeral Notation
//			=1: uppercase letters with 'm' for minor chords (default)
//			=2: lowercase letters for minor chords
//	%%nnsfont font_name size (default: 'monospace 16')

if (typeof abc2svg == "undefined")
    var	abc2svg = {}

abc2svg.nns = {
    note_nm: "CDEFGAB",

	// Nashville
    nns_nm: ["1", "♯1", "2", "♭3", "3", "4", "♯4",
		"5", "♯5", "6", "♭7", "7"],
	// Roman
    rnn_nm: ["I", "♯I", "II", "♭III", "III", "IV", "♯IV",
		"V", "♯V", "VI", "♭VII", "VII"],
    rnn_nm_m: ["III", "♯III", "IV", "♭V", "V", "VI", "♯VI",
		"VII", "♯VII", "I", "♭II", "II", "III"],
	// Roman 2
    rnn2_nm: ["I", "♯I", "ii", "♭III", "iii", "IV", "♯IV",
		"V", "♯V", "vi", "♭VII", "vii"],
    rnn2_nm_m: ["III", "♯III", "iv", "♭V", "v", "VI", "♯VI",
		"VII", "♯VII", "i", "♭II", "ii", "III"],
// inversions: 1st: (upper)6, 2nd: (upper)6 (lower) 4 

// generate the grid
    block_gen: function(of, s) {
	if (s.subtype != "nns") {
		of(s)
		return
	}

    var	abc = this,
	img,
	cfmt = abc.cfmt(),
	nns = cfmt.nns

// generate the chord list
function build_nns(s, font) {
    var	i, k, l, nr, bar, w, hr, x, y, row,
	chords = s.chords,
	bars = s.bars,
	parts = s.parts || [],
	cells = [],
	nc = nns.n

	// set the chord(s) in each measure
	function set_chords() {
	    var	i, ch,
		pch = '-'

		for (i = 0; i < chords.length; i++) {
			ch = chords[i]
			if (!ch[0])
				ch[0] = pch
			switch (ch.length) {
			case 0:
				continue
			case 1:
				pch = ch[0]
				continue
			case 2:
				pch = ch[1]
				continue
			case 3:
				pch = ch[2]
				continue
			}
			pch = ch[3]
		}
	} // set_chords()

	// get the original length of chord symbol
	function get_l(p) {
	    var	i,
		l = 0

		for (i = 0; i < p.length; i++) {
			if (p[i] == '<') {
				while (p[i] != '>')
					i++
				continue
			}
			l++
		}
		return l
	} // get_l()

	function build_cell(c) {
	    var	i, j, k,
		u = '',
		t = ''

		row += '   '
		if (c.length == 1) {
			row += c[0]	// one chord in the measure
			return
		}
		i = 0
		while (i < 4) {
			t += c[i]
			k = get_l(c[i])
			j = k
			while (--j >= 0)
				u += ' '
			if (i < 3 && !c[i + 1]) {
				while (i < 3 && !c[i + 1])
					i++
				i++
				if (i < 4 && c[i])
					t += ' '
			} else {
				j = k
				t += '<tspan dx="-'
					+ (j * .6).toFixed(1)
					+ 'em" dy=".2em">'
				while (--j >= 0)
					t += '_'
				t += '</tspan>'
				i++
				if (i < 4 && c[i])
					t += '<tspan dy="-.2em"> </tspan>'
				else
					t += '<tspan dx="-.6em" dy="-.2em"> </tspan>'
			}
		}
		row += t + '<tspan dx="-'
			+ (.6 * u.length).toFixed(1)
			+ 'em" text-decoration="underline">'
			+ u
			+ '</tspan>'
	} // build_cell()

	// ------- build_nns() -------

	// set some chords in each measure
	set_chords()

	// build the content of the measures
	if (!nns.ls) {
		cells = chords
	} else {				// with list of mesure numbers
		bar = bars
		bars = [ ]
		for (i = 0; i < nns.ls.length; i++) {
			l = nns.ls[i]
			if (l.indexOf('-') < 0)
				l = [l, l]
			else
				l = l.split('-')
			for (k = l[0] - 1; k < l[1]; k++) {
				if (!chords[k])		// error
					break
				cells.push(chords[k])
				bars.push(bar[k])
			}
		}
		bars.push(bar[k])		// ending bar
	}

	// get the number of columns
	if (nc < 0)
		nc = -nc
	if (nc < 3) {				// auto
		nc = cells.length % 6 == 0 ? 6 : 8
		if (nc == 8 && cells.length < 12)
			nc = 4
	}
	if (nc > cells.length)
		nc = cells.length

	// generate the rows
	abc.set_font('nns')
	x = img.lm + 30
	y = -1 + font.size * .6
	nr = 0
	hr = font.size * 2
	for (i = 0; i < cells.length; i++) {
		if (i == 0
		 || (nns.repbrk
		  && (bars[i].slice(-1) == ':' || bars[i][0] == ':'))
		 || parts[i]
		 || k >= nc) {
			if (row) {
				abc.out_svg('<text class="'
					+ abc.font_class(font)
					+ '" x="')
				abc.out_sxsy(x, '" y="', y)
				abc.out_svg('">' + row + '</text>\n')
			}
			row = ''
			y -= hr			// new row
			k = 0
			nr++
			if (parts[i]) {
				w = font.size * parts[i].length * .6 + 10
				if (w < 50)
					w = 50
				abc.out_svg('<text class="'
					+ abc.font_class(font)
					+ ' box'
					+ '" x="')
				abc.out_sxsy(x - w, '" y="', y)
				abc.out_svg('">' + parts[i] + '</text>\n')
			}
		}
		k++
		if (bars[i].slice(-1) == ':')
			row += ' |:'
		build_cell(cells[i])
		if (bars[i + 1][0] == ':')
			row += ' :|'
	}
	if (row) {
		abc.out_svg('<text class="'
			+ abc.font_class(font)
			+ '" x="')
		abc.out_sxsy(x, '" y="', y)
		abc.out_svg('">' + row + '</text>\n')
	}

	abc.vskip(hr * nr + 6)
} // build_nns()

	// ----- block_gen() -----
    var	p_voice, n, font, f2

	abc.set_page()
	img = abc.get_img()

	// set the text style
	if (!cfmt.nnsfont)
		abc.param_set_font("nnsfont", "monospace 16")
	font = abc.get_font('nns')

	// create the chord list
	abc.blk_flush()
	build_nns(s, font)
	abc.blk_flush()
    }, // block_gen()

    // hook before the generation
    set_stems: function(of) {
    var	C, tsfirst, voice_tb, fmt, p_v, s, s2,
	abc = this,
	nns = abc.cfmt().nns

	function get_beat(s) {
	    var	beat = C.BLEN / 4

		if (!s.a_meter[0] || s.a_meter[0].top[0] == 'C'
		 || !s.a_meter[0].bot)
			return beat
		beat = C.BLEN / s.a_meter[0].bot[0] |0
		if (s.a_meter[0].bot[0] == 8
		 && s.a_meter[0].top[0] % 3 == 0)
			beat = C.BLEN / 8 * 3
		return beat
	} // get_beat()

	// transpose the chord back to "C"
	function set_nm(p, tr, mode) {
	    var	i, o, o2, a, n,
		csa = []

		i = p.indexOf('/')		// get the bass if any
		if (i > 0) {
			while (1) {
				if (p[i -1] != '<')
					break
				i = p.indexOf('/', i + 1)
				if (i < 0)
					break
			}
		}
		if (i < 0) {
			csa.push(p)
		} else {
			csa.push(p.slice(0, i))
			csa.push(p.slice(i + 1))
		}

		for (i = 0; i < csa.length; i++) {	// main and optional bass
			p = csa[i]

			o = p.search(/[A-G]/)		// get the base chord
			if (o < 0)
				continue		// not a chord!

			a = 0
			o2 = o + 1
			if (p[o2] == '#' || p[o2] == '♯') {
				a++
				o2++
			} else if (p[o2] == 'b' || p[o2] == '♭') {
				a--
				o2++
			}
			n = ([0, 2, 4, 5, 7, 9, 11]
					[abc2svg.nns.note_nm.indexOf(p[o])]
				+ a
				+ tr) % 12
			if (!nns.roman) {
				n = abc2svg.nns.nns_nm[n]	// major and minor
			} else if (nns.roman == 1) {
			   if (!mode)
				n = abc2svg.nns.rnn_nm[n]
			   else
				n = abc2svg.nns.rnn_nm_m[n]
			} else {
			   if (!mode)
				n = abc2svg.nns.rnn2_nm[n]
			   else
				n = abc2svg.nns.rnn2_nm_m[n]
				if (p[o2] == 'm')
					o2++
			}
			csa[i] = p.slice(0, o)
				+ n
				+ p.slice(o2)
		}
		return csa.join('/')
	} // set_nm()

	// build the arrays of chords and bars
	function build_chords(sb) {		// block 'nns'
	    var	s, i, w, bt, rep,
		bars = [],
		chords = [],
		parts = [],
		chord = [],
		beat = get_beat(voice_tb[0].meter),
		wm = voice_tb[0].meter.wmeasure,
		cur_beat = 0,
		beat_i = 0,
		tr = (tsfirst.p_v.key.k_sf + 12) * 5,	// transposition to "C"
		mode = tsfirst.p_v.key.k_mode

		// scan all the symbols
		bars.push('|')
		for (s = tsfirst; s; s = s.ts_next) {
			while (s.time > cur_beat) {
				if (beat_i < 3)	// only 2, 3 or 4 beats / measure...
					beat_i++
				cur_beat += beat
			}
			if (s.part)
				parts[chords.length] = s.part.text
			switch (s.type) {
			case C.KEY:
				tr = (s.k_sf + 12) * 5
				mode = s.k_mode
				break
			case C.NOTE:
			case C.REST:
				if (!s.a_gch)
					break

				// search a chord symbol
				for (i = 0; i < s.a_gch.length; i++) {
					if (s.a_gch[i].type == 'g') {
						if (!chord[beat_i]) {
							chord[beat_i] =
							    set_nm(s.a_gch[i].text,
									tr, mode)
						}
						break
					}
				}
				break
			case C.BAR:
				bt = s.bar_type
				if (s.time < wm) {		// if anacrusis
					if (chord.length) {
						chords.push(chord)
						bars.push(bt)
					} else {
						bars[0] = bt
					}
				} else {
					if (!s.bar_num)		// if not normal measure bar
						break
					chords.push(chord)
					bars.push(bt)
				}
				chord = []
				cur_beat = s.time	// synchronize in case of error
				beat_i = 0
				if (bt.indexOf(':') >= 0)
					rep = true	// some repeat
				while (s.ts_next && s.ts_next.type == C.BAR)
					s = s.ts_next
				break
			case C.METER:
				beat = get_beat(s)
				wm = s.wmeasure
				break
			}
		}

		if (chord.length) {
			bars.push('')
			chords.push(chord)
		}
		if (!chords.length)
			return			// no chord in this tune

		sb.chords = chords
		sb.bars = bars
		if (parts.length)
			sb.parts = parts
	} // build_chords

	// -------- set_stems --------

	// create a specific block
	if (nns) {
		C = abc2svg.C
		tsfirst = this.get_tsfirst()
		fmt = tsfirst.fmt
		voice_tb = this.get_voice_tb()
		p_v = voice_tb[this.get_top_v()]
		s = {
			type: C.BLOCK,
			subtype: 'nns',
			dur: 0,
			time: 0,
			p_v: p_v,
			v: p_v.v,
			st: p_v.st
		}

		build_chords(s)			// build the array of the chords

		// and insert it in the tune
		if (!s.chords) {		// if no chord
			;
		} else if (nns.nomusic) {	// if just the chords
			this.set_tsfirst(s)
		} else if (nns.n < 0) {		// below
			for (s2 = tsfirst; s2.ts_next; s2 = s2.ts_next)
				;
			s.time = s2.time
			s.prev = p_v.last_sym.prev // before the last symbol
			s.prev.next = s
			s.next = p_v.last_sym
			p_v.last_sym.prev = s

			s.ts_prev = s2.ts_prev
			s.ts_prev.ts_next = s
			s.ts_next = s2
			s2.ts_prev = s
			if (s2.seqst) {
				s.seqst = true
				s2.seqst = false
			}
		} else {			// above
			s.next = p_v.sym
			s.ts_next = tsfirst
			tsfirst.ts_prev = s
			this.set_tsfirst(s)
			p_v.sym.prev = s
			p_v.sym = s
		}
		s.fmt = s.prev ? s.prev.fmt : fmt
	}
	of()
    }, // set_stems()

    set_fmt: function(of, cmd, parm) {
	if (cmd == "nns") {
		if (!parm)
			parm = "1"
		parm = parm.split(/\s+/)
	    var	nns = {
			n: Number(parm.shift())
		}
		if (isNaN(nns.n)) {
			if (parm.length) {
				this.syntax(1, this.errs.bad_val, "%%nns")
				return
			}
			nns.n = 1
		}
		while (parm.length) {
			var item = parm.shift()
			if (item == "nomusic")
				nns.nomusic = true
			else if (item == "roman")
				nns.roman = 1
			else if (item == "repbrk")
				nns.repbrk = true
			else if (item.slice(0, 8) == "include=")
				nns.ls = item.slice(8).split(',')
			else if (item.slice(0, -1) == "roman=")
				nns.roman = item.slice(-1) == "1" ? 1 : 2
		}
		this.cfmt().nns = nns
		return
	}
	of(cmd, parm)
    },

    set_hooks: function(abc) {
	abc.block_gen = abc2svg.nns.block_gen.bind(abc, abc.block_gen)
	abc.set_stems = abc2svg.nns.set_stems.bind(abc, abc.set_stems)
	abc.set_format = abc2svg.nns.set_fmt.bind(abc, abc.set_format)
    }
} // nns

if (!abc2svg.mhooks)
	abc2svg.mhooks = {}
abc2svg.mhooks.nns = abc2svg.nns.set_hooks
