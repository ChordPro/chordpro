// diag.js - module to insert guitar chord diagrams
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
// This module is loaded when "%%diagram" or "%%setdiag" appear in a ABC source.
//
// The command %%diagram draws a chord diagram above the chord symbols.
//
// Parameters
//	%%diagram [ <#diagram> | 0 ]
// with
//	<#diagram> identifier of the diagram type (number)
//	('1' is for the 6 strings guitar)
//
// The command %%setdiag defines the chord diagram of a chord symbol
//	for the current diagram type.
//
// Parameters
//	%%setdiag <chord> <dots> <label[,pos]> <fingers> [barre=<num>-<num>]
// with
//	<chord> = chord symbol
//	<dots>  = list of diagram offset of dots on the strings - '0 or 'x': no dot
//	<label> = text to write on the left of the <pos>th fret
//				(<pos> default = 1, fret #0 is no text)
//	<fingers> = finger numbers ou 'x' (mute) or '0'/'y' (no finger)
//	barre=<num>-<num> draw a bar between the two string numbers in the first fret
//				(numbering order 654321 for E,A,D,GBe)

if (typeof abc2svg == "undefined")
    var	abc2svg = {}

abc2svg.diag = {

    cd4: {},
// common diagrams by Guido Gonzato from http://www.guitar-chord.org/ (2021-08-27)
    cd6: {
	C: "x32010 ,0 x32010",
	Cm: "x03320 fr3 x03420 barre=5-1",
	C7: "x32310 ,0 x32410",
	Cm7: "003020 fr3 x03020 barre=5-1",
	CM7: "032000 ,0 x21000",
	Csus4: "x03340 fr3 x02340 barre=5-1",
	D: "000232 ,0 x00132",
	Dm: "000231 ,0 x00231",
	D7: "000212 ,0 x00312",
	Dm7: "000211 ,0 xx0211",
	DM7: "000222 ,0 xx0111",
	Dsus4: "000233 ,0 xx0134",
	E: "022100 ,0 023100",
	Em: "022000 ,0 023000",
	E7: "020100 ,0 020100",
	Em7: "022030 ,0 023040",
	EM7: "021100 ,0 031200",
	Esus4: "022200 ,0 023400",
	F: "033200 fr1 034200 barre=6-1",
	Fm: "033000 fr1 034000 barre=6-1",
	F7: "030200 fr1 030200 barre=6-1",
	Fm7: "030000 fr1 030000 barre=6-1",
	FM7: "xx3210 ,0 xx3210",
	Fsus4: "033300 fr1 023400 barre=6-1",
	G: "320003 ,0 230004",
	Gm: "033000 fr3 034000 barre=6-1",
	G7: "320001 ,0 320001",
	Gm7: "030000 fr3 030000 barre=6-1",
	GM7: "320002 ,0 310002",
	Gsus4: "033300 fr3 023400 barre=6-1",
	A: "002220 ,0 002340",
	Am: "002210 ,0 002310",
	A7: "002020 ,0 002030",
	Am7: "002010 ,0 002010",
	AM7: "002120 ,0 x02130",
	Asus4: "x02230 ,0 x02340",
	B: "x03330 fr2 002340 barre=5-1",
	Bm: "x03320 fr2 003410 barre=5-1",
	B7: "021202 ,0 x21304",
	Bm7: "003020 fr2 x03020 barre=5-1",
	BM7: "003230 fr2 x03240 barre=5-1",
	Bsus4: "x03340 fr2 x02340 barre=5-1",
    }, // cd6{}

// function called before tune generation
    draw_gchord: function(of, i, s, x, y) {
    var	gch, nm,
	cfmt = this.cfmt(),
	n = cfmt.diag,				// number of strings
	glyphs = this.get_glyphs()

	// create the base decorations if not done yet
	if (!glyphs.ddot) {
		this.add_style("\
\n.fng {font:6px sans-serif}\
\n.frn {font:italic 7px sans-serif}")
		glyphs.ddot = '<circle id="ddot" class="fill" r="1.5"/>'
	}

	if (!glyphs["fb" + n]) {
		if (n == 4) {
			glyphs.fb4 = '<g id="fb4">\n\
<path class="stroke" stroke-width="0.4" d="\
M-6 -24h12m0 6h-12\
m0 6h12m0 6h-12\
m0 6h12"/>\n\
<path class="stroke" stroke-width="0.5" d="\
M-6 -24v24m4 0v-24\
m4 0v24m4 0v-24"/>\n\
</g>'
			glyphs.nut4 =
				'<path id="nut4" class="stroke" stroke-width="1.6" d="\
M-6.2 -24.5h12.4"/>'
		} else {
			glyphs.fb6 = '<g id="fb6">\n\
<path class="stroke" stroke-width="0.4" d="\
M-10 -24h20m0 6h-20\
m0 6h20m0 6h-20\
m0 6h20"/>\n\
<path class="stroke" stroke-width="0.5" d="\
M-10 -24v24m4 0v-24\
m4 0v24m4 0v-24\
m4 0v24m4 0v-24"/>\n\
</g>'
			glyphs.nut6 =
				'<path id="nut6" class="stroke" stroke-width="1.6" d="\
M-10.2 -24.5h20.4"/>'
		}
	}

	// convert the chord symbol to a "better known" one
	function ch_cnv(t) {
	    var	a = t.match(/[A-G][#♯b♭]?([^/]*)\/?/)	// a[1] = chord type
		if (a && a[1]) {
			a[2] = abc2svg.ch_alias[a[1]]
			if (a[2] != undefined)
				t = t.replace(a[1], a[2])
		}
		return t.replace('/', '.')
			.replace(/\u266f/g,'#')
			.replace(/\u266d/g,'b')
	} // ch_cnv()

	// create a glyph of the diagram
	function diag_add(nm) {			// chord name
	    var	dc, i, l, x, y,
		d = abc2svg.diag["cd" + n][nm.slice(1)]
						// definition of the diagram

		if (!d)
			return		// no diagram of this chord
		d = d.split(' ')
		x = 2 - 2 * n
		dc = '<g id="' + nm + '">\n\
<use xlink:href="#fb' + n + '"/>\n'
		l = d[1].split(',')	// label,position
		if (!l[0] || l[0].slice(-1) == l[1])
			dc += '<use xlink:href="#nut' + n + '"/>\n'
		if (l[0])
			dc += '<text x="' + (x - 10).toString()
				+ '" y="' + ((l[1] || 1) * 6 - 25)
				+ '" class="frn">' + l[0] + '</text>\n'
		// fingers
		dc += '<text x="' + (n == 6 ? '-12,-8,-4,0,4,8'
					: '-8,-4,0,4')
				+ '" y="-26" class="fng">'
				+ d[2].replace(/[y0]/g, ' ')
				+ '</text>\n'
		// dots
		for (i = 0; i < n; i++) {
			l = d[0][i]
			if (l && l != 'x' && l != '0')
				dc += '<use x="' + (i * 4 + x)
					+ '" y="' + (l * 6 - 27)
					+ '" xlink:href="#ddot"/>\n'
		}
		// barre
		if (d[3]) {
			l = d[3].match(/barre=(\d)-(\d)/)
			if (l)
				dc += '<path id="barre" class="stroke"\
 stroke-width="1.4" d="M' + ((n - l[1]) * 4 + x - 2)
					+ ' -21h' + ((l[1] - l[2]) * 4 + 4) + '"/>'
		}
		dc += '</g>'
		glyphs[nm] = dc
	} // diag_add()

	// --- draw_gchord ---
	of(i, s, x, y)		// draw the chord symbols and the annotations

	if ((s.invis && s.play)	// play sequence: no chord nor annotation
	 || !n)			// no %%diagram
		return
	gch = s.a_gch[i]
	if (!gch || gch.type != 'g' || gch.capo)
		return
	nm = n + ch_cnv(gch.text)	// glyph name

	// build a glyph if not done yet
	if (!glyphs[nm])
		diag_add(nm)

	// output the diagram above the chord symbol
	if (glyphs[nm]) {
		x = s.x
		y = this.y_get(s.st, 1, x - 10, 20)
		this.xygl(x, y + 2, nm)
		this.y_set(s.st, 1, x - 10, 20, y + 34)
	}
    }, // draw_gchord()

    set_fmt: function(of, cmd, param) {
    var	a, d, n,
	cfmt = this.cfmt()

	switch (cmd) {
	case "diagram":
		n = param
		if (n == '0')
			n = ''
		else if (n != '4')
			n = '6'
		cfmt.diag = n
		return
	case "setdiag":
		n = cfmt.diag
		if (!n)
			n = "6"		// default = 6 strings guitar
		a = param.match(/(\S*)\s+(.*)/)
		if (a && a.length == 3) {
			d = a[2].split(' ')
			if (d && d.length >= 3) {
				abc2svg.diag["cd" + n][a[1].replace('/', '.')]
					= a[2]
				return
			}
		}
		this.syntax(1, this.errs.bad_val, "%%setdiag")
		return
	}
	of(cmd, param)
    },

    set_hooks: function(abc) {
	abc.draw_gchord = abc2svg.diag.draw_gchord.bind(abc,abc.draw_gchord)
	abc.set_format = abc2svg.diag.set_fmt.bind(abc, abc.set_format)
    }
} // diag

if (!abc2svg.mhooks)
	abc2svg.mhooks = {}
abc2svg.mhooks.diag = abc2svg.diag.set_hooks
