// grid3.js - module to insert a manual chords
//
// Copyright (C) 2020-2024 Jean-Francois Moine
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
// This module is loaded when "%%begingrid" appears in a ABC source.
//
// Parameters
//	%%begingrid [ chord-define [ noprint ] ] [ lm=<left margin> ] [ width=<width> ]
//	    list of chords, '-' or '.', measure bars ('|') and ':' for repeat
//	%%endgrid
//
//	%%gridfont font_name size (default: 'serif 16')
//
// When this command appears inside a tune and when 'chord-define' is present,
// the chords are used to define the chord symbols that are displayed
// above the staff system.
// When 'noprint' is also present, the grid itself is not displayed.
//
// The left margin may be '-1' to center the grid (default).

if (typeof abc2svg == "undefined")
    var	abc2svg = {}

abc2svg.grid3 = {

// generate the grid
    block_gen: function(of, s) {
	if (s.subtype != "grid3") {
		of(s)
		return
	}

	this.set_page()
	this.blk_flush()

    var	abc = this,
	cfmt = abc.cfmt(),
	img = abc.get_img(),
	posy = abc.get_posy(),
	txt = s.text,
	font, font_cl, cls, w,
	ln, i,
	lines = [],
	cl = [],
	bars = [],
	cells = [],
	nr = 0,			// number of rows
	nc = 0,			// number of columns
	wc = 0			// width of a cell

	// generate the grid
	function build_grid() {
	    var	i, k, l, line, bl, bar, w, hr, x0, x, y, yl, cl, cell,
		lc = '',
		path = '<path class="stroke" stroke-width="1" d="M',
		sf = '" style="font-size:' + (font.size * .72).toFixed(1) + 'px'
						// small font

		function build_ch(cl, x, y, n) {
			return '<text class="' + cl + '" x="' +
				x.toFixed(1) + '" y="' + y.toFixed(1) + '">' +
					cell[n] + '</text>\n'
		} // build_ch()

		function build_cell(cell, x, y, yl, hr) {
		    var	line

			if (cell.length > 1) {
				line = path +
					(x - wc / 2).toFixed(1) + ' ' +
					yl.toFixed(1) + 'l' +
					wc.toFixed(1) + ' -' + hr.toFixed(1) +
					'"/>\n'
				if (cell[1]) {
				    line += path +
					(x - wc / 2).toFixed(1) + ' ' +
					(yl - hr).toFixed(1) + 'l' +
					(wc / 2).toFixed(1) + ' ' + (hr / 2).toFixed(1) +
						'"/>\n' +
					build_ch(cls + sf, x - wc / 3, y, 0) +
					build_ch(cls + sf, x, y - hr * .32, 1)
				} else {
					line += build_ch(cls + sf,
						x - wc * .2, y - hr / 4, 0)
				}
				if (cell.length >= 3) {
				  if (cell[3]) {
				    line += path +
					x.toFixed(1) + ' ' +
					(yl - hr / 2).toFixed(1) + 'l' +
					(wc / 2).toFixed(1) + ' ' + (hr / 2).toFixed(1) +
						'"/>\n' +
					build_ch(cls + sf, x, y + hr * .3, 2) +
					build_ch(cls + sf, x + wc / 3, y, 3)
				  } else {
					line += build_ch(cls + sf,
						x + wc * .2, y + hr / 4, 2)
				  }
				}
			} else {
				line = build_ch(cls, x, y, 0)
			}
			return line
		} // build_cell()

		// -- build_grid() --

		// build the content of the cells
		hr = font.size * 2.1
		if (wc < hr * 1.4)
			wc = hr * 1.4			// cell width
		if (s.width) {
			w = s.width
			wc = w / nc
		} else {
			w = wc * nc			// grid width
		}
		x0 = s.lm < 0
			? (img.width / cfmt.scale - w) / 2	// center
			: s.lm + 1
		if ((s.fmt || cfmt).trimsvg)		// adjust the SVG width
			img.wx = x0 + w - img.lm - img.rm

		// generate the cells
		yl = posy + 3
		y = posy + 3 - font.size * .7
		while (1) {
			cl = cells.shift()
			if (!cl)
				break
			y += hr
			yl += hr
			x = x0 + wc / 2
			while (1) {
				cell = cl.shift()
				if (!cell)
					break
				lc += build_cell(cell, x, y, yl, hr)
				x += wc
			}
		}

		// draw the lines
		line = '<path class="stroke" d="\n'
		y = posy + 3
		for (i = 0; i <= nr; i++) {
			line += 'M' + x0.toFixed(1) + ' ' + y.toFixed(1) +
				'h' + w.toFixed(1)+ '\n'
			y += hr
		}
		x = x0
		y = posy + 3
		for (i = 0; i <= nc; i++) {
			line += 'M' + x.toFixed(1) + ' ' + y.toFixed(1) +
				'v' + (hr * nr).toFixed(1) + '\n'
			x += wc
		}
		line += '"/>\n'

		// insert the cells
		line += lc

		// show the repeat signs
		y = posy + 3 - font.size * .7
		while (1) {
			bl = bars.shift()
			if (!bl)
				break
			x = x0
			y += hr
			while (1) {
				bar = bl.shift()
				if (!bar)
					break
				if (bar[0] == ':')
					line += '<text class="' + cls + '" x="' +
						(x - 5).toFixed(1) +
						'" y="' + y.toFixed(1) +
						'" style="font-weight:bold;font-size:' +
						(font.size * 1.6).toFixed(1) +
						'px">:</text>\n'
				if (bar.slice(-1) == ':')
					line += '<text class="' + cls + '" x="' +
						(x + 5).toFixed(1) +
						'" y="' + y.toFixed(1) +
						'" style="font-weight:bold;font-size:' +
						(font.size * 1.6).toFixed(1) +
						'px">:</text>\n'
				x += wc
			}
		}
		abc.out_svg(line)
		abc.vskip(hr * nr + 6)
	} // build_grid()

	// ----- block_gen ----

	// set the text style
	if (!cfmt.gridfont)
		abc.param_set_font("gridfont", "serif 16")
	font = abc.get_font('grid')
	font_cl = abc.font_class(font)
	cls = font_cl + " mid"
	abc.add_style("\n.mid {text-anchor:middle}")
	abc.set_font('grid')		// (for strwh())

	// scan the grid content
	txt = txt.split('\n')
	while (1) {
		ln = txt.shift()	// line
		if (!ln)
			break

		// extract the bars and the chords
		ln = ln.match(/[|:]+|[^|:\s]+/g)
		bars[nr] = []
		cells[nr] = []
		i = -1
		while (1) {
			cl = ln.shift()
			if (!cl)
				break
			if (cl.match(/[:|]+/)) {
				bars[nr][++i] = cl
				cells[nr][i] = []
			} else {
				if (!cells[nr][i]) {	// if starting '|' is missing
					bars[nr][++i] = '|'
					cells[nr][i] = []
				}
				if (cl == '.' || cl == '-')
					cl = ''
				cells[nr][i].push(cl)
			}
		}
		if (cells[nr][i].length)
			bars[nr][++i] = '|'	// missing ending bar
		else
			cells[nr][i] = null	// keep just the measure bar

		if (i > nc)
			nc = i

		i = 0
		while (1) {
			cl = cells[nr][i++]
			if (!cl)
				break
			if (cl.length == 2) {
				cl[2] = cl[1]	// "| A B |" => "|A - B|"
				cl[1] = ''
			}
			w = abc.strwh(cl.join(''))[0]
			if (w > wc)
				wc = w
		}
		nr++
	}
	wc += abc.strwh('  ')[0]

	// build the grid and insert it in the music
	build_grid()
	abc.blk_flush()
    }, // block_gen()

// handle %%begingrid
    do_begin_end: function(of, type, opt, txt) {
    var	i,
	lm = -1,		// left margin - default: center the grid
	width			// grid width - default: computed

	if (type != "grid") {
		of(type, opt, txt)
		return
	}

	// replace the accidentals
	txt = txt.replace(/#|=|b/g,
		function(x) {
			switch (x) {
			case '#': return "\u266f"
			case '=': return "\u266e"
//			case 'b': return "\u266d"
			}
			return "\u266d"
		})

	if (opt.indexOf("chord-define") >= 0)
		this.cfmt().csdef = txt
	if (opt.indexOf("noprint") < 0) {
		type += "3"
		i = opt.indexOf("lm=") + 3
		if (i >= 3)
			lm = parseInt(opt.slice(i, i + 3))
		i = opt.indexOf("width=") + 6
		if (i >= 6)
			width = parseInt(opt.slice(i, i + 3))
		if (this.parse.state >= 2) {
			s = this.new_block(type)
			s.text = txt
			s.lm = lm
			s.width = width
		} else {
			abc2svg.grid3.block_gen.call(this, null, {
						subtype: type,
						text: txt,
						lm: lm,
						width: width
						})
		}
	}
    }, // do_begin_end()

    output_music: function(of) {
    var	ln, i, dt, ss, ntim, p_vc, s3, cl,
	C = abc2svg.C,
	abc = this,
	s = abc.get_tsfirst(),
	vt = abc.get_voice_tb(),
	t = abc.cfmt().csdef,
	cs = []

	// add a chord symbol
	function add_cs(ss, ch) {
	    var	s = {			// invisible rest in the voice "grid3"
			type: C.REST,
			fname: ss.fname,
			istart: ss.istart,
			iend: ss.iend,
			v: p_vc.v,
			p_v: p_vc,
			time: ntim,
			st: 0,
			fmt: ss.fmt,
			dur: 0,
			dur_orig: 0,
			invis: true,
			seqst: true,
			nhd: 0,
			notes: [{
				pit: 18,
				dur: 0
			}]
		}

		if (ch != '.' && ch != '-') {
			abc.set_a_gch(s, [{	// define the chord symbol
				type: 'g',
				text: ch,
				otext: ch,
				istart: ss.istart,
				iend: ss.iend,
				font: abc.get_font("gchord"),
				pos: p_vc.pos.gch || C.SL_ABOVE
			}])
		}

		// insert the rest
		if (!p_vc.last_sym) {
			p_vc.sym = s
		} else {
			s.prev = p_vc.last_sym
			s.prev.next = s
		}
		p_vc.last_sym = s
		s.ts_next = ss
		s.ts_prev = ss.ts_prev
		s.ts_prev.ts_next = s
		ss.ts_prev = s
		if (s.time == ss.time)
			delete ss.seqst
		return s
	} // add_cs()

	if (t) {				// if chord-define
		p_vc = {
			id: "grid3",
			v: vt.length,
			time: 0,
			pos: {
				gst: 0
			},
			scale: 1,
			st: 0,
			second: true,
			sls: []
		}
		vt.push(p_vc)	// add the voice supporting the chord symbols

		t = t.split('\n')
		while (1) {			// scan the grid content
			ln = t.shift()		// line
			if (!ln)
				break
			ln = ln.trimLeft()
			if (ln[0] == '|')
				ln = ln.slice(ln[1] == ':' ? 2 : 1)
			if (ln[ln.length - 1] != '|')
				ln = ln + '|'

			// extract the bars and the chords
			ln = ln.match(/[|:]+|[^|:\s]+/g)
			while (1) {
				cl = ln.shift()
				if (!cl)
					break
				if (cl[0] == '|' || cl[0] == ':') {
					while (s && !s.dur)
						s = s.ts_next
					if (!s)
						break
					ss = s			// first note/rest
					while (s && !s.bar_type)
						s = s.ts_next	// end of measure
					if (!cs.length)
						cs = ['.']
					ntim = ss.time
					dt = (s.time - ntim) / cs.length
					s3 = null
					for (i = 0; i < cs.length; i++) {
						if ((cs[i] != '.'
						  && cs[i] != '-')
						 || !s3) {
							while (ss.time < ntim)
								ss = ss.ts_next
							s3 = add_cs(ss, cs[i])
						}
						s3.dur += dt
						s3.dur_orig =
							s3.notes[0].dur = s3.dur
						ntim += dt
					}
					while (s && s.type != C.BAR)
						s = s.ts_next
					ss = {
						type: C.BAR,
						bar_type: "|",
						fname: s.fname,
						istart: s.istart,
						iend: s.iend,
						v: p_vc.v,
						p_v: p_vc,
						st: 0,
						time: s.time,
						dur: 0,
						nhd: 0,
						notes: [{
							pit: 18
						}],
						next: s,
						ts_next: s,
						prev: s.prev,
						ts_prev: s.ts_prev
					}
					if (!s)
						break
					ss.fmt = s.fmt
					if (s.seqst) {
						ss.seqst = true
						delete s.seqst
					}
					ss.prev.next =
						ss.ts_prev.ts_next =
						s.prev =
							s.ts_prev = ss
					cs = []
				} else {
					cs.push(cl)
				}
			}
		}
	}
	of()
    }, // output_music()

    set_hooks: function(abc) {
	abc.block_gen = abc2svg.grid3.block_gen.bind(abc, abc.block_gen)
	abc.do_begin_end = abc2svg.grid3.do_begin_end.bind(abc, abc.do_begin_end)
	abc.output_music = abc2svg.grid3.output_music.bind(abc, abc.output_music)
    }
} // grid3

if (!abc2svg.mhooks)
	abc2svg.mhooks = {}
abc2svg.mhooks.grid3 = abc2svg.grid3.set_hooks
