// tunhd.js - module for a formatted tune header
//
// Copyright (C) 2025 Jean-Francois Moine
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
// This module is loaded when "%%titleformat" appears in a ABC source.
//

"use strict"
if (typeof abc2svg == "undefined")
    var	abc2svg = {}

abc2svg.tunhd = {
    info_fnt: {
		A: "info",
		C: "composer",
		O: "composer",
		P: "parts",
		Q: "tempo",
		R: "info",
		T: "title",
		X: "title"
    },

    // output the tune header from a titleformat
    tunhd: function(of) {
    var	abc = this,
	cfmt = abc.cfmt(),
	glovar = abc.glovar(),
	info = abc.info(),
	info_sz = {
		A: cfmt.infospace,
		C: cfmt.composerspace,
		O: cfmt.composerspace,
		R: cfmt.infospace
	},
	info_nb = {},
	c, align, q, j,
	hfnt = abc.get_font("history"),
	line = [],				// array of [align, str, w, h]
	p = cfmt.titleformat,
	i = 0,
	ya = {
		l: cfmt.titlespace,
		c: cfmt.titlespace,
		r: cfmt.titlespace
	},
	xa = {
		l: 0,
		c: abc.get_lwidth() * .5,
		r: abc.get_lwidth()
	}

	if (!p)
		return of()

	// output one title line
	function out() {
	    var	item, align, p, h, x, yd,
		yb = {
			l: 0,
			c: 0,
			r: 0
		},
		y = 0,
		i = 0

		while (1) {			// get the y offset of the top text
			item = line[i++]	// [ align, string, height ]
			if (!item)
				break
			align = item[0]
			h = item[2] * 1.1
			if (y < h)
				y = h
			yb[align] = item[2]
		}
		ya.l += y - yb.l
		ya.c += y - yb.c
		ya.r += y - yb.r
		while (1) {
			item = line.shift()
			if (!item)
				break
			align = item[0]
			p = item[1]
			h = item[2] * 1.1
			x = xa[align]
			y = ya[align] + h
			yd = y - item[2] * .22	// descent
			abc.out_svg('<text class="'
				+ abc.font_class(hfnt)
				+ '" x="')
			abc.out_sxsy(x, '" y="', -yd)
			if (align == 'c')
				abc.out_svg('" text-anchor="middle')
			else if (align == 'r')
				abc.out_svg('" text-anchor="end')
			abc.out_svg('">' + p + '</text>\n')
			ya[align] = y
		}
		if (ya.c > ya.l)
			ya.l = ya.c
		if (ya.r > ya.l)
			ya.l = ya.r
		ya.c = ya.r = ya.l
	} // out()

	// convert a string containing info fields ($x)
	// and return [ align, string, height ]
	function cnv(p) {
	    var	c, j, t, fntnam, fnt, wh, nfnt,
		h = 0,
		i = 0,
		l = 0,
		o = ""

		while (1) {
			c = p[i++]
			if (!c)
				break
			if (c != '$') {
				if (!o)
					h = hfnt.size * 1.1
				o += c
				continue
			}
			if (p[i] < 'A' || p[i] > 'Z') {
				if (isNaN(+p[i]))
					o += c
				else
					nfnt = +p[i++]
				continue
			}
			c = p[i++]			// info letter
			if (!info[c])
				continue		// return?
			j = info_nb[c] || 0
			info_nb[c] = j + 1
			t = info[c].split('\n')[j]	// info value
			if (!t)
				continue		// return?
			fntnam = abc2svg.tunhd.info_fnt[c] || "history"
			fnt = abc.get_font(fntnam)
			switch (c) {
			case 'P':
				t = cfmt.partname ? abc.part_seq(c) : info.P
				break
			case 'Q':
				abc.set_width(glovar.tempo)
				t = glovar.tempo.tempo_str
				glovar.tempo.invis = 1 //true
				break
			case 'T':
				if (j)
					fnt = abc.get_font("subtitle")
				break
			default:
				t = info[c].split('\n')[j]
				break
			}
			if (fnt != hfnt || nfnt) {
				if (nfnt)
					fnt = abc.get_font("u" + nfnt)
				abc.set_font(fnt)
			}
			if (c == 'Q') {			// string already formatted
				wh = glovar.tempo.tempo_wh
			} else {
				t = abc.str2svg(t)
				wh = t.wh
			}
			if (fnt != hfnt)
				t = '<tspan class="' + abc.font_class(fnt)
					+ '">' + t + '</tspan>'
			if (wh[1] > h)
				h = wh[1]
			o += t
		}
		if (!o)
			return
		return [ align, o, h]
	} // cnv()

	abc.set_font(hfnt)
	while (1) {
		while (p[i] == ' ')
			i++
		c = p[i++]
		if (!c)
			break
		if (c < 'A' || c > 'Z') {
			switch (c) {
			case ',':			// end line
				out()
				// fall thru
			default:
				continue
			case '<':
				align = 'l'
				c = p[i++]
				break
			case '>':
				align = 'r'
				c = p[i++]
				break
			case '"':
				align = 'c'
				break
			}
		} else {
			switch (p[i]) {		// old syntax
			case '-':
				align = 'l'
				i++
				break
			case '1':
				align = 'r'
				i++
				break
			case '0':
				i++
				// fall thru
			default:
				align = 'c'
				break
			}
		}
		if (c != '"') {
			q = "$" + c
			if (p[i] == '+')
				q += " $" + p[++i]	// assume there is a letter
		} else {
			j = p.indexOf('"' , i + 1)
			if (j < 0) {
//fixme: error
				i = p.length
				continue
			}
			q = p.slice(i, j)
			i = j + 1
		}
		q = cnv(q)
		if (q)					// if some text
			line.push(q)
	}
	out()						// last line

	abc.vskip(ya.l + cfmt.musicspace)
    }, // tunhd()

    set_fmt: function(of, cmd, parm) {
	if (cmd == "titleformat")
		this.cfmt()[cmd] = parm
	else
		of(cmd, parm)
    }, // set_fmt()

    set_hooks: function(abc) {
	abc.set_format = abc2svg.tunhd.set_fmt.bind(abc, abc.set_format)
	abc.tunhd = abc2svg.tunhd.tunhd.bind(abc, abc.tunhd)
    }
} // tunhd

if (!abc2svg.mhooks)
	abc2svg.mhooks = {}
abc2svg.mhooks.tunhd = abc2svg.tunhd.set_hooks
