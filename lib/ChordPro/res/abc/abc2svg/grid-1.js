// abc2svg - grid.js - module to insert a chord grid before or after a tune
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
// This module is loaded when "%%grid" appears in a ABC source.
//
// Parameters
//	%%grid <n> [include=<list>] [nomusic] [norepeat] [repbrk] [parts]
//		<n> = number of columns (1: auto)
//			> 0: above the tune, < 0: under the tune
//		<list> = comma separated list of (continuous) measure numbers
//		'nomusic' displays only the grid
//		'norepeat' omits the ':' indications
//		'repbrk' starts a new grid line on start/stop repeat
//		'parts' displays the parts on the left side of the grid
//	%%gridfont font_name size (default: 'serif 16')

if (typeof abc2svg == "undefined")
    var	abc2svg = {}

abc2svg.grid = {
    pl: '<path class="stroke" stroke-width="1" d="M',

// generate the grid
    block_gen: function(of, s) {
	if (s.subtype != "grid") {
		of(s)
		return
	}

    var	abc = this,
	img, cls,
	cfmt = abc.cfmt(),
	grid = cfmt.grid

// generate the grid
function build_grid(s, font) {
    var	i, k, l, nr, bar, w, hr, x0, x, y, yl, ps, d,
	lc = '',
	chords = s.chords,
	bars = s.bars,
	parts = s.parts || [],
	wmx = s.wmx,
	cells = [],
	nc = grid.n

	// set some chord(s) in each cell
	function set_chords() {
	    var	i, ch,
		pch = '-'

		for (i = 0; i < chords.length; i++) {
			ch = chords[i]
			if (!ch[0])
				ch[0] = pch
			if (ch.length == 0)
				continue
			if (ch.length == 1) {
				pch = ch[0]
				continue
			}
			if (ch.length == 2) {
				ch[2] = ch[1];
				ch[1] = null;
				pch = ch[2]
				continue
			}
			if (ch.length == 3) {
				pch = ch[2]
				continue
			}
			if (!ch[2])
				ch[2] = ch[1] || ch[0];
			pch = ch[3]
		}
	} // set_chords()

	function build_cell(cell, x, y, yl, hr) {
		if (cell.length > 1) {
			abc.out_svg(abc2svg.grid.pl)		// / line
			abc.out_sxsy(x - wmx / 2, ' ', yl)
			abc.out_svg('l' +
				wmx.toFixed(1) + ' -' + hr.toFixed(1) +
				'"/>\n')
			if (cell[1]) {
			    abc.out_svg(abc2svg.grid.pl)	// \ left line
			    abc.out_sxsy(x - wmx / 2, ' ', yl + hr)
			    abc.out_svg('l' +
				(wmx / 2).toFixed(1) + ' ' + (hr / 2).toFixed(1) +
				'"/>\n')
			    abc.set_font('gs')			// small font
			    abc.xy_str(x - wmx / 3, y, cell[0])
			    abc.xy_str(x, y + hr / 3, cell[1])
			} else {
			    abc.set_font('gs')
			    abc.xy_str(x - wmx * .2, y + hr / 4, cell[0])
			}
			if (cell.length >= 3) {
			  if (cell[3]) {
			    abc.out_svg(abc2svg.grid.pl)	// \ right line
			    abc.out_sxsy(x, ' ', yl + hr / 2)
			    abc.out_svg('l' +
				(wmx / 2).toFixed(1) + ' ' + (hr / 2).toFixed(1) +
				'"/>\n')
			    abc.set_font('gs')
			    abc.xy_str(x, y - hr / 3, cell[2])
			    abc.xy_str(x + wmx / 3, y, cell[3])
			  } else {
			    abc.set_font('gs')
			    abc.xy_str(x + wmx * .2, y - hr / 4, cell[2])
			  }
			}
		} else {
			abc.set_font('grid')
			abc.xy_str(x, y, cell[0])
		}
	} // build_cell()

	// draw the horizontal lines
	function draw_hl() {
	    var	i, i1, j, x,
		y = -1

		for (i = 0; i <= nr + 1; i++) {
			j = 0
			i1 = i > 0 ? i - 1 : 0
			while (1) {
				while (j <= nc && !d[i1][j])
					j++
				if (j > nc)
					break
				x = wmx * j
				while (j <= nc && d[i1][j])
					j++
				if (i && i1 < nr) {
					while (j <= nc && d[i1 + 1][j])
						j++
				}
				abc.out_svg('M')
				abc.out_sxsy(x0 + x, ' ', y)
				abc.out_svg('h' + (wmx * j - x).toFixed(1)+ '\n')
			}
			y -= hr
		}
	} // draw_hl()

	// draw the vertical lines
	function draw_vl() {
	    var	i, i1, j, y,
		x = x0

		for (i = 0; i <= nc; i++) {
			j = 0
			i1 = i > 0 ? i - 1 : 0
			while (1) {
				while (j <= nr && !d[j][i1])
					j++
				if (j > nr)
					break
				y = hr * j
				while (j <= nr && d[j][i1])
					j++
				abc.out_svg('M')
				abc.out_sxsy(x, ' ', -y - .5)
				abc.out_svg('v' + (hr * j - y + 1).toFixed(1) + '\n')
			}
			x += wmx
		}
	} // draw_vl()

	// ------- build_grid() -------

	// set some chords in each cell
	set_chords()

	// build the content of the cells
	if (!grid.ls) {
		cells = chords
	} else {				// with list of mesure numbers
		bar = bars;
		bars = [ ]
		ps = parts
		parts = []
		for (i = 0; i < grid.ls.length; i++) {
			l = grid.ls[i]
			if (l.indexOf('-') < 0)
				l = [l, l]
			else
				l = l.split('-')
			for (k = l[0] - 1; k < l[1]; k++) {
				if (!chords[k])		// error
					break
				cells.push(chords[k]);
				bars.push(bar[k])
				parts.push(ps[k])
			}
		}
		bars.push(bar[k])		// ending bar
	}

	// get the number of columns
	if (nc < 0)
		nc = -nc
	if (nc < 3)				// auto
		nc = cells.length % 6 == 0 ? 6 : 8
	if (nc > cells.length)
		nc = cells.length;

	hr = font.size * 2
	if (wmx < hr * 1.5)
		wmx = hr * 1.5				// cell width

	x0 = img.width - img.lm - img.rm		// staff width
	w = wmx * nc
	if (w > x0) {
		nc /= 2;
		w /= 2
	}

	// generate the cells
	yl = -1
	y = -1 + font.size * .6
	nr = -1
	x0 = (x0 / cfmt.scale - w) / 2
	d = []
	for (i = 0; i < cells.length; i++) {
		if (i == 0
		 || (grid.repbrk
		  && (bars[i].slice(-1) == ':' || bars[i][0] == ':'))
		 || parts[i]
		 || k >= nc) {
			y -= hr			// new row
			yl -= hr
			x = x0 + wmx / 2
			k = 0
			nr++
			d[nr] = []
		}
		d[nr][k] = 1
		k++
		build_cell(cells[i], x, y, yl, hr)
		x += wmx
	}

	// draw the lines
	abc.out_svg('<path class="stroke" stroke-width="1" d="\n')
	draw_hl()
	draw_vl()
	abc.out_svg('"/>\n')

	// show the repeat signs and the parts
	y = -1 + font.size * .7
	x = x0
	for (i = 0; i < bars.length; i++) {
		bar = bars[i]
		if (bar[0] == ':') {
			abc.out_svg('<text class="' + cls + '" x="')
			abc.out_sxsy(x - 5, '" y="', y)
			abc.out_svg('" style="font-weight:bold;font-size:' +
				(font.size * 1.5).toFixed(1) + 'px">:</text>\n')
		}
		if (i == 0
		 || (grid.repbrk
		  && (bar.slice(-1) == ':' || bar[0] == ':'))
		 || parts[i]
		 || k >= nc) {
			y -= hr;			// new row
			x = x0
			k = 0
			if (parts[i]) {
				w = abc.strwh(parts[i])[0]
				abc.out_svg('<text class="' + cls + '" x="')
				abc.out_sxsy(x - 2 - w, '" y="', y)
				abc.out_svg('" style="font-weight:bold">' +
					parts[i] + '</text>\n')
			}
		}
		k++
		if (bar.slice(-1) == ':') {
			abc.out_svg('<text class="' + cls + '" x="')
			abc.out_sxsy(x + 5, '" y="', y)
			abc.out_svg('" style="font-weight:bold;font-size:' +
				(font.size * 1.5).toFixed(1) + 'px">:</text>\n')
		}
		x += wmx
	}
	abc.vskip(hr * (nr + 1) + 6)
} // build_grid()

	// ----- block_gen() -----
    var	p_voice, n, font, f2

	abc.set_page()
	img = abc.get_img()

	// set the text style
	font = abc.get_font('grid')
	if (font.class)
		font.class += ' mid'
	else
		font.class = 'mid'
	cls = abc.font_class(font)

	// define a smaller font
	abc.param_set_font("gsfont",
		font.name + ' ' + (font.size * .7).toFixed(1))
	f2 = cfmt.gsfont
	if (font.weight)
		f2.weight = font.weight
	if (font.style)
		f2.style = font.style
	f2.class = font.class
	abc.add_style("\n.mid {text-anchor:middle}")

	// create the grid
	abc.blk_flush()
	build_grid(s, font)
	abc.blk_flush()
    }, // block_gen()

    set_stems: function(of) {
    var	C = abc2svg.C,
	abc = this,
	tsfirst = abc.get_tsfirst(),
	voice_tb = abc.get_voice_tb(),
	cfmt = abc.cfmt(),
	grid = cfmt.grid

	// extract one of the chord symbols
	// With chords as "[yyy];xxx"
	// (!sel - default) returns "yyy" and (sel) returns "xxx"
	function cs_filter(a_cs) {
	    var	i, cs, t

		for (i = 0; i < a_cs.length; i++) {
			cs = a_cs[i]
			if (cs.type != 'g')
				continue
			t = cs.text
			if (cfmt.altchord) {
				for (i++; i < a_cs.length; i++) {
					cs = a_cs[i]
					if (cs.type != 'g')
						continue
					t = cs.text
					break
				}
			}
			return t.replace(/\[|\]/g, '')
		}
	} // cs_filter()

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

	// build the arrays of chords and bars
	function build_chords(sb) {		// block 'grid'
	    var	s, i, w, bt, rep,
		bars = [],
		chords = [],
		parts = [],
		chord = [],
		beat = get_beat(voice_tb[0].meter),
		wm = voice_tb[0].meter.wmeasure,
		cur_beat = 0,
		beat_i = 0,
		wmx = 0,
		some_chord = 0

		// scan the music symbols
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
			case C.NOTE:
			case C.REST:
			case C.SPACE:
				if (!s.a_gch || chord[beat_i])
					break
				bt = cs_filter(s.a_gch)
				if (!bt)
					break
					w = abc.strwh(bt.replace(
						/<[^>]+>/gm,''))
					if (w[0] > wmx)
						wmx = w[0]
					bt = new String(bt)
					bt.wh = w
				chord[beat_i] = bt
				break
			case C.BAR:
				i = s.bar_num		// check if normal measure bar
				bt = s.bar_type
				while (s.ts_next && s.ts_next.time == s.time) {
					if (s.ts_next.dur
					 || s.ts_next.type == C.SPACE)
						break
					s = s.ts_next
					if (s.type == C.METER) {
						beat = get_beat(s)
						wm = s.wmeasure
						continue
					}
					if (s.type != C.BAR)
						continue
					if (s.bar_type[0] == ':'
					 && bt[0] != ':')
						bt = ':' + bt
					if (s.bar_type.slice(-1) == ':'
					 && bt.slice(-1) != ':')
						bt += ':'
					if (s.bar_num)
						i = s.bar_num
					if (s.part)
						parts[chords.length + 1] = s.part.text
				}
				if (grid.norep)
					bt = '|'
				if (s.time < wm) {		// if anacrusis
					if (chord.length) {
						chords.push(chord)
						bars.push(bt)
					} else {
						bars[0] = bt
					}
				} else {
					if (!i)		// if not normal measure bar
						break
					chords.push(chord)
					bars.push(bt)
				}
				if (chord.length)
					some_chord++
				chord = []
				cur_beat = s.time	// synchronize in case of error
				beat_i = 0
				if (bt.indexOf(':') >= 0)
					rep = true	// some repeat
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
		if (!some_chord)
			return			// no chord in this tune

		wmx += abc.strwh(rep ? '    ' : '  ')[0]

		sb.chords = chords
		sb.bars = bars
		if (grid.parts && parts.length)
			sb.parts = parts
		sb.wmx = wmx
	} // build_chords

	// -------- set_stems --------

	// create a specific block
	if (grid) {
	    var	C = abc2svg.C,
		tsfirst = this.get_tsfirst(),
		fmt = tsfirst.fmt,
		voice_tb = this.get_voice_tb(),
		p_v = voice_tb[this.get_top_v()],
		s = {
			type: C.BLOCK,
			subtype: 'grid',
			dur: 0,
			time: 0,
			p_v: p_v,
			v: p_v.v,
			st: p_v.st
		}

		if (!cfmt.gridfont)
			abc.param_set_font("gridfont", "serif 16")
		abc.set_font('grid')
		build_chords(s)			// build the array of the chords

		// and insert it in the tune
		if (!s.chords) {		// if no chord
			;
		} else if (grid.nomusic) {	// if just the grid
			this.set_tsfirst(s)
		} else if (grid.n < 0) {	// below
			for (var s2 = tsfirst; s2.ts_next; s2 = s2.ts_next)
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
	if (cmd == "grid") {
		if (!parm)
			parm = "1";
		parm = parm.split(/\s+/)
		var grid = {n: Number(parm.shift())}
		if (isNaN(grid.n)) {
			if (parm.length) {
				this.syntax(1, this.errs.bad_val, "%%grid")
				return
			}
			grid.n = 1
		}
		while (parm.length) {
			var item = parm.shift()
			if (item == "norepeat")
				grid.norep = true
			else if (item == "nomusic")
				grid.nomusic = true
			else if (item == "parts")
				grid.parts = true
			else if (item == "repbrk")
				grid.repbrk = true
			else if (item.slice(0, 8) == "include=")
				grid.ls = item.slice(8).split(',')
		}
		this.cfmt().grid = grid
		return
	}
	of(cmd, parm)
    },

    set_hooks: function(abc) {
	abc.block_gen = abc2svg.grid.block_gen.bind(abc, abc.block_gen)
	abc.set_stems = abc2svg.grid.set_stems.bind(abc, abc.set_stems)
	abc.set_format = abc2svg.grid.set_fmt.bind(abc, abc.set_format)
    }
} // grid

if (!abc2svg.mhooks)
	abc2svg.mhooks = {}
abc2svg.mhooks.grid = abc2svg.grid.set_hooks
